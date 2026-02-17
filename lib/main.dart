import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

// --- UTILS ---

class Toast {
  static void show(String msg, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}

// --- DATA MODELS ---

enum UserRole { owner, member }

class SolicitudUnirse {
  String id;
  String nombre;
  String apellido;
  String dni;
  String telefono;
  String correo;
  bool aceptada;

  SolicitudUnirse({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.telefono,
    required this.correo,
    this.aceptada = false,
  });
}

class Integrante {
  String id;
  String nombre;
  String usuario; // Rol visible (Admin/Miembro)
  String dni;
  String telefono;
  String correo;
  String numero; // Número del sorteo
  bool ocupado;
  bool pagoRealizado;

  Integrante({
    this.id = '',
    this.nombre = 'Cupo Disponible',
    this.usuario = 'Toque para editar',
    this.dni = '',
    this.telefono = '',
    this.correo = '',
    this.numero = '',
    this.ocupado = false,
    this.pagoRealizado = false,
  });
}

class SolicitudIntercambio {
  final String solicitanteId;
  final String solicitanteNombre;
  final String objetivoId;
  final String objetivoNombre;
  String status; // 'pendiente', 'aprobada', 'rechazada'

  SolicitudIntercambio({
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.objetivoId,
    required this.objetivoNombre,
    this.status = 'pendiente',
  });
}

// --- APP STATE (PROVIDER) ---

class SaviState extends ChangeNotifier {
  // Simulación de Rol
  UserRole rolActual = UserRole.owner; // Por defecto Dueño
  String miIdUsuario = "OWNER-001";

  // Datos Generales
  String nombreJunta = "Viaje a Cancún 2026";
  String montoJunta = "S/ 5,000";
  int numPersonas = 10;
  String periodo = "Mensual";
  String fechaInicio = "01/03/2026";
  String fechaFinal = "01/01/2027";
  String codigoJunta = "SAVI-8823";
  String dniDueno = "12345678";

  List<Integrante> listaCupos = [];

  // Buzones
  List<SolicitudUnirse> solicitudesUnirse = [];
  List<SolicitudIntercambio> solicitudesIntercambio = [];

  // Stats
  double ahorradoTotal = 0.00;
  int juntasActivas = 1;

  SaviState() {
    _inicializarDatosDemo();
  }

  void _inicializarDatosDemo() {
    listaCupos.clear();
    // Dueño siempre es el 1 al inicio
    listaCupos.add(Integrante(
      id: "OWNER-001",
      nombre: 'Luis (Dueño)',
      usuario: 'Administrador',
      dni: '12345678',
      numero: '1',
      ocupado: true,
      pagoRealizado: false,
    ));
    // Rellenar espacios vacíos
    redimensionarCupos(10);
  }

  // --- MÉTODOS DE SIMULACIÓN DE ROL ---
  void cambiarRolSimulado(UserRole nuevoRol) {
    rolActual = nuevoRol;
    if (rolActual == UserRole.owner) {
      miIdUsuario = "OWNER-001";
    } else {
      miIdUsuario = "MEMBER-999";
    }
    notifyListeners();
  }

  bool get esDueno => rolActual == UserRole.owner;

  // --- GESTIÓN DE LA JUNTA ---

  void redimensionarCupos(int n) {
    int current = listaCupos.length;
    if (n > current) {
      for (int i = 0; i < n - current; i++) {
        listaCupos.add(Integrante());
      }
    } else if (n < current) {
      listaCupos = listaCupos.sublist(0, n);
    }
    numPersonas = n;
    notifyListeners();
  }

  void actualizarFechaFin(String nuevaFecha) {
    fechaFinal = nuevaFecha;
    notifyListeners();
  }

  void crearJunta(String nombre, String monto, String cant, String per,
      String inicio, String fin) {
    nombreJunta = nombre;
    String symbol = "S/";
    montoJunta = "$symbol $monto";
    numPersonas = int.tryParse(cant) ?? 10;
    periodo = per;
    fechaInicio = inicio;
    fechaFinal = fin;

    listaCupos.clear();
    listaCupos.add(Integrante(
        id: miIdUsuario,
        nombre: 'Tú (Admin)',
        usuario: 'Administrador',
        numero: '1',
        ocupado: true));
    redimensionarCupos(numPersonas);
    juntasActivas++;
    notifyListeners();
  }

  // --- FLUJO INTEGRANTE: UNIRSE ---

  void enviarSolicitudUnirse(
      String nom, String ape, String dni, String tel, String mail) {
    solicitudesUnirse.add(SolicitudUnirse(
      id: "MEMBER-999",
      nombre: nom,
      apellido: ape,
      dni: dni,
      telefono: tel,
      correo: mail,
    ));
    notifyListeners();
  }

  void aceptarSolicitud(SolicitudUnirse solicitud) {
    int index = listaCupos.indexWhere((c) => !c.ocupado);
    if (index != -1) {
      listaCupos[index] = Integrante(
        id: solicitud.id,
        nombre: "${solicitud.nombre} ${solicitud.apellido}",
        usuario: "Miembro",
        dni: solicitud.dni,
        telefono: solicitud.telefono,
        correo: solicitud.correo,
        numero: (index + 1).toString(),
        ocupado: true,
      );
      solicitud.aceptada = true;
      solicitudesUnirse.remove(solicitud);
      notifyListeners();
    }
  }

  // --- SORTEO E INTERCAMBIO ---

  void generarSorteoBase() {
    List<String> numeros =
        List.generate(numPersonas, (i) => (i + 1).toString());
    numeros.shuffle();
    for (int i = 0; i < listaCupos.length; i++) {
      if (listaCupos[i].ocupado) {
        listaCupos[i].numero = numeros[i];
      }
    }
    notifyListeners();
  }

  void solicitarIntercambio(String objetivoId, String objetivoNombre) {
    var yo = listaCupos.firstWhere((c) => c.id == miIdUsuario,
        orElse: () => Integrante());
    solicitudesIntercambio.add(SolicitudIntercambio(
        solicitanteId: miIdUsuario,
        solicitanteNombre: yo.nombre,
        objetivoId: objetivoId,
        objetivoNombre: objetivoNombre));
    notifyListeners();
  }

  void aprobarIntercambio(SolicitudIntercambio solicitud) {
    int indexA = listaCupos.indexWhere((c) => c.id == solicitud.solicitanteId);
    int indexB = listaCupos.indexWhere((c) => c.id == solicitud.objetivoId);

    if (indexA != -1 && indexB != -1) {
      String tempNum = listaCupos[indexA].numero;
      listaCupos[indexA].numero = listaCupos[indexB].numero;
      listaCupos[indexB].numero = tempNum;

      solicitud.status = 'aprobada';
      solicitudesIntercambio.remove(solicitud);
      notifyListeners();
    }
  }

  void rechazarIntercambio(SolicitudIntercambio solicitud) {
    solicitudesIntercambio.remove(solicitud);
    notifyListeners();
  }

  void subirVoucher(int index) {
    listaCupos[index].pagoRealizado = true;
    notifyListeners();
  }
}

void main() {
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
      // INTEGRACIÓN: Ruta inicial vuelve a ser Welcome
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
        '/form_unirse': (_) => const FormularioUnirseScreen(),
      },
    );
  }
}

// --- SCREENS ORIGINALES (DISEÑO) ---
// --- PANTALLA DE BIENVENIDA (CON INDICADORES Y BOTÓN CONDICIONAL) ---

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentPage = 0; // Controla en qué página estamos (0, 1 o 2)

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

          // Indicadores (Bolitas) y Botón
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila de bolitas (Indicadores)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 10,
                      width: _currentPage == index
                          ? 20
                          : 10, // Se estira si está activo
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFFF9800) // Naranja activo
                            : Colors.grey[300], // Gris inactivo
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30), // Espacio entre bolitas y botón

                // Botón "COMENZAR AHORA" (Solo visible en la última página, índice 2)
                _currentPage == 2
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            minimumSize: const Size(
                                double.infinity, 50), // Ancho completo
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
                    : const SizedBox(
                        height: 50), // Espacio vacío para mantener altura
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

// --- PANTALLA DE LOGIN Y REGISTRO (CON LOGO) ---

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // REEMPLAZADO: Icono por Logo
            Image.asset(
              'assets/logo.png',
              height: 100, // Ajusta el tamaño según necesites
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.savings,
                  size: 80,
                  color: Colors.orange), // Respaldo si falla
            ),
            const SizedBox(height: 20),
            const Text("¡Bienvenido Estimado cliente!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            _buildTextField(Icons.person, "Usuario o Correo"),
            const SizedBox(height: 15),
            _buildTextField(Icons.lock, "Contraseña", isPassword: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
                child: const Text("INICIAR SESIÓN"),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("¿No tienes cuenta? Regístrate aquí"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint,
      {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.orange),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AL CAMBIAR ESTO: Envolvemos el ScrollView en un Center
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // No necesitamos el SizedBox grande del principio si ya está centrado
              // REEMPLAZADO: Icono por Logo
              Image.asset(
                'assets/logo.png',
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.savings, size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              const Text("Crear Cuenta Nueva",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              _buildTextField(Icons.person, "Nombre Completo"),
              const SizedBox(height: 15),
              _buildTextField(Icons.email, "Correo Electrónico"),
              const SizedBox(height: 15),
              _buildTextField(Icons.phone, "Número de Teléfono"),
              const SizedBox(height: 15),
              _buildTextField(Icons.lock, "Contraseña", isPassword: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("REGISTRARME AHORA"),
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
    );
  }

  Widget _buildTextField(IconData icon, String hint,
      {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.orange),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

// --- HOME & NUEVA LÓGICA ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Controllers para Crear Junta
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _cantCtrl = TextEditingController();
  final _inicioCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    // Barra lateral de depuración para cambiar roles
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("SAVI", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // SIMULADOR DE ROLES (SOLO DEMO)
          PopupMenuButton<UserRole>(
            icon: const Icon(Icons.switch_account, color: Colors.purple),
            tooltip: "Simular Rol",
            onSelected: (role) {
              state.cambiarRolSimulado(role);
              Toast.show(
                  "Rol cambiado a: ${role == UserRole.owner ? 'Dueño' : 'Integrante'}",
                  context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: UserRole.owner, child: Text("Ver como DUEÑO")),
              const PopupMenuItem(
                  value: UserRole.member, child: Text("Ver como INTEGRANTE")),
            ],
          ),
          // BUZÓN DE SOLICITUDES (Solo Dueño)
          if (state.esDueno)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/solicitudes_dueno'),
                ),
                if (state.solicitudesUnirse.isNotEmpty ||
                    state.solicitudesIntercambio.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                          "${state.solicitudesUnirse.length + state.solicitudesIntercambio.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  )
              ],
            )
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

  // TAB 1: INICIO (Con diseño original + lógica nueva)
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
                      Text("Hola, ${state.esDueno ? 'Luis' : 'Integrante'}",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
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
          // Stats Row
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      "Ahorrado Total",
                      "S/ ${state.ahorradoTotal}",
                      Icons.account_balance_wallet)),
              const SizedBox(width: 15),
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

  // TAB 2: MIS JUNTAS
  Widget _buildTabMisJuntas(SaviState state) {
    bool estoyEnJunta = state.listaCupos.any((c) => c.id == state.miIdUsuario);

    if (!state.esDueno && !estoyEnJunta) {
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
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/detalles'),
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
                        Text(state.nombreJunta,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                            state.esDueno
                                ? "Eres el Organizador"
                                : "Participante",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(state.montoJunta,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey)
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  // TAB 3: UNIRSE
  Widget _buildTabUnirse(SaviState state) {
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
                  const TextField(
                    decoration: InputDecoration(
                      labelText: "Código de Invitación o Link",
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/form_unirse');
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text("SOY INTEGRANTE (SOLICITAR)"),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                      "Al pulsar 'Soy Integrante', deberás llenar tus datos para que el dueño apruebe tu ingreso.",
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

  // TAB 4: CREAR
  Widget _buildTabCrear(SaviState state) {
    if (!state.esDueno) {
      return const Center(
          child: Text("Debes ser Dueño/Organizador para crear juntas."));
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
              _buildInput("Monto Objetivo", "Monto total", _montoCtrl,
                  Icons.attach_money,
                  isNumber: true),
              const SizedBox(height: 15),
              _buildInput(
                  "Cantidad Integrantes", "Máx 10", _cantCtrl, Icons.group,
                  isNumber: true),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildDateInput("Inicio", _inicioCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDateInput("Fin", _finCtrl)),
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
                  onPressed: () {
                    state.crearJunta(
                        _nombreCtrl.text,
                        _montoCtrl.text,
                        _cantCtrl.text,
                        state.periodo,
                        _inicioCtrl.text,
                        _finCtrl.text);
                    setState(() => _currentIndex = 1);
                    Toast.show("Junta creada exitosamente", context);
                  },
                  child: const Text("CREAR Y PUBLICAR"),
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
        DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030));
        if (picked != null) ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon:
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // TAB 5: PERFIL
  Widget _buildTabPerfil(SaviState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.account_circle, size: 100, color: Colors.grey),
        const SizedBox(height: 10),
        Center(
            child: Text(state.esDueno ? "Luis (Admin)" : "Usuario Miembro",
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
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text("CERRAR SESIÓN",
              style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// --- FORMULARIO UNIRSE (CORREGIDO Y FUNCIONAL) ---

class FormularioUnirseScreen extends StatefulWidget {
  const FormularioUnirseScreen({super.key});

  @override
  State<FormularioUnirseScreen> createState() => _FormularioUnirseScreenState();
}

class _FormularioUnirseScreenState extends State<FormularioUnirseScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _dniCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _apeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Solicitud de Ingreso")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                  "Por favor, completa tus datos para enviar la solicitud al organizador.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // CAMPOS DE TEXTO
              TextFormField(
                controller: _dniCtrl,
                decoration: const InputDecoration(
                    labelText: "DNI", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(
                    labelText: "Nombres", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _apeCtrl,
                decoration: const InputDecoration(
                    labelText: "Apellidos", border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(
                    labelText: "Celular / WhatsApp",
                    border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _mailCtrl,
                decoration: const InputDecoration(
                    labelText: "Correo Electrónico",
                    border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
              ),
              const SizedBox(height: 30),

              // BOTÓN DE ENVÍO
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  // 1. Validar formulario de forma segura
                  if (_formKey.currentState?.validate() ?? false) {
                    // 2. Enviar datos al Estado (Dueño)
                    state.enviarSolicitudUnirse(_nomCtrl.text, _apeCtrl.text,
                        _dniCtrl.text, _telCtrl.text, _mailCtrl.text);

                    // 3. Simular que ahora eres miembro (para esperar aprobación)
                    state.cambiarRolSimulado(UserRole.member);

                    // 4. Mostrar confirmación y LUEGO cerrar
                    showDialog(
                        context: context,
                        barrierDismissible: false, // Obligar a usar el botón OK
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text("Solicitud Enviada"),
                            content: const Text(
                                "✅ Tu solicitud ha sido enviada al dueño.\n\n"
                                "⚠️ PARA PROBAR:\n"
                                "1. Dale OK abajo.\n"
                                "2. Cambia tu rol a 'DUEÑO' (Icono Morado arriba).\n"
                                "3. Revisa la campana de notificaciones."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // Cerrar el diálogo
                                  Navigator.of(dialogContext).pop();
                                  // Cerrar la pantalla del formulario
                                  Navigator.of(context).pop();
                                },
                                child: const Text("OK, ENTENDIDO"),
                              )
                            ],
                          );
                        });
                  }
                },
                child: const Text("ENVIAR SOLICITUD"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- BUZÓN DEL DUEÑO (SOLICITUDES) ---

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
                          trailing: IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green, size: 30),
                            onPressed: () {
                              state.aceptarSolicitud(sol);
                              Toast.show("Solicitud aceptada", context);
                            },
                          ),
                        ),
                      );
                    },
                  ),
            // TAB INTERCAMBIOS
            state.solicitudesIntercambio.isEmpty
                ? const Center(child: Text("No hay solicitudes de intercambio"))
                : ListView.builder(
                    itemCount: state.solicitudesIntercambio.length,
                    itemBuilder: (ctx, i) {
                      final swap = state.solicitudesIntercambio[i];
                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: const Text("Solicitud de Intercambio de N°"),
                          subtitle: Text(
                              "${swap.solicitanteNombre} quiere cambiar con ${swap.objetivoNombre}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    state.rechazarIntercambio(swap),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => state.aprobarIntercambio(swap),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
          ],
        ),
      ),
    );
  }
}

// --- DETALLES SCREEN (DASHBOARD) ---
class DetallesJuntaScreen extends StatelessWidget {
  const DetallesJuntaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
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
                  const Text("Monto de la junta",
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
            // LAS 4 CARDS (Con diseño original)
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

// --- INFO SCREEN (DETALLES ESPECIFICOS CON PERMISOS) ---
class InfoJuntaScreen extends StatelessWidget {
  const InfoJuntaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    final esDueno = state.esDueno;

    return Scaffold(
      appBar: AppBar(title: const Text("Detalles de la Junta")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoCard(
              "Monto", state.montoJunta, Icons.monetization_on, Colors.orange),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // No Editables
              _buildGridItem("Periodo", state.periodo, Icons.access_time,
                  editable: false),
              _buildGridItem("Inicio", state.fechaInicio, Icons.date_range,
                  editable: false),

              // Editables solo por dueño
              GestureDetector(
                onTap: esDueno ? () => _editarPersonas(context, state) : null,
                child: _buildGridItem(
                    "Personas", "${state.numPersonas} Miembros", Icons.people,
                    editable: esDueno),
              ),
              GestureDetector(
                onTap: esDueno ? () => _editarFechaFin(context, state) : null,
                child: _buildGridItem(
                    "Fin", state.fechaFinal, Icons.event_available,
                    editable: esDueno),
              ),

              // Navegación a Sorteo
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/sorteo'),
                child: _buildGridItem("Sorteo", "Ver turnos", Icons.shuffle,
                    editable: true, isAction: true),
              ),

              // Info estática
              _buildGridItem("Validación DNI", "DNI Dueño: ${state.dniDueno}",
                  Icons.verified_user,
                  editable: false),
            ],
          )
        ],
      ),
    );
  }

  void _editarPersonas(BuildContext context, SaviState state) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Editar Cantidad"),
              content: const Text("Aumentar cupos a 10?"),
              actions: [
                TextButton(
                    onPressed: () {
                      state.redimensionarCupos(10);
                      Navigator.pop(context);
                    },
                    child: const Text("ACEPTAR"))
              ],
            ));
  }

  void _editarFechaFin(BuildContext context, SaviState state) async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030));
    if (picked != null) {
      state.actualizarFechaFin(DateFormat('dd/MM/yyyy').format(picked));
    }
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
          if (editable && !isAction)
            const Positioned(
                right: 8,
                top: 8,
                child: Icon(Icons.edit, size: 16, color: Colors.grey)),
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
                    state.generarSorteoBase();
                    Toast.show("Sorteo realizado", context);
                  }),
                  const SizedBox(height: 10),
                  _botonDueno(
                      Icons.swap_horiz,
                      "VER SOLICITUDES (${state.solicitudesIntercambio.length})",
                      Colors.blue,
                      () => Navigator.pushNamed(context, '/solicitudes_dueno')),
                  const SizedBox(height: 10),
                  _botonDueno(
                      Icons.verified_user,
                      "VALIDACIÓN DNI",
                      Colors.green,
                      () => Toast.show(
                          "Todos los DNI validados correctamente", context)),
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
                      child: Text(
                          "Toca a un compañero para solicitar intercambio de número."))
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
                    onTap: (!esDueno && !soyYo && c.ocupado)
                        ? () {
                            _dialogSolicitarCambio(context, state, c);
                          }
                        : null,
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

  void _dialogSolicitarCambio(
      BuildContext context, SaviState state, Integrante objetivo) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Solicitar Intercambio"),
              content: Text(
                  "¿Deseas enviar una solicitud al dueño para cambiar tu número con ${objetivo.nombre}?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCELAR")),
                ElevatedButton(
                    onPressed: () {
                      state.solicitarIntercambio(objetivo.id, objetivo.nombre);
                      Navigator.pop(context);
                      Toast.show("Solicitud enviada al dueño", context);
                    },
                    child: const Text("ENVIAR"))
              ],
            ));
  }
}

// --- INTEGRANTES & PAGOS ---

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
                    maxLines: 1),
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
                    onPressed: () => state.subirVoucher(index),
                    child: const Text("SUBIR PAGO",
                        style: TextStyle(fontSize: 10)),
                  ),
                if (cupo.pagoRealizado)
                  TextButton(
                      onPressed: () {},
                      child: const Text("Ver Voucher",
                          style: TextStyle(fontSize: 10)))
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- REPORTAR & INVITAR ---

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
            QrImageView(data: state.codigoJunta, size: 200.0),
            const SizedBox(height: 20),
            Text(state.codigoJunta,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                icon: const Icon(Icons.share),
                onPressed: () =>
                    Share.share("Únete a mi Junta: ${state.codigoJunta}"),
                label: const Text("COMPARTIR CÓDIGO"))
          ],
        ),
      ),
    );
  }
}
