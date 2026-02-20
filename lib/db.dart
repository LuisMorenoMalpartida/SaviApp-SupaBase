import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logger.dart';
//import 'dart:io';
//import 'package:mime/mime.dart';

// --- ACCESO GLOBAL A LA DB ---
// Allow injecting a test double for the Supabase client during tests.
dynamic supabase = Supabase.instance.client;

/// Replace the active supabase client (used for testing/mocking)
void setSupabaseClient(dynamic client) {
  supabase = client;
}

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

class ParticipanteModel {
  final String id;
  final String usuarioId;
  final String juntaId;
  final String rol;
  final bool pagoRealizado;
  final String? voucherUrl;

  ParticipanteModel({
    required this.id,
    required this.usuarioId,
    required this.juntaId,
    required this.rol,
    required this.pagoRealizado,
    this.voucherUrl,
  });

  factory ParticipanteModel.fromJson(Map<String, dynamic> j) {
    return ParticipanteModel(
      id: j['id']?.toString() ?? '',
      usuarioId: j['usuario_id']?.toString() ?? '',
      juntaId: j['junta_id']?.toString() ?? '',
      rol: j['rol']?.toString() ?? '',
      pagoRealizado:
          j['pago_realizado'] == true || j['pago_realizado'] == 'true',
      voucherUrl: j['voucher_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'junta_id': juntaId,
      'rol': rol,
      'pago_realizado': pagoRealizado,
      'voucher_url': voucherUrl,
    };
  }
}

class PerfilModel {
  final String id;
  final String nombre;
  final String apellido;
  final String dni;
  final String telefono;
  final String? email;
  final String? avatarUrl;

  PerfilModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.telefono,
    this.email,
    this.avatarUrl,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> j) {
    return PerfilModel(
      id: j['id']?.toString() ?? '',
      nombre: j['nombre']?.toString() ?? '',
      apellido: j['apellido']?.toString() ?? '',
      dni: j['dni']?.toString() ?? '',
      telefono: j['telefono']?.toString() ?? '',
      email: j['email']?.toString(),
      avatarUrl: j['avatar_url']?.toString(),
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
  logger.error('[backend] auth-error: $s');
  if (s.contains('refresh_token_not_found') ||
      s.contains('Refresh Token Not Found') ||
      s.contains('refresh token not found')) {
    try {
      logger.info('[backend] checkAndSignOutOnAuthError matched, signing out.');
      Supabase.instance.client.auth.signOut();
    } catch (err) {
      logger.error('[backend] signOut failed: $err');
    }
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
    debugPrint(
        '[backend.SaviState] constructor start: ${DateTime.now().toIso8601String()}');
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
    debugPrint(
        '[backend.SaviState] constructor end: ${DateTime.now().toIso8601String()}');
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
    } on AuthException catch (e) {
      onError("Credenciales incorrectas");
      _checkAndSignOutOnAuthError(e);
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
      required Function(Map<String, dynamic>) onSuccess}) async {
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

      // Notify caller with created junta data (contains codigo_acceso)
      onSuccess(Map<String, dynamic>.from(data));

      await supabase.from('participantes').insert({
        'junta_id': data['id'],
        'usuario_id': currentUser!.id,
        'rol': 'dueño'
      });

      await cargarMisJuntas();
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
      debugPrint(
          '[backend.SaviState] cargarMisJuntas start: ${DateTime.now().toIso8601String()} user=${currentUser?.id}');
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
      debugPrint(
          '[backend.SaviState] cargarMisJuntas finished: ${DateTime.now().toIso8601String()} count=${misJuntas.length}');
      notifyListeners();
    } catch (e) {
      debugPrint("Error carga: $e");
      _checkAndSignOutOnAuthError(e);
    }
  }

  // --- 7. ELIMINAR JUNTA ---
  Future<void> eliminarJunta(String id) async {
    if (currentUser == null) return;
    try {
      isLoading = true;
      notifyListeners();
      // eliminar la junta (y dependencias si fuese necesario)
      await supabase.from('juntas').delete().eq('id', id);
      // refrescar lista local
      await cargarMisJuntas();
    } catch (e) {
      debugPrint('Error eliminando junta: $e');
      _checkAndSignOutOnAuthError(e);
    } finally {
      isLoading = false;
      notifyListeners();
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

  // --- WRAPPERS ADICIONALES PARA PARTICIPANTES / SOLICITUDES / PERFILES ---
  Future<List<dynamic>> obtenerParticipantesPorJunta(String juntaId) async {
    try {
      final participantes =
          await supabase.from('participantes').select().eq('junta_id', juntaId);
      return (participantes as List<dynamic>);
    } catch (e) {
      logger.error('Error obtenerParticipantesPorJunta: $e');
      _checkAndSignOutOnAuthError(e);
      return [];
    }
  }

  Future<List<ParticipanteModel>> obtenerParticipantesModelPorJunta(
      String juntaId) async {
    try {
      final participantes =
          await supabase.from('participantes').select().eq('junta_id', juntaId);
      final list = (participantes as List<dynamic>?) ?? [];
      return list
          .map((e) => ParticipanteModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      logger.error('Error obtenerParticipantesModelPorJunta: $e');
      _checkAndSignOutOnAuthError(e);
      return [];
    }
  }

  Future<List<dynamic>> obtenerSolicitudesPorJuntas(
      List<dynamic> juntaIds) async {
    try {
      if (juntaIds.isEmpty) return [];
      final res = await supabase
          .from('solicitudes')
          .select('id,usuario_id,estado,junta_id')
          .filter('junta_id', 'in', juntaIds)
          .eq('estado', 'pendiente');
      return (res as List<dynamic>);
    } catch (e) {
      logger.error('Error obtenerSolicitudesPorJuntas: $e');
      _checkAndSignOutOnAuthError(e);
      return [];
    }
  }

  Future<List<dynamic>> obtenerSolicitudesPorJunta(String juntaId) async {
    try {
      final res = await supabase
          .from('solicitudes')
          .select('id,usuario_id,estado')
          .eq('junta_id', juntaId);
      return (res as List<dynamic>);
    } catch (e) {
      debugPrint('Error obtenerSolicitudesPorJunta: $e');
      _checkAndSignOutOnAuthError(e);
      return [];
    }
  }

  Future<List<dynamic>> obtenerPerfilesPorIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      final perfiles = await supabase
          .from('perfiles')
          .select('id,nombre,apellido,dni,telefono')
          .filter('id', 'in', ids);
      return (perfiles as List<dynamic>);
    } catch (e) {
      logger.error('Error obtenerPerfilesPorIds: $e');
      _checkAndSignOutOnAuthError(e);
      return [];
    }
  }

  Future<List<PerfilModel>> obtenerPerfilesModelPorIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      final perfiles = await supabase
          .from('perfiles')
          .select('id,nombre,apellido,dni,telefono,email,avatar_url')
          .filter('id', 'in', ids);
      final list = (perfiles as List<dynamic>?) ?? [];
      return list
          .map((e) => PerfilModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      logger.error('Error obtenerPerfilesModelPorIds: $e');
      _checkAndSignOutOnAuthError(e);
      return [];
    }
  }

  Future<void> actualizarSolicitudEstado(
      String solicitudId, String estado) async {
    try {
      await supabase
          .from('solicitudes')
          .update({'estado': estado}).eq('id', solicitudId);
    } catch (e) {
      debugPrint('Error actualizarSolicitudEstado: $e');
      _checkAndSignOutOnAuthError(e);
      rethrow;
    }
  }

  Future<void> insertarParticipante(String juntaId, String usuarioId,
      {String rol = 'miembro'}) async {
    try {
      await supabase.from('participantes').insert({
        'junta_id': juntaId,
        'usuario_id': usuarioId,
        'rol': rol,
      });
    } catch (e) {
      debugPrint('Error insertarParticipante: $e');
      _checkAndSignOutOnAuthError(e);
      rethrow;
    }
  }

  Future<void> actualizarParticipanteVoucher(String juntaId, String usuarioId,
      {bool? pagoRealizado, String? voucherUrl}) async {
    try {
      final payload = <String, dynamic>{};
      if (pagoRealizado != null) payload['pago_realizado'] = pagoRealizado;
      if (voucherUrl != null) payload['voucher_url'] = voucherUrl;
      if (payload.isEmpty) return;
      try {
        await supabase
            .from('participantes')
            .update(payload)
            .eq('junta_id', juntaId)
            .eq('usuario_id', usuarioId);
      } catch (e) {
        final s = e.toString();
        debugPrint('Initial update error in actualizarParticipanteVoucher: $s');
        // If DB doesn't have the column 'pago_realizado' retry without it
        if (s.contains('pago_realizado') || s.contains('42703')) {
          if (payload.containsKey('voucher_url')) {
            await supabase
                .from('participantes')
                .update({'voucher_url': payload['voucher_url']})
                .eq('junta_id', juntaId)
                .eq('usuario_id', usuarioId);
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error actualizarParticipanteVoucher wrapper: $e');
      _checkAndSignOutOnAuthError(e);
      rethrow;
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
      final cleaned = codigo.trim();
      debugPrint('[backend] unirseAJunta buscar codigo="$cleaned"');
      if (cleaned.isEmpty) {
        onError('Código vacío');
        return;
      }

      var junta = await supabase
          .from('juntas')
          .select('id,codigo_acceso')
          .eq('codigo_acceso', cleaned)
          .maybeSingle();

      // Try case-insensitive lookup if exact match failed
      if (junta == null) {
        final pattern = '%$cleaned%';
        debugPrint('[backend] trying ilike with pattern="$pattern"');
        try {
          junta = await supabase
              .from('juntas')
              .select('id,codigo_acceso')
              .filter('codigo_acceso', 'ilike', pattern)
              .maybeSingle();
        } catch (e) {
          debugPrint('[backend] ilike search failed: $e');
        }
      }

      // If still null, fetch recent codes and try a client-side match for diagnostics
      if (junta == null) {
        try {
          final recent = await supabase
              .from('juntas')
              .select('id,codigo_acceso')
              .order('creado_at', ascending: false)
              .limit(50);
          debugPrint(
              '[backend] recent joined codes (sample): ${recent is List ? (recent.map((r) => r['codigo_acceso']).toList()) : recent}');

          if (recent is List) {
            for (var r in recent) {
              final code = (r['codigo_acceso'] ?? '').toString().trim();
              if (code.toLowerCase() == cleaned.toLowerCase()) {
                debugPrint(
                    '[backend] client-side matched code="$code" id=${r['id']}');
                junta = r;
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('[backend] recent codes debug failed: $e');
        }
      }

      debugPrint('[backend] unirseAJunta result for "$cleaned": $junta');

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
      try {
        debugPrint(
            '[backend] _checkAndSignOutOnAuthError matched, signing out. error="$s"');
        supabase.auth.signOut();
      } catch (err) {
        debugPrint(
            '[backend] _checkAndSignOutOnAuthError signOut failed: $err');
      }
    }
  }
}

// Al final de backend.dart, después de la clase SaviState
final supabaseClient = Supabase.instance.client;
