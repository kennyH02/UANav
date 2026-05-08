import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize tile caching for offline map support
  if (!kIsWeb) {
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore('osmStore').manage.create();
  }

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw StateError('Missing SUPABASE_URL in .env');
  }

  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw StateError('Missing SUPABASE_ANON_KEY in .env');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UANav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF46166B),
          primary: const Color(0xFF46166B),
          secondary: const Color(0xFFEAAA00),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
