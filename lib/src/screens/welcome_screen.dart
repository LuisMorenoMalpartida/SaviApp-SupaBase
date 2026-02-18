import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bienvenido a SAVI', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Iniciar sesión')),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Registrarse')),
          ],
        ),
      ),
    );
  }
}
