//Do not Modify

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final http.Client _client;
  final String? _baseUrl;
  ApiService({http.Client? client, this._baseUrl})
    : _client = client ?? http.Client();

  void close() => _client.close();

  Future<Map<String, dynamic>> request(
    String path, {
    Map<String, String>? form,
  }) async {
    final uri = Uri.parse(
      '${(_baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/+$'), '')}/$path',
    );
    try {
      final response =
          await (form == null
                  ? _client.get(
                      uri,
                      headers: {
                        'Accept': 'application/json',
                      },
                    )
                  : _client.post(
                      uri,
                      headers: {
                        'Accept': 'application/json',
                      },
                      body: form,
                    ))
              .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Server returned HTTP ${response.statusCode}. Check the API URL and server.',
        );
      }
      final dynamic body;
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        throw Exception(
          'Server returned invalid JSON. Check PHP and database availability.',
        );
      }
      if (body is! Map<String, dynamic>) {
        throw Exception('Expected a JSON object from PHP.');
      }
      if (body.containsKey('status') &&
          body['status'] != 'success') {
        throw Exception(
          body['message'] is String
              ? body['message'] as String
              : 'The server rejected the request.',
        );
      }
      return body;
    } on TimeoutException {
      throw Exception(
        'Request timed out. A write may have completed; refresh before retrying.',
      );
    } on http.ClientException {
      throw Exception(
        'Cannot reach the API. Check the configured address and network; refresh before retrying a write.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> list(
    String resource,
  ) async {
    final body = await request('$resource/all');
    final data = body['data'];
    if (data is! List ||
        data.any((row) => row is! Map<String, dynamic>)) {
      throw Exception(
        'Expected a data array of records from PHP.',
      );
    }
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> mutate(
    String path, {
    Map<String, String>? form,
  }) async {
    final body = await request(path, form: form);
    if (body['status'] != 'success' ||
        body['message'] is! String) {
      throw Exception(
        'The server did not confirm the operation. Refresh before retrying.',
      );
    }
  }
}
