import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/toast.dart';
import '../state/savi_state.dart';

class ReportarScreen extends StatefulWidget {
  const ReportarScreen({super.key});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  String? seleccionado;
  final comentarioCtrl = TextEditingController();

  @override
  void dispose() {
    comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);
    final deudores =
        state.listaCupos.where((c) => c.ocupado && !c.pagoRealizado).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Reportar Incidencia")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text('Seleccione deudor'),
            ...deudores.map((d) => ListTile(
                title: Text(d.nombre ?? ''),
                leading: Icon(
                  seleccionado == (d.id ?? '')
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                onTap: () => setState(() => seleccionado = d.id ?? ''))),
            const SizedBox(height: 12),
            TextField(
                controller: comentarioCtrl,
                decoration: const InputDecoration(labelText: 'Comentario')),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () {
                  Toast.show('Reporte enviado', context);
                  Navigator.pop(context);
                },
                child: const Text('Enviar'))
          ],
        ),
      ),
    );
  }
}
