import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class DetallesJuntaScreen extends StatelessWidget {
  const DetallesJuntaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    if (state.juntaSeleccionada == null) {
      return const Scaffold(body: Center(child: Text('Seleccione una junta')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles Junta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(state.nombreJunta,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Código: ${state.codigoJunta}'),
            const SizedBox(height: 12),
            Text('Participantes: ${state.numPersonas}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/pagos'),
              child: const Text('Ver pagos'),
            ),
          ],
        ),
      ),
    );
  }
}
