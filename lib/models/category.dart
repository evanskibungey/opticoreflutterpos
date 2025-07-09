

class Category {
  final int id;
  final String name;
  final String? description;
  final String status;
  final int? productsCount;
  final String? createdAt;
  final String? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.productsCount,
    this.createdAt,
    this.updatedAt,
  });

  // Create a Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'] ?? 'active',
      productsCount: json['products_count'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'products_count': productsCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // For editing, we need a version that doesn't include readonly properties
  Map<String, dynamic> toEditJson() {
    return {
      'name': name,
      'description': description,
      'status': status,
    };
  }

  // Create a copy of the category with updated fields
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? status,
    int? productsCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Check if category is active
  bool isActive() {
    return status == 'active';
  }
  
  // Get display label (for UI presentation)
  String getDisplayLabel() {
    if (productsCount != null) {
      return '$name ($productsCount)';
    }
    return name;
  }
  
  // For debugging
  @override
  String toString() {
    return 'Category{id: $id, name: $name, status: $status, productsCount: $productsCount}';
  }
}