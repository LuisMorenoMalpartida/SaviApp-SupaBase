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

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _cantCtrl.dispose();
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
        title: const Text('SAVI'),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Mis Juntas"),
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: "Unirse"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Crear"),
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
        children: [
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
                  ElevatedButton(
                    onPressed: () => setState(() => _currentIndex = 3),
                    child: const Text('Crear Junta'),
                  )
                ],
              ),
            ),
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
    final codigoCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          TextField(
              controller: codigoCtrl,
              decoration:
                  const InputDecoration(labelText: 'Código de la junta')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => state.unirseAJunta(codigoCtrl.text, context),
            child: const Text('Enviar solicitud'),
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
                  decoration:
                      const InputDecoration(labelText: 'Nombre de la junta')),
              const SizedBox(height: 8),
              TextField(
                  controller: _montoCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Monto por cuota')),
              const SizedBox(height: 8),
              TextField(
                  controller: _cantCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Cantidad de participantes')),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => state.crearJunta(
                    _nombreCtrl.text,
                    _montoCtrl.text,
                    _cantCtrl.text,
                    'Mensual',
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    '',
                    context),
                child: const Text('Crear'),
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
