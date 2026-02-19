import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../db.dart' as backend;
import '../parsers/parsers.dart' as parsers;
import '../utils/navigation.dart';
import '../utils/toast.dart';

enum UserRole { owner, member }

class SaviState extends ChangeNotifier {
  // Referencia al estado del backend
  final backend.SaviState _backend = backend.SaviState();

  // Getter para acceder a Supabase (usando tu supabaseClient)
  final supabase = backend.supabaseClient;

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

  SaviState() {
    _init();
  }

  Future<void> _init() async {
    try {
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
    } catch (e) {
      debugPrint("Error en init: $e");
    }
  }

  Future<void> _actualizarDesdeBackend() async {
    try {
      if (_backend.currentUser != null) {
        miIdUsuario = _backend.currentUser!.id;
        rolActual = _backend.esDueno ? UserRole.owner : UserRole.member;
        await cargarJuntas();
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
      notifyListeners();
    } catch (e) {
      debugPrint("Error en _actualizarDesdeBackend: $e");
    }
  }

  // --- PERFIL ---
  Future<void> cargarPerfil() async {
    try {
      if (miIdUsuario.isEmpty) return;
      final perfil = await _backend.obtenerPerfil(miIdUsuario);
      if (perfil != null) {
        perfilNombre = perfil['nombre'] ?? '';
        perfilApellido = perfil['apellido'] ?? '';
        perfilDni = perfil['dni'] ?? '';
        perfilTelefono = perfil['telefono'] ?? '';
        perfilAvatar = perfil['avatar_url'] ?? '';
      }
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
    } catch (e) {
      debugPrint("Error cargando detalles: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarParticipantes(String juntaId) async {
    try {
      final participantes = await supabase.from('participantes').select('''
            usuario_id,
            rol,
            numero_turno,
            pago_realizado,
            voucher_url,
            perfiles:usuario_id (
              nombre,apellido,dni,telefono
            )
          ''').eq('junta_id', juntaId);

      listaCupos = await compute(parsers.parseIntegrantes,
          {'data': participantes as List<dynamic>, 'numPersonas': numPersonas});
    } catch (e) {
      debugPrint("Error cargando participantes: $e");
      backend.checkAndSignOutOnAuthError(e);
      listaCupos = [];
    }
  }

  Future<void> cargarSolicitudes(String juntaId) async {
    try {
      try {
        final unirse = await supabase.from('solicitudes').select('''
              id,usuario_id,estado,perfiles:usuario_id (nombre,apellido,dni,telefono)
            ''').eq('junta_id', juntaId);

        solicitudesUnirse =
            await compute(parsers.parseSolicitudes, (unirse as List<dynamic>));
      } catch (e) {
        debugPrint("Tabla solicitudes no disponible: $e");
        solicitudesUnirse = [];
      }

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
        onSuccess: () {
          Toast.show("Junta creada exitosamente", navigatorKey.currentContext);
        },
      );
    } catch (e) {
      debugPrint("Error en crearJunta: $e");
      Toast.show("Error al crear la junta", navigatorKey.currentContext);
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
      if (juntaSeleccionada == null) return;

      await supabase
          .from('solicitudes')
          .update({'estado': 'aprobada'}).eq('id', solicitud['id']);

      await supabase.from('participantes').insert({
        'junta_id': juntaSeleccionada!.id,
        'usuario_id': solicitud['usuario_id'],
        'rol': 'miembro',
      });

      solicitudesUnirse.removeWhere((s) => s['id'] == solicitud['id']);
      await cargarParticipantes(juntaSeleccionada!.id);

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
      await supabase
          .from('solicitudes')
          .update({'estado': 'rechazada'}).eq('id', solicitud['id']);

      solicitudesUnirse.removeWhere((s) => s['id'] == solicitud['id']);
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
      await supabase
          .from('participantes')
          .update({'pago_realizado': true, 'voucher_url': voucherUrl})
          .eq('junta_id', juntaSeleccionada!.id)
          .eq('usuario_id', cupo.id);

      cupo.pagoRealizado = true;
      cupo.voucherUrl = voucherUrl;
      notifyListeners();

      final ctx = navigatorKey.currentContext;
      Toast.show("Pago registrado", ctx);
    } catch (e) {
      debugPrint("Error subiendo voucher: $e");
      backend.checkAndSignOutOnAuthError(e);
      final ctx = navigatorKey.currentContext;
      Toast.show("Error al subir voucher", ctx);
    }
  }
}
