import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../state/savi_state.dart';
import 'package:flutter/services.dart';

class CrearTab extends StatefulWidget {
  const CrearTab({super.key});

  @override
  State<CrearTab> createState() => _CrearTabState();
}

class _CrearTabState extends State<CrearTab> {
  final _nombreCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _cantCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinalCtrl = TextEditingController();
  String? _periodo;
  String _moneda = 'Soles';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _montoCtrl.dispose();
    _cantCtrl.dispose();
    _dniCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context);

    if (state.currentUser == null) {
      return const Center(child: Text('Inicia sesión para crear una junta'));
    }

    // Form layout matching the provided design
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Builder(builder: (ctx) {
                    final user = state.currentUser;
                    String name = 'Usuario';
                    try {
                      final meta = (user?.userMetadata ?? user?.user_metadata)
                          as Map<String, dynamic>?;
                      name = meta != null &&
                              (meta['nombre'] ?? meta['name']) != null
                          ? (meta['nombre'] ?? meta['name']).toString()
                          : (user?.email?.split('@').first ?? 'Usuario');
                    } catch (_) {
                      name = user?.email?.split('@').first ?? 'Usuario';
                    }

                    return Text('Hola! $name',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.orange));
                  }),
                  const SizedBox(height: 6),
                  const Text('necesitamos algunos datos para empezar.'),
                  const SizedBox(height: 14),

                  // DNI
                  _buildField(
                    controller: _dniCtrl,
                    hint: 'Coloca tu DNI o CE',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Nombre de la junta
                  _buildField(
                      controller: _nombreCtrl,
                      hint: 'Empieza dándole un nombre a tu junta',
                      icon: Icons.edit_note),
                  const SizedBox(height: 12),

                  // Fecha inicio / fecha final
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                            controller: _fechaInicioCtrl,
                            hint: 'fecha inicio',
                            icon: Icons.calendar_month,
                            onPick: () => _pickDate(_fechaInicioCtrl)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Hasta'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDateField(
                            controller: _fechaFinalCtrl,
                            hint: 'fecha final',
                            icon: Icons.calendar_month,
                            onPick: () => _pickDate(_fechaFinalCtrl)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Monto + moneda
                  _buildMontoWithCurrency(),
                  const SizedBox(height: 12),

                  // Cantidad
                  _buildField(
                      controller: _cantCtrl,
                      hint: 'cantidad de integrantes',
                      icon: Icons.format_list_numbered),
                  const SizedBox(height: 12),

                  // Periodo
                  _buildPeriodDropdown(),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _onCreatePressed,
                      child: const Text('Crear'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Show the last created code card if present
          if (state.ultimoCodigoCreado != null &&
              state.ultimoCodigoCreado!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Código creado',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        SelectableText(state.ultimoCodigoCreado ?? ''),
                      ],
                    )),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: state.ultimoCodigoCreado ?? ''));
                      },
                      icon: const Icon(Icons.copy),
                    ),
                    IconButton(
                        onPressed: () {
                          state.clearUltimoCodigoCreado();
                        },
                        icon: const Icon(Icons.close)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
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
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onPick,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.orange),
            filled: true,
            fillColor: Colors.white,
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
      ),
    );
  }

  Widget _buildMontoWithCurrency() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Aquí pon el monto objetivo de tu junta',
              prefixIcon: const Icon(Icons.attach_money, color: Colors.orange),
              filled: true,
              fillColor: Colors.white,
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
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _moneda,
              items: const [
                DropdownMenuItem(value: 'Soles', child: Text('Soles')),
                DropdownMenuItem(value: 'Dólares', child: Text('Dólares')),
              ],
              onChanged: (v) => setState(() => _moneda = v ?? 'Soles'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown() {
    const periodoOptions = ['Mensual', 'Semanal', 'Quincenal'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: (_periodo != null && periodoOptions.contains(_periodo))
              ? _periodo
              : null,
          hint: const Text('Periodo de pago'),
          items: const [
            DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
            DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
            DropdownMenuItem(value: 'Quincenal', child: Text('Quincenal')),
          ],
          onChanged: (v) => setState(() => _periodo = v),
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _onCreatePressed() {
    final state = Provider.of<SaviState>(context, listen: false);
    // clamp cantidad to max 20
    int parsedCant = int.tryParse(_cantCtrl.text) ?? 1;
    if (parsedCant > 20) parsedCant = 20;

    state.crearJunta(
      _nombreCtrl.text,
      _montoCtrl.text,
      parsedCant.toString(),
      _periodo ?? 'Mensual',
      _fechaInicioCtrl.text.isNotEmpty
          ? _fechaInicioCtrl.text
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
      _fechaFinalCtrl.text,
      moneda: _moneda,
    );
  }
}
