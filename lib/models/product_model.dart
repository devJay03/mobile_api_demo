class ProductModel {
  final int id;
  final String name;
  final int categoryId;
  final String? categoryName;
  final double price;
  final int quantity;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.price,
    required this.quantity,
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['category_name'] != null) {
      catName = json['category_name'].toString();
    } else if (json['categoryName'] != null) {
      catName = json['categoryName'].toString();
    } else if (json['category'] is Map && json['category']['name'] != null) {
      catName = json['category']['name'].toString();
    }

    return ProductModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      categoryId: _parseInt(json['category_id'] ?? json['categoryId']),
      categoryName: catName,
      price: _parseDouble(json['price']),
      quantity: _parseInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'category_name': categoryName,
      'price': price,
      'quantity': quantity,
    };
  }
}
