import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  const AppEnvironment._();

  static bool _isInitialized = false;

  static Future<void> load() async {
    if (_isInitialized) {
      return;
    }
    await dotenv.load(fileName: '.env', isOptional: true);
    _isInitialized = true;
  }

  static String get supabaseUrl => _readValue(
        dotenvKey: 'SUPABASE_URL',
        dartDefine: const String.fromEnvironment('SUPABASE_URL'),
        label: 'SUPABASE_URL',
      );

  static String get supabaseAnonKey => _readValue(
        dotenvKey: 'SUPABASE_ANON_KEY',
        dartDefine: const String.fromEnvironment('SUPABASE_ANON_KEY'),
        label: 'SUPABASE_ANON_KEY',
      );

  static String? get googleWebClientId => _readOptionalValue(
        dotenvKey: 'GOOGLE_WEB_CLIENT_ID',
        dartDefine: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      );

  static String _readValue({
    required String dotenvKey,
    required String dartDefine,
    required String label,
  }) {
    final envValue = dotenv.maybeGet(dotenvKey);
    final value = (envValue?.trim().isNotEmpty ?? false)
        ? envValue!.trim()
        : dartDefine.trim();
    if (value.isEmpty ||
        value.contains('your-project-id') ||
        value.contains('your-public-anon-key')) {
      throw StateError(
        '$label belum diatur. Isi file .env dari .env.example atau kirim lewat --dart-define.',
      );
    }
    return value;
  }

  static String? _readOptionalValue({
    required String dotenvKey,
    required String dartDefine,
  }) {
    final envValue = dotenv.maybeGet(dotenvKey);
    final value = (envValue?.trim().isNotEmpty ?? false)
        ? envValue!.trim()
        : dartDefine.trim();
    return value.isEmpty ? null : value;
  }
}
