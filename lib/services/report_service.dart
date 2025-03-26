// lib/services/report_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/api_config.dart';
import '../models/report_models.dart';
import '../models/sale.dart';
import '../models/product.dart';

class ReportService {
  final storage = const FlutterSecureStorage();
  final _cache = ReportCache();
  final Map<String, ApiRequest> _activeRequests = {};

  // Lightweight class for API requests that can be cancelled
  void cancelAllRequests() {
    _activeRequests.forEach((key, request) {
      request.cancel();
    });
    _activeRequests.clear();
  }

  // Get sales report with pagination and performance optimizations
  Future<Map<String, dynamic>> getSalesReport(
    SalesReportFilter filter, {
    bool useCache = true,
    String? requestId,
  }) async {
    // Generate cache key based on filter parameters
    final cacheKey = 'sales_report_${jsonEncode(filter.toQueryParams())}';

    // Check cache first if enabled
    if (useCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        debugPrint('Using cached sales report data');
        return cached as Map<String, dynamic>; // Direct access, no .data property
      }
    }

    // Create a request ID for tracking/cancellation
    final reqId = requestId ?? 'sales_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create a new API request that can be cancelled
      final apiRequest = ApiRequest();
      _activeRequests[reqId] = apiRequest;

      // Build query parameters including pagination
      final queryParams = filter.toQueryParams();

      // Log the request for debugging
      ApiConfig.logApiRequest(
        'GET',
        ApiConfig.salesReportEndpoint,
        queryParams.cast<String, dynamic>(),
      );

      final uri = Uri.parse(
        ApiConfig.getEndpointUrl(ApiConfig.salesReportEndpoint),
      ).replace(queryParameters: queryParams);

      // Use isolate for large data processing if the computation may be heavy
      final response = await apiRequest.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse large JSON data in a separate isolate to avoid UI freezing
        final jsonData = await compute(_parseJsonResponse, response.body);
        ApiConfig.logApiResponse(
          ApiConfig.salesReportEndpoint,
          response.statusCode,
          'Success',
        );

        // Process data on a background isolate
        final processedData = await _processSalesReportData(jsonData, filter);

        // Cache the processed result
        if (useCache) {
          _cache.set(cacheKey, processedData);
        }

        // Remove from active requests
        _activeRequests.remove(reqId);

        return processedData;
      } else {
        ApiConfig.logApiResponse(
          ApiConfig.salesReportEndpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        _activeRequests.remove(reqId);
        throw Exception('Failed to load sales report: ${response.body}');
      }
    } catch (e) {
      _activeRequests.remove(reqId);
      ApiConfig.logApiResponse(
        ApiConfig.salesReportEndpoint,
        0,
        e.toString(),
        isError: true,
      );
      throw Exception('Error getting sales report: $e');
    }
  }

  // Helper function to process sales report data in a separate isolate
  Future<Map<String, dynamic>> _processSalesReportData(
    Map<String, dynamic> jsonData,
    SalesReportFilter filter,
  ) async {
    // Use compute to run in a separate isolate
    return await compute(_processSalesData, jsonData);
  }

  // Static method for processing in isolate
  static Map<String, dynamic> _processSalesData(Map<String, dynamic> jsonData) {
    // Parse sales data with error handling
    List<Sale> sales = [];
    try {
      final salesData = jsonData['sales'] as List? ?? [];

      // Process sales in smaller batches to avoid memory issues
      for (int i = 0; i < salesData.length; i += 50) {
        final end = (i + 50 < salesData.length) ? i + 50 : salesData.length;
        final batch = salesData.sublist(i, end);

        final batchSales = batch.map((item) => Sale.fromJson(item)).toList();
        sales.addAll(batchSales);
      }
    } catch (e) {
      debugPrint('Error parsing sales: $e');
    }

    // Parse summary data with error handling
    SalesReportSummary summary;
    try {
      summary = SalesReportSummary.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing summary: $e');
      // Provide a default summary if parsing fails
      summary = SalesReportSummary(
        totalSales: 0,
        totalRevenue: 0,
        totalItems: 0,
        topProducts: [],
        topCategories: [],
      );
    }

    return {
      'sales': sales,
      'summary': summary,
      'startDate': jsonData['start_date'],
      'endDate': jsonData['end_date'],
      'dateRange': jsonData['date_range'],
      'cashiers': (jsonData['cashiers'] as List? ?? []),
      'page': jsonData['page'] ?? 1,
      'lastPage': jsonData['last_page'] ?? 1,
      'hasMorePages': (jsonData['page'] ?? 1) < (jsonData['last_page'] ?? 1),
    };
  }

  // Static method to parse JSON in isolate
  static Map<String, dynamic> _parseJsonResponse(String responseBody) {
    return jsonDecode(responseBody);
  }

  // Get inventory report (enhanced with similar optimizations)
  Future<Map<String, dynamic>> getInventoryReport(
    InventoryReportFilter filter, {
    bool useCache = true,
    String? requestId,
  }) async {
    final cacheKey = 'inventory_report_${jsonEncode(filter.toQueryParams())}';

    if (useCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        return cached as Map<String, dynamic>; // Direct access, no .data property
      }
    }

    final reqId =
        requestId ?? 'inventory_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final apiRequest = ApiRequest();
      _activeRequests[reqId] = apiRequest;

      final queryParams = filter.toQueryParams();

      ApiConfig.logApiRequest(
        'GET',
        ApiConfig.inventoryReportEndpoint,
        queryParams.cast<String, dynamic>(),
      );

      final uri = Uri.parse(
        ApiConfig.getEndpointUrl(ApiConfig.inventoryReportEndpoint),
      ).replace(queryParameters: queryParams);

      final response = await apiRequest.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = await compute(_parseJsonResponse, response.body);
        
        // Debug log to check response structure
        debugPrint('Inventory API Response Keys: ${jsonData.keys.toList()}');
        
        ApiConfig.logApiResponse(
          ApiConfig.inventoryReportEndpoint,
          response.statusCode,
          'Success',
        );

        // Process in a background isolate
        final result = await compute(_processInventoryData, jsonData);

        if (useCache) {
          _cache.set(cacheKey, result);
        }

        _activeRequests.remove(reqId);
        return result;
      } else {
        ApiConfig.logApiResponse(
          ApiConfig.inventoryReportEndpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        _activeRequests.remove(reqId);
        throw Exception('Failed to load inventory report: ${response.body}');
      }
    } catch (e) {
      _activeRequests.remove(reqId);
      ApiConfig.logApiResponse(
        ApiConfig.inventoryReportEndpoint,
        0,
        e.toString(),
        isError: true,
      );
      throw Exception('Error getting inventory report: $e');
    }
  }

  // Static method for processing inventory data in isolate
  static Map<String, dynamic> _processInventoryData(
    Map<String, dynamic> jsonData,
  ) {
    List<Product> products = [];
    try {
      final productsData = jsonData['products'] as List? ?? [];

      // Process in batches
      for (int i = 0; i < productsData.length; i += 50) {
        final end =
            (i + 50 < productsData.length) ? i + 50 : productsData.length;
        final batch = productsData.sublist(i, end);

        products.addAll(batch.map((item) => Product.fromJson(item)));
      }
    } catch (e) {
      debugPrint('Error parsing products: $e');
    }

    // Parse summary data
    InventoryReportSummary summary;
    try {
      summary = InventoryReportSummary.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing inventory summary: $e');
      summary = InventoryReportSummary(
        totalProducts: 0,
        totalValue: 0,
        lowStockCount: 0,
        outOfStockCount: 0,
      );
    }

    // Include pagination data in the response
    return {
      'products': products,
      'summary': summary,
      'categories': jsonData['categories'] as List? ?? [],
      'current_page': jsonData['current_page'] ?? 1,
      'last_page': jsonData['last_page'] ?? 1,
      'hasMorePages': jsonData['hasMorePages'] ?? false,
      'total': jsonData['total'] ?? products.length,
    };
  }

  // Get users report (with optimizations)
  Future<Map<String, dynamic>> getUsersReport(
    UsersReportFilter filter, {
    bool useCache = true,
    String? requestId,
  }) async {
    final cacheKey = 'users_report_${jsonEncode(filter.toQueryParams())}';

    if (useCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        return cached as Map<String, dynamic>; // Direct access, no .data property
      }
    }

    final reqId = requestId ?? 'users_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final apiRequest = ApiRequest();
      _activeRequests[reqId] = apiRequest;

      final queryParams = filter.toQueryParams();

      ApiConfig.logApiRequest(
        'GET',
        ApiConfig.usersReportEndpoint,
        queryParams.cast<String, dynamic>(),
      );

      final uri = Uri.parse(
        ApiConfig.getEndpointUrl(ApiConfig.usersReportEndpoint),
      ).replace(queryParameters: queryParams);

      final response = await apiRequest.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = await compute(_parseJsonResponse, response.body);
        ApiConfig.logApiResponse(
          ApiConfig.usersReportEndpoint,
          response.statusCode,
          'Success',
        );

        // Process data in background
        final result = await compute(_processUsersData, jsonData);

        if (useCache) {
          _cache.set(cacheKey, result);
        }

        _activeRequests.remove(reqId);
        return result;
      } else {
        ApiConfig.logApiResponse(
          ApiConfig.usersReportEndpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        _activeRequests.remove(reqId);
        throw Exception('Failed to load users report: ${response.body}');
      }
    } catch (e) {
      _activeRequests.remove(reqId);
      ApiConfig.logApiResponse(
        ApiConfig.usersReportEndpoint,
        0,
        e.toString(),
        isError: true,
      );
      throw Exception('Error getting users report: $e');
    }
  }

  // Static method for processing user data in isolate
  static Map<String, dynamic> _processUsersData(Map<String, dynamic> jsonData) {
    // Parse cashier performance data
    final Map<String, UserPerformance> cashierPerformance = {};

    try {
      final cashiers = jsonData['cashiers'] as List? ?? [];

      for (final cashier in cashiers) {
        final id = cashier['id']?.toString();
        if (id != null) {
          cashierPerformance[id] = UserPerformance.fromJson(cashier);
        }
      }
    } catch (e) {
      debugPrint('Error parsing cashier performance: $e');
    }

    return {
      'cashierPerformance': cashierPerformance,
      'startDate': jsonData['start_date'],
      'endDate': jsonData['end_date'],
    };
  }

  // Get stock movements report (with optimizations)
  Future<Map<String, dynamic>> getStockMovementsReport(
    StockMovementsReportFilter filter, {
    bool useCache = true,
    String? requestId,
  }) async {
    final cacheKey = 'stock_movements_${jsonEncode(filter.toQueryParams())}';

    if (useCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        return cached as Map<String, dynamic>; // Direct access, no .data property
      }
    }

    final reqId = requestId ?? 'stock_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final apiRequest = ApiRequest();
      _activeRequests[reqId] = apiRequest;

      final queryParams = filter.toQueryParams();

      ApiConfig.logApiRequest(
        'GET',
        ApiConfig.stockMovementsReportEndpoint,
        queryParams.cast<String, dynamic>(),
      );

      final uri = Uri.parse(
        ApiConfig.getEndpointUrl(ApiConfig.stockMovementsReportEndpoint),
      ).replace(queryParameters: queryParams);

      final response = await apiRequest.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = await compute(_parseJsonResponse, response.body);
        ApiConfig.logApiResponse(
          ApiConfig.stockMovementsReportEndpoint,
          response.statusCode,
          'Success',
        );

        // Process in background
        final result = await compute(_processStockMovementsData, jsonData);

        if (useCache) {
          _cache.set(cacheKey, result);
        }

        _activeRequests.remove(reqId);
        return result;
      } else {
        ApiConfig.logApiResponse(
          ApiConfig.stockMovementsReportEndpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        _activeRequests.remove(reqId);
        throw Exception(
          'Failed to load stock movements report: ${response.body}',
        );
      }
    } catch (e) {
      _activeRequests.remove(reqId);
      ApiConfig.logApiResponse(
        ApiConfig.stockMovementsReportEndpoint,
        0,
        e.toString(),
        isError: true,
      );
      throw Exception('Error getting stock movements report: $e');
    }
  }

  // Static method for processing stock movements data in isolate
  static Map<String, dynamic> _processStockMovementsData(
    Map<String, dynamic> jsonData,
  ) {
    Pagination<StockMovement> movements;
    try {
      movements = Pagination<StockMovement>.fromJson(
        jsonData['movements'] ??
            {
              'data': [],
              'current_page': 1,
              'last_page': 1,
              'per_page': 10,
              'total': 0,
            },
        (item) => StockMovement.fromJson(item),
      );
    } catch (e) {
      debugPrint('Error parsing stock movements: $e');
      movements = Pagination<StockMovement>(
        data: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 10,
        total: 0,
      );
    }

    List<Product> products = [];
    try {
      products =
          (jsonData['products'] as List? ?? [])
              .map((item) => Product.fromJson(item))
              .toList();
    } catch (e) {
      debugPrint('Error parsing products in stock movements: $e');
    }

    return {
      'movements': movements,
      'products': products,
      'startDate': jsonData['start_date'],
      'endDate': jsonData['end_date'],
    };
  }

  // Export sales report to CSV (with optimizations)
  Future<String> exportSalesReport(SalesReportFilter filter) async {
    return _exportReport(
      ApiConfig.salesReportExportEndpoint,
      filter,
      'sales_report',
    );
  }

  // Export inventory report to CSV
  Future<String> exportInventoryReport(InventoryReportFilter filter) async {
    return _exportReport(
      ApiConfig.inventoryReportExportEndpoint,
      filter,
      'inventory_report',
    );
  }

  // Export users report to CSV
  Future<String> exportUsersReport(UsersReportFilter filter) async {
    return _exportReport(
      ApiConfig.usersReportExportEndpoint,
      filter,
      'users_report',
    );
  }

  // Export stock movements report to CSV
  Future<String> exportStockMovementsReport(
    StockMovementsReportFilter filter,
  ) async {
    return _exportReport(
      ApiConfig.stockMovementsReportExportEndpoint,
      filter,
      'stock_movements_report',
    );
  }

  // Generic helper method to export reports (optimized)
  Future<String> _exportReport(
    String endpoint,
    ReportFilter filter,
    String filePrefix,
  ) async {
    final reqId = 'export_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final apiRequest = ApiRequest();
      _activeRequests[reqId] = apiRequest;

      final queryParams = filter.toQueryParams();

      ApiConfig.logApiRequest(
        'GET',
        endpoint,
        queryParams.cast<String, dynamic>(),
      );

      final uri = Uri.parse(
        ApiConfig.getEndpointUrl(endpoint),
      ).replace(queryParameters: queryParams);

      final response = await apiRequest.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ApiConfig.logApiResponse(endpoint, response.statusCode, 'Success');

        // Save the CSV file in a background isolate
        final fileName =
            '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.csv';
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';

        // Write file in a separate isolate
        await compute(_writeFile, {
          'path': filePath,
          'bytes': response.bodyBytes,
        });

        _activeRequests.remove(reqId);
        return filePath;
      } else {
        ApiConfig.logApiResponse(
          endpoint,
          response.statusCode,
          response.body,
          isError: true,
        );
        _activeRequests.remove(reqId);
        throw Exception('Failed to export report: ${response.body}');
      }
    } catch (e) {
      _activeRequests.remove(reqId);
      ApiConfig.logApiResponse(endpoint, 0, e.toString(), isError: true);
      throw Exception('Error exporting report: $e');
    }
  }

  // Static method to write file in isolate
  static Future<void> _writeFile(Map<String, dynamic> params) async {
    final filePath = params['path'] as String;
    final bytes = params['bytes'] as List<int>;

    final file = File(filePath);
    await file.writeAsBytes(bytes);
  }

  // Share a report file
  Future<void> shareReportFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], subject: 'Report Export');
    } catch (e) {
      throw Exception('Error sharing report: $e');
    }
  }

  // Helper function to implement retry logic with cancellation support
  Future<http.Response> _retryableRequest(
    Future<http.Response> Function() requestFunction, {
    int maxRetries = 3,
    int retryDelay = 1500,
  }) async {
    int retries = 0;

    while (retries < maxRetries) {
      try {
        return await requestFunction();
      } catch (e) {
        if (e is CancelRequestException) {
          throw e; // Don't retry cancelled requests
        }

        retries++;
        if (retries >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: retryDelay * retries));
      }
    }

    throw Exception('Max retries exceeded');
  }

  // Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  // Dispose resources
  void dispose() {
    cancelAllRequests();
  }
}

// Utility class for caching report data
class ReportCache {
  final Map<String, CachedReport> _cache = {};
  final int _maxCacheEntries = 20;
  
  // Returns the cached data directly, not the CachedReport object
  dynamic get(String key) {
    final cached = _cache[key];
    if (cached == null) return null;
    
    // Check if cache is expired (30 minutes)
    if (DateTime.now().difference(cached.timestamp).inMinutes > 30) {
      _cache.remove(key);
      return null;
    }
    
    // Update last accessed time to implement LRU behavior
    _cache[key] = CachedReport(
      data: cached.data,
      timestamp: cached.timestamp,
      lastAccessed: DateTime.now(),
    );
    
    // Return the data directly
    return cached.data;
  }
  
  void set(String key, dynamic data) {
    // Implement LRU cache - if we reach the limit, remove least recently used
    if (_cache.length >= _maxCacheEntries) {
      // Find and remove least recently accessed entry
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.lastAccessed.isBefore(b.value.lastAccessed) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }
    
    _cache[key] = CachedReport(
      data: data,
      timestamp: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
  }

  void clear() {
    _cache.clear();
  }

  // Remove a specific item from cache
  void remove(String key) {
    _cache.remove(key);
  }
}

class CachedReport {
  final dynamic data;
  final DateTime timestamp;
  final DateTime lastAccessed;

  CachedReport({
    required this.data,
    required this.timestamp,
    DateTime? lastAccessed,
  }) : this.lastAccessed = lastAccessed ?? DateTime.now();
}

// Utility class for API requests that can be cancelled
class ApiRequest {
  final http.Client _client = http.Client();
  bool _isCancelled = false;

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    if (_isCancelled) throw CancelRequestException('Request was cancelled');

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(Duration(milliseconds: ApiConfig.connectionTimeout));

      if (_isCancelled)
        throw CancelRequestException('Request was cancelled after completion');

      return response;
    } catch (e) {
      if (_isCancelled)
        throw CancelRequestException('Request was cancelled during execution');
      rethrow;
    }
  }

  void cancel() {
    _isCancelled = true;
    _client.close();
  }
}

// Exception for cancelled requests
class CancelRequestException implements Exception {
  final String message;

  CancelRequestException(this.message);

  @override
  String toString() => 'CancelRequestException: $message';
}

// Lightweight model for sales list views to reduce memory usage
class SaleSummary {
  final int id;
  final String receiptNumber;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String createdAt;

  SaleSummary({
    required this.id,
    required this.receiptNumber,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory SaleSummary.fromJson(Map<String, dynamic> json) {
    return SaleSummary(
      id: json['id'] ?? 0,
      receiptNumber: json['receipt_number'] ?? '',
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  factory SaleSummary.fromSale(Sale sale) {
    return SaleSummary(
      id: sale.id,
      receiptNumber: sale.receiptNumber,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethod,
      status: sale.status,
      createdAt: sale.createdAt,
    );
  }
}