import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final dynamic category; // Could be a map or a Category object
  final String sku;
  final String? serialNumber; // Made nullable since it might not always be present
  final double price;
  final double costPrice;
  final int stock;
  final int minStock;
  final String? image;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.category,
    required this.sku,
    this.serialNumber, // Made optional
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    this.image,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // Get the complete image URL if image is not null
  String? get imageUrl {
    if (image == null || image!.isEmpty) {
      return null;
    }
    
    return ApiConfig.getImageUrl(image);
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle potential errors and missing fields
    try {
      // Process category and categoryId
      int? extractedCategoryId;
      dynamic extractedCategory;
      
      // Attempt to extract category_id, handling different possible formats
      if (json.containsKey('category_id')) {
        if (json['category_id'] != null) {
          extractedCategoryId = int.tryParse(json['category_id'].toString()) ?? 0;
        }
      }
      
      // Attempt to extract category
      if (json.containsKey('category')) {
        extractedCategory = json['category'];
        // If category is a map with 'id', use it as categoryId if not already set
        if (extractedCategory is Map && extractedCategoryId == null) {
          extractedCategoryId = int.tryParse(extractedCategory['id'].toString()) ?? 0;
        }
      }
      
      // Default to 0 if still null
      extractedCategoryId ??= 0;
      
      // Handle price values safely
      double extractedPrice = 0.0;
      double extractedCostPrice = 0.0;
      
      if (json.containsKey('price') && json['price'] != null) {
        extractedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
      }
      
      if (json.containsKey('cost_price') && json['cost_price'] != null) {
        extractedCostPrice = double.tryParse(json['cost_price'].toString()) ?? 0.0;
      }
      
      // Handle integer values safely
      int extractedStock = 0;
      int extractedMinStock = 0;
      
      if (json.containsKey('stock') && json['stock'] != null) {
        extractedStock = int.tryParse(json['stock'].toString()) ?? 0;
      }
      
      if (json.containsKey('min_stock') && json['min_stock'] != null) {
        extractedMinStock = int.tryParse(json['min_stock'].toString()) ?? 0;
      }
      
      // Create the Product object with all the safely extracted values
      return Product(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Unknown Product',
        description: json['description'],
        categoryId: extractedCategoryId,
        category: extractedCategory,
        sku: json['sku'] ?? '',
        serialNumber: json['serial_number'],
        price: extractedPrice,
        costPrice: extractedCostPrice,
        stock: extractedStock,
        minStock: extractedMinStock,
        image: json['image'],
        status: json['status'] ?? 'inactive',
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );
    } catch (e) {
      // Fallback in case of any errors
      debugPrint('Error parsing Product from JSON: $e');
      return Product(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Error Loading Product',
        description: null,
        categoryId: 0,
        sku: '',
        price: 0.0,
        costPrice: 0.0,
        stock: 0,
        minStock: 0,
        status: 'inactive',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'sku': sku,
      'serial_number': serialNumber,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'min_stock': minStock,
      'image': image,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create a copy of product with updated fields
  Product copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    dynamic category,
    String? sku,
    String? serialNumber,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? image,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      serialNumber: serialNumber ?? this.serialNumber,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      image: image ?? this.image,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get category name safely
  String getCategoryName() {
    if (category == null) {
      return 'Uncategorized';
    }
    
    if (category is Map) {
      return category['name'] ?? 'Uncategorized';
    }
    
    // Try to check if there is a name property accessible via dot notation
    try {
      final dynamic name = category.name;
      if (name != null && name is String) {
        return name;
      }
    } catch (_) {
      // Ignore any errors if the property doesn't exist
    }
    
    return 'Uncategorized';
  }
  
  // Helper methods for stock status
  bool isLowStock() {
    return stock <= minStock && stock > 0;
  }
  
  bool isOutOfStock() {
    return stock <= 0;
  }
  
  bool isInStock() {
    return stock > 0;
  }
}