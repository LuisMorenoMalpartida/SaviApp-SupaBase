import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/savi_state.dart';

class RecuperarScreen extends StatefulWidget {
  const RecuperarScreen({super.key});

  @override
  State<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends State<RecuperarScreen> {
  final emailCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    emailCtrl.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    emailCtrl.removeListener(_onFieldsChanged);
    emailCtrl.dispose();
    super.dispose();
  }

  void _onFieldsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo.png', height: 200, fit: BoxFit.contain),
              const SizedBox(height: 20),
              const Text(
                'Recuperar cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              if (!_sent) ...[
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email, color: Colors.orange),
                    errorText: _errorText,
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
                    onPressed: _sending ||
                            emailCtrl.text.isEmpty ||
                            (_errorText != null)
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            setState(() => _sending = true);
                            // validate email format one more time
                            final email = emailCtrl.text.trim();
                            final emailRegex =
                                RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                            if (!emailRegex.hasMatch(email)) {
                              setState(() {
                                _sending = false;
                                _errorText = 'Email inválido';
                              });
                              return;
                            }

                            final state =
                                Provider.of<SaviState>(context, listen: false);
                            final success =
                                await state.solicitarRecuperacion(email);
                            if (!mounted) return;
                            setState(() {
                              _sending = false;
                              _sent = success;
                              if (!success) {
                                _errorText = 'Error al solicitar recuperación';
                              }
                            });
                          },
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('Solicitar restablecimiento'),
                  ),
                ),
              ],
              if (_sent) ...[
                const SizedBox(height: 8),
                Icon(Icons.check_circle, size: 56, color: Colors.orange),
                const SizedBox(height: 12),
                const Text('Se ha enviado un correo de restablecimiento.'),
                const SizedBox(height: 8),
                const Text(
                    'Revisa tu bandeja de entrada y sigue las instrucciones.'),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Volver',
                      style: TextStyle(color: Colors.orange)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
