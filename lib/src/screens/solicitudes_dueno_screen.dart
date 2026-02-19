import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class SolicitudesDuenoScreen extends StatelessWidget {
  const SolicitudesDuenoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    final solicitudes = state.solicitudesUnirse;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: solicitudes.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) return const SizedBox(height: 8);
          if (index == 1) return const Text('Solicitudes de unirse');
          final s = solicitudes[index - 2];
          return Card(
            child: ListTile(
              title: Text(s['perfiles'] != null
                  ? '${s['perfiles']['nombre'] ?? ''} ${s['perfiles']['apellido'] ?? ''}'
                  : s['usuario_id']),
              subtitle: Text('DNI: ${s['perfiles']?['dni'] ?? ''}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => state.aceptarSolicitud(s)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => state.rechazarSolicitud(s)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
