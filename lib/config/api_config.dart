import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final configured = dotenv.isInitialized
        ? dotenv.env['API_BASE_URL']
        : null;
    return (configured == null || configured.trim().isEmpty
            ? 'http://10.0.2.2/sample/api' //Change the fallback to your actual project's URL
            : configured.trim())
        .replaceFirst(RegExp(r'/+$'), '');
  }
}
