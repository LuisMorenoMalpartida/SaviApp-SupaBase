import 'package:flutter/material.dart';
import 'utils/navigation.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/detalles_junta_screen.dart';
import 'screens/info_junta_screen.dart';
import 'screens/integrantes_pagos_screen.dart';
import 'screens/invitar_screen.dart';
import 'screens/reportar_screen.dart';
import 'screens/sorteo_screen.dart';
import 'screens/solicitudes_dueno_screen.dart';
import 'screens/recuperar_screen.dart';

class SaviApp extends StatefulWidget {
  const SaviApp({super.key});

  @override
  State<SaviApp> createState() => _SaviAppState();
}

class _SaviAppState extends State<SaviApp> {
  DateTime? _lastBackPressed;
  OverlayEntry? _toastEntry;

  void _showToast(BuildContext context, String message) {
    _toastEntry?.remove();
    _toastEntry = OverlayEntry(builder: (ctx) {
      return Positioned(
        bottom: 90,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    });

    final overlay = Overlay.of(context);
    overlay.insert(_toastEntry!);
    Future.delayed(const Duration(milliseconds: 1500)).then((_) {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  @override
  void dispose() {
    _toastEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SAVI',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/welcome',
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () async {
            // if there's somewhere to pop inside navigator, allow default pop
            if (Navigator.of(context).canPop()) return true;

            final now = DateTime.now();
            if (_lastBackPressed == null ||
                now.difference(_lastBackPressed!) >
                    const Duration(seconds: 2)) {
              _lastBackPressed = now;
              _showToast(context, 'Presione otra vez para salir');
              return false;
            }
            return true;
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/detalles': (_) => const DetallesJuntaScreen(),
        '/info': (_) => const InfoJuntaScreen(),
        '/pagos': (_) => const IntegrantesPagosScreen(),
        '/invitar': (_) => const InvitarScreen(),
        '/reportar': (_) => const ReportarScreen(),
        '/sorteo': (_) => const SorteoScreen(),
        '/solicitudes_dueno': (_) => const SolicitudesDuenoScreen(),
        '/recuperar': (_) => const RecuperarScreen(),
      },
    );
  }
}
