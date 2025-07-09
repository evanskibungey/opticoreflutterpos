import 'dart:io';
import 'dart:typed_data';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Printer connection status enum
enum PrinterConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class ThermalPrinterService extends ChangeNotifier {
  static const String _savedPrinterIpKey = 'saved_printer_ip';
  static const String _savedPrinterPortKey = 'saved_printer_port';
  static const String _autoConnectKey = 'auto_connect_printer';
  static const int _defaultPort = 9100;
  
  // Singleton instance
  static ThermalPrinterService? _instance;
  static ThermalPrinterService get instance {
    _instance ??= ThermalPrinterService._internal();
    return _instance!;
  }
  
  // Private constructor
  ThermalPrinterService._internal() {
    _initializeService();
  }
  
  // Network printer instance
  NetworkPrinter? _printer;
  
  // Connection state
  PrinterConnectionStatus _connectionStatus = PrinterConnectionStatus.disconnected;
  String? _connectedPrinterIp;
  int? _connectedPrinterPort;
  String _statusMessage = 'Disconnected';
  
  // Getters
  PrinterConnectionStatus get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus == PrinterConnectionStatus.connected;
  bool get isConnecting => _connectionStatus == PrinterConnectionStatus.connecting;
  String get printerStatus => _statusMessage;
  String? get connectedPrinterIp => _connectedPrinterIp;
  int? get connectedPrinterPort => _connectedPrinterPort;
  
  // Initialize service and attempt auto-reconnection
  Future<void> _initializeService() async {
    try {
      final settings = await getSavedPrinterSettings();
      final autoConnect = settings['auto_connect'] ?? false;
      
      if (autoConnect && settings['ip'] != null) {
        // Attempt to reconnect to saved printer
        await Future.delayed(Duration(seconds: 1)); // Small delay to ensure app is ready
        await connectToPrinter(
          settings['ip'],
          port: settings['port'],
          autoConnect: false, // Prevent infinite loop
        );
      }
    } catch (e) {
      print('Error during printer service initialization: $e');
    }
  }
  
  // Update connection status and notify listeners
  void _updateStatus(PrinterConnectionStatus status, String message, {String? ip, int? port}) {
    _connectionStatus = status;
    _statusMessage = message;
    
    if (status == PrinterConnectionStatus.connected) {
      _connectedPrinterIp = ip;
      _connectedPrinterPort = port;
    } else {
      _connectedPrinterIp = null;
      _connectedPrinterPort = null;
    }
    
    notifyListeners();
    print('Printer status updated: $message');
  }
  
  // Get saved printer settings
  Future<Map<String, dynamic>> getSavedPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ip': prefs.getString(_savedPrinterIpKey),
      'port': prefs.getInt(_savedPrinterPortKey) ?? _defaultPort,
      'auto_connect': prefs.getBool(_autoConnectKey) ?? false,
    };
  }
  
  // Save printer settings
  Future<void> savePrinterSettings(String ip, int port, {bool autoConnect = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPrinterIpKey, ip);
    await prefs.setInt(_savedPrinterPortKey, port);
    await prefs.setBool(_autoConnectKey, autoConnect);
    print('Printer settings saved: $ip:$port, auto-connect: $autoConnect');
  }
  
  // Clear saved printer settings
  Future<void> clearPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPrinterIpKey);
    await prefs.remove(_savedPrinterPortKey);
    await prefs.remove(_autoConnectKey);
    print('Printer settings cleared');
  }
  
  // Discover printers on the network
  Future<List<String>> discoverPrinters() async {
    final List<String> discoveredPrinters = [];
    
    try {
      // Get the device's IP address
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      
      if (wifiIP == null) {
        throw Exception('No WiFi connection found');
      }
      
      // Extract the subnet (e.g., 192.168.1.x)
      final subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.'));
      
      // Scan the network for devices
      final stream = NetworkAnalyzer.discover2(
        subnet, 
        _defaultPort,
        timeout: Duration(milliseconds: 3000),
      );
      
      await for (final NetworkAddress address in stream) {
        if (address.exists) {
          // Test if it's actually a printer by trying to connect
          try {
            final printer = NetworkPrinter(PaperSize.mm80, await CapabilityProfile.load());
            final PosPrintResult connectResult = await printer.connect(
              address.ip,
              port: _defaultPort,
              timeout: Duration(seconds: 3),
            );
            
            if (connectResult == PosPrintResult.success) {
              discoveredPrinters.add(address.ip);
              printer.disconnect();
            }
          } catch (e) {
            // Not a printer, continue
          }
        }
      }
    } catch (e) {
      print('Error discovering printers: $e');
    }
    
    return discoveredPrinters;
  }
  
  // Connect to printer with persistent connection
  Future<bool> connectToPrinter(String ipAddress, {int port = 9100, bool autoConnect = true}) async {
    if (_connectionStatus == PrinterConnectionStatus.connecting) {
      return false; // Already connecting
    }
    
    _updateStatus(PrinterConnectionStatus.connecting, 'Connecting to printer...');
    
    try {
      // Disconnect existing connection if any
      if (_printer != null) {
        _printer!.disconnect();
        _printer = null;
      }
      
      // Load capability profile
      final profile = await CapabilityProfile.load();
      _printer = NetworkPrinter(PaperSize.mm80, profile);
      
      final PosPrintResult result = await _printer!.connect(
        ipAddress,
        port: port,
        timeout: Duration(seconds: 10),
      );
      
      if (result == PosPrintResult.success) {
        // Save successful connection settings
        await savePrinterSettings(ipAddress, port, autoConnect: autoConnect);
        _updateStatus(
          PrinterConnectionStatus.connected,
          'Connected to $ipAddress:$port',
          ip: ipAddress,
          port: port,
        );
        return true;
      } else {
        _updateStatus(PrinterConnectionStatus.error, 'Failed to connect to printer');
        _printer = null;
        return false;
      }
    } catch (e) {
      print('Error connecting to printer: $e');
      _updateStatus(PrinterConnectionStatus.error, 'Connection error: ${e.toString()}');
      _printer = null;
      return false;
    }
  }
  
  // Disconnect from printer
  void disconnect() {
    try {
      if (_printer != null) {
        _printer!.disconnect();
        _printer = null;
      }
    } catch (e) {
      print('Error disconnecting from printer: $e');
    } finally {
      _updateStatus(PrinterConnectionStatus.disconnected, 'Disconnected');
    }
  }
  
  // Attempt to reconnect using saved settings
  Future<bool> reconnect() async {
    try {
      final settings = await getSavedPrinterSettings();
      if (settings['ip'] != null) {
        return await connectToPrinter(
          settings['ip'],
          port: settings['port'],
          autoConnect: false,
        );
      }
      return false;
    } catch (e) {
      print('Error during reconnection: $e');
      return false;
    }
  }
  
  // Check connection status and attempt reconnection if needed
  Future<bool> ensureConnection() async {
    if (isConnected) {
      return true;
    }
    
    // Attempt reconnection
    return await reconnect();
  }
  
  // Helper method to print a single receipt copy
  void _printSingleReceipt({
    required String receiptNumber,
    required List<Map<String, dynamic>> items,
    required dynamic total,
    required String paymentMethod,
    required Map<String, dynamic> customer,
    required String copyType, // "CUSTOMER COPY" or "SHOP COPY"
    required String currencySymbol,
  }) {
    // Use current device time instead of stored time
    final currentTime = DateTime.now();
    
    // Company header
    _printer!.text(
      'OPTICORE',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    
    _printer!.text(
      'Your Network Hub',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text(
      'Tel: +254113131335',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text('');
    
    // Copy type header (Customer Copy or Shop Copy)
    _printer!.text(
      '=== $copyType ===',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size2,
      ),
    );
    
    _printer!.text('');
    _printer!.hr();
    
    // Receipt info with current time
    _printer!.row([
      PosColumn(text: 'Receipt #:', width: 6),
      PosColumn(text: receiptNumber, width: 6, styles: PosStyles(bold: true)),
    ]);
    
    _printer!.row([
      PosColumn(text: 'Date:', width: 6),
      PosColumn(text: DateFormat('yyyy-MM-dd HH:mm').format(currentTime), width: 6),
    ]);
    
    _printer!.row([
      PosColumn(text: 'Payment:', width: 6),
      PosColumn(text: paymentMethod.toUpperCase(), width: 6),
    ]);
    
    _printer!.text('');
    
    // Customer info for credit sales
    if (paymentMethod == 'credit') {
      _printer!.text(
        'CUSTOMER DETAILS',
        styles: PosStyles(bold: true, align: PosAlign.center),
      );
      _printer!.hr(ch: '-');
      
      _printer!.row([
        PosColumn(text: 'Name:', width: 4),
        PosColumn(text: customer['name'] ?? 'Walk-in Customer', width: 8),
      ]);
      
      _printer!.row([
        PosColumn(text: 'Phone:', width: 4),
        PosColumn(text: customer['phone'] ?? '-', width: 8),
      ]);
      
      _printer!.text('');
    }
    
    // Items header
    _printer!.text(
      'ITEMS',
      styles: PosStyles(bold: true, align: PosAlign.center),
    );
    _printer!.hr();
    
    _printer!.row([
      PosColumn(text: 'Item', width: 5, styles: PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
      PosColumn(text: 'Price', width: 3, styles: PosStyles(bold: true)),
      PosColumn(text: 'Total', width: 2, styles: PosStyles(bold: true)),
    ]);
    
    _printer!.hr(ch: '-');
    
    // Print items
    for (final item in items) {
      final itemName = item['name'] ?? 'Unknown Item';
      final quantity = item['quantity'] ?? 0;
      final price = _formatNumber(item['price']);
      final subtotal = _formatNumber(item['subtotal']);
      
      // Item name (might wrap to multiple lines)
      _printer!.row([
        PosColumn(text: itemName, width: 12),
      ]);
      
      // Quantity, price, subtotal
      _printer!.row([
        PosColumn(text: '', width: 5),
        PosColumn(text: '$quantity', width: 2),
        PosColumn(text: '$currencySymbol$price', width: 3),
        PosColumn(text: '$currencySymbol$subtotal', width: 2, styles: PosStyles(bold: true)),
      ]);
      
      // Serial number if available
      if (item['serial_number'] != null && item['serial_number'].toString().isNotEmpty) {
        _printer!.text(
          'S/N: ${item['serial_number']}',
          styles: PosStyles(align: PosAlign.left, width: PosTextSize.size1),
        );
      }
      
      _printer!.text('');
    }
    
    _printer!.hr();
    
    // Totals
    _printer!.row([
      PosColumn(text: 'Subtotal:', width: 8),
      PosColumn(
        text: '$currencySymbol${_formatNumber(total)}',
        width: 4,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    
    _printer!.row([
      PosColumn(text: 'Tax (0%):', width: 8),
      PosColumn(
        text: '${currencySymbol}0.00',
        width: 4,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    
    _printer!.hr();
    
    _printer!.row([
      PosColumn(
        text: 'TOTAL:',
        width: 8,
        styles: PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: '$currencySymbol${_formatNumber(total)}',
        width: 4,
        styles: PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);
    
    _printer!.text('');
    _printer!.hr();
    
    // Footer
    _printer!.text(
      'Thank you for your business!',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    
    _printer!.text(
      'Goods sold cannot be returned or exchanged',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text('');
    _printer!.text(
      'Powered by HittyTech',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text('');
    _printer!.cut();
    
    // Add extra feed between copies
    _printer!.feed(3);
  }
  
  // Test printer connection
  Future<bool> testPrint() async {
    if (!await ensureConnection()) {
      return false;
    }
    
    try {
      _printer!.text(
        'TEST PRINT',
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
      _printer!.text('');
      _printer!.text(
        'Printer connection successful!',
        styles: PosStyles(align: PosAlign.center),
      );
      _printer!.text(
        'Test Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
        styles: PosStyles(align: PosAlign.center),
      );
      _printer!.text('');
      _printer!.text(
        'Connection maintained across app navigation',
        styles: PosStyles(align: PosAlign.center),
      );
      _printer!.text('');
      _printer!.cut();
      
      // Add feed lines to ensure proper cutting
      _printer!.feed(2);
      
      // The disconnect/reconnect pattern ensures commands are sent
      // This is a common pattern with ESC/POS thermal printers
      final tempIp = _connectedPrinterIp!;
      final tempPort = _connectedPrinterPort!;
      
      _printer!.disconnect();
      
      // Small delay to ensure disconnect completes
      await Future.delayed(Duration(milliseconds: 500));
      
      // Reconnect to maintain the persistent connection
      final profile = await CapabilityProfile.load();
      _printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult reconnectResult = await _printer!.connect(
        tempIp,
        port: tempPort,
        timeout: Duration(seconds: 10),
      );
      
      if (reconnectResult != PosPrintResult.success) {
        print('Reconnection failed after test print, but print job was sent');
        _updateStatus(PrinterConnectionStatus.error, 'Reconnection failed after printing');
        _printer = null;
        // Print job was likely successful even if reconnection failed
        return true;
      }
      
      return true;
    } catch (e) {
      print('Error during test print: $e');
      _updateStatus(PrinterConnectionStatus.error, 'Print failed: ${e.toString()}');
      return false;
    }
  }
  
  // Print receipt from new sale (now prints 2 copies with current time)
  Future<bool> printReceipt({
    required String receiptNumber,
    required Map<String, dynamic> receiptData,
    String currencySymbol = 'KSh',
  }) async {
    if (!await ensureConnection()) {
      throw Exception('Printer not connected. Please check printer settings.');
    }
    
    try {
      // Parse receipt data (ignore stored date, use current time)
      final items = List<Map<String, dynamic>>.from(receiptData['items'] ?? []);
      final dynamic total = receiptData['total'] ?? 0.0;
      final paymentMethod = receiptData['payment_method'] ?? 'cash';
      final customer = receiptData['customer'] ?? {'name': 'Walk-in Customer', 'phone': '-'};
      
      // Start printing
      _printer!.reset();
      
      // Print Customer Copy
      _printSingleReceipt(
        receiptNumber: receiptNumber,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        customer: customer,
        copyType: 'CUSTOMER COPY',
        currencySymbol: currencySymbol,
      );
      
      // Print Shop Copy
      _printSingleReceipt(
        receiptNumber: receiptNumber,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        customer: customer,
        copyType: 'SHOP COPY',
        currencySymbol: currencySymbol,
      );
      
      // Final feed after both copies
      _printer!.feed(2);
      
      // The disconnect/reconnect pattern ensures commands are sent
      // This is a common pattern with ESC/POS thermal printers
      final tempIp = _connectedPrinterIp!;
      final tempPort = _connectedPrinterPort!;
      
      _printer!.disconnect();
      
      // Small delay to ensure disconnect completes
      await Future.delayed(Duration(milliseconds: 500));
      
      // Reconnect to maintain the persistent connection
      final profile = await CapabilityProfile.load();
      _printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult reconnectResult = await _printer!.connect(
        tempIp,
        port: tempPort,
        timeout: Duration(seconds: 10),
      );
      
      if (reconnectResult != PosPrintResult.success) {
        print('Reconnection failed after receipt print, but print job was sent');
        _updateStatus(PrinterConnectionStatus.error, 'Reconnection failed after printing');
        _printer = null;
        // Print job was likely successful even if reconnection failed
        return true;
      }
      
      return true;
    } catch (e) {
      print('Error printing receipt: $e');
      _updateStatus(PrinterConnectionStatus.error, 'Print failed: ${e.toString()}');
      return false;
    }
  }
  
  // Helper method to print a single sale receipt copy
  void _printSingleSaleReceipt({
    required dynamic sale,
    required String copyType, // "CUSTOMER COPY" or "SHOP COPY"
    required String currencySymbol,
  }) {
    // Use current device time instead of stored time
    final currentTime = DateTime.now();
    
    // Company header
    _printer!.text(
      'OPTICORE',
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    
    _printer!.text(
      'Your Network Hub',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text(
      'Tel: +254113131335',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text('');
    
    // Copy type header (Customer Copy or Shop Copy)
    _printer!.text(
      '=== $copyType ===',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size2,
      ),
    );
    
    _printer!.text('');
    
    // Sale status (if voided)
    if (sale.status.toLowerCase() == 'voided') {
      _printer!.text(
        '*** VOIDED SALE ***',
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
        ),
      );
      _printer!.text('');
    }
    
    _printer!.hr();
    
    // Receipt info with current time
    _printer!.row([
      PosColumn(text: 'Receipt #:', width: 6),
      PosColumn(text: sale.receiptNumber, width: 6, styles: PosStyles(bold: true)),
    ]);
    
    _printer!.row([
      PosColumn(text: 'Date:', width: 6),
      PosColumn(text: DateFormat('yyyy-MM-dd HH:mm').format(currentTime), width: 6),
    ]);
    
    _printer!.row([
      PosColumn(text: 'Cashier:', width: 6),
      PosColumn(text: sale.user?.name ?? 'N/A', width: 6),
    ]);
    
    _printer!.row([
      PosColumn(text: 'Payment:', width: 6),
      PosColumn(text: sale.paymentMethod.toUpperCase(), width: 6),
    ]);
    
    _printer!.text('');
    
    // Customer info if available
    if (sale.customer != null) {
      _printer!.text(
        'CUSTOMER DETAILS',
        styles: PosStyles(bold: true, align: PosAlign.center),
      );
      _printer!.hr(ch: '-');
      
      _printer!.row([
        PosColumn(text: 'Name:', width: 4),
        PosColumn(text: sale.customer.name, width: 8),
      ]);
      
      if (sale.customer.phone.isNotEmpty && sale.customer.phone != '0000000000') {
        _printer!.row([
          PosColumn(text: 'Phone:', width: 4),
          PosColumn(text: sale.customer.phone, width: 8),
        ]);
      }
      
      _printer!.text('');
    }
    
    // Items
    if (sale.items != null && sale.items!.isNotEmpty) {
      _printer!.text(
        'ITEMS',
        styles: PosStyles(bold: true, align: PosAlign.center),
      );
      _printer!.hr();
      
      _printer!.row([
        PosColumn(text: 'Item', width: 5, styles: PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: true)),
        PosColumn(text: 'Price', width: 3, styles: PosStyles(bold: true)),
        PosColumn(text: 'Total', width: 2, styles: PosStyles(bold: true)),
      ]);
      
      _printer!.hr(ch: '-');
      
      for (final item in sale.items!) {
        final itemName = item.product?.name ?? 'Unknown Product';
        final quantity = item.quantity;
        final price = item.unitPrice.toStringAsFixed(2);
        final subtotal = item.subtotal.toStringAsFixed(2);
        
        // Item name
        _printer!.row([
          PosColumn(text: itemName, width: 12),
        ]);
        
        // Quantity, price, subtotal
        _printer!.row([
          PosColumn(text: '', width: 5),
          PosColumn(text: '$quantity', width: 2),
          PosColumn(text: '$currencySymbol$price', width: 3),
          PosColumn(text: '$currencySymbol$subtotal', width: 2, styles: PosStyles(bold: true)),
        ]);
        
        // Serial number if available
        if (item.serialNumber != null && item.serialNumber!.isNotEmpty) {
          _printer!.text(
            'S/N: ${item.serialNumber}',
            styles: PosStyles(align: PosAlign.left, width: PosTextSize.size1),
          );
        }
        
        _printer!.text('');
      }
    }
    
    _printer!.hr();
    
    // Totals
    _printer!.row([
      PosColumn(text: 'Subtotal:', width: 8),
      PosColumn(
        text: '$currencySymbol${sale.totalAmount.toStringAsFixed(2)}',
        width: 4,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    
    _printer!.row([
      PosColumn(text: 'Tax (0%):', width: 8),
      PosColumn(
        text: '${currencySymbol}0.00',
        width: 4,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    
    _printer!.hr();
    
    _printer!.row([
      PosColumn(
        text: 'TOTAL:',
        width: 8,
        styles: PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: '$currencySymbol${sale.totalAmount.toStringAsFixed(2)}',
        width: 4,
        styles: PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
        ),
      ),
    ]);
    
    _printer!.text('');
    _printer!.hr();
    
    // Footer
    _printer!.text(
      'Thank you for your business!',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    
    _printer!.text(
      'Goods sold cannot be returned or exchanged',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text('');
    _printer!.text(
      'Powered by HittyTech',
      styles: PosStyles(align: PosAlign.center),
    );
    
    _printer!.text('');
    _printer!.cut();
    
    // Add extra feed between copies
    _printer!.feed(3);
  }
  
  // Print receipt from sale history (now prints 2 copies with current time)
  Future<bool> printSaleReceipt({
    required dynamic sale, // Sale object from sale history
    String currencySymbol = 'KSh',
  }) async {
    if (!await ensureConnection()) {
      throw Exception('Printer not connected. Please check printer settings.');
    }
    
    try {
      // Start printing
      _printer!.reset();
      
      // Print Customer Copy
      _printSingleSaleReceipt(
        sale: sale,
        copyType: 'CUSTOMER COPY',
        currencySymbol: currencySymbol,
      );
      
      // Print Shop Copy
      _printSingleSaleReceipt(
        sale: sale,
        copyType: 'SHOP COPY',
        currencySymbol: currencySymbol,
      );
      
      // Final feed after both copies
      _printer!.feed(2);
      
      // The disconnect/reconnect pattern ensures commands are sent
      // This is a common pattern with ESC/POS thermal printers
      final tempIp = _connectedPrinterIp!;
      final tempPort = _connectedPrinterPort!;
      
      _printer!.disconnect();
      
      // Small delay to ensure disconnect completes
      await Future.delayed(Duration(milliseconds: 500));
      
      // Reconnect to maintain the persistent connection
      final profile = await CapabilityProfile.load();
      _printer = NetworkPrinter(PaperSize.mm80, profile);
      final PosPrintResult reconnectResult = await _printer!.connect(
        tempIp,
        port: tempPort,
        timeout: Duration(seconds: 10),
      );
      
      if (reconnectResult != PosPrintResult.success) {
        print('Reconnection failed after sale receipt print, but print job was sent');
        _updateStatus(PrinterConnectionStatus.error, 'Reconnection failed after printing');
        _printer = null;
        // Print job was likely successful even if reconnection failed
        return true;
      }
      
      return true;
    } catch (e) {
      print('Error printing sale receipt: $e');
      _updateStatus(PrinterConnectionStatus.error, 'Print failed: ${e.toString()}');
      return false;
    }
  }
  
  // Helper method to format numeric values
  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    
    if (value is String) {
      try {
        return double.parse(value).toStringAsFixed(2);
      } catch (e) {
        return value;
      }
    }
    
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    
    return value.toString();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
