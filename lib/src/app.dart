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

class SaviApp extends StatelessWidget {
  const SaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SAVI',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/welcome',
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
      },
    );
  }
}
