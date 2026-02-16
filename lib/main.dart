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

class Integrante {
  String id;
  String nombre;
  String usuario;
  String dni;
  String telefono;
  String correo;
  String numero;
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
  final String numFrom;
  final String numTo;
  SolicitudIntercambio(this.numFrom, this.numTo);
}

// --- APP STATE (PROVIDER) ---

class SaviState extends ChangeNotifier {
  // Config
  String moneda = "Soles";
  String usuarioActualId = "USR-001";
  bool esDueno = true;
  bool isCreator = true;

  // Current Junta Data
  String nombreJunta = "Viaje a Cancún 2026";
  String montoJunta = "S/ 5,000";
  int numPersonas = 10;
  String periodo = "Mensual";
  String fechaInicio = "01/03/2026";
  String fechaFinal = "01/01/2027";
  String codigoJunta = "SAVI-8823";

  List<Integrante> listaCupos = [];
  List<SolicitudIntercambio> solicitudes = [];

  // Stats
  double ahorradoTotal = 0.00;
  int juntasActivas = 0;

  SaviState() {
    // Inicializar con datos demo
    if (listaCupos.isEmpty) {
      // Admin
      listaCupos.add(Integrante(
        id: usuarioActualId,
        nombre: 'Luis (Yo)',
        usuario: 'Administrador',
        numero: '1',
        ocupado: true,
        pagoRealizado: false,
      ));
      // Demo users
      listaCupos.add(Integrante(
          nombre: 'Marizol',
          usuario: 'Miembro',
          numero: '2',
          ocupado: true,
          pagoRealizado: true));
      listaCupos.add(Integrante(
          nombre: 'Carlos',
          usuario: 'Miembro',
          numero: '3',
          ocupado: true,
          pagoRealizado: false));
      // Fill rest
      redimensionarCupos(10);
    }
  }

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

  void crearJunta(String nombre, String monto, String cant, String per,
      String inicio, String fin) {
    nombreJunta = nombre;
    String symbol = moneda == "Soles" ? "S/" : "\$";
    montoJunta = "$symbol $monto";
    numPersonas = int.tryParse(cant) ?? 10;
    if (numPersonas > 10) numPersonas = 10;
    if (numPersonas < 1) numPersonas = 1;
    periodo = per;
    fechaInicio = inicio;
    fechaFinal = fin;

    // Reset cupos
    listaCupos.clear();
    listaCupos.add(Integrante(
        id: usuarioActualId,
        nombre: 'Tú (Admin)',
        usuario: 'Administrador',
        numero: '1',
        ocupado: true));
    redimensionarCupos(numPersonas);

    // Update Stats
    juntasActivas++;

    notifyListeners();
  }

  void generarSorteo(BuildContext context) {
    var participantes =
        listaCupos.where((c) => c.ocupado && c.numero != '1').toList();
    if (participantes.isEmpty) {
      Toast.show("No hay participantes para sortear", context);
      return;
    }

    List<int> available = List.generate(listaCupos.length - 1, (i) => i + 2);
    available.shuffle();

    for (int i = 0; i < participantes.length; i++) {
      if (i < available.length) {
        participantes[i].numero = available[i].toString();
      }
    }
    notifyListeners();
    Toast.show("Sorteo realizado", context);
  }

  void actualizarIntegrante(
      int index, String nombre, String dni, String tel, String correo) {
    if (index >= 0 && index < listaCupos.length) {
      listaCupos[index].nombre = nombre;
      listaCupos[index].dni = dni;
      listaCupos[index].telefono = tel;
      listaCupos[index].correo = correo;
      listaCupos[index].ocupado = true;

      // Auto assign number if empty
      if (listaCupos[index].numero.isEmpty) {
        Set<String> used = listaCupos.map((e) => e.numero).toSet();
        for (int i = 2; i <= listaCupos.length; i++) {
          if (!used.contains(i.toString())) {
            listaCupos[index].numero = i.toString();
            break;
          }
        }
      }
      notifyListeners();
    }
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
          primaryColor: const Color(0xFFFF9800), // Orange
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
      },
    );
  }
}

// --- SCREENS ---

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            children: [
              _buildPage(
                  Colors.orange[100]!, "assets/1.png", "Bienvenido a SAVI"),
              _buildPage(
                  Colors.orange[200]!, "assets/2.png", "Organiza tus Juntas"),
              _buildPage(Colors.orange[300]!, "assets/3.png",
                  "Gestiona Pagos Fácilmente"),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text("COMENZAR AHORA",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(Color color, String img, String text) {
    return Container(
      color: color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Image
            const Icon(Icons.image, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(text,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

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
            const Icon(Icons.savings,
                size: 80, color: Colors.orange), // Logo placeholder
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Icon(Icons.savings, size: 80, color: Colors.orange),
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
                onPressed: () => Navigator.pop(context), // Back to login
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Controllers for Create Tab
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _cantCtrl = TextEditingController();
  final _inicioCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    final List<Widget> tabs = [
      _buildTabInicio(state),
      _buildTabMisJuntas(state),
      _buildTabUnirse(state),
      _buildTabCrear(state),
      _buildTabPerfil(state),
    ];

    return Scaffold(
      body: SafeArea(child: tabs[_currentIndex]),
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

  // TAB 1: INICIO
  Widget _buildTabInicio(SaviState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Card
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(0)), // Dark header like KV
            child: Center(
                child: Text("SAVI",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 20),
          // Banner Image
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
                child: Icon(Icons.image, size: 80, color: Colors.white)),
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      "Ahorrado Total",
                      "S/ ${state.ahorradoTotal.toStringAsFixed(2)}",
                      Icons.account_balance_wallet_outlined)),
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
                      child: const Text("BUSCAR"))),
            ],
          ),
          const SizedBox(height: 20),
          // Tip Card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.orange.withOpacity(0.3))),
            child: const ListTile(
              leading:
                  Icon(Icons.lightbulb_outline, color: Colors.orange, size: 40),
              title: Text("Tip Financiero",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Invierte el 10% de tus ingresos en tu junta."),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon) {
    return Card(
      color: Colors.orange,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 5),
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(val,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // TAB 2: MIS JUNTAS
  Widget _buildTabMisJuntas(SaviState state) {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        if (state.juntasActivas == 0)
          const SizedBox(
              height: 300,
              child: Center(
                  child: Text(
                      "Aquí aparecerán tus juntas creadas.\nUsa la pestaña 'Crear' para empezar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey))))
        else
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/detalles'),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.nombreJunta,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text("Gestión activa",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(state.montoJunta,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ingresa el Código QR o Link",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Ej: SAVI-8823",
                      suffixIcon:
                          const Icon(Icons.qr_code, color: Colors.orange),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            Toast.show(
                                "Escaneo no disponible en demo", context);
                          },
                          icon: const Icon(Icons.qr_code_scanner,
                              color: Colors.orange)),
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.upload_file,
                              color: Colors.orange)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Toast.show("Solicitud enviada", context);
                          },
                          child: const Text("UNIRSE AHORA"),
                        ),
                      )
                    ],
                  )
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
                    setState(() => _currentIndex = 1); // Go to Mis Juntas
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
        const Center(
            child: Text("Usuario Savi",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
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
          child: const Text("CERRAR SESIÓN"),
        )
      ],
    );
  }
}

// --- DETALLES SCREEN ---
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
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(context, "Detalles", "Consulta datos",
                    Icons.list_alt, Colors.blue, '/info'),
                _buildActionCard(context, "Invitar", "Comparte ID",
                    Icons.qr_code, Colors.green, '/invitar'),
                _buildActionCard(context, "Integrantes", "Registra pagos",
                    Icons.groups, Colors.blue, '/pagos'),
                _buildActionCard(context, "Reportar", "Informa faltas",
                    Icons.report_problem, Colors.red, '/reportar'),
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
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
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

// --- INTEGRANTES SCREEN ---
class IntegrantesPagosScreen extends StatelessWidget {
  const IntegrantesPagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Integrantes y Pagos")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/sorteo'),
        child: const Icon(Icons.shuffle),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemCount: state.listaCupos.length,
        itemBuilder: (context, index) {
          final cupo = state.listaCupos[index];
          final esMio = cupo.id == state.usuarioActualId;

          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell(
              onTap: () => _showEditDialog(context, state, index),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          cupo.pagoRealizado ? Colors.green : Colors.grey[300],
                      child: Text(cupo.numero.isEmpty ? "?" : cupo.numero,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    Text(cupo.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(cupo.usuario,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: cupo.pagoRealizado
                              ? Colors.green[50]
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(
                          cupo.pagoRealizado ? "PAGO RECIBIDO" : "PENDIENTE",
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: cupo.pagoRealizado
                                  ? Colors.green
                                  : Colors.red)),
                    ),
                    if (esMio && !cupo.pagoRealizado)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10)),
                        onPressed: () => state.subirVoucher(index),
                        child: const Text("SUBIR PAGO",
                            style: TextStyle(fontSize: 10)),
                      )
                    else if (cupo.pagoRealizado)
                      TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 12),
                        label: const Text("VOUCHER",
                            style: TextStyle(fontSize: 10)),
                        onPressed: () =>
                            Toast.show("Voucher visualizado", context),
                      )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, SaviState state, int index) {
    final cupo = state.listaCupos[index];
    final nombreCtrl = TextEditingController(text: cupo.nombre);
    final dniCtrl = TextEditingController(text: cupo.dni);

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Editar Integrante"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: "Nombre")),
                  TextField(
                      controller: dniCtrl,
                      decoration: const InputDecoration(labelText: "DNI")),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CANCELAR")),
                ElevatedButton(
                    onPressed: () {
                      state.actualizarIntegrante(
                          index, nombreCtrl.text, dniCtrl.text, "", "");
                      Navigator.pop(ctx);
                    },
                    child: const Text("GUARDAR"))
              ],
            ));
  }
}

// --- INFO SCREEN ---
class InfoJuntaScreen extends StatelessWidget {
  const InfoJuntaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
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
              _buildGridItem("Periodo", state.periodo, Icons.access_time),
              _buildGridItem(
                  "Personas", "${state.numPersonas} Miembros", Icons.people),
              _buildGridItem("Inicio", state.fechaInicio, Icons.date_range),
              _buildGridItem("Fin", state.fechaFinal, Icons.event_available),
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
            const SizedBox(height: 5),
            Text(val,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, String val, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Icon(icon, size: 30, color: Colors.orange),
            const SizedBox(height: 10),
            Text(val, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
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
    return Scaffold(
      appBar: AppBar(title: const Text("Sorteo de Turnos")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20))),
            child: Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => state.generarSorteo(context),
                  icon: const Icon(Icons.casino),
                  label: const Text("GENERAR SORTEO"),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    Toast.show("Solicitud enviada", context);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text("SOLICITAR INTERCAMBIO"),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Asignaciones actuales",
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.listaCupos.length,
              itemBuilder: (ctx, i) {
                final c = state.listaCupos[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Text(c.numero,
                            style: const TextStyle(color: Colors.white))),
                    title: Text(c.nombre),
                    subtitle: Text(c.usuario),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// --- INVITAR & REPORTAR SCREENS ---

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
            // QR Generado
            QrImageView(
              data: "https://savi.app/unirse/${state.codigoJunta}",
              version: QrVersions.auto,
              size: 200.0,
            ),
            const SizedBox(height: 20),
            Text(state.codigoJunta,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(
                      'Únete a mi Junta en SAVI con el código: ${state.codigoJunta} o entra a https://savi.app/unirse/${state.codigoJunta}');
                },
                label: const Text("COMPARTIR ENLACE"))
          ],
        ),
      ),
    );
  }
}

class ReportarScreen extends StatelessWidget {
  const ReportarScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reportar")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Notifica incumplimientos",
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
                decoration: InputDecoration(
                    labelText: "DNI",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 15),
            TextField(
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: "Reclamo",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ENVIAR REPORTE")),
            )
          ],
        ),
      ),
    );
  }
}
