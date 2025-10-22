import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env yükle (pubspec.yaml -> assets altında .env gerektirir)
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnon = dotenv.env['SUPABASE_ANON_KEY'];

  // Opsiyonel güvenlik: env yoksa fail fast
  assert(
    supabaseUrl != null && supabaseAnon != null,
    'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env',
  );

  await Supabase.initialize(url: supabaseUrl!, anonKey: supabaseAnon!);

  runApp(CineTvApp()); // <-- app.dart içindeki router’lı uygulama
}
