import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/services/thermal_printer_service.dart';

/// Opticore theme colors - matching web version
class OpticoreColors {
  // Main blues
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);

  // Grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Additional colors
  static const Color green500 = Color(0xFF10B981);
  static const Color red500 = Color(0xFFEF4444);
  static const Color orange500 = Color(0xFFF97316);
}

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isTesting = false;
  List<String> _discoveredPrinters = [];
  String? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
    _portController.text = '9100'; // Default port
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  // Load saved printer settings
  Future<void> _loadSavedSettings() async {
    try {
      final printerService = context.read<ThermalPrinterService>();
      final settings = await printerService.getSavedPrinterSettings();
      if (mounted) {
        setState(() {
          _ipController.text = settings['ip'] ?? '';
          _portController.text = settings['port'].toString();
        });
      }
    } catch (e) {
      print('Error loading saved settings: $e');
    }
  }

  // Discover printers on network
  Future<void> _discoverPrinters() async {
    setState(() {
      _isDiscovering = true;
      _discoveredPrinters.clear();
    });

    try {
      final printerService = context.read<ThermalPrinterService>();
      final printers = await printerService.discoverPrinters();
      if (mounted) {
        setState(() {
          _discoveredPrinters = printers;
          _isDiscovering = false;
        });

        if (printers.isEmpty) {
          _showSnackBar(
            'No printers found on the network',
            OpticoreColors.orange500,
          );
        } else {
          _showSnackBar(
            'Found ${printers.length} printer(s)',
            OpticoreColors.green500,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
        _showSnackBar(
          'Error discovering printers: ${e.toString()}',
          OpticoreColors.red500,
        );
      }
    }
  }

  // Connect to printer
  Future<void> _connectToPrinter() async {
    if (_ipController.text.isEmpty) {
      _showSnackBar('Please enter printer IP address', OpticoreColors.red500);
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final printerService = context.read<ThermalPrinterService>();
      final port = int.tryParse(_portController.text) ?? 9100;
      final success = await printerService.connectToPrinter(
        _ipController.text,
        port: port,
      );

      if (mounted) {
        setState(() {
          _isConnecting = false;
        });

        if (success) {
          _showSnackBar(
            'Successfully connected to printer',
            OpticoreColors.green500,
          );
        } else {
          _showSnackBar(
            'Failed to connect to printer',
            OpticoreColors.red500,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        _showSnackBar(
          'Error connecting: ${e.toString()}',
          OpticoreColors.red500,
        );
      }
    }
  }

  // Test print
  Future<void> _testPrint() async {
    final printerService = context.read<ThermalPrinterService>();
    if (!printerService.isConnected) {
      _showSnackBar('Please connect to a printer first', OpticoreColors.red500);
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final success = await printerService.testPrint();

      if (mounted) {
        setState(() {
          _isTesting = false;
        });

        if (success) {
          _showSnackBar(
            'Test print successful!',
            OpticoreColors.green500,
          );
        } else {
          _showSnackBar(
            'Test print failed',
            OpticoreColors.red500,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
        _showSnackBar(
          'Test print error: ${e.toString()}',
          OpticoreColors.red500,
        );
      }
    }
  }

  // Disconnect from printer
  void _disconnectPrinter() {
    final printerService = context.read<ThermalPrinterService>();
    printerService.disconnect();
    _showSnackBar(
      'Disconnected from printer',
      OpticoreColors.blue500,
    );
  }

  // Show snackbar message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == OpticoreColors.green500
                  ? Icons.check_circle_outline
                  : color == OpticoreColors.red500
                  ? Icons.error_outline
                  : Icons.info_outline,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opticoreGradient = LinearGradient(
      colors: [OpticoreColors.blue500, OpticoreColors.blue600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: OpticoreColors.gray50,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.print, size: 20),
            SizedBox(width: 8),
            Text(
              'Printer Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: opticoreGradient),
        ),
        elevation: 0,
        actions: [
          // Real-time printer status indicator in app bar
          Consumer<ThermalPrinterService>(
            builder: (context, printerService, child) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: printerService.isConnected 
                      ? Colors.green.withOpacity(0.9)
                      : printerService.connectionStatus == PrinterConnectionStatus.connecting
                      ? Colors.orange.withOpacity(0.9)
                      : Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      printerService.isConnected 
                          ? Icons.print 
                          : printerService.connectionStatus == PrinterConnectionStatus.connecting
                          ? Icons.sync
                          : Icons.print_disabled,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      printerService.isConnected 
                          ? 'Connected'
                          : printerService.connectionStatus == PrinterConnectionStatus.connecting
                          ? 'Connecting...'
                          : 'Disconnected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status card with Consumer for reactive updates
              Consumer<ThermalPrinterService>(
                builder: (context, printerService, child) {
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: OpticoreColors.blue500.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: printerService.isConnected
                                ? OpticoreColors.green500.withOpacity(0.1)
                                : printerService.connectionStatus == PrinterConnectionStatus.connecting
                                ? OpticoreColors.orange500.withOpacity(0.1)
                                : OpticoreColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            printerService.isConnected
                                ? Icons.print
                                : printerService.connectionStatus == PrinterConnectionStatus.connecting
                                ? Icons.sync
                                : Icons.print_disabled,
                            color: printerService.isConnected
                                ? OpticoreColors.green500
                                : printerService.connectionStatus == PrinterConnectionStatus.connecting
                                ? OpticoreColors.orange500
                                : OpticoreColors.gray500,
                            size: 32,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Printer Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: OpticoreColors.gray800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          printerService.printerStatus,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: printerService.isConnected
                                ? OpticoreColors.green500
                                : printerService.connectionStatus == PrinterConnectionStatus.connecting
                                ? OpticoreColors.orange500
                                : OpticoreColors.red500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (printerService.isConnected && printerService.connectedPrinterIp != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: OpticoreColors.blue50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: OpticoreColors.blue200),
                            ),
                            child: Text(
                              '${printerService.connectedPrinterIp}:${printerService.connectedPrinterPort}',
                              style: TextStyle(
                                color: OpticoreColors.blue700,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 24),

              // Printer discovery section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: OpticoreColors.blue500,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Discover Printers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: OpticoreColors.gray800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Scan your WiFi network for available thermal printers',
                      style: TextStyle(
                        color: OpticoreColors.gray600,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Discover button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isDiscovering ? null : _discoverPrinters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OpticoreColors.blue500,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: _isDiscovering
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Icon(Icons.search),
                        label: Text(
                          _isDiscovering ? 'Discovering...' : 'Discover Printers',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Discovered printers list
                    if (_discoveredPrinters.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Found Printers:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: OpticoreColors.gray800,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._discoveredPrinters.map((printer) => Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.print,
                            color: OpticoreColors.blue500,
                          ),
                          title: Text(printer),
                          subtitle: Text('Port: 9100'),
                          trailing: Radio<String>(
                            value: printer,
                            groupValue: _selectedPrinter,
                            onChanged: (value) {
                              setState(() {
                                _selectedPrinter = value;
                                _ipController.text = value ?? '';
                              });
                            },
                            activeColor: OpticoreColors.blue500,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedPrinter = printer;
                              _ipController.text = printer;
                            });
                          },
                        ),
                      )).toList(),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Manual connection section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_ethernet,
                          color: OpticoreColors.blue500,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Manual Connection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: OpticoreColors.gray800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Enter printer IP address and port manually',
                      style: TextStyle(
                        color: OpticoreColors.gray600,
                      ),
                    ),
                    SizedBox(height: 16),

                    // IP Address field
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'Printer IP Address',
                        hintText: '192.168.1.100',
                        prefixIcon: Icon(Icons.computer, color: OpticoreColors.blue500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: OpticoreColors.blue500, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Port field
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        hintText: '9100',
                        prefixIcon: Icon(Icons.router, color: OpticoreColors.blue500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: OpticoreColors.blue500, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),

                    SizedBox(height: 20),

                    // Connection buttons with Consumer for reactive updates
                    Consumer<ThermalPrinterService>(
                      builder: (context, printerService, child) {
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isConnecting ? null : _connectToPrinter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: OpticoreColors.green500,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: _isConnecting
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : Icon(Icons.link),
                                label: Text(
                                  _isConnecting ? 'Connecting...' : 'Connect',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            if (printerService.isConnected) ...[
                              SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _disconnectPrinter,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: OpticoreColors.red500,
                                    side: BorderSide(color: OpticoreColors.red500),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(Icons.link_off),
                                  label: Text(
                                    'Disconnect',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Test print section with Consumer for reactive visibility
              Consumer<ThermalPrinterService>(
                builder: (context, printerService, child) {
                  if (!printerService.isConnected) {
                    return SizedBox.shrink();
                  }
                  
                  return Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.print_outlined,
                              color: OpticoreColors.blue500,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Test Print',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: OpticoreColors.gray800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Print a test receipt to verify the connection',
                          style: TextStyle(
                            color: OpticoreColors.gray600,
                          ),
                        ),
                        SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isTesting ? null : _testPrint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OpticoreColors.orange500,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _isTesting
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Icon(Icons.print),
                            label: Text(
                              _isTesting ? 'Printing...' : 'Print Test Receipt',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
