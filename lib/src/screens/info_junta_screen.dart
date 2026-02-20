import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';
import '../widgets/app_card.dart';

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
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/detalles'),
            child: AppCard(
              child: ListTile(
                title: const Text('Nombre'),
                subtitle: Text(state.nombreJunta),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
              child: ListTile(
                  title: const Text('Código'),
                  subtitle: Text(state.codigoJunta))),
          const SizedBox(height: 12),
          AppCard(
              child: ListTile(
                  title: const Text('Periodo'), subtitle: Text(state.periodo))),
        ],
      ),
    );
  }
}
