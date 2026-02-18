import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/savi_state.dart';

class CrearTab extends StatefulWidget {
  const CrearTab({super.key});

  @override
  State<CrearTab> createState() => _CrearTabState();
}

class _CrearTabState extends State<CrearTab> {
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _cantCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _cantCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    if (state.currentUser == null) {
      return const Center(child: Text('Inicia sesión para crear una junta'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre de la junta',
                  prefixIcon:
                      const Icon(Icons.edit_calendar, color: Colors.orange),
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
              const SizedBox(height: 8),
              TextField(
                controller: _montoCtrl,
                decoration: InputDecoration(
                  labelText: 'Monto por cuota',
                  prefixIcon:
                      const Icon(Icons.attach_money, color: Colors.orange),
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
              const SizedBox(height: 8),
              TextField(
                controller: _cantCtrl,
                decoration: InputDecoration(
                  labelText: 'Cantidad de participantes',
                  prefixIcon: const Icon(Icons.group, color: Colors.orange),
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => state.crearJunta(
                    _nombreCtrl.text,
                    _montoCtrl.text,
                    _cantCtrl.text,
                    'Mensual',
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    '',
                  ),
                  child: const Text('Crear'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
