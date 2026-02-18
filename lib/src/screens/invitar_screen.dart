import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class InvitarScreen extends StatelessWidget {
  const InvitarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Invitar")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Invita a tus contactos usando el código de la junta'),
            const SizedBox(height: 12),
            state.codigoJunta.isNotEmpty
                ? SelectableText('Código: ${state.codigoJunta}')
                : const Text('Selecciona una junta'),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () {/* share logic */},
                child: const Text('Compartir'))
          ],
        ),
      ),
    );
  }
}
