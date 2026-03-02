import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Sistema de variables de entorno.
///
/// Prioridad de carga:
///   1. --dart-define (web production, siempre disponible si se buildea con ese flag)
///   2. .env en disco (solo móvil/desktop en desarrollo)
///
/// En web NUNCA se intenta cargar el .env desde assets (evita el 404 ruidoso
/// y el error "Unable to load asset" que confundía el diagnóstico).
class EnvConfig {
  const EnvConfig._();

  static Future<void> load() async {
    // En web las variables vienen siempre de --dart-define.
    // No tiene sentido intentar cargar .env desde assets en producción.
    if (kIsWeb) {
      debugPrint('[ENV] Web: usando --dart-define (no se carga .env en web)');
      return;
    }

    // Mobile / Desktop: carga el .env del disco.
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('[ENV] .env cargado OK');
    } catch (e) {
      debugPrint('[ENV] .env no encontrado en disco: $e');
    }
  }

  static String get supabaseUrl {
    // --dart-define tiene prioridad absoluta.
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    // Fallback: .env en disco (solo nativo).
    if (!kIsWeb) return dotenv.env['SUPABASE_URL'] ?? '';
    return '';
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    if (!kIsWeb) return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return '';
  }
}
