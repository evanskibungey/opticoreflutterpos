import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  final storage = FlutterSecureStorage();

  Future<AdminDashboardData> getAdminDashboardData() async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminDashboardEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        // Log the response to debug
        print('Admin Dashboard API Response: ${response.body}');
        
        final data = jsonDecode(response.body);
        
        // Debug each key in the data
        data.forEach((key, value) {
          if (value is Map || value is List) {
            print('Key: $key, Type: ${value.runtimeType}');
          } else {
            print('Key: $key, Type: ${value.runtimeType}, Value: $value');
          }
        });
        
        return AdminDashboardData.fromJson(data);
      } else {
        throw Exception('Failed to load admin dashboard data: ${response.body}');
      }
    } catch (e) {
      print('Error getting admin dashboard data: $e');
      rethrow;
    }
  }

  Future<CashierDashboardData> getCashierDashboardData() async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cashierDashboardEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        // Log the response for debugging
        print('Cashier Dashboard API Response: ${response.body}');
        
        final data = jsonDecode(response.body);
        return CashierDashboardData.fromJson(data);
      } else {
        throw Exception('Failed to load cashier dashboard data: ${response.body}');
      }
    } catch (e) {
      print('Error getting cashier dashboard data: $e');
      rethrow;
    }
  }
}