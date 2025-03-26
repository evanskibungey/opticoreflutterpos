import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/category.dart';

class CategoryService {
  final storage = FlutterSecureStorage();

  // Get all categories with optional filter params
  Future<Map<String, dynamic>> getCategories({
    String? search,
    String? status,
    String sort = 'name',
    int page = 1,
  }) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      // Build query parameters
      final queryParams = {
        'page': page.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      if (sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories').replace(
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
        
        // Parse categories
        final List<Category> categories = (data['data'] as List)
            .map((categoryJson) => Category.fromJson(categoryJson))
            .toList();
            
        // Return both categories and pagination info
        return {
          'categories': categories,
          'current_page': data['current_page'] ?? 1,
          'last_page': data['last_page'] ?? 1,
          'total': data['total'] ?? categories.length,
        };
      } else {
        throw Exception('Failed to load categories: ${response.body}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  // Get a single category by ID
  Future<Category> getCategory(int id) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/categories/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data);
      } else {
        throw Exception('Failed to load category: ${response.body}');
      }
    } catch (e) {
      print('Error fetching category: $e');
      rethrow;
    }
  }

  // Create a new category
  Future<Category> createCategory(String name, String? description, String status) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'status': status,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data);
      } else {
        // Parse error message if available
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to create category';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  // Update an existing category
  Future<Category> updateCategory(int id, String name, String? description, String status) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/categories/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'status': status,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data);
      } else {
        // Parse error message if available
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to update category';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(int id) async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/categories/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        // Check for specific error about products being associated
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to delete category';
        
        // Throw a specific error if products exist
        if (errorMessage.contains('associated products')) {
          throw Exception('Cannot delete category with associated products');
        } else {
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}