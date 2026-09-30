import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService({StorageService? storageService, ApiService? apiService})
      : _apiService = apiService ??
            ApiService(
              storageService: storageService ?? StorageService(),
            );

  Future<List<ProductModel>> getProducts() async {
    final response = await _apiService.get(Uri.parse(ApiConfig.products));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        list = decoded['data'] as List<dynamic>;
      } else if (decoded is Map && decoded['products'] is List) {
        list = decoded['products'] as List<dynamic>;
      } else {
        list = [];
      }
      return list
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else {
      throw Exception(_getErrorMessage(response, 'Failed to fetch products'));
    }
  }

  Future<void> createProduct(Map<String, dynamic> productData) async {
    final response = await _apiService.post(
      Uri.parse(ApiConfig.products),
      body: jsonEncode(productData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_getErrorMessage(response, 'Failed to create product'));
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> productData) async {
    final response = await _apiService.put(
      Uri.parse('${ApiConfig.products}/$id'),
      body: jsonEncode(productData),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_getErrorMessage(response, 'Failed to update product'));
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await _apiService.delete(
      Uri.parse('${ApiConfig.products}/$id'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_getErrorMessage(response, 'Failed to delete product'));
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
