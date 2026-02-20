import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';

class IntegrantesPagosScreen extends StatelessWidget {
  const IntegrantesPagosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Estado de Pagos')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.9),
        itemCount: state.listaCupos.length,
        itemBuilder: (context, i) {
          return Consumer<SaviState>(builder: (ctx, state, _) {
            final c = state.listaCupos[i];
            final nombre = c.nombre ?? 'Disponible';
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(c.pagoRealizado ? 'Pagado' : 'Pendiente'),
                  const SizedBox(height: 12),
                  AppButton(
                      onPressed: () => _mostrarSubirVoucher(context, state, i),
                      child: const Text('Subir voucher'))
                ],
              ),
            );
          });
        },
      ),
    );
  }

  void _mostrarSubirVoucher(BuildContext context, SaviState state, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subir voucher'),
        content: const Text('Simular subida de voucher'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              state.subirVoucher(index, 'https://example.com/voucher.png');
              Navigator.pop(context);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
