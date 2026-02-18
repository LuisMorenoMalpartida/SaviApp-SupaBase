import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importamos el backend
import 'backend.dart' as backend;

// --- UTILS ---

class Toast {
  static void show(String msg, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}

// --- MODELOS DE DATOS PARA UI ---

enum UserRole { owner, member }

class IntegranteUI {
  String id;
  String nombre;
  String usuario; // Rol visible (Admin/Miembro)
  String dni;
  String telefono;
  String correo;
  String numero; // Número del sorteo
  bool ocupado;
  bool pagoRealizado;
  String? voucherUrl;

  IntegranteUI({
    this.id = '',
    this.nombre = 'Cupo Disponible',
    this.usuario = 'Toque para editar',
    this.dni = '',
    this.telefono = '',
    this.correo = '',
    this.numero = '',
    this.ocupado = false,
    this.pagoRealizado = false,
    this.voucherUrl,
  });
}

class SolicitudUnirseUI {
  final String id;
  final String usuarioId;
  final String nombre;
  final String apellido;
  final String dni;
  final String telefono;
  final String correo;
  String estado; // 'pendiente', 'aprobada', 'rechazada'

  SolicitudUnirseUI({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.telefono,
    required this.correo,
    this.estado = 'pendiente',
  });
}

class SolicitudIntercambioUI {
  final String id;
  final String solicitanteId;
  final String solicitanteNombre;
  final String objetivoId;
  final String objetivoNombre;
  String estado; // 'pendiente', 'aprobada', 'rechazada'

  SolicitudIntercambioUI({
    required this.id,
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.objetivoId,
    required this.objetivoNombre,
    this.estado = 'pendiente',
  });
}

// --- APP STATE (PROVIDER) CON BACKEND REAL ---

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

  List<IntegranteUI> listaCupos = [];
  List<SolicitudUnirseUI> solicitudesUnirse = [];
  List<SolicitudIntercambioUI> solicitudesIntercambio = [];

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
          debugPrint("Error en listener auth: $e");
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

  // --- AUTENTICACIÓN ---

  Future<void> iniciarSesion(
      String email, String password, BuildContext context) async {
    try {
      await _backend.iniciarSesion(email, password, (error) {
        Toast.show(error, context);
      });

      if (_backend.currentUser != null && context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint("Error en iniciarSesion: $e");
      Toast.show("Error al iniciar sesión", context);
    }
  }

  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String dni,
    required String telefono,
    required BuildContext context,
    required Function() onSuccess,
  }) async {
    try {
      await _backend.registrarUsuario(
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
        dni: dni,
        telefono: telefono,
        onError: (error) => Toast.show(error, context),
        onSuccess: onSuccess,
      );
    } catch (e) {
      debugPrint("Error en registrarUsuario: $e");
      Toast.show("Error al registrar usuario", context);
    }
  }

  void logout() {
    try {
      _backend.logout();
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Toast.show("Sesión cerrada", ctx);
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
            *,
            perfiles:usuario_id (
              nombre,
              apellido,
              dni,
              telefono
            )
          ''').eq('junta_id', juntaId);

      listaCupos = (participantes as List).map((p) {
        final perfil = p['perfiles'] ?? {};
        return IntegranteUI(
          id: p['usuario_id'],
          nombre:
              "${perfil['nombre'] ?? ''} ${perfil['apellido'] ?? ''}".trim(),
          usuario: p['rol'] == 'dueño' ? 'Administrador' : 'Miembro',
          dni: perfil['dni'] ?? '',
          telefono: perfil['telefono'] ?? '',
          correo: '',
          numero: p['numero_turno']?.toString() ?? '',
          ocupado: true,
          pagoRealizado: p['pago_realizado'] ?? false,
          voucherUrl: p['voucher_url'],
        );
      }).toList();

      // Rellenar cupos disponibles si faltan
      while (listaCupos.length < numPersonas) {
        listaCupos.add(IntegranteUI());
      }
    } catch (e) {
      debugPrint("Error cargando participantes: $e");
      listaCupos = [];
    }
  }

  Future<void> cargarSolicitudes(String juntaId) async {
    try {
      // Verificar si la tabla solicitudes existe
      try {
        final unirse = await supabase.from('solicitudes').select('''
              *,
              perfiles:usuario_id (
                nombre,
                apellido,
                dni,
                telefono
              )
            ''').eq('junta_id', juntaId).eq('estado', 'pendiente');

        solicitudesUnirse = (unirse as List).map((s) {
          final perfil = s['perfiles'] ?? {};
          return SolicitudUnirseUI(
            id: s['id'],
            usuarioId: s['usuario_id'],
            nombre: perfil['nombre'] ?? '',
            apellido: perfil['apellido'] ?? '',
            dni: perfil['dni'] ?? '',
            telefono: perfil['telefono'] ?? '',
            correo: '',
            estado: s['estado'],
          );
        }).toList();
      } catch (e) {
        // Si la tabla no existe, solo continuamos
        debugPrint("Tabla solicitudes no disponible: $e");
        solicitudesUnirse = [];
      }

      // Solicitudes de intercambio (pendiente de implementar)
      solicitudesIntercambio = [];
    } catch (e) {
      debugPrint("Error cargando solicitudes: $e");
      solicitudesUnirse = [];
    }
  }

  Future<void> crearJunta(
    String nombre,
    String monto,
    String cant,
    String per,
    String inicio,
    String fin,
    BuildContext context,
  ) async {
    try {
      await _backend.crearJunta(
        nombre: nombre,
        monto: double.tryParse(monto) ?? 0,
        periodo: per,
        inicio: DateFormat('dd/MM/yyyy').parse(inicio),
        cantidad: int.tryParse(cant) ?? 10,
        onError: (error) => Toast.show(error, context),
        onSuccess: () {
          cargarJuntas();
          Toast.show("Junta creada exitosamente", context);
        },
      );
    } catch (e) {
      debugPrint("Error en crearJunta: $e");
      Toast.show("Error al crear la junta", context);
    }
  }

  Future<void> unirseAJunta(String codigo, BuildContext context) async {
    try {
      await _backend.unirseAJunta(
        codigo,
        (error) => Toast.show(error, context),
        () {
          Toast.show("Solicitud enviada al dueño", context);
        },
      );
    } catch (e) {
      debugPrint("Error en unirseAJunta: $e");
      Toast.show("Error al unirse a la junta", context);
    }
  }

  // --- SOLICITUDES ---

  Future<void> aceptarSolicitud(SolicitudUnirseUI solicitud) async {
    try {
      if (juntaSeleccionada == null) return;

      // Actualizar estado de la solicitud
      await supabase
          .from('solicitudes')
          .update({'estado': 'aprobada'}).eq('id', solicitud.id);

      // Agregar como participante
      await supabase.from('participantes').insert({
        'junta_id': juntaSeleccionada!.id,
        'usuario_id': solicitud.usuarioId,
        'rol': 'miembro',
      });

      // Actualizar UI
      solicitudesUnirse.remove(solicitud);
      await cargarParticipantes(juntaSeleccionada!.id);

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Toast.show("Solicitud aceptada", ctx);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error aceptando solicitud: $e");
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Toast.show("Error al aceptar solicitud", ctx);
      }
    }
  }

  Future<void> rechazarSolicitud(SolicitudUnirseUI solicitud) async {
    try {
      await supabase
          .from('solicitudes')
          .update({'estado': 'rechazada'}).eq('id', solicitud.id);

      solicitudesUnirse.remove(solicitud);
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Toast.show("Solicitud rechazada", ctx);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error rechazando solicitud: $e");
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Toast.show("Error al rechazar solicitud", ctx);
      }
    }
  }

  // --- PAGOS ---

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
      if (ctx != null) {
        Toast.show("Pago registrado", ctx);
      }
    } catch (e) {
      debugPrint("Error subiendo voucher: $e");
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Toast.show("Error al subir voucher", ctx);
      }
    }
  }
}

// Clave global para navegación
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Supabase con tus credenciales
    await Supabase.initialize(
      url: 'https://wwrzudqkzycdgpsdgvnu.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind3cnp1ZHFrenljZGdwc2Rndm51Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNDUxOTEsImV4cCI6MjA4NjkyMTE5MX0.O8K7g1mih8XgzDqTH4tCoGgoPf3aV53h1Fhuz7A7N3c',
    );
    debugPrint("✅ Supabase initialized successfully");
  } catch (e) {
    debugPrint("❌ Error initializing Supabase: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => SaviState(),
      child: const SaviApp(),
    ),
  );
}

class SaviApp extends StatelessWidget {
  const SaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SAVI',
      theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: const Color(0xFFFF9800),
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          )),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/detalles': (_) => const DetallesJuntaScreen(),
        '/info': (_) => const InfoJuntaScreen(),
        '/pagos': (_) => const IntegrantesPagosScreen(),
        '/invitar': (_) => const InvitarScreen(),
        '/reportar': (_) => const ReportarScreen(),
        '/sorteo': (_) => const SorteoScreen(),
        '/solicitudes_dueno': (_) => const SolicitudesDuenoScreen(),
      },
    );
  }
}

// --- PANTALLA DE BIENVENIDA ---

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildPage("assets/1.png"),
              _buildPage("assets/2.png"),
              _buildPage("assets/3.png"),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 10,
                      width: _currentPage == index ? 20 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFFF9800)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                _currentPage == 2
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text("COMENZAR AHORA",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    : const SizedBox(height: 50),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(String imagePath) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported,
              size: 100,
              color: Colors.grey),
        ),
      ),
    );
  }
}

// --- PANTALLA DE LOGIN ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        // Cerrar teclado al tocar fuera
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.savings, size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              const Text("¡Bienvenido Estimado cliente!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              TextField(
                controller: emailCtrl,
                focusNode: emailFocus,
                textInputAction: TextInputAction.next,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(passFocus);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.orange),
                  hintText: "Correo Electrónico",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passCtrl,
                focusNode: passFocus,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                  _handleLogin(context, state);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                  hintText: "Contraseña",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () => _handleLogin(context, state),
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("INICIAR SESIÓN"),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text("¿No tienes cuenta? Regístrate aquí"),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, SaviState state) {
    FocusScope.of(context).unfocus(); // Cerrar teclado antes de procesar
    state.iniciarSesion(emailCtrl.text, passCtrl.text, context);
  }
}

// --- PANTALLA DE REGISTRO ---

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final dniCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();

  final nombreFocus = FocusNode();
  final apellidoFocus = FocusNode();
  final dniFocus = FocusNode();
  final telefonoFocus = FocusNode();
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    dniCtrl.dispose();
    telefonoCtrl.dispose();
    nombreFocus.dispose();
    apellidoFocus.dispose();
    dniFocus.dispose();
    telefonoFocus.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.savings, size: 80, color: Colors.orange),
                ),
                const SizedBox(height: 20),
                const Text("Crear Cuenta Nueva",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextField(
                  controller: nombreCtrl,
                  focusNode: nombreFocus,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(apellidoFocus);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person, color: Colors.orange),
                    hintText: "Nombres",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: apellidoCtrl,
                  focusNode: apellidoFocus,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(dniFocus);
                  },
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.person_outline, color: Colors.orange),
                    hintText: "Apellidos",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: dniCtrl,
                  focusNode: dniFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(telefonoFocus);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge, color: Colors.orange),
                    hintText: "DNI",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: telefonoCtrl,
                  focusNode: telefonoFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(emailFocus);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: Colors.orange),
                    hintText: "Teléfono",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: emailCtrl,
                  focusNode: emailFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(passFocus);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: Colors.orange),
                    hintText: "Correo Electrónico",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passCtrl,
                  focusNode: passFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                    _handleRegister(context, state);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                    hintText: "Contraseña",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _handleRegister(context, state),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("REGISTRARME AHORA"),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Ya tengo cuenta, Iniciar sesión"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister(BuildContext context, SaviState state) {
    FocusScope.of(context).unfocus(); // Cerrar teclado antes de procesar
    state.registrarUsuario(
      email: emailCtrl.text,
      password: passCtrl.text,
      nombre: nombreCtrl.text,
      apellido: apellidoCtrl.text,
      dni: dniCtrl.text,
      telefono: telefonoCtrl.text,
      context: context,
      onSuccess: () {
        Toast.show("Registro exitoso. Ya puedes iniciar sesión.", context);
        Navigator.pop(context);
      },
    );
  }
}

// --- HOME SCREEN ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _cantCtrl = TextEditingController();
  final _inicioCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<SaviState>(context, listen: false);
      state.cargarJuntas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo2.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          if (state.esDueno && state.juntaSeleccionada != null)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/solicitudes_dueno'),
                ),
                if (state.solicitudesUnirse.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text("${state.solicitudesUnirse.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  )
              ],
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              state.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _buildBody(state),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "Mis Juntas"),
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: "Unirse"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: "Crear"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  Widget _buildBody(SaviState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentIndex) {
      case 0:
        return _buildTabInicio(state);
      case 1:
        return _buildTabMisJuntas(state);
      case 2:
        return _buildTabUnirse(state);
      case 3:
        return _buildTabCrear(state);
      case 4:
        return _buildTabPerfil(state);
      default:
        return Container();
    }
  }

  Widget _buildTabInicio(SaviState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.waving_hand, color: Colors.orange, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hola, ${state.currentUser?.email?.split('@')[0] ?? 'Usuario'}",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                          "Rol actual: ${state.esDueno ? 'Organizador' : 'Participante'}",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard("Juntas Activas",
                      "${state.juntasActivas}", Icons.show_chart)),
            ],
          ),
          const SizedBox(height: 20),
          const Text("¿Qué quieres hacer hoy?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => setState(() => _currentIndex = 3),
                      child: const Text("CREAR JUNTA"))),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => setState(() => _currentIndex = 2),
                      child: const Text("BUSCAR JUNTA"))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon) {
    return Card(
      color: Colors.orange,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 5),
            Text(val,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabMisJuntas(SaviState state) {
    if (state.misJuntas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30.0),
          child: Text(
              "No tienes juntas activas.\nVe a la pestaña 'Unirse' para buscar una junta.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: state.misJuntas.map((junta) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            onTap: () async {
              await state.seleccionarJunta(junta);
              Navigator.pushNamed(context, '/detalles');
            },
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(Icons.savings, color: Colors.blue)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(junta.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            junta.creadorId == state.currentUser?.id
                                ? "Eres el Organizador"
                                : "Participante",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("S/ ${junta.montoCuota.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey)
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabUnirse(SaviState state) {
    final codigoCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text("Unirse a una Junta",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: codigoCtrl,
                    decoration: const InputDecoration(
                      labelText: "Código de Invitación",
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (codigoCtrl.text.isNotEmpty) {
                        await state.unirseAJunta(codigoCtrl.text, context);
                      } else {
                        Toast.show("Ingresa un código", context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SOLICITAR INGRESO"),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                      "Al pulsar 'Solicitar Ingreso', enviarás una solicitud al dueño para que apruebe tu participación.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabCrear(SaviState state) {
    if (state.currentUser == null) {
      return const Center(
          child: Text("Debes iniciar sesión para crear juntas."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nueva Junta",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildInput("Nombre de la junta", "Ej: Viaje 2026", _nombreCtrl,
                  Icons.edit),
              const SizedBox(height: 15),
              _buildInput("Monto por Cuota", "Monto por persona", _montoCtrl,
                  Icons.attach_money,
                  isNumber: true),
              const SizedBox(height: 15),
              _buildInput(
                  "Cantidad Integrantes", "Máx 20", _cantCtrl, Icons.group,
                  isNumber: true),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildDateInput("Inicio", _inicioCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDateInput("Fin (opcional)", _finCtrl)),
                ],
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: state.periodo,
                items: ["Mensual", "Quincenal", "Semanal"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => state.periodo = v!,
                decoration: InputDecoration(
                  labelText: "Periodo",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () async {
                    if (_inicioCtrl.text.isEmpty) {
                      Toast.show("Selecciona fecha de inicio", context);
                      return;
                    }

                    await state.crearJunta(
                        _nombreCtrl.text,
                        _montoCtrl.text,
                        _cantCtrl.text,
                        state.periodo,
                        _inicioCtrl.text,
                        _finCtrl.text,
                        context);

                    if (state.misJuntas.isNotEmpty) {
                      setState(() => _currentIndex = 1);
                    }
                  },
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("CREAR Y PUBLICAR"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String label, String hint, TextEditingController ctrl, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildDateInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      onTap: () async {
        try {
          DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)));
          if (picked != null)
            ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
        } catch (e) {
          debugPrint("Error seleccionando fecha: $e");
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon:
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTabPerfil(SaviState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.account_circle, size: 100, color: Colors.grey),
        const SizedBox(height: 10),
        Center(
            child: Text(state.currentUser?.email ?? "Usuario",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 30),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Mi Cuenta"),
            onTap: () {}),
        ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Seguridad"),
            onTap: () {}),
        const Divider(),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            state.logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text("CERRAR SESIÓN",
              style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// --- SOLICITUDES DEL DUEÑO ---

class SolicitudesDuenoScreen extends StatelessWidget {
  const SolicitudesDuenoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Solicitudes Pendientes"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Ingresos"),
              Tab(text: "Intercambios"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB INGRESOS
            state.solicitudesUnirse.isEmpty
                ? const Center(child: Text("No hay solicitudes de ingreso"))
                : ListView.builder(
                    itemCount: state.solicitudesUnirse.length,
                    itemBuilder: (ctx, i) {
                      final sol = state.solicitudesUnirse[i];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading:
                              const CircleAvatar(child: Icon(Icons.person_add)),
                          title: Text("${sol.nombre} ${sol.apellido}"),
                          subtitle:
                              Text("DNI: ${sol.dni}\nQuiere unirse a la junta"),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red, size: 30),
                                onPressed: () {
                                  state.rechazarSolicitud(sol);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 30),
                                onPressed: () {
                                  state.aceptarSolicitud(sol);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            // TAB INTERCAMBIOS
            const Center(child: Text("Módulo de intercambios en desarrollo")),
          ],
        ),
      ),
    );
  }
}

// --- DETALLES JUNTA SCREEN ---

class DetallesJuntaScreen extends StatelessWidget {
  const DetallesJuntaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    if (state.juntaSeleccionada == null) {
      return const Scaffold(
        body: Center(child: Text("No hay junta seleccionada")),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(state.nombreJunta,
              style: const TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.orange.withOpacity(0.2))),
              child: Column(
                children: [
                  const Text("Cuota por persona",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(state.montoJunta,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(context, "Detalles", "Ver info de la junta",
                    Icons.info, Colors.blue, '/info'),
                _buildActionCard(context, "Invitar", "Agregar miembros",
                    Icons.person_add, Colors.green, '/invitar'),
                _buildActionCard(context, "Integrantes", "Ver y editar",
                    Icons.group, Colors.orange, '/pagos'),
                _buildActionCard(context, "Reportar", "Reportar problema",
                    Icons.report, Colors.red, '/reportar'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String sub,
      IconData icon, Color color, String route) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 5),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- INFO JUNTA SCREEN ---

class InfoJuntaScreen extends StatelessWidget {
  const InfoJuntaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    if (state.juntaSeleccionada == null) {
      return const Scaffold(
        body: Center(child: Text("No hay junta seleccionada")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Detalles de la Junta")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(
              "Cuota", state.montoJunta, Icons.monetization_on, Colors.orange),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildGridItem("Periodo", state.periodo, Icons.access_time,
                  editable: false),
              _buildGridItem("Inicio", state.fechaInicio, Icons.date_range,
                  editable: false),
              _buildGridItem(
                  "Personas", "${state.numPersonas} Miembros", Icons.people,
                  editable: false),
              _buildGridItem(
                  "Fin",
                  state.fechaFinal.isEmpty ? "Por definir" : state.fechaFinal,
                  Icons.event_available,
                  editable: false),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/sorteo'),
                child: _buildGridItem("Sorteo", "Ver turnos", Icons.shuffle,
                    editable: true, isAction: true),
              ),
              _buildGridItem("Código", state.codigoJunta, Icons.qr_code,
                  editable: false),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String val, IconData icon, Color color) {
    return Card(
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(val,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, String val, IconData icon,
      {bool editable = false, bool isAction = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Icon(icon,
                    size: 30, color: isAction ? Colors.purple : Colors.orange),
                const SizedBox(height: 10),
                Text(val,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (isAction)
            const Positioned(
                right: 8,
                top: 8,
                child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

// --- SORTEO SCREEN ---

class SorteoScreen extends StatelessWidget {
  const SorteoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    final esDueno = state.esDueno;

    return Scaffold(
      appBar:
          AppBar(title: Text(esDueno ? "Gestión Sorteo" : "Resultados Sorteo")),
      body: Column(
        children: [
          if (esDueno) ...[
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _botonDueno(Icons.casino, "REALIZAR SORTEO", Colors.orange,
                      () {
                    Toast.show("Función en desarrollo", context);
                  }),
                  const SizedBox(height: 10),
                  _botonDueno(
                      Icons.swap_horiz,
                      "VER SOLICITUDES (${state.solicitudesIntercambio.length})",
                      Colors.blue,
                      () => Navigator.pushNamed(context, '/solicitudes_dueno')),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const Divider(),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.blue[50],
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                      child:
                          Text("Los números se asignan al iniciar la junta."))
                ]),
              ),
            )
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.listaCupos.length,
              itemBuilder: (ctx, i) {
                final c = state.listaCupos[i];
                final soyYo = c.id == state.miIdUsuario;

                return Card(
                  color: soyYo ? Colors.yellow[50] : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          c.ocupado ? Colors.orange : Colors.grey[200],
                      child: Text(c.numero.isEmpty ? "?" : c.numero,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(c.nombre + (soyYo ? " (Tú)" : "")),
                    subtitle: Text(c.ocupado ? "Miembro" : "Disponible"),
                    onTap: null,
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _botonDueno(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 50),
          alignment: Alignment.centerLeft),
      icon: Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: onTap,
    );
  }
}

// --- INTEGRANTES Y PAGOS SCREEN ---

class IntegrantesPagosScreen extends StatelessWidget {
  const IntegrantesPagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Estado de Pagos")),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemCount: state.listaCupos.length,
        itemBuilder: (context, index) {
          final cupo = state.listaCupos[index];
          final esMio = cupo.id == state.miIdUsuario;

          return Card(
            elevation: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor:
                      cupo.pagoRealizado ? Colors.green : Colors.red[100],
                  child: Icon(
                      cupo.pagoRealizado ? Icons.check : Icons.access_time,
                      color: cupo.pagoRealizado ? Colors.white : Colors.red),
                ),
                const SizedBox(height: 10),
                Text(cupo.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (cupo.pagoRealizado)
                  const Text("PAGADO",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 10))
                else
                  const Text("PENDIENTE",
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                const SizedBox(height: 10),
                if (esMio && !cupo.pagoRealizado)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 30)),
                    onPressed: () =>
                        _mostrarSubirVoucher(context, state, index),
                    child: const Text("SUBIR PAGO",
                        style: TextStyle(fontSize: 10)),
                  ),
                if (cupo.pagoRealizado && cupo.voucherUrl != null)
                  TextButton(
                      onPressed: () {
                        Toast.show("Voucher: ${cupo.voucherUrl}", context);
                      },
                      child: const Text("Ver Voucher",
                          style: TextStyle(fontSize: 10)))
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarSubirVoucher(BuildContext context, SaviState state, int index) {
    // Por ahora simulamos la subida
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Subir Voucher"),
        content: const Text(
            "Simulación: En una app real, aquí seleccionarías una imagen"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulamos una URL
              state.subirVoucher(index,
                  "voucher_${DateTime.now().millisecondsSinceEpoch}.jpg");
              Navigator.pop(context);
            },
            child: const Text("Subir"),
          ),
        ],
      ),
    );
  }
}

// --- REPORTAR SCREEN ---

class ReportarScreen extends StatefulWidget {
  const ReportarScreen({super.key});
  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  String? seleccionado;
  final comentarioCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    final deudores =
        state.listaCupos.where((c) => c.ocupado && !c.pagoRealizado).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Reportar Incidencia")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Reportar falta de pago u otro problema",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              hint: const Text("Seleccionar integrante"),
              value: seleccionado,
              items: deudores
                  .map((c) =>
                      DropdownMenuItem(value: c.nombre, child: Text(c.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => seleccionado = v),
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "Integrante"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: comentarioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: "Detalle del reporte",
                  hintText:
                      "Ej: No ha realizado el pago correspondiente a la fecha...",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Toast.show("Reporte enviado a administración", context);
                  Navigator.pop(context);
                },
                child: const Text("ENVIAR REPORTE"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- INVITAR SCREEN ---

class InvitarScreen extends StatelessWidget {
  const InvitarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Invitar")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.codigoJunta.isNotEmpty)
              QrImageView(data: state.codigoJunta, size: 200.0)
            else
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: Text("Sin código")),
              ),
            const SizedBox(height: 20),
            Text(state.codigoJunta.isEmpty ? "Sin código" : state.codigoJunta,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                icon: const Icon(Icons.share),
                onPressed: state.codigoJunta.isNotEmpty
                    ? () => Share.share(
                        "Únete a mi Junta en SAVI con el código: ${state.codigoJunta}")
                    : null,
                label: const Text("COMPARTIR CÓDIGO"))
          ],
        ),
      ),
    );
  }
}
