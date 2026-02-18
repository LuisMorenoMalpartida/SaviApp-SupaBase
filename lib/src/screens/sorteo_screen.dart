import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class SorteoScreen extends StatelessWidget {
  const SorteoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    final esDueno = state.esDueno;

    return Scaffold(
      appBar:
          AppBar(title: Text(esDueno ? "Gestión Sorteo" : "Resultados Sorteo")),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text(esDueno ? 'Panel del dueño' : 'Resultados del sorteo'),
        ],
      ),
    );
  }
}
