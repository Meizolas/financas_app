import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const mobileAuthRedirectUrl = 'financasapp://login-callback';

  static String get url => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  static String get appEnv => dotenv.env['APP_ENV']?.trim() ?? 'development';

  static String get authRedirectUrl {
    final configured = dotenv.env['SUPABASE_AUTH_REDIRECT_URL']?.trim() ?? '';
    if (configured.isNotEmpty) return configured;

    if (kIsWeb) {
      final base = Uri.base;
      if (base.hasScheme && base.host.isNotEmpty) {
        return Uri(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : null,
        ).toString();
      }
    }

    return mobileAuthRedirectUrl;
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
