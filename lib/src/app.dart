import 'package:flutter/material.dart';
import 'utils/navigation.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
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

// Compatibility shim: new Flutter `PopScope` API may not be available
// on older SDKs or our linter; provide a thin wrapper that preserves
// the expected `onWillPop` signature while delegating to
// `WillPopScope`. This lets call sites use `PopScope(...)` safely.
class PopScope extends StatefulWidget {
  final Future<bool> Function()? onWillPop;
  final Widget child;

  const PopScope({super.key, this.onWillPop, required this.child});

  @override
  State<PopScope> createState() => _PopScopeState();
}

class _PopScopeState extends State<PopScope> {
  Future<bool> Function()? _handler;
  Route<dynamic>? _route;
  VoidCallback? _unregisterPop;

  @override
  void initState() {
    super.initState();
    _handler = widget.onWillPop ?? () async => true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cache the route and register pop callback; capture an unregister
      // closure so we don't need to query the widget tree in dispose.
      _route = ModalRoute.of(context);
      final r = _route as dynamic;
      try {
        r.registerPopEntry?.call(_onWillPop);
        _unregisterPop = () {
          try {
            r.unregisterPopEntry?.call(_onWillPop);
          } catch (_) {}
        };
      } catch (_) {
        try {
          r.addScopedWillPopCallback?.call(_onWillPop);
          _unregisterPop = () {
            try {
              r.removeScopedWillPopCallback?.call(_onWillPop);
            } catch (_) {}
          };
        } catch (_) {
          _unregisterPop = null;
        }
      }
    });
  }

  Future<bool> _onWillPop() async {
    return await (_handler?.call() ?? Future.value(true));
  }

  @override
  void didUpdateWidget(covariant PopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handler = widget.onWillPop ?? () async => true;
  }

  @override
  void dispose() {
    // Use the cached unregister closure registered in initState instead
    // of querying the element tree here (which may be deactivated).
    try {
      _unregisterPop?.call();
    } catch (_) {}
    _unregisterPop = null;
    _route = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
                color: Colors.black.withAlpha((0.85 * 255).round()),
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
      theme: AppTheme.light(),
      initialRoute: '/welcome',
      builder: (context, child) {
        return PopScope(
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
