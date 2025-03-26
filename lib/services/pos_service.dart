import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class PosService {
  final storage = FlutterSecureStorage();

  // Process a sale
  Future<Map<String, dynamic>> processSale({
    required List<Map<String, dynamic>> cartItems,
    required String paymentMethod,
    Map<String, String>? customerDetails,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/sales'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'cart_items': cartItems,
          'payment_method': paymentMethod,
          'customer_details': customerDetails,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'receipt_number': data['receipt_number'],
            'receipt_data': data['receipt_data'],
            'sale_id': data['sale_id'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to process sale');
        }
      } else {
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Error: ${response.statusCode}');
        } catch (e) {
          throw Exception('Failed to process sale: Status ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error processing sale: $e');
      rethrow;
    }
  }

  // Get recent sales
  Future<List<Map<String, dynamic>>> getRecentSales({int limit = 10}) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final queryParams = {
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/sales').replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load recent sales: ${response.body}');
      }
    } catch (e) {
      print('Error fetching recent sales: $e');
      rethrow;
    }
  }

  // Get sale details
  Future<Map<String, dynamic>> getSaleDetails(int saleId) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/sales/$saleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load sale details: ${response.body}');
      }
    } catch (e) {
      print('Error fetching sale details: $e');
      rethrow;
    }
  }

  // Void a sale
  Future<bool> voidSale(int saleId, String reason) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/sales/$saleId/void'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to void sale: ${response.body}');
      }
    } catch (e) {
      print('Error voiding sale: $e');
      rethrow;
    }
  }

  // Check stock availability for a product
  Future<Map<String, dynamic>> checkStock(int productId, int quantity) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/stock/check'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'available': data['available'] ?? false,
          'current_stock': data['current_stock'] ?? 0,
        };
      } else {
        throw Exception('Failed to check stock: ${response.body}');
      }
    } catch (e) {
      print('Error checking stock: $e');
      rethrow;
    }
  }
}