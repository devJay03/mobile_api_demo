import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.isInitialized
      ? (dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2/web-api/api')
      : 'http://10.0.2.2/web-api/api';

  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get logout => '$baseUrl/logout';
  static String get categories => '$baseUrl/categories';
  static String get products => '$baseUrl/products';
}
