import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/savi_state.dart';

class PerfilTab extends StatelessWidget {
  const PerfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
            title: const Text('Mi perfil'), subtitle: Text(state.miIdUsuario)),
      ],
    );
  }
}
