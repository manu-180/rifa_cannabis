import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Sistema de variables de entorno.
///
/// Prioridad de lectura (en los getters):
///   1. --dart-define (producción web y cualquier build con flags)
///   2. .env cargado desde assets (local web y desktop; el archivo debe estar en pubspec)
///
/// Carga: en todos los entornos se intenta cargar .env desde assets.
/// Para que funcione en local necesitas un archivo .env en la raíz (copia de .env.example).
/// En producción web se suele buildear con --dart-define y esos valores tienen prioridad.
class EnvConfig {
  const EnvConfig._();

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('[ENV] .env cargado OK (assets)');
    } catch (e) {
      debugPrint('[ENV] .env no cargado: $e');
      debugPrint('[ENV] Crea .env en la raíz (copia de .env.example) o usa --dart-define al buildear.');
    }
  }

  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }
}
