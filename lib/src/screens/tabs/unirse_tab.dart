import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/savi_state.dart';

class UnirseTab extends StatefulWidget {
  const UnirseTab({super.key});

  @override
  State<UnirseTab> createState() => _UnirseTabState();
}

class _UnirseTabState extends State<UnirseTab> {
  final _codigoCtrl = TextEditingController();

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          TextField(
            controller: _codigoCtrl,
            decoration: InputDecoration(
              labelText: 'Código de la junta',
              prefixIcon: const Icon(Icons.vpn_key, color: Colors.orange),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => state.unirseAJunta(_codigoCtrl.text),
              child: const Text('Enviar solicitud'),
            ),
          ),
        ],
      ),
    );
  }
}
