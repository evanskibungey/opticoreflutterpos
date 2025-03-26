// models/customer.dart
import 'dart:math';
class Customer {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Print the JSON to debug
    print('Customer JSON: $json');
    
    try {
      return Customer(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'],
        address: json['address'],
        balance: _parseDoubleFromJson(json['balance']) ?? 0.0,
        createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
        updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Customer from JSON: $e');
      print('JSON data: $json');
      
      // Return a default customer object to prevent app crashes
      return Customer(
        id: 0,
        name: 'Error: ${e.toString().substring(0, min(30, e.toString().length))}...',
        phone: '',
        balance: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
}

// Helper function to safely parse doubles from JSON
double? _parseDoubleFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}
