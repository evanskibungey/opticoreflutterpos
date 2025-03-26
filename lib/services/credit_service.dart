// services/credit_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_app/config/api_config.dart';
import 'package:pos_app/models/credit_sale.dart';
import 'package:pos_app/models/payment.dart';

import '../models/customer.dart';


import '../services/auth_service.dart';

class CreditService {
  final AuthService _authService = AuthService();

  // Get all customers with credit balances
  Future<Map<String, dynamic>> getCustomersWithCredit() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.getEndpointUrl(ApiConfig.creditsEndpoint)),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    ApiConfig.logApiResponse(
      ApiConfig.creditsEndpoint, 
      response.statusCode, 
      response.body,
      isError: response.statusCode != 200,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final List<Customer> customers = (data['data']['customers'] as List)
          .map((customer) => Customer.fromJson(customer))
          .toList();
          
      final double totalCredit = double.parse(data['data']['totalCredit'].toString());
      
      return {
        'customers': customers,
        'totalCredit': totalCredit,
      };
    } else {
      throw Exception('Failed to load customers with credit');
    }
  }

  // Get customer details with credit sales and payments
  Future<Map<String, dynamic>> getCustomerCreditDetails(int customerId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.getEndpointUrl('${ApiConfig.customerCreditsEndpoint}$customerId')),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    ApiConfig.logApiResponse(
      '${ApiConfig.customerCreditsEndpoint}$customerId', 
      response.statusCode, 
      response.body,
      isError: response.statusCode != 200,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final Customer customer = Customer.fromJson(data['data']['customer']);
      
      final List<CreditSale> creditSales = (data['data']['creditSales'] as List)
          .map((sale) => CreditSale.fromJson(sale))
          .toList();
      
      final List<Payment> payments = (data['data']['payments'] as List)
          .map((payment) => Payment.fromJson(payment))
          .toList();
      
      return {
        'customer': customer,
        'creditSales': creditSales,
        'payments': payments,
      };
    } else {
      throw Exception('Failed to load customer credit details');
    }
  }

  // Record a payment for a customer
  Future<Map<String, dynamic>> recordPayment(
    int customerId, 
    double amount,
    String paymentMethod,
    String? referenceNumber,
    String? notes,
  ) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.getEndpointUrl('${ApiConfig.customerCreditsEndpoint}$customerId/payment')),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'amount': amount,
        'payment_method': paymentMethod,
        'reference_number': referenceNumber,
        'notes': notes,
      }),
    );

    ApiConfig.logApiResponse(
      '${ApiConfig.customerCreditsEndpoint}$customerId/payment', 
      response.statusCode, 
      response.body,
      isError: response.statusCode != 200,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final Payment payment = Payment.fromJson(data['data']['payment']);
      final Customer customer = Customer.fromJson(data['data']['customer']);
      
      return {
        'payment': payment,
        'customer': customer,
      };
    } else {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to record payment');
    }
  }
}