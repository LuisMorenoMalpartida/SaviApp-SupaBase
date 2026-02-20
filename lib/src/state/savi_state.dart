import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:savi_app/backend.dart' as backend;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:savi_app/logger.dart';
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
  // Optional device token (e.g. FCM) that UI can set after obtaining it.
  String? deviceToken;

  SaviState() {
    _init();
  }

  Future<void> _init() async {
    try {
      logger.debug(
          '[SaviState] _init start: ${DateTime.now().toIso8601String()}');
      // Escuchar cambios en la autenticación de manera segura
      supabase.auth.onAuthStateChange.listen((data) {
        try {
          _actualizarDesdeBackend();
        } catch (e) {
          logger.error('Auth state change handler error: $e');
        }
      });

      // Cargar estado inicial
      await _actualizarDesdeBackend();
      logger.debug(
          '[SaviState] _init finished _actualizar: ${DateTime.now().toIso8601String()}');
    } catch (e) {
      logger.error("Error en init: $e");
    }
  }

  Future<void> _actualizarDesdeBackend() async {
    try {
      logger.debug(
          '[SaviState] _actualizarDesdeBackend start: ${DateTime.now().toIso8601String()} currentUser=${_backend.currentUser?.id ?? ''}');
      if (_backend.currentUser != null) {
        miIdUsuario = _backend.currentUser!.id;
        rolActual = _backend.esDueno ? UserRole.owner : UserRole.member;
        await cargarJuntas();
        // refresh owner solicitudes list
        await cargarSolicitudesParaDueno();
        // Start realtime subscription for owner solicitudes if user is owner
        if (rolActual == UserRole.owner) {
          startRealtimeSolicitudes();
        } else {
          stopRealtimeSolicitudes();
        }
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
      logger.debug(
          '[SaviState] _actualizarDesdeBackend finished: ${DateTime.now().toIso8601String()}');
      notifyListeners();
    } catch (e) {
      logger.error("Error en _actualizarDesdeBackend: $e");
    }
  }

  // Helpers to avoid retaining BuildContext across async gaps
  void _safeToast(String message) {
    final nav = navigatorKey.currentState;
    final ctx = nav?.overlay?.context;
    if (ctx != null) {
      Toast.show(message, ctx);
    }
  }

  Future<void> _safeShowCodeDialog(String codigo) async {
    final nav = navigatorKey.currentState;
    final ctx = nav?.overlay?.context;
    if (ctx == null) return;
    await showDialog<void>(
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
              onPressed: () => Navigator.pop(dctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void startPollingSolicitudes(
      {Duration interval = const Duration(seconds: 15)}) {
    _solicitudesTimer?.cancel();
    _solicitudesTimer = Timer.periodic(interval, (_) async {
      try {
        await cargarSolicitudesParaDueno();
      } catch (e) {
        logger.error('Error polling solicitudes: $e');
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
      if (ownerJuntas.isEmpty) {
        return;
      }

      // Supabase stream builders may not support `filter(...)` the same way
      // as the normal query builder. Subscribe to the table and filter
      // events in the listener as a safe fallback.
      final stream = supabase.from('solicitudes').stream(primaryKey: ['id']);

      _solicitudesSub = stream.listen((_) async {
        try {
          await cargarSolicitudesParaDueno();
        } catch (e) {
          logger.error('Error handling realtime solicitudes event: $e');
        }
      });
    } catch (e) {
      logger.error(
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
      if (miIdUsuario.isEmpty) {
        return;
      }
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
        final perfiles =
            await _backend.obtenerPerfilesModelPorIds(ids.toList());
        for (var perfil in perfiles) {
          perfilesMap[perfil.id] = {
            'id': perfil.id,
            'nombre': perfil.nombre,
            'apellido': perfil.apellido,
            'dni': perfil.dni,
            'telefono': perfil.telefono,
            'email': perfil.email,
            'avatar_url': perfil.avatarUrl,
          };
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
      logger.error('Error cargando solicitudes para dueño: $e');
      solicitudesUnirse = [];
    }
  }

  // --- PERFIL ---
  Future<void> cargarPerfil() async {
    try {
      logger.debug(
          '[SaviState] cargarPerfil start: ${DateTime.now().toIso8601String()} user=$miIdUsuario');
      if (miIdUsuario.isEmpty) {
        return;
      }
      final perfil = await _backend.obtenerPerfil(miIdUsuario);
      if (perfil != null) {
        perfilNombre = perfil['nombre'] ?? '';
        perfilApellido = perfil['apellido'] ?? '';
        perfilDni = perfil['dni'] ?? '';
        perfilTelefono = perfil['telefono'] ?? '';
        perfilAvatar = perfil['avatar_url'] ?? '';
      }
      logger.debug(
          '[SaviState] cargarPerfil finished: ${DateTime.now().toIso8601String()}');
      notifyListeners();
    } catch (e) {
      logger.error('Error cargando perfil: $e');
    }
  }

  /// Solicitar restablecimiento de contraseña para el email dado.
  /// Retorna true si se envió correctamente, false en error.
  Future<bool> solicitarRecuperacion(String email) async {
    try {
      await backend.SaviState().enviarEmailRecuperacion(email);
      return true;
    } catch (e) {
      logger.error('Error solicitarRecuperacion: $e');
      return false;
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
          _safeToast(err);
        },
        onSuccess: () {
          perfilNombre = nombre;
          perfilApellido = apellido;
          perfilDni = dni;
          perfilTelefono = telefono;
          _safeToast('Perfil actualizado');
          notifyListeners();
        },
      );
    } catch (e) {
      logger.error('Error guardando perfil: $e');
      _safeToast('Error al guardar perfil');
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
      logger.error('Error en subirAvatar: $e');
      _safeToast('Error al subir avatar');
      return null;
    }
  }

  // --- AUTENTICACIÓN ---

  Future<void> iniciarSesion(String email, String password) async {
    try {
      await _backend.iniciarSesion(email, password, (error) {
        _safeToast(error);
      });

      if (_backend.currentUser != null) {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    } catch (e) {
      logger.error("Error en iniciarSesion: $e");
      _safeToast("Error al iniciar sesión");
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
          _safeToast(error);
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        onSuccess: () {
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
      );
      return await completer.future;
    } catch (e) {
      logger.error("Error en registrarUsuario: $e");
      _safeToast("Error al registrar usuario");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // If we have a device token registered, remove it from backend first
      if (deviceToken != null && _backend.currentUser != null) {
        try {
          await backend.removeDeviceToken(
              _backend.currentUser!.id, deviceToken!);
        } catch (e) {
          logger.error('removeDeviceToken failed: $e');
        }
      }

      await _backend.logout();
      deviceToken = null;
      _safeToast("Sesión cerrada");
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      logger.error("Error en logout: $e");
    }
  }

  /// Register a device token (FCM) for the current user. The UI should
  /// call this after acquiring the token from Firebase Messaging.
  Future<void> setDeviceToken(String token) async {
    deviceToken = token;
    if (_backend.currentUser != null) {
      try {
        await backend.registerDeviceToken(_backend.currentUser!.id, token);
      } catch (e) {
        logger.error('registerDeviceToken failed: $e');
      }
    }
  }

  /// Clear/unregister the stored device token for the current user.
  Future<void> clearDeviceToken() async {
    if (deviceToken != null && _backend.currentUser != null) {
      try {
        await backend.removeDeviceToken(_backend.currentUser!.id, deviceToken!);
      } catch (e) {
        logger.error('clearDeviceToken failed: $e');
      }
    }
    deviceToken = null;
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
      logger.error("Error en cargarJuntas: $e");
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
      logger.error("Error en seleccionarJunta: $e");
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
      logger.error("Error cargando detalles: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarParticipantes(String juntaId) async {
    try {
      // Obtener participantes usando el wrapper tipado del backend
      final parts = await _backend.obtenerParticipantesModelPorJunta(juntaId);

      // Obtener perfiles por separado para los usuario_ids encontrados
      final Set<String> ids = parts.map((p) => p.usuarioId).toSet();

      Map<String, dynamic> perfilesMap = {};
      if (ids.isNotEmpty) {
        final perfiles =
            await _backend.obtenerPerfilesModelPorIds(ids.toList());
        for (var perfil in perfiles) {
          perfilesMap[perfil.id] = {
            'id': perfil.id,
            'nombre': perfil.nombre,
            'apellido': perfil.apellido,
            'dni': perfil.dni,
            'telefono': perfil.telefono,
            'email': perfil.email,
            'avatar_url': perfil.avatarUrl,
          };
        }
      }

      // Combinar participantes con su perfil (si existe)
      final combined = parts.map((p) {
        return {
          ...p.toJson(),
          'perfiles': perfilesMap[p.usuarioId] ?? {},
        };
      }).toList();

      listaCupos = await compute(parsers.parseIntegrantes,
          {'data': combined, 'numPersonas': numPersonas});
    } catch (e) {
      logger.error('Error cargando participantes: $e');
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
        for (var perfil in perfiles) {
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
      logger.error("Error cargando solicitudes: $e");
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
          _safeToast(error);
        },
        onSuccess: (data) async {
          _safeToast("Junta creada exitosamente");
          // Store last created code so UI can display it
          try {
            ultimoCodigoCreado = data['codigo_acceso']?.toString() ?? '';
            notifyListeners();
          } catch (_) {}
          // Mostrar codigo de acceso en un diálogo con opción de copiar
          try {
            final codigo = data['codigo_acceso']?.toString() ?? '';
            await _safeShowCodeDialog(codigo);
          } catch (e) {
            logger.error('Error mostrando codigo: $e');
          }

          // Refrescar la lista de juntas para que la UI (Home) se actualice
          try {
            await cargarJuntas();
          } catch (e) {
            logger.error('Error refrescando juntas tras creación: $e');
          }
        },
      );
    } catch (e) {
      logger.error("Error en crearJunta: $e");
      _safeToast("Error al crear la junta");
    }
  }

  Future<void> eliminarJunta(String id) async {
    try {
      await _backend.eliminarJunta(id);
      // refrescar listas locales
      await cargarJuntas();
      _safeToast('Junta eliminada');
    } catch (e) {
      logger.error('Error en eliminarJunta: $e');
      _safeToast('Error al eliminar junta');
    }
  }

  Future<void> unirseAJunta(String codigo) async {
    try {
      await _backend.unirseAJunta(
        codigo,
        (error) {
          _safeToast(error);
        },
        () {
          _safeToast("Solicitud enviada al dueño");
        },
      );
    } catch (e) {
      logger.error("Error en unirseAJunta: $e");
      _safeToast("Error al unirse a la junta");
    }
  }

  Future<void> aceptarSolicitud(dynamic solicitud) async {
    try {
      final juntaId = solicitud['junta_id'] ?? juntaSeleccionada?.id;
      if (juntaId == null) {
        return;
      }

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

      _safeToast("Solicitud aceptada");
      notifyListeners();
    } catch (e) {
      logger.error("Error aceptando solicitud: $e");
      backend.checkAndSignOutOnAuthError(e);
      _safeToast("Error al aceptar solicitud");
    }
  }

  Future<void> rechazarSolicitud(dynamic solicitud) async {
    try {
      await _backend.actualizarSolicitudEstado(solicitud['id'], 'rechazada');

      solicitudesUnirse.removeWhere((s) => s['id'] == solicitud['id']);
      // refresh owner's solicitudes list
      await cargarSolicitudesParaDueno();
      _safeToast("Solicitud rechazada");
      notifyListeners();
    } catch (e) {
      logger.error("Error rechazando solicitud: $e");
      backend.checkAndSignOutOnAuthError(e);
      _safeToast("Error al rechazar solicitud");
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
        logger.error('Error updating voucher via backend wrapper: $e');
        backend.checkAndSignOutOnAuthError(e);
        _safeToast('Error al subir voucher');
        return;
      }

      // Update local model defensively
      try {
        cupo.pagoRealizado = true;
      } catch (_) {}
      cupo.voucherUrl = voucherUrl;
      notifyListeners();

      _safeToast('Pago registrado');
    } catch (e) {
      logger.error('Error subiendo voucher: $e');
      backend.checkAndSignOutOnAuthError(e);
      _safeToast('Error al subir voucher');
    }
  }
}
