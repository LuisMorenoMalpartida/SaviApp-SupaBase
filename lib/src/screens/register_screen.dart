import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/toast.dart';
import '../state/savi_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final dniCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    dniCtrl.dispose();
    telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SaviState>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 8),
                TextField(
                    controller: apellidoCtrl,
                    decoration: const InputDecoration(labelText: 'Apellido')),
                const SizedBox(height: 8),
                TextField(
                    controller: dniCtrl,
                    decoration: const InputDecoration(labelText: 'DNI')),
                const SizedBox(height: 8),
                TextField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono')),
                const SizedBox(height: 8),
                TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña')),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _handleRegister(context, state),
                  child: const Text('Registrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleRegister(BuildContext context, SaviState state) {
    FocusScope.of(context).unfocus();
    state.registrarUsuario(
      email: emailCtrl.text,
      password: passCtrl.text,
      nombre: nombreCtrl.text,
      apellido: apellidoCtrl.text,
      dni: dniCtrl.text,
      telefono: telefonoCtrl.text,
      context: context,
      onSuccess: () {
        Toast.show("Registro exitoso. Ya puedes iniciar sesión.", context);
        Navigator.pop(context);
      },
    );
  }
}
