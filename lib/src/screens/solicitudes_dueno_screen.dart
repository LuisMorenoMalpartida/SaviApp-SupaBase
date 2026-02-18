import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class SolicitudesDuenoScreen extends StatelessWidget {
  const SolicitudesDuenoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 8),
          const Text('Solicitudes de unirse'),
          ...state.solicitudesUnirse.map((s) {
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
          }).toList(),
        ],
      ),
    );
  }
}
