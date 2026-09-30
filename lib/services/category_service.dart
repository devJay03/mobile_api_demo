import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class CategoryService {
  final ApiService _apiService;

  CategoryService({StorageService? storageService, ApiService? apiService})
      : _apiService = apiService ??
            ApiService(
              storageService: storageService ?? StorageService(),
            );

  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiService.get(Uri.parse(ApiConfig.categories));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        list = decoded['data'] as List<dynamic>;
      } else if (decoded is Map && decoded['categories'] is List) {
        list = decoded['categories'] as List<dynamic>;
      } else {
        list = [];
      }
      return list
          .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else {
      throw Exception(_getErrorMessage(response, 'Failed to fetch categories'));
    }
  }

  Future<void> createCategory(String name, String? description) async {
    final response = await _apiService.post(
      Uri.parse(ApiConfig.categories),
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response, 'Failed to create category'));
    }
  }

  Future<void> updateCategory(int id, String name, String? description) async {
    final response = await _apiService.put(
      Uri.parse('${ApiConfig.categories}/$id'),
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_getErrorMessage(response, 'Failed to update category'));
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await _apiService.delete(
      Uri.parse('${ApiConfig.categories}/$id'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_getErrorMessage(response, 'Failed to delete category'));
    }
  }

  String _getErrorMessage(http.Response response, String defaultMessage) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
      }
    } catch (_) {}
    return '$defaultMessage (${response.statusCode})';
  }
}
