// models/credit_sale.dart
class CreditSale {
  final int id;
  final String referenceNo;
  final int customerId;
  final double totalAmount;
  final double discount;
  final double tax;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItem> items;

  CreditSale({
    required this.id,
    required this.referenceNo,
    required this.customerId,
    required this.totalAmount,
    required this.discount,
    required this.tax,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory CreditSale.fromJson(Map<String, dynamic> json) {
    // Print the JSON to debug
    print('CreditSale JSON: $json');
    
    try {
      List<SaleItem> saleItems = [];
      if (json['items'] != null) {
        saleItems = List<SaleItem>.from(
          (json['items'] as List).map((item) => SaleItem.fromJson(item))
        );
      }
      
      return CreditSale(
        id: json['id'] ?? 0,
        referenceNo: json['reference_no'] ?? '',
        customerId: json['customer_id'] ?? 0,
        totalAmount: _parseDoubleFromJson(json['total_amount']) ?? 0.0,
        discount: _parseDoubleFromJson(json['discount']) ?? 0.0,
        tax: _parseDoubleFromJson(json['tax']) ?? 0.0,
        finalAmount: _parseDoubleFromJson(json['final_amount']) ?? 0.0,
        paymentMethod: json['payment_method'] ?? 'unknown',
        paymentStatus: json['payment_status'] ?? 'unknown',
        status: json['status'] ?? 'unknown',
        createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
        updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
        items: saleItems,
      );
    } catch (e) {
      print('Error parsing CreditSale from JSON: $e');
      print('JSON data: $json');
      
      // Return a default credit sale object to prevent app crashes
      return CreditSale(
        id: 0,
        referenceNo: 'ERROR',
        customerId: 0,
        totalAmount: 0.0,
        discount: 0.0,
        tax: 0.0,
        finalAmount: 0.0,
        paymentMethod: 'error',
        paymentStatus: 'error',
        status: 'error',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [],
      );
    }
  }
}

// SaleItem model
class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final Map<String, dynamic>? product;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.product,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    try {
      return SaleItem(
        id: json['id'] ?? 0,
        saleId: json['sale_id'] ?? 0,
        productId: json['product_id'] ?? 0,
        quantity: json['quantity'] ?? 0,
        unitPrice: _parseDoubleFromJson(json['unit_price']) ?? 0.0,
        subtotal: _parseDoubleFromJson(json['subtotal']) ?? 0.0,
        product: json['product'],
      );
    } catch (e) {
      print('Error parsing SaleItem from JSON: $e');
      print('JSON data: $json');
      
      // Return a default sale item object to prevent app crashes
      return SaleItem(
        id: 0,
        saleId: 0,
        productId: 0,
        quantity: 0,
        unitPrice: 0.0,
        subtotal: 0.0,
      );
    }
  }
}

// Helper function to safely parse doubles from JSON (if not already defined)
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
  