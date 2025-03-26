import 'dart:convert';
import 'package:flutter/foundation.dart';

class DebugHelper {
  // Enable or disable debug logging
  static bool enableDebugLogs = true;
  
  // Log API response for debugging
  static void logApiResponse(String endpoint, dynamic response, {bool isError = false}) {
    if (!enableDebugLogs) return;
    
    try {
      if (isError) {
        debugPrint('🔴 API ERROR [$endpoint]: $response');
      } else {
        debugPrint('🟢 API RESPONSE [$endpoint]: ${_truncateResponse(response)}');
      }
    } catch (e) {
      debugPrint('Error logging API response: $e');
    }
  }
  
  // Log API request for debugging
  static void logApiRequest(String endpoint, dynamic requestBody) {
    if (!enableDebugLogs) return;
    
    try {
      debugPrint('🔷 API REQUEST [$endpoint]: ${_truncateResponse(requestBody)}');
    } catch (e) {
      debugPrint('Error logging API request: $e');
    }
  }
  
  // Pretty print JSON data for debugging
  static void prettyPrintJson(String tag, dynamic jsonData) {
    if (!enableDebugLogs) return;
    
    try {
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String prettyJson = encoder.convert(jsonData);
      
      // Split by newline and add tag to each line
      final List<String> lines = prettyJson.split('\n');
      debugPrint('⚙️ $tag:');
      for (var line in lines) {
        debugPrint('   $line');
      }
    } catch (e) {
      debugPrint('Error pretty printing JSON: $e');
    }
  }
  
  // Log image URL issues
  static void logImageIssue(String productName, String? imageUrl, String issue) {
    if (!enableDebugLogs) return;
    
    debugPrint('🖼️ IMAGE ISSUE [$productName]: $issue');
    debugPrint('   URL: $imageUrl');
  }
  
  // Helper to truncate long responses in logs
  static String _truncateResponse(dynamic response) {
    String responseStr;
    
    if (response is String) {
      responseStr = response;
    } else {
      try {
        responseStr = json.encode(response);
      } catch (e) {
        return '$response';
      }
    }
    
    if (responseStr.length > 500) {
      return '${responseStr.substring(0, 500)}... (truncated)';
    }
    
    return responseStr;
  }
}