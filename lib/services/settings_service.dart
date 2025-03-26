// lib/services/settings_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class SettingsService {
  final storage = const FlutterSecureStorage();
  // Local cache of settings
  Map<String, dynamic> _settingsCache = {
    'currency_symbol': 'Ksh',
    'company_name': 'Eldo Gas',
    'company_address': '',
    'company_phone': '',
    'receipt_footer': 'Thank you for your business!',
    'tax_percentage': '0',
    'low_stock_threshold': '5',
  };
  bool _settingsLoaded = false;

  // Get all settings
  Future<Map<String, dynamic>> getSettings() async {
    // If we've already loaded settings, return the cached version
    if (_settingsLoaded) {
      return _settingsCache;
    }
    
    try {
      final token = await storage.read(key: ApiConfig.authTokenKey);
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      // Log the request for debugging
      ApiConfig.logApiRequest('GET', ApiConfig.settingsEndpoint);
      
      final response = await http.get(
        Uri.parse(ApiConfig.getEndpointUrl(ApiConfig.settingsEndpoint)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
      );
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        ApiConfig.logApiResponse(ApiConfig.settingsEndpoint, response.statusCode, 'Success');
        
        // Convert array of settings to map for easier access
        if (jsonData is List) {
          Map<String, dynamic> settingsMap = {};
          for (var setting in jsonData) {
            settingsMap[setting['key']] = setting['value'];
          }
          _settingsCache = settingsMap;
        } else if (jsonData is Map) {
          _settingsCache = Map<String, dynamic>.from(jsonData);
        }
        
        _settingsLoaded = true;
        return _settingsCache;
      } else {
        ApiConfig.logApiResponse(
          ApiConfig.settingsEndpoint, 
          response.statusCode, 
          response.body,
          isError: true,
        );
        
        // Return cached settings if API fails
        return _settingsCache;
      }
    } catch (e) {
      ApiConfig.logApiResponse(ApiConfig.settingsEndpoint, 0, e.toString(), isError: true);
      print('Error getting settings: $e');
      // Return cached settings if there's an error
      return _settingsCache;
    }
  }

  // Get a specific setting
  Future<String> getSetting(String key, {String defaultValue = ''}) async {
    try {
      final settings = await getSettings();
      return settings[key]?.toString() ?? defaultValue;
    } catch (e) {
      print('Error getting setting $key: $e');
      // Check if it's in the cache
      return _settingsCache[key]?.toString() ?? defaultValue;
    }
  }

  // Clear settings cache to force reload
  void clearCache() {
    _settingsLoaded = false;
  }
}