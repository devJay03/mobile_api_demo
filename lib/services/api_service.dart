import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/notifiers.dart';
import '../views/pages/auth/login_page.dart';
import 'storage_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class ApiService {
  final http.Client _client;
  final StorageService _storageService;
  final GlobalKey<NavigatorState>? navigatorKey;

  ApiService({
    http.Client? client,
    StorageService? storageService,
    this.navigatorKey,
  })  : _client = client ?? http.Client(),
        _storageService = storageService ?? StorageService();

  Future<Map<String, String>> _buildHeaders([Map<String, String>? customHeaders]) async {
    final token = await _storageService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Future<http.Response> _checkResponse(http.Response response, {bool checkAuth = true}) async {
    if (checkAuth && response.statusCode == 401) {
      await handleUnauthorized();
    }
    return response;
  }

  Future<void> handleUnauthorized() async {
    await _storageService.deleteToken();
    isUserLoggedInNotifier.value = false;
    final navState = (navigatorKey ?? rootNavigatorKey).currentState;
    if (navState != null) {
      navState.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool checkAuth = true,
  }) async {
    final allHeaders = await _buildHeaders(headers);
    final response = await _client.get(url, headers: allHeaders);
    return await _checkResponse(response, checkAuth: checkAuth);
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool checkAuth = true,
  }) async {
    final allHeaders = await _buildHeaders(headers);
    final response = await _client.post(url, headers: allHeaders, body: body);
    return await _checkResponse(response, checkAuth: checkAuth);
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool checkAuth = true,
  }) async {
    final allHeaders = await _buildHeaders(headers);
    final response = await _client.put(url, headers: allHeaders, body: body);
    return await _checkResponse(response, checkAuth: checkAuth);
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool checkAuth = true,
  }) async {
    final allHeaders = await _buildHeaders(headers);
    final response = await _client.delete(url, headers: allHeaders, body: body);
    return await _checkResponse(response, checkAuth: checkAuth);
  }
}
