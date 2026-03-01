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
  debugPrint('🔐 [LOGIN DEBUG] SUPABASE_URL cargada: ${url.isEmpty ? "VACÍA (problema en web sin dart-define)" : "OK (${url.length} chars)"}');
  debugPrint('🔐 [LOGIN DEBUG] SUPABASE_ANON_KEY cargada: ${anonKey.isEmpty ? "VACÍA (auth fallará)" : "OK (${anonKey.length} chars)"}');

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
