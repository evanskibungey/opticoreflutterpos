import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL - Production endpoint
  static const String baseUrl = 'https://sales.opticore.co.ke';
  
  // Auth endpoints
  static const String loginEndpoint = '/api/login';
  static const String logoutEndpoint = '/api/logout';
  
  // User management endpoints
  static const String usersEndpoint = '/api/users';
  
  // Dashboard endpoints
  static const String adminDashboardEndpoint = '/api/admin/dashboard';
  static const String cashierDashboardEndpoint = '/api/cashier/dashboard';
  
  // Category endpoints
  static const String categoriesEndpoint = '/api/categories';
  
  // Product endpoints
  static const String productsEndpoint = '/api/products';
  static const String productCategoriesEndpoint = '/api/products/categories';
  
  // Sales endpoints
  static const String salesEndpoint = '/api/sales';
  static const String recentSalesEndpoint = '/api/pos/recent-sales';
  static const String checkStockEndpoint = '/api/stock/check';
  
  // Inventory endpoints
  static const String inventoryEndpoint = '/api/inventory';
  static const String lowStockEndpoint = '/api/inventory/low-stock';
  static const String outOfStockEndpoint = '/api/inventory/out-of-stock';
  
  // Settings endpoints
  static const String settingsEndpoint = '/api/settings';
  
  // Report endpoints
  static const String reportsBaseEndpoint = '/api/reports';
  static const String salesReportEndpoint = '/api/reports/sales';
  static const String salesReportExportEndpoint = '/api/reports/sales/export';
  static const String inventoryReportEndpoint = '/api/reports/inventory';
  static const String inventoryReportExportEndpoint = '/api/reports/inventory/export';
  static const String usersReportEndpoint = '/api/reports/users';
  static const String usersReportExportEndpoint = '/api/reports/users/export';
  static const String stockMovementsReportEndpoint = '/api/reports/stock-movements';
  static const String stockMovementsReportExportEndpoint = '/api/reports/stock-movements/export';
  // Credit management endpoints
static const String creditsEndpoint = '/api/credits';
static const String creditAnalyticsEndpoint = '/api/credits/analytics';
static const String customerCreditsEndpoint = '/api/credits/'; // Add customer ID at end
static const String recordPaymentEndpoint = '/api/credits/'; // Add customer ID + /payment at end
  
  // Timeout settings (in milliseconds)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  // Retry settings
  static const int maxRetries = 3;
  static const int retryDelay = 1500; // in milliseconds
  
  // Storage paths
  static const String storagePath = 'storage';
  static const String productImagesPath = 'products';
  
  // Authentication storage key
  static const String authTokenKey = 'auth_token';
  
  // Debug settings
  static const bool enableDebugLogs = true;
  
  // Get full URL for endpoints
  static String getEndpointUrl(String endpoint) {
    return baseUrl + endpoint;
  }
  
  // Get full image URL from relative path
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // Check if it's already a full URL
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Add storage path if needed
    String imagePath = relativePath;
    if (!imagePath.startsWith('storage/')) {
      imagePath = 'storage/$imagePath';
    }
    
    return '$baseUrl/$imagePath';
  }
  
  // Log API request (for debugging)
  static void logApiRequest(String method, String endpoint, [Map<String, dynamic>? body]) {
    if (!enableDebugLogs) return;
    
    debugPrint('🔷 API $method REQUEST: $baseUrl$endpoint');
    if (body != null) {
      debugPrint('   Body: $body');
    }
  }
  
  // Log API response (for debugging)
  static void logApiResponse(String endpoint, int statusCode, dynamic body, {bool isError = false}) {
    if (!enableDebugLogs) return;
    
    if (isError) {
      debugPrint('🔴 API ERROR [$statusCode] $endpoint: $body');
    } else {
      debugPrint('🟢 API RESPONSE [$statusCode] $endpoint');
    }
  }
}