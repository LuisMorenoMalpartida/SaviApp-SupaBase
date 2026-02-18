import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/savi_state.dart';

class MisJuntasTab extends StatelessWidget {
  const MisJuntasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
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
}
