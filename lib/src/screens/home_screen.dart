import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';
import 'tabs/mis_juntas_tab.dart';
import 'tabs/unirse_tab.dart';
import 'tabs/crear_tab.dart';
import 'tabs/perfil_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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
        return const MisJuntasTab();
      case 2:
        return const UnirseTab();
      case 3:
        return const CrearTab();
      case 4:
        return const PerfilTab();
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
}
