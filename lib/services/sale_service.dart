// lib/services/sale_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/sale.dart';


class SaleService {
  final storage = FlutterSecureStorage();

  // Get sales list with pagination and optional filters
  Future<Pagination<Sale>> getSales({
    int page = 1,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      // Build query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
      if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
      if (search != null) queryParams['search'] = search;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      // Log the request for debugging
      ApiConfig.logApiRequest('GET', ApiConfig.salesEndpoint, queryParams);
      
      final uri = Uri.parse(ApiConfig.getEndpointUrl(ApiConfig.salesEndpoint)).replace(
        queryParameters: queryParams,
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        ApiConfig.logApiResponse(ApiConfig.salesEndpoint, response.statusCode, 'Success');
        return Pagination<Sale>.fromJson(
          jsonData, 
          (item) => Sale.fromJson(item),
        );
      } else {
        ApiConfig.logApiResponse(
          ApiConfig.salesEndpoint, 
          response.statusCode, 
          response.body,
          isError: true,
        );
        throw Exception('Failed to load sales: ${response.body}');
      }
    } catch (e) {
      ApiConfig.logApiResponse(ApiConfig.salesEndpoint, 0, e.toString(), isError: true);
      throw Exception('Error getting sales: $e');
    }
  }

  // Get recent sales for the POS dashboard
  Future<List<Sale>> getRecentSales({int limit = 5}) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      // Log the request for debugging
      ApiConfig.logApiRequest('GET', ApiConfig.recentSalesEndpoint);
      
      final response = await http.get(
        Uri.parse('${ApiConfig.getEndpointUrl(ApiConfig.recentSalesEndpoint)}?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        ApiConfig.logApiResponse(ApiConfig.recentSalesEndpoint, response.statusCode, 'Success');
        return (jsonData['data'] as List)
            .map((item) => Sale.fromJson(item))
            .toList();
      } else {
        ApiConfig.logApiResponse(
          ApiConfig.recentSalesEndpoint, 
          response.statusCode, 
          response.body,
          isError: true,
        );
        throw Exception('Failed to load recent sales: ${response.body}');
      }
    } catch (e) {
      ApiConfig.logApiResponse(ApiConfig.recentSalesEndpoint, 0, e.toString(), isError: true);
      throw Exception('Error getting recent sales: $e');
    }
  }

  // Get single sale details
  Future<Sale> getSaleDetails(int saleId) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final endpoint = '${ApiConfig.salesEndpoint}/$saleId';
      
      // Log the request for debugging
      ApiConfig.logApiRequest('GET', endpoint);
      
      final response = await http.get(
        Uri.parse(ApiConfig.getEndpointUrl(endpoint)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );
      
      if (response.statusCode == 200) {
        ApiConfig.logApiResponse(endpoint, response.statusCode, 'Success');
        return Sale.fromJson(jsonDecode(response.body));
      } else {
        ApiConfig.logApiResponse(
          endpoint, 
          response.statusCode, 
          response.body,
          isError: true,
        );
        throw Exception('Failed to load sale details: ${response.body}');
      }
    } catch (e) {
      ApiConfig.logApiResponse(ApiConfig.salesEndpoint, 0, e.toString(), isError: true);
      throw Exception('Error getting sale details: $e');
    }
  }

  // Void a sale
  Future<bool> voidSale(int saleId, String reason) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final endpoint = '${ApiConfig.salesEndpoint}/$saleId/void';
      final body = {'reason': reason};
      
      // Log the request for debugging
      ApiConfig.logApiRequest('POST', endpoint, body);
      
      final response = await http.post(
        Uri.parse(ApiConfig.getEndpointUrl(endpoint)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        ApiConfig.logApiResponse(endpoint, response.statusCode, 'Success');
        return jsonResponse['success'] ?? false;
      } else {
        ApiConfig.logApiResponse(
          endpoint, 
          response.statusCode, 
          response.body,
          isError: true,
        );
        throw Exception('Failed to void sale: ${response.body}');
      }
    } catch (e) {
      ApiConfig.logApiResponse(ApiConfig.salesEndpoint, 0, e.toString(), isError: true);
      throw Exception('Error voiding sale: $e');
    }
  }

  // Helper function to implement retry logic
  Future<http.Response> _retryableRequest(Future<http.Response> Function() requestFunction) async {
    int retries = 0;
    
    while (retries < ApiConfig.maxRetries) {
      try {
        return await requestFunction();
      } catch (e) {
        retries++;
        if (retries >= ApiConfig.maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: ApiConfig.retryDelay * retries));
      }
    }
    
    throw Exception('Max retries exceeded');
  }
}