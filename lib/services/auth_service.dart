import 'dart:convert';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService;
  final ApiService _apiService;

  AuthService({StorageService? storageService, ApiService? apiService})
      : _storageService = storageService ?? StorageService(),
        _apiService = apiService ??
            ApiService(
              storageService: storageService ?? StorageService(),
            );

  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.post(
      Uri.parse(ApiConfig.login),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
      checkAuth: false,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] ??
          data['access_token'] ??
          (data['data'] is Map
              ? data['data']['token'] ?? data['data']['access_token']
              : null);

      if (token != null) {
        await _storageService.saveToken(token.toString());
      }

      final dynamic userJson = data['user'] ??
          (data['data'] is Map ? data['data']['user'] : null) ??
          data;

      if (userJson is Map<String, dynamic>) {
        return UserModel.fromJson(userJson);
      } else if (userJson is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(userJson));
      }
      throw Exception('Invalid user data received from server');
    } else {
      String errorMessage = 'Login failed';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          errorMessage = errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              errorMessage;
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<UserModel> register(
    String name,
    String email,
    String password, {
    String? passwordConfirmation,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
    if (passwordConfirmation != null) {
      payload['password_confirmation'] = passwordConfirmation;
    }

    final response = await _apiService.post(
      Uri.parse(ApiConfig.register),
      body: jsonEncode(payload),
      checkAuth: false,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] ??
          data['access_token'] ??
          (data['data'] is Map
              ? data['data']['token'] ?? data['data']['access_token']
              : null);

      if (token != null) {
        await _storageService.saveToken(token.toString());
      }

      final dynamic userJson = data['user'] ??
          (data['data'] is Map ? data['data']['user'] : null) ??
          data;

      if (userJson is Map<String, dynamic>) {
        return UserModel.fromJson(userJson);
      } else if (userJson is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(userJson));
      }
      return UserModel(id: 0, name: name, email: email);
    } else {
      String errorMessage = 'Registration failed';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          errorMessage = errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              errorMessage;
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        await _apiService
            .post(
              Uri.parse(ApiConfig.logout),
            )
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {
      // Ignore network errors on logout so local token is always cleared
    } finally {
      await _storageService.deleteToken();
    }
  }
}
