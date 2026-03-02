import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rifa_cannabis/core/config/env_config.dart';
import 'package:rifa_cannabis/core/config/theme/app_theme.dart';
import 'package:rifa_cannabis/features/raffle/presentation/views/raffle_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();

  final url = EnvConfig.supabaseUrl;
  final anonKey = EnvConfig.supabaseAnonKey;

  debugPrint('[ENV] SUPABASE_URL: ${url.isEmpty ? "VACÍA ❌" : "OK (${url.length} chars) ✅"}');
  debugPrint('[ENV] SUPABASE_ANON_KEY: ${anonKey.isEmpty ? "VACÍA ❌" : "OK (${anonKey.length} chars) ✅"}');

  if (url.isEmpty || anonKey.isEmpty) {
    debugPrint('[ENV] ❌ Variables vacías — buildear con --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rifa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RaffleView(),
    );
  }
}
