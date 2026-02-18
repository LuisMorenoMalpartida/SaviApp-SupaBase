import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/state/savi_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://wwrzudqkzycdgpsdgvnu.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind3cnp1ZHFrenljZGdwc2Rndm51Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNDUxOTEsImV4cCI6MjA4NjkyMTE5MX0.O8K7g1mih8XgzDqTH4tCoGgoPf3aV53h1Fhuz7A7N3c',
    );
    debugPrint('✅ Supabase initialized');
  } catch (e) {
    debugPrint('❌ Supabase initialize error: $e');
  }

  runApp(
    ChangeNotifierProvider<SaviState>(
      create: (_) => SaviState(),
      child: const SaviApp(),
    ),
  );
}
