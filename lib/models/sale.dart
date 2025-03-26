// lib/models/sale.dart
import 'dart:convert';

import 'package:pos_app/models/product.dart';
import 'package:pos_app/models/user.dart';

class Sale {
  final int id;
  final int userId;
  final int? customerId; // Make nullable since guest customers might have null ID
  final String receiptNumber;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final Customer? customer;
  final User? user;
  final List<SaleItem>? items;

  Sale({
    required this.id,
    required this.userId,
    this.customerId,
    required this.receiptNumber,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.user,
    this.items,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      customerId: json['customer_id'], // Allow null
      receiptNumber: json['receipt_number'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      items: json['items'] != null
          ? List<SaleItem>.from(json['items'].map((item) => SaleItem.fromJson(item)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'receipt_number': receiptNumber,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'customer': customer?.toJson(),
      'user': user?.toJson(),
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }
}

// lib/models/sale_item.dart
class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? serialNumber;
  final String createdAt;
  final String updatedAt;
  final Product? product;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.serialNumber,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] ?? 0,
      saleId: json['sale_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      serialNumber: json['serial_number'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'serial_number': serialNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'product': product?.toJson(),
    };
  }
}

// lib/models/customer.dart
class Customer {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String status;
  final double? balance;
  final String createdAt;
  final String updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.status,
    this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      status: json['status'],
      balance: json['balance'] != null ? double.parse(json['balance'].toString()) : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'status': status,
      'balance': balance,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

// lib/models/pagination.dart
class Pagination<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return Pagination<T>(
      data: (json['data'] as List).map((item) => fromJson(item)).toList(),
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }
}