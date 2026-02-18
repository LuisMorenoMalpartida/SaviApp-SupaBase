import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class InfoJuntaScreen extends StatelessWidget {
  const InfoJuntaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    if (state.juntaSeleccionada == null) {
      return const Scaffold(body: Center(child: Text('Seleccione una junta')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de la Junta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
              title: const Text('Nombre'), subtitle: Text(state.nombreJunta)),
          ListTile(
              title: const Text('Código'), subtitle: Text(state.codigoJunta)),
          ListTile(title: const Text('Periodo'), subtitle: Text(state.periodo)),
        ],
      ),
    );
  }
}
