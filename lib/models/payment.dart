// models/payment.dart
class Payment {
  final int id;
  final int customerId;
  final int userId;
  final double amount;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;

  Payment({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    // Print the JSON to debug
    print('Payment JSON: $json');
    
    try {
      return Payment(
        id: json['id'] ?? 0,
        customerId: json['customer_id'] ?? 0,
        userId: json['user_id'] ?? 0,
        amount: _parseDoubleFromJson(json['amount']) ?? 0.0,
        paymentMethod: json['payment_method'] ?? 'unknown',
        referenceNumber: json['reference_number'],
        notes: json['notes'],
        createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
        updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
        userName: json['user_name'],
      );
    } catch (e) {
      print('Error parsing Payment from JSON: $e');
      print('JSON data: $json');
      
      // Return a default payment object to prevent app crashes
      return Payment(
        id: 0,
        customerId: 0,
        userId: 0,
        amount: 0.0,
        paymentMethod: 'error',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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