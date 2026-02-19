import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'dart:io';
//import 'package:mime/mime.dart';

// --- ACCESO GLOBAL A LA DB ---
final supabase = Supabase.instance.client;

// --- MODELOS DE DATOS ---
class JuntaModel {
  final String id;
  final String nombre;
  final double montoCuota;
  final String periodo;
  final DateTime fechaInicio;
  final int maxParticipantes;
  final String codigoAcceso;
  final String creadorId;

  JuntaModel(
      {required this.id,
      required this.nombre,
      required this.montoCuota,
      required this.periodo,
      required this.fechaInicio,
      required this.maxParticipantes,
      required this.codigoAcceso,
      required this.creadorId});

  factory JuntaModel.fromJson(Map<String, dynamic> json) {
    return JuntaModel(
      id: json['id'],
      nombre: json['nombre'],
      montoCuota: double.parse(json['monto_cuota'].toString()),
      periodo: json['periodo'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      maxParticipantes: json['max_participantes'],
      codigoAcceso: json['codigo_acceso'],
      creadorId: json['creador_id'],
    );
  }
}

// Parser que puede correr en un isolate mediante `compute`
List<JuntaModel> _parseJuntas(List<dynamic> data) {
  return data
      .map((e) => JuntaModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

// Función pública para revisar errores de autenticación y forzar signOut
void checkAndSignOutOnAuthError(Object e) {
  final s = e.toString();
  if (s.contains('refresh_token_not_found') ||
      s.contains('Refresh Token Not Found') ||
      s.contains('refresh token not found')) {
    // Intenta cerrar sesión localmente
    try {
      Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}

// --- PROVIDER (LÓGICA) ---
class SaviState extends ChangeNotifier {
  User? currentUser;
  bool isLoading = false;
  List<JuntaModel> misJuntas = [];
  JuntaModel? juntaSeleccionada;

  SaviState() {
    // Escuchar cambios de sesión en tiempo real
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        currentUser = session.user;
        cargarMisJuntas();
      } else {
        currentUser = null;
        misJuntas = [];
      }
      notifyListeners();
    });
  }

  // GETTER: ¿Soy el dueño de la junta seleccionada?
  bool get esDueno {
    if (currentUser == null || juntaSeleccionada == null) return false;
    return juntaSeleccionada!.creadorId == currentUser!.id;
  }

  // --- 1. REGISTRO ---
  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String dni,
    required String telefono,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'dni': dni,
          'telefono': telefono,
        },
      );

      if (res.user != null) {
        onSuccess();
      }
    } on AuthException catch (e) {
      onError(e.message);
      _checkAndSignOutOnAuthError(e);
    } catch (e) {
      onError("Error inesperado");
      _checkAndSignOutOnAuthError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- 2. LOGIN ---
  Future<void> iniciarSesion(
      String email, String password, Function(String) onError) async {
    try {
      isLoading = true;
      notifyListeners();
      await supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (_) {
      onError("Credenciales incorrectas");
      _checkAndSignOutOnAuthError(_);
    } catch (e) {
      onError("Error de conexión");
      _checkAndSignOutOnAuthError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- 3. CREAR JUNTA ---
  Future<void> crearJunta(
      {required String nombre,
      required double monto,
      required String periodo,
      required DateTime inicio,
      required int cantidad,
      String moneda = 'Soles',
      required Function(String) onError,
      required Function() onSuccess}) async {
    if (currentUser == null) return;
    try {
      isLoading = true;
      notifyListeners();
      String codigo =
          "SAVI-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}";
      double total = monto * cantidad;

      final data = await supabase
          .from('juntas')
          .insert({
            'nombre': nombre,
            'monto_cuota': monto,
            'monto_total_pozo': total,
            'periodo': periodo,
            'fecha_inicio': inicio.toIso8601String(),
            'fecha_fin':
                inicio.add(const Duration(days: 365)).toIso8601String(),
            'max_participantes': cantidad,
            'moneda': moneda,
            'codigo_acceso': codigo,
            'creador_id': currentUser!.id,
            'estado': 'abierta'
          })
          .select()
          .single();

      await supabase.from('participantes').insert({
        'junta_id': data['id'],
        'usuario_id': currentUser!.id,
        'rol': 'dueño'
      });

      await cargarMisJuntas();
      onSuccess();
    } catch (e) {
      onError("Error al crear: $e");
      _checkAndSignOutOnAuthError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- 4. CARGAR JUNTAS ---
  Future<void> cargarMisJuntas() async {
    if (currentUser == null) return;
    try {
      final parts = await supabase
          .from('participantes')
          .select('junta_id')
          .eq('usuario_id', currentUser!.id);
      List ids = (parts as List).map((e) => e['junta_id']).toList();

      if (ids.isNotEmpty) {
        // Seleccionar solo columnas necesarias para reducir tamaño de respuesta
        final data = await supabase
            .from('juntas')
            .select(
                'id,nombre,monto_cuota,periodo,fecha_inicio,max_participantes,codigo_acceso,creador_id,creado_at')
            .filter('id', 'in', ids)
            .order('creado_at', ascending: false);
        // Parsear en un isolate para evitar trabajo en el hilo UI
        misJuntas = await compute(_parseJuntas, data as List<dynamic>);
      } else {
        misJuntas = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error carga: $e");
      _checkAndSignOutOnAuthError(e);
    }
  }

  // --- PERFIL DE USUARIO ---
  Future<Map<String, dynamic>?> obtenerPerfil(String userId) async {
    try {
      final perfil = await supabase
          .from('perfiles')
          .select('nombre,apellido,dni,telefono,email')
          .eq('id', userId)
          .maybeSingle();
      if (perfil is Map<String, dynamic>) return perfil;
      return null;
    } catch (e) {
      debugPrint('Error obteniendo perfil: $e');
      _checkAndSignOutOnAuthError(e);
      return null;
    }
  }

  Future<void> actualizarPerfil({
    required String userId,
    String? nombre,
    String? apellido,
    String? dni,
    String? telefono,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      final values = <String, dynamic>{};
      if (nombre != null) values['nombre'] = nombre;
      if (apellido != null) values['apellido'] = apellido;
      if (dni != null) values['dni'] = dni;
      if (telefono != null) values['telefono'] = telefono;
      // Use UPSERT to avoid duplicate key errors and create-or-update in one call
      final payload = <String, dynamic>{'id': userId, ...values};
      // ensure email exists when inserting
      payload['email'] = supabase.auth.currentUser?.email ?? '';

      await supabase.from('perfiles').upsert(payload);

      onSuccess();
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      _checkAndSignOutOnAuthError(e);
      onError(e.toString());
    }
  }

  /// Sube un archivo de avatar al bucket `avatars` y actualiza la fila de perfil
  Future<String?> subirAvatar({
    required String userId,
    required String filePath,
  }) async {
    /*
    // Upload disabled temporarily. Original logic commented out:
    final file = File(filePath);
    final bucket = 'avatars';
    final destPath = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

    // 1) Upload file
    try {
      final detectedMime =
          lookupMimeType(filePath) ?? 'application/octet-stream';
      debugPrint('Detected mime type: $detectedMime');
      debugPrint('Supabase client: $supabase');
      debugPrint(
          'Current user id (from client): ${supabase.auth.currentUser?.id}');
      debugPrint('Uploading to bucket="$bucket" path="$destPath"');
      await supabase.storage.from(bucket).upload(destPath, file,
          fileOptions: FileOptions(contentType: detectedMime));
    } catch (e) {
      debugPrint(
          'Error en storage.upload (bucket=$bucket, path=$destPath): $e');
      _checkAndSignOutOnAuthError(e);
      throw Exception('storage.upload error: $e');
    }

    // 2) Obtener URL pública
    String publicUrl;
    try {
      publicUrl = supabase.storage.from(bucket).getPublicUrl(destPath);
      debugPrint('Public URL obtained: $publicUrl');
    } catch (e) {
      debugPrint(
          'Error al obtener publicUrl (bucket=$bucket, path=$destPath): $e');
      _checkAndSignOutOnAuthError(e);
      throw Exception('getPublicUrl error: $e');
    }

    // 3) Upsert perfil con avatar_url
    try {
      await supabase.from('perfiles').upsert({
        'id': userId,
        'avatar_url': publicUrl,
        'email': supabase.auth.currentUser?.email ?? ''
      });
    } catch (e) {
      debugPrint('Error en upsert perfiles: $e');
      _checkAndSignOutOnAuthError(e);
      throw Exception('upsert perfiles error: $e');
    }

    return publicUrl;
    */

    debugPrint('subirAvatar is temporarily disabled');
    return null;
  }

  // --- 5. UNIRSE A JUNTA ---
  Future<void> unirseAJunta(
      String codigo, Function(String) onError, Function() onSuccess) async {
    if (currentUser == null) return;
    try {
      isLoading = true;
      notifyListeners();
      final junta = await supabase
          .from('juntas')
          .select('id')
          .eq('codigo_acceso', codigo)
          .maybeSingle();

      if (junta == null) {
        onError("Código no existe");
        return;
      }

      // Verificar si ya estoy
      final existe = await supabase
          .from('participantes')
          .select()
          .eq('junta_id', junta['id'])
          .eq('usuario_id', currentUser!.id)
          .maybeSingle();
      if (existe != null) {
        onError("Ya estás en esta junta");
        return;
      }

      await supabase.from('solicitudes').insert({
        'junta_id': junta['id'],
        'usuario_id': currentUser!.id,
        'estado': 'pendiente'
      });
      onSuccess();
    } catch (e) {
      onError("Error al unirse: $e");
      _checkAndSignOutOnAuthError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- 6. CERRAR SESIÓN ---
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  void _checkAndSignOutOnAuthError(Object e) {
    final s = e.toString();
    if (s.contains('refresh_token_not_found') ||
        s.contains('Refresh Token Not Found') ||
        s.contains('refresh token not found')) {
      // Forzar sign out local si el refresh token no existe/está inválido
      supabase.auth.signOut();
    }
  }
}

// Al final de backend.dart, después de la clase SaviState
final supabaseClient = Supabase.instance.client;
