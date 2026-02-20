import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:savi_app/backend.dart' as backend;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../parsers/parsers.dart' as parsers;
import '../utils/navigation.dart';
import '../utils/toast.dart';

enum UserRole { owner, member }

class SaviState extends ChangeNotifier {
  // Referencia al estado del backend
  final backend.SaviState _backend = backend.SaviState();

  // Getter para acceder a Supabase (usando tu supabaseClient)
  final SupabaseClient supabase = backend.supabaseClient;

  // Datos de UI
  UserRole rolActual = UserRole.member;
  String miIdUsuario = '';

  // Datos de la junta seleccionada
  String nombreJunta = "";
  String montoJunta = "";
  int numPersonas = 0;
  String periodo = "Mensual";
  String fechaInicio = "";
  String fechaFinal = "";
  String codigoJunta = "";
  String dniDueno = "";

  // Perfil del usuario (editable)
  String perfilNombre = '';
  String perfilApellido = '';
  String perfilDni = '';
  String perfilTelefono = '';
  String perfilAvatar = '';

  List<dynamic> listaCupos = [];
  List<dynamic> solicitudesUnirse = [];
  List<dynamic> solicitudesIntercambio = [];

  int juntasActivas = 0;
  bool isLoading = false;

  // Getters del backend
  dynamic get currentUser => _backend.currentUser;
  bool get esDueno => _backend.esDueno;

  // Lista de juntas del usuario
  List<backend.JuntaModel> misJuntas = [];
  backend.JuntaModel? juntaSeleccionada;
  Timer? _solicitudesTimer;
  String? ultimoCodigoCreado;
  StreamSubscription<dynamic>? _solicitudesSub;

  SaviState() {
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint(
          '[SaviState] _init start: ${DateTime.now().toIso8601String()}');
      // Escuchar cambios en la autenticación de manera segura
      supabase.auth.onAuthStateChange.listen((data) {
        try {
          _actualizarDesdeBackend();
        } catch (e) {
          debugPrint('Auth state change handler error: $e');
        }
      });

      // Cargar estado inicial
      await _actualizarDesdeBackend();
      debugPrint(
          '[SaviState] _init finished _actualizar: ${DateTime.now().toIso8601String()}');
    } catch (e) {
      debugPrint("Error en init: $e");
    }
  }

  Future<void> _actualizarDesdeBackend() async {
    try {
      debugPrint(
          '[SaviState] _actualizarDesdeBackend start: ${DateTime.now().toIso8601String()} currentUser=${_backend.currentUser?.id}');
      if (_backend.currentUser != null) {
        miIdUsuario = _backend.currentUser!.id;
        rolActual = _backend.esDueno ? UserRole.owner : UserRole.member;
        await cargarJuntas();
        // refresh owner solicitudes list
        await cargarSolicitudesParaDueno();
        // Start realtime subscription for owner solicitudes if user is owner
        if (rolActual == UserRole.owner)
          startRealtimeSolicitudes();
        else
          stopRealtimeSolicitudes();
        await cargarPerfil();
      } else {
        miIdUsuario = '';
        rolActual = UserRole.member;
        misJuntas = [];
        juntaSeleccionada = null;
        listaCupos = [];
        solicitudesUnirse = [];
        juntasActivas = 0;
        nombreJunta = "";
        montoJunta = "";
        codigoJunta = "";
      }
      debugPrint(
          '[SaviState] _actualizarDesdeBackend finished: ${DateTime.now().toIso8601String()}');
      notifyListeners();
    } catch (e) {
      debugPrint("Error en _actualizarDesdeBackend: $e");
    }
  }

  void startPollingSolicitudes(
      {Duration interval = const Duration(seconds: 15)}) {
    _solicitudesTimer?.cancel();
    _solicitudesTimer = Timer.periodic(interval, (_) async {
      try {
        await cargarSolicitudesParaDueno();
      } catch (e) {
        debugPrint('Error polling solicitudes: $e');
      }
    });
  }

  void stopPollingSolicitudes() {
    _solicitudesTimer?.cancel();
    _solicitudesTimer = null;
  }

  void startRealtimeSolicitudes() {
    try {
      stopRealtimeSolicitudes();
      final ownerJuntas = misJuntas
          .where((j) => j.creadorId == miIdUsuario)
          .map((j) => j.id)
          .toList();
      if (ownerJuntas.isEmpty) return;

      // Supabase stream builders may not support `filter(...)` the same way
      // as the normal query builder. Subscribe to the table and filter
      // events in the listener as a safe fallback.
      final stream = supabase.from('solicitudes').stream(primaryKey: ['id']);

      _solicitudesSub = stream.listen((_) async {
        try {
          await cargarSolicitudesParaDueno();
        } catch (e) {
          debugPrint('Error handling realtime solicitudes event: $e');
        }
      });
    } catch (e) {
      debugPrint(
          'Realtime subscription failed, keeping polling as fallback: $e');
      startPollingSolicitudes();
    }
  }

  void stopRealtimeSolicitudes() {
    try {
      _solicitudesSub?.cancel();
    } catch (_) {}
    _solicitudesSub = null;
  }

  // Note: realtime subscription removed for compatibility; we refresh owner
  // solicitudes when the app initializes or when relevant actions occur.

  Future<void> cargarSolicitudesParaDueno() async {
    try {
      if (miIdUsuario.isEmpty) return;
      // Ensure misJuntas updated
      final ownerJuntas = misJuntas
          .where((j) => j.creadorId == miIdUsuario)
          .map((j) => j.id)
          .toList();
      if (ownerJuntas.isEmpty) {
        solicitudesUnirse = [];
        notifyListeners();
        return;
      }

      final solicitudes =
          await _backend.obtenerSolicitudesPorJuntas(ownerJuntas);
      final Set<String> ids = solicitudes
          .map((s) => s['usuario_id']?.toString())
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      Map<String, dynamic> perfilesMap = {};
      if (ids.isNotEmpty) {
        final perfiles = await _backend.obtenerPerfilesPorIds(ids.toList());
        for (var perfil in perfiles) {
          perfilesMap[perfil['id'].toString()] = perfil;
        }
      }

      final combined = solicitudes.map((s) {
        final copy = Map<String, dynamic>.from(s as Map);
        copy['perfiles'] = perfilesMap[s['usuario_id']?.toString()] ?? {};
        return copy;
      }).toList();

      solicitudesUnirse = await compute(parsers.parseSolicitudes, combined);
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando solicitudes para dueño: $e');
      solicitudesUnirse = [];
    }
  }

  // --- PERFIL ---
  Future<void> cargarPerfil() async {
    try {
      debugPrint(
          '[SaviState] cargarPerfil start: ${DateTime.now().toIso8601String()} user=$miIdUsuario');
      if (miIdUsuario.isEmpty) return;
      final perfil = await _backend.obtenerPerfil(miIdUsuario);
      if (perfil != null) {
        perfilNombre = perfil['nombre'] ?? '';
        perfilApellido = perfil['apellido'] ?? '';
        perfilDni = perfil['dni'] ?? '';
        perfilTelefono = perfil['telefono'] ?? '';
        perfilAvatar = perfil['avatar_url'] ?? '';
      }
      debugPrint(
          '[SaviState] cargarPerfil finished: ${DateTime.now().toIso8601String()}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  Future<void> guardarPerfil({
    required String nombre,
    required String apellido,
    required String dni,
    required String telefono,
  }) async {
    try {
      await _backend.actualizarPerfil(
        userId: miIdUsuario,
        nombre: nombre,
        apellido: apellido,
        dni: dni,
        telefono: telefono,
        onError: (err) {
          Toast.show(err, navigatorKey.currentContext);
        },
        onSuccess: () {
          perfilNombre = nombre;
          perfilApellido = apellido;
          perfilDni = dni;
          perfilTelefono = telefono;
          Toast.show('Perfil actualizado', navigatorKey.currentContext);
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      Toast.show('Error al guardar perfil', navigatorKey.currentContext);
    }
  }

  Future<String?> subirAvatar(String filePath) async {
    try {
      final url =
          await _backend.subirAvatar(userId: miIdUsuario, filePath: filePath);
      if (url != null) {
        perfilAvatar = url;
        notifyListeners();
      }
      return url;
    } catch (e) {
      debugPrint('Error en subirAvatar: $e');
      Toast.show('Error al subir avatar', navigatorKey.currentContext);
      return null;
    }
  }

  // --- AUTENTICACIÓN ---

  Future<void> iniciarSesion(String email, String password) async {
    try {
      await _backend.iniciarSesion(email, password, (error) {
        Toast.show(error, navigatorKey.currentContext);
      });

      if (_backend.currentUser != null) {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint("Error en iniciarSesion: $e");
      Toast.show("Error al iniciar sesión", navigatorKey.currentContext);
    }
  }

  Future<bool> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String dni,
    required String telefono,
  }) async {
    final completer = Completer<bool>();
    try {
      await _backend.registrarUsuario(
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
        dni: dni,
        telefono: telefono,
        onError: (error) {
          Toast.show(error, navigatorKey.currentContext);
          if (!completer.isCompleted) completer.complete(false);
        },
        onSuccess: () {
          if (!completer.isCompleted) completer.complete(true);
        },
      );
      return await completer.future;
    } catch (e) {
      debugPrint("Error en registrarUsuario: $e");
      Toast.show("Error al registrar usuario", navigatorKey.currentContext);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _backend.logout();
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Toast.show("Sesión cerrada", ctx);
        Navigator.pushNamedAndRemoveUntil(ctx, '/login', (r) => false);
      }
    } catch (e) {
      debugPrint("Error en logout: $e");
    }
  }

  @override
  void dispose() {
    _solicitudesTimer?.cancel();
    super.dispose();
  }

  void clearUltimoCodigoCreado() {
    ultimoCodigoCreado = null;
    notifyListeners();
  }

  // --- GESTIÓN DE JUNTAS ---

  Future<void> cargarJuntas() async {
    try {
      await _backend.cargarMisJuntas();
      misJuntas = _backend.misJuntas;
      juntasActivas = misJuntas.length;
      notifyListeners();
    } catch (e) {
      debugPrint("Error en cargarJuntas: $e");
      misJuntas = [];
      juntasActivas = 0;
      notifyListeners();
    }
  }

  Future<void> seleccionarJunta(backend.JuntaModel junta) async {
    try {
      juntaSeleccionada = junta;
      await cargarDetallesJunta(junta.id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error en seleccionarJunta: $e");
    }
  }

  Future<void> cargarDetallesJunta(String juntaId) async {
    try {
      isLoading = true;
      notifyListeners();

      // Cargar datos básicos de la junta
      if (juntaSeleccionada != null) {
        nombreJunta = juntaSeleccionada!.nombre;
        montoJunta = "S/ ${juntaSeleccionada!.montoCuota.toStringAsFixed(2)}";
        numPersonas = juntaSeleccionada!.maxParticipantes;
        periodo = juntaSeleccionada!.periodo;
        fechaInicio =
            DateFormat('dd/MM/yyyy').format(juntaSeleccionada!.fechaInicio);
        codigoJunta = juntaSeleccionada!.codigoAcceso;
      }

      // Cargar participantes
      await cargarParticipantes(juntaId);

      // Cargar solicitudes pendientes
      await cargarSolicitudes(juntaId);

      // Realtime subscription removed for compatibility; rely on explicit
      // refresh when opening solicitudes or reloading state.
    } catch (e) {
      debugPrint("Error cargando detalles: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarParticipantes(String juntaId) async {
    try {
      // Obtener participantes usando el wrapper del backend
      final parts = await _backend.obtenerParticipantesPorJunta(juntaId);

      // Obtener perfiles por separado para los usuario_ids encontrados
      final Set<String> ids = parts
          .map((p) => p['usuario_id']?.toString())
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      Map<String, dynamic> perfilesMap = {};
      if (ids.isNotEmpty) {
        final perfiles = await _backend.obtenerPerfilesPorIds(ids.toList());
        for (var perfil in (perfiles as List<dynamic>)) {
          perfilesMap[perfil['id'].toString()] = perfil;
        }
      }

      // Combinar participantes con su perfil (si existe)
      final combined = parts.map((p) {
        final copy = Map<String, dynamic>.from(p as Map);
        copy['perfiles'] = perfilesMap[p['usuario_id']?.toString()] ?? {};
        return copy;
      }).toList();

      listaCupos = await compute(parsers.parseIntegrantes,
          {'data': combined, 'numPersonas': numPersonas});
    } catch (e) {
      debugPrint("Error cargando participantes: $e");
      backend.checkAndSignOutOnAuthError(e);
      listaCupos = [];
    }
  }

  Future<void> cargarSolicitudes(String juntaId) async {
    try {
      // Obtener solicitudes usando wrapper
      final solicitudes = await _backend.obtenerSolicitudesPorJunta(juntaId);

      final Set<String> ids = solicitudes
          .map((s) => s['usuario_id']?.toString())
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      Map<String, dynamic> perfilesMap = {};
      if (ids.isNotEmpty) {
        final perfiles = await _backend.obtenerPerfilesPorIds(ids.toList());
        for (var perfil in (perfiles as List<dynamic>)) {
          perfilesMap[perfil['id'].toString()] = perfil;
        }
      }

      final combined = solicitudes.map((s) {
        final copy = Map<String, dynamic>.from(s as Map);
        copy['perfiles'] = perfilesMap[s['usuario_id']?.toString()] ?? {};
        return copy;
      }).toList();

      solicitudesUnirse =
          await compute(parsers.parseSolicitudes, (combined as List<dynamic>));

      solicitudesIntercambio = [];
    } catch (e) {
      debugPrint("Error cargando solicitudes: $e");
      backend.checkAndSignOutOnAuthError(e);
      solicitudesUnirse = [];
    }
  }

  Future<void> crearJunta(
    String nombre,
    String monto,
    String cant,
    String per,
    String inicio,
    String fin, {
    String moneda = 'Soles',
  }) async {
    try {
      await _backend.crearJunta(
        nombre: nombre,
        monto: double.tryParse(monto) ?? 0,
        periodo: per,
        inicio: DateFormat('dd/MM/yyyy').parse(inicio),
        cantidad: int.tryParse(cant) ?? 10,
        moneda: moneda,
        onError: (error) {
          Toast.show(error, navigatorKey.currentContext);
        },
        onSuccess: (data) async {
          final ctx = navigatorKey.currentContext;
          Toast.show("Junta creada exitosamente", ctx);
          // Store last created code so UI can display it
          try {
            ultimoCodigoCreado = data['codigo_acceso']?.toString() ?? '';
            notifyListeners();
          } catch (_) {}
          // Mostrar codigo de acceso en un diálogo con opción de copiar
          try {
            final codigo = data['codigo_acceso']?.toString() ?? '';
            if (ctx != null) {
              showDialog<void>(
                context: ctx,
                builder: (dctx) => AlertDialog(
                  title: const Text('Código de la junta'),
                  content: SelectableText(codigo),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: codigo));
                          Navigator.pop(dctx);
                        },
                        child: const Text('Copiar')),
                    TextButton(
                        onPressed: () => Navigator.pop(dctx),
                        child: const Text('OK')),
                  ],
                ),
              );
            }
          } catch (e) {
            debugPrint('Error mostrando codigo: $e');
          }

          // Refrescar la lista de juntas para que la UI (Home) se actualice
          try {
            await cargarJuntas();
          } catch (e) {
            debugPrint('Error refrescando juntas tras creación: $e');
          }
        },
      );
    } catch (e) {
      debugPrint("Error en crearJunta: $e");
      Toast.show("Error al crear la junta", navigatorKey.currentContext);
    }
  }

  Future<void> eliminarJunta(String id) async {
    try {
      await _backend.eliminarJunta(id);
      // refrescar listas locales
      await cargarJuntas();
      final ctx = navigatorKey.currentContext;
      if (ctx != null) Toast.show('Junta eliminada', ctx);
    } catch (e) {
      debugPrint('Error en eliminarJunta: $e');
      final ctx = navigatorKey.currentContext;
      if (ctx != null) Toast.show('Error al eliminar junta', ctx);
    }
  }

  Future<void> unirseAJunta(String codigo) async {
    try {
      await _backend.unirseAJunta(
        codigo,
        (error) {
          Toast.show(error, navigatorKey.currentContext);
        },
        () {
          Toast.show("Solicitud enviada al dueño", navigatorKey.currentContext);
        },
      );
    } catch (e) {
      debugPrint("Error en unirseAJunta: $e");
      Toast.show("Error al unirse a la junta", navigatorKey.currentContext);
    }
  }

  Future<void> aceptarSolicitud(dynamic solicitud) async {
    try {
      final juntaId = solicitud['junta_id'] ?? juntaSeleccionada?.id;
      if (juntaId == null) return;

      await _backend.actualizarSolicitudEstado(solicitud['id'], 'aprobada');

      await _backend.insertarParticipante(juntaId, solicitud['usuario_id'],
          rol: 'miembro');

      solicitudesUnirse.removeWhere((s) => s['id'] == solicitud['id']);
      // refresh participants for the affected junta if selected, otherwise skip
      if (juntaSeleccionada != null && juntaSeleccionada!.id == juntaId) {
        await cargarParticipantes(juntaId);
      }

      // Also refresh owner's solicitudes list
      await cargarSolicitudesParaDueno();

      final ctx = navigatorKey.currentContext;
      Toast.show("Solicitud aceptada", ctx);
      notifyListeners();
    } catch (e) {
      debugPrint("Error aceptando solicitud: $e");
      backend.checkAndSignOutOnAuthError(e);
      final ctx = navigatorKey.currentContext;
      Toast.show("Error al aceptar solicitud", ctx);
    }
  }

  Future<void> rechazarSolicitud(dynamic solicitud) async {
    try {
      await _backend.actualizarSolicitudEstado(solicitud['id'], 'rechazada');

      solicitudesUnirse.removeWhere((s) => s['id'] == solicitud['id']);
      // refresh owner's solicitudes list
      await cargarSolicitudesParaDueno();
      final ctx = navigatorKey.currentContext;
      Toast.show("Solicitud rechazada", ctx);
      notifyListeners();
    } catch (e) {
      debugPrint("Error rechazando solicitud: $e");
      backend.checkAndSignOutOnAuthError(e);
      final ctx = navigatorKey.currentContext;
      Toast.show("Error al rechazar solicitud", ctx);
    }
  }

  Future<void> subirVoucher(int index, String voucherUrl) async {
    try {
      if (juntaSeleccionada == null) return;

      final cupo = listaCupos[index];

      try {
        await _backend.actualizarParticipanteVoucher(
            juntaSeleccionada!.id, cupo.id,
            pagoRealizado: true, voucherUrl: voucherUrl);
      } catch (e) {
        debugPrint('Error updating voucher via backend wrapper: $e');
        backend.checkAndSignOutOnAuthError(e);
        final ctx = navigatorKey.currentContext;
        if (ctx != null) Toast.show('Error al subir voucher', ctx);
        return;
      }

      // Update local model defensively
      try {
        cupo.pagoRealizado = true;
      } catch (_) {}
      cupo.voucherUrl = voucherUrl;
      notifyListeners();

      final ctx = navigatorKey.currentContext;
      Toast.show('Pago registrado', ctx);
    } catch (e) {
      debugPrint('Error subiendo voucher: $e');
      backend.checkAndSignOutOnAuthError(e);
      final ctx = navigatorKey.currentContext;
      Toast.show('Error al subir voucher', ctx);
    }
  }
}
