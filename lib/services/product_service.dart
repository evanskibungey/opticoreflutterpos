import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductService {
  final storage = FlutterSecureStorage();

  // Get all products with optional filter params

  Future<Map<String, dynamic>> getProducts({
    String? search,
    int? categoryId,
    String? status,
    String? stockStatus, // 'all', 'in_stock', 'low_stock', 'out_of_stock'
    String sort = 'created_at', // Default to created_at instead of name
    String sortDirection =
        'asc', // Add sort direction parameter (asc = oldest first)
    int page = 1,
  }) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Build query parameters
      final queryParams = {'page': page.toString()};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (stockStatus != null && stockStatus.isNotEmpty) {
        queryParams['stock_status'] = stockStatus;
      }

      if (sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      // Add sort direction to the query parameters
      queryParams['sort_direction'] = sortDirection;

      final uri = Uri.parse(
        ApiConfig.baseUrl + ApiConfig.productsEndpoint,
      ).replace(queryParameters: queryParams);

      // Log the request for debugging
      ApiConfig.logApiRequest('GET', ApiConfig.productsEndpoint, queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        ApiConfig.productsEndpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse products with image URL handling
        final List<Product> products = [];

        for (var productJson in (data['data'] as List)) {
          products.add(Product.fromJson(productJson));
        }

        // Return both products and pagination info
        return {
          'products': products,
          'current_page': data['current_page'] ?? 1,
          'last_page': data['last_page'] ?? 1,
          'total': data['total'] ?? products.length,
        };
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          ApiConfig.productsEndpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      rethrow;
    }
  }

  // Get categories for product filtering
  Future<Map<String, dynamic>> getCategories({
    String? status,
    bool includeProductCount = false,
  }) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      if (includeProductCount) {
        queryParams['include_count'] = 'true';
      }

      final uri = Uri.parse(
        ApiConfig.baseUrl + ApiConfig.categoriesEndpoint,
      ).replace(queryParameters: queryParams);

      // Log the request for debugging
      ApiConfig.logApiRequest('GET', ApiConfig.categoriesEndpoint, queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        ApiConfig.categoriesEndpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract categories based on response structure
        final List<Category> categories = [];

        if (data is Map && data.containsKey('data')) {
          // API returns paginated response
          for (var categoryJson in (data['data'] as List)) {
            categories.add(Category.fromJson(categoryJson));
          }

          // Return with pagination info
          return {
            'categories': categories,
            'current_page': data['current_page'] ?? 1,
            'last_page': data['last_page'] ?? 1,
            'total': data['total'] ?? categories.length,
          };
        } else if (data is List) {
          // API returns direct list
          for (var categoryJson in data) {
            categories.add(Category.fromJson(categoryJson));
          }

          return {'categories': categories, 'total': categories.length};
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          ApiConfig.categoriesEndpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  // Get a single product by ID
  Future<Product> getProduct(int id) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final endpoint = '${ApiConfig.productsEndpoint}/$id';

      // Log the request for debugging
      ApiConfig.logApiRequest('GET', endpoint, null);

      final response = await http
          .get(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        endpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final product = Product.fromJson(data);

        // Debug image URL if enabled
        if (ApiConfig.enableDebugLogs && product.image != null) {
          debugPrint(
            '🖼️ Product detail: ${product.name}, Image: ${product.image}, URL: ${product.imageUrl}',
          );
        }

        return product;
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        throw Exception(
          'Failed to load product details: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error fetching product: $e');
      rethrow;
    }
  }

  // Create a new product
  Future<Product> createProduct(
    Map<String, dynamic> productData,
    File? imageFile,
  ) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // If there's an image, use multipart request
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConfig.baseUrl + ApiConfig.productsEndpoint),
        );

        // Add authorization header
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        // Add text fields
        productData.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add image file
        var pic = await http.MultipartFile.fromPath('image', imageFile.path);
        request.files.add(pic);

        // Log the request for debugging
        ApiConfig.logApiRequest(
          'POST (multipart)',
          ApiConfig.productsEndpoint,
          productData,
        );

        // Send request
        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        // Log response for debugging
        ApiConfig.logApiResponse(
          ApiConfig.productsEndpoint,
          response.statusCode,
          'Multipart response received',
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(responseData);
          return Product.fromJson(data);
        } else {
          // Log the error response
          ApiConfig.logApiResponse(
            ApiConfig.productsEndpoint,
            response.statusCode,
            responseData,
            isError: true,
          );

          // Parse error message if available
          final errorData = jsonDecode(responseData);
          final errorMessage =
              errorData['message'] ?? 'Failed to create product';
          throw Exception(errorMessage);
        }
      } else {
        // Regular JSON request if no image

        // Log the request for debugging
        ApiConfig.logApiRequest(
          'POST',
          ApiConfig.productsEndpoint,
          productData,
        );

        final response = await http
            .post(
              Uri.parse(ApiConfig.baseUrl + ApiConfig.productsEndpoint),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(productData),
            )
            .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

        // Log response for debugging
        ApiConfig.logApiResponse(
          ApiConfig.productsEndpoint,
          response.statusCode,
          'Response received',
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return Product.fromJson(data);
        } else {
          // Log the error response
          ApiConfig.logApiResponse(
            ApiConfig.productsEndpoint,
            response.statusCode,
            response.body,
            isError: true,
          );

          // Parse error message if available
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['message'] ?? 'Failed to create product';
          throw Exception(errorMessage);
        }
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error creating product: $e');
      rethrow;
    }
  }

  // Update an existing product
  Future<Product> updateProduct(
    int id,
    Map<String, dynamic> productData,
    File? imageFile,
  ) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final endpoint = '${ApiConfig.productsEndpoint}/$id';

      // If there's an image, use multipart request
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST', // Use POST for multipart
          Uri.parse(ApiConfig.baseUrl + endpoint),
        );

        // Add method override for PUT
        request.fields['_method'] = 'PUT';

        // Add authorization header
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        // Add text fields
        productData.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        // Add image file
        var pic = await http.MultipartFile.fromPath('image', imageFile.path);
        request.files.add(pic);

        // Log the request for debugging
        ApiConfig.logApiRequest('PUT (multipart)', endpoint, productData);

        // Send request
        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        // Log response for debugging
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          'Multipart response received',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(responseData);
          return Product.fromJson(data);
        } else {
          // Log the error response
          ApiConfig.logApiResponse(
            endpoint,
            response.statusCode,
            responseData,
            isError: true,
          );

          // Parse error message if available
          final errorData = jsonDecode(responseData);
          final errorMessage =
              errorData['message'] ?? 'Failed to update product';
          throw Exception(errorMessage);
        }
      } else {
        // Regular JSON request if no image

        // Log the request for debugging
        ApiConfig.logApiRequest('PUT', endpoint, productData);

        final response = await http
            .put(
              Uri.parse(ApiConfig.baseUrl + endpoint),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(productData),
            )
            .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

        // Log response for debugging
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          'Response received',
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Product.fromJson(data);
        } else {
          // Log the error response
          ApiConfig.logApiResponse(
            endpoint,
            response.statusCode,
            response.body,
            isError: true,
          );

          // Parse error message if available
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['message'] ?? 'Failed to update product';
          throw Exception(errorMessage);
        }
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(int id) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final endpoint = '${ApiConfig.productsEndpoint}/$id';

      // Log the request for debugging
      ApiConfig.logApiRequest('DELETE', endpoint, null);

      final response = await http
          .delete(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        endpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          response.body,
          isError: true,
        );

        // Check for specific error about sales records
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to delete product';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  // Update product stock
 // In ProductService
Future<Product> updateStock(int id, int newStock, String? notes) async {
  try {
    final token = await storage.read(key: ApiConfig.authTokenKey);

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final endpoint = '${ApiConfig.productsEndpoint}/$id/update-stock';
    final requestData = {'new_stock': newStock, 'notes': notes};

    // Log the request for debugging
    ApiConfig.logApiRequest('POST', endpoint, requestData);

    final response = await http
        .post(
          Uri.parse(ApiConfig.baseUrl + endpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestData),
        )
        .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

    // Log response for debugging
    ApiConfig.logApiResponse(
      endpoint,
      response.statusCode,
      'Response received',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Debug log to verify the structure of the response
      if (ApiConfig.enableDebugLogs) {
        debugPrint('📊 Stock update response: ${response.body}');
      }
      
      // Make sure we're accessing the right property
      final productData = data['product'] ?? data;
      
      // Return the updated product
      return Product.fromJson(productData);
    } else {
      // Log the error response
      ApiConfig.logApiResponse(
        endpoint,
        response.statusCode,
        response.body,
        isError: true,
      );

      // Parse error message if available
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Failed to update stock';
      throw Exception(errorMessage);
    }
  } catch (e) {
    debugPrint('Error updating stock: $e');
    rethrow;
  }
}

  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Log the request for debugging
      ApiConfig.logApiRequest('GET', ApiConfig.lowStockEndpoint, null);

      final response = await http
          .get(
            Uri.parse(ApiConfig.baseUrl + ApiConfig.lowStockEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        ApiConfig.lowStockEndpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Handle case where data field is missing or null
        if (!jsonData.containsKey('data') || jsonData['data'] == null) {
          return []; // Return empty list instead of throwing an error
        }

        // Safely cast to list with null check
        final List<dynamic> productsJson = jsonData['data'] as List<dynamic>;

        // Parse each product
        final List<Product> products = [];
        for (var productJson in productsJson) {
          products.add(Product.fromJson(productJson));
        }

        return products;
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          ApiConfig.lowStockEndpoint,
          response.statusCode,
          response.body,
          isError: true,
        );

        // Add informative error
        throw Exception(
          'Failed to load low stock products: Status ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error fetching low stock products: $e');
      // If it's a parse error, return empty list instead of throwing
      if (e.toString().contains('type \'Null\' is not a subtype of type')) {
        debugPrint('Returning empty list due to parse error');
        return [];
      }
      rethrow;
    }
  }

  // Get stock movements for a product
  Future<Map<String, dynamic>> getStockMovements(int productId) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final endpoint =
          '${ApiConfig.inventoryEndpoint}/products/$productId/movements';

      // Log the request for debugging
      ApiConfig.logApiRequest('GET', endpoint, null);

      final response = await http
          .get(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        endpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Safely extract data with fallbacks
        return {
          'product': jsonData['product'] ?? {},
          'data': jsonData['data'] ?? [],
        };
      } else if (response.statusCode == 404) {
        // Handle not found gracefully
        return {'product': {}, 'data': []};
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          response.body,
          isError: true,
        );

        throw Exception(
          'Failed to load stock movements: Status ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error fetching stock movements: $e');
      // Return empty data instead of failing
      return {'product': {}, 'data': []};
    }
  }

  // Validate single product price
  Future<Map<String, dynamic>> validatePrice(int productId, double price) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final endpoint = '${ApiConfig.productsEndpoint}/validate-price';
      final requestData = {
        'product_id': productId,
        'price': price,
      };

      // Log the request for debugging
      ApiConfig.logApiRequest('POST', endpoint, requestData);

      final response = await http
          .post(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        endpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'valid': data['valid'] ?? false,
          'min_price': data['min_price'] ?? 0.0,
          'max_price': data['max_price'] ?? double.infinity,
          'default_price': data['default_price'] ?? 0.0,
          'message': data['message'] ?? '',
        };
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          response.body,
          isError: true,
        );

        // Parse error message if available
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to validate price';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error validating price: $e');
      rethrow;
    }
  }

  // Validate multiple product prices
  Future<Map<String, dynamic>> validatePrices(List<Map<String, dynamic>> items) async {
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final endpoint = '${ApiConfig.productsEndpoint}/validate-prices';
      final requestData = {'items': items};

      // Log the request for debugging
      ApiConfig.logApiRequest('POST', endpoint, requestData);

      final response = await http
          .post(
            Uri.parse(ApiConfig.baseUrl + endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      // Log response for debugging
      ApiConfig.logApiResponse(
        endpoint,
        response.statusCode,
        'Response received',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'all_valid': data['all_valid'] ?? false,
          'results': data['results'] ?? [],
        };
      } else {
        // Log the error response
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          response.body,
          isError: true,
        );

        // Parse error message if available
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to validate prices';
        throw Exception(errorMessage);
      }
    } on SocketException {
      throw Exception('Network error - please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timed out - please try again');
    } catch (e) {
      debugPrint('Error validating prices: $e');
      rethrow;
    }
  }
}
