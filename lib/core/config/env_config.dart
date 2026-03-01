import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de variables de entorno (estilo APEX).
/// En Web se carga el .env desde assets (incluido en pubspec).
class EnvConfig {
  const EnvConfig._();

  static Future<void> load() async {
    if (kIsWeb) {
      try {
        final contents = await rootBundle.loadString('.env');
        _parseEnv(contents);
      } catch (e) {
        debugPrint("Nota: .env no cargado en web (revisá que assets incluyan .env): $e");
      }
      return;
    }
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Nota: .env no cargado: $e");
    }
  }

  static final Map<String, String> _webEnv = {};

  static void _parseEnv(String contents) {
    for (final line in contents.replaceAll('\r', '').split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx > 0) {
        final key = trimmed.substring(0, idx).trim();
        String value = trimmed.substring(idx + 1).trim();
        if (value.startsWith('"') && value.endsWith('"')) value = value.substring(1, value.length - 1);
        if (value.startsWith("'") && value.endsWith("'")) value = value.substring(1, value.length - 1);
        _webEnv[key] = value;
      }
    }
  }

  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (kIsWeb && _webEnv.isNotEmpty) return _webEnv['SUPABASE_URL'] ?? '';
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (kIsWeb && _webEnv.isNotEmpty) return _webEnv['SUPABASE_ANON_KEY'] ?? '';
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }
}
