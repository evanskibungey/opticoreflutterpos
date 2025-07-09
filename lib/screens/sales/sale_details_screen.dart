// lib/screens/admin/sales/sale_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/models/sale.dart';
import 'package:pos_app/services/sale_service.dart';
import 'package:pos_app/services/thermal_printer_service.dart';
import 'package:pos_app/screens/admin/printer_settings_screen.dart';

class SaleDetailsScreen extends StatefulWidget {
  final int saleId;
  
  const SaleDetailsScreen({Key? key, required this.saleId}) : super(key: key);

  @override
  _SaleDetailsScreenState createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  final SaleService _saleService = SaleService();
  final ThermalPrinterService _printerService = ThermalPrinterService.instance;
  
  bool _isLoading = true;
  bool _isPrinting = false;
  String? _errorMessage;
  Sale? _sale;
  
  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }
  
  Future<void> _loadSaleDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final sale = await _saleService.getSaleDetails(widget.saleId);
      setState(() {
        _sale = sale;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _showVoidDialog() {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to void this sale? This action cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for voiding',
                hintText: 'Enter the reason for voiding this sale',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason for voiding'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              
              try {
                final success = await _saleService.voidSale(
                  widget.saleId,
                  reasonController.text.trim(),
                );
                
                if (success) {
                  _loadSaleDetails(); // Refresh the details
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sale voided successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to void sale'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Void Sale'),
          ),
        ],
      ),
    );
  }
  
  // Print receipt using thermal printer
  Future<void> _printReceipt() async {
    if (_sale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No sale data available to print'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_printerService.isConnected) {
      _showPrinterSetupDialog();
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final success = await _printerService.printSaleReceipt(
        sale: _sale!,
        currencySymbol: 'KSh',
      );

      if (mounted) {
        setState(() {
          _isPrinting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Receipt printed successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          _showPrintError('Failed to print receipt');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
        _showPrintError('Print error: ${e.toString()}');
      }
    }
  }

  // Show printer setup dialog
  void _showPrinterSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.print, color: Colors.blue),
            SizedBox(width: 12),
            Text('Printer Setup Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No thermal printer is connected. Would you like to set up a printer now?',
            ),
            SizedBox(height: 12),
            Text('- Connect your thermal printer to WiFi'),
            Text('- Make sure it\'s on the same network'),
            Text('- Configure printer settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrinterSettingsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Setup Printer'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Show print error
  void _showPrintError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Setup',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrinterSettingsScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          if (_sale != null && _sale!.status.toLowerCase() != 'voided')
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showVoidDialog,
              tooltip: 'Void Sale',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSaleDetails,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _buildSaleDetails(),
    );
  }
  
  Widget _buildSaleDetails() {
    if (_sale == null) {
      return const Center(
        child: Text('Sale not found'),
      );
    }
    
    final theme = Theme.of(context);
    final currencySymbol = '\$'; // Replace with your app's currency symbol
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Sales Receipt',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_sale!.status.toLowerCase() == 'voided')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red, width: 1),
                            ),
                            child: const Text(
                              'VOIDED',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sale info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Receipt #:'),
                      Text(
                        _sale!.receiptNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date:'),
                      Text(_formatDate(_sale!.createdAt)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cashier:'),
                      Text(_sale!.user?.name ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  
                  // Customer info
                  if (_sale!.customer != null) ...[
                    Text(
                      'Customer Details',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Name:'),
                        Text(_sale!.customer!.name),
                      ],
                    ),
                    if (_sale!.customer!.phone.isNotEmpty && _sale!.customer!.phone != '0000000000') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Phone:'),
                          Text(_sale!.customer!.phone),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                  
                  // Items
                  if (_sale!.items != null && _sale!.items!.isNotEmpty) ...[
                    Text(
                      'Items',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Table header
                    Row(
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Product',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Qty',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Price',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    
                    // Item rows
                    ..._sale!.items!.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product?.name ?? 'Unknown Product'),
                                if (item.serialNumber != null && item.serialNumber!.isNotEmpty)
                                  Text(
                                    'S/N: ${item.serialNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$currencySymbol${item.subtotal.toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    const Divider(),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$currencySymbol${_sale!.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Payment info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Method:'),
                      Text(
                        _formatPaymentMethod(_sale!.paymentMethod),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Status:'),
                      _buildPaymentStatus(_sale!.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          ElevatedButton.icon(
          onPressed: _isPrinting ? null : _printReceipt,
          icon: _isPrinting 
            ? SizedBox(
              width: 16,
            height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.print),
                  label: Text(_isPrinting ? 'Printing...' : 'Print Receipt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality will be implemented soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Format date for display
  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }
  
  // Format payment method for display
  String _formatPaymentMethod(String method) {
    return method.substring(0, 1).toUpperCase() + method.substring(1);
  }
  
  // Build payment status widget
  Widget _buildPaymentStatus(String status) {
    Color statusColor;
    
    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}