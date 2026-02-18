import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/savi_state.dart';

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
  final _codigoCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _cantCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

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
        automaticallyImplyLeading: false,
        title: Image.asset('assets/logo2.png', height: 36),
        actions: [
          IconButton(
            onPressed: () => state.logout(),
            icon: const Icon(Icons.logout),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Mis Juntas'),
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: 'Unirse'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Crear'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildBody(SaviState state) {
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card (Juntas activas) - moved above actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Juntas activas',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text('${state.juntasActivas}')
                    ],
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prompt
          Text('¿Que deberiamos hacer hoy?',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => setState(() => _currentIndex = 3),
                    child: const Text('CREAR JUNTA'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('BUSCAR'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabMisJuntas(SaviState state) {
    if (state.misJuntas.isEmpty) {
      return const Center(child: Text('No tienes juntas'));
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: state.misJuntas.map((junta) {
        return ListTile(
          title: Text(junta.nombre),
          subtitle: Text('Cuota: S/ ${junta.montoCuota.toStringAsFixed(2)}'),
          onTap: () async {
            await state.seleccionarJunta(junta);
            Navigator.pushNamed(context, '/detalles');
          },
        );
      }).toList(),
    );
  }

  Widget _buildTabUnirse(SaviState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          TextField(
            controller: _codigoCtrl,
            decoration: InputDecoration(
              labelText: 'Código de la junta',
              prefixIcon: const Icon(Icons.vpn_key, color: Colors.orange),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => state.unirseAJunta(_codigoCtrl.text, context),
              child: const Text('Enviar solicitud'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabCrear(SaviState state) {
    if (state.currentUser == null) {
      return const Center(child: Text('Inicia sesión para crear una junta'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre de la junta',
                  prefixIcon:
                      const Icon(Icons.edit_calendar, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _montoCtrl,
                decoration: InputDecoration(
                  labelText: 'Monto por cuota',
                  prefixIcon:
                      const Icon(Icons.attach_money, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cantCtrl,
                decoration: InputDecoration(
                  labelText: 'Cantidad de participantes',
                  prefixIcon: const Icon(Icons.group, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => state.crearJunta(
                      _nombreCtrl.text,
                      _montoCtrl.text,
                      _cantCtrl.text,
                      'Mensual',
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      '',
                      context),
                  child: const Text('Crear'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPerfil(SaviState state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
            title: const Text('Mi perfil'), subtitle: Text(state.miIdUsuario)),
      ],
    );
  }
}
