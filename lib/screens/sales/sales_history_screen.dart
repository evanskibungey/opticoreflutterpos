import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_app/models/sale.dart';
import 'package:pos_app/screens/sales/sale_details_screen.dart';
import 'package:pos_app/services/sale_service.dart';
import 'package:pos_app/services/settings_service.dart';
import 'package:pos_app/services/thermal_printer_service.dart';
import 'package:pos_app/widget/printer_status_widget.dart';
import 'package:pos_app/screens/admin/printer_settings_screen.dart';

/// Opticore theme colors - matching web version
class OpticoreColors {
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color green500 = Color(0xFF10B981);
  static const Color red500 = Color(0xFFEF4444);
  static const Color orange500 = Color(0xFFF97316);
  static const Color whatsapp = Color(0xFF25D366);
}

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SaleService _saleService = SaleService();
  final SettingsService _settingsService = SettingsService();
  final storage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String? _errorMessage;
  Pagination<Sale>? _salesData;
  String _currencySymbol = 'KSh'; // Default currency symbol
  
  // Filters
  String? _selectedStatus;
  String? _selectedPaymentMethod;
  String? _searchQuery;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Current page
  int _currentPage = 1;
  
  // Print states for individual sales
  final Map<int, bool> _printingStates = {};
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSalesData();
  }
  
  // Load app settings
  Future<void> _loadSettings() async {
    try {
      final currencySymbol = await _settingsService.getSetting('currency_symbol', defaultValue: 'KSh');
      if (mounted) {
        setState(() {
          _currencySymbol = currencySymbol;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  
  // Load sales data with current filters
  Future<void> _loadSalesData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final sales = await _saleService.getSales(
        page: _currentPage,
        status: _selectedStatus,
        paymentMethod: _selectedPaymentMethod,
        search: _searchQuery,
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
      );
      
      if (mounted) {
        setState(() {
          _salesData = sales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  // Print receipt for a specific sale
  Future<void> _printSaleReceipt(Sale sale) async {
    final printerService = context.read<ThermalPrinterService>();
    
    if (!printerService.isConnected) {
      _showPrinterSetupDialog();
      return;
    }
    
    setState(() {
      _printingStates[sale.id] = true;
    });
    
    try {
      final success = await printerService.printSaleReceipt(
        sale: sale,
        currencySymbol: _currencySymbol,
      );
      
      if (mounted) {
        setState(() {
          _printingStates[sale.id] = false;
        });
        
        if (success) {
          _showSnackBar(
            'Receipt printed successfully!',
            OpticoreColors.green500,
          );
        } else {
          _showSnackBar(
            'Failed to print receipt',
            OpticoreColors.red500,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _printingStates[sale.id] = false;
        });
        _showSnackBar(
          'Print error: ${e.toString()}',
          OpticoreColors.red500,
        );
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
            Icon(Icons.print_disabled, color: OpticoreColors.orange500),
            SizedBox(width: 12),
            Text('Printer Setup Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No thermal printer is connected. Set up a printer to print receipts.',
              style: TextStyle(color: OpticoreColors.gray700),
            ),
            SizedBox(height: 16),
            Text(
              'Setup Steps:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: OpticoreColors.gray800,
              ),
            ),
            SizedBox(height: 8),
            Text('• Connect your thermal printer to WiFi'),
            Text('• Make sure it\'s on the same network'),
            Text('• Configure printer settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
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
              backgroundColor: OpticoreColors.blue500,
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.settings, size: 18),
            label: Text('Setup Printer'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
                  : Icons.error_outline,
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
  
  // Load next page
  void _loadNextPage() {
    if (_salesData != null && _salesData!.currentPage < _salesData!.lastPage) {
      setState(() {
        _currentPage++;
      });
      _loadSalesData();
    }
  }
  
  // Load previous page
  void _loadPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadSalesData();
    }
  }
  
  // Apply filters
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
    _loadSalesData();
  }
  
  // Clear filters
  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPaymentMethod = null;
      _searchQuery = null;
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _loadSalesData();
  }
  
  // Show date picker
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Icon(Icons.history, size: 20),
            SizedBox(width: 8),
            Text(
              'Sales History',
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
          // Printer status indicator in app bar
          AppBarPrinterStatus(showText: false),
          
          // Search button
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.filter_list),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: OpticoreColors.orange500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Printer status banner
          PrinterStatusBanner(),
          
          // Filter summary
          if (_hasActiveFilters()) _buildFilterSummary(),
          
          // Sales list
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                ? _buildErrorState()
                : _salesData == null || _salesData!.data.isEmpty
                ? _buildEmptyState()
                : _buildSalesList(),
          ),
          
          // Pagination
          if (_salesData != null && _salesData!.data.isNotEmpty)
            _buildPagination(),
        ],
      ),
      // Floating printer status for quick access
      floatingActionButton: Consumer<ThermalPrinterService>(
        builder: (context, printerService, child) {
          if (printerService.isConnected) {
            return SizedBox.shrink();
          }
          
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrinterSettingsScreen(),
                ),
              );
            },
            backgroundColor: OpticoreColors.orange500,
            foregroundColor: Colors.white,
            icon: Icon(Icons.print_disabled),
            label: Text('Setup Printer'),
          );
        },
      ),
    );
  }
  
  // Check if there are active filters
  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedPaymentMethod != null ||
        (_searchQuery != null && _searchQuery!.isNotEmpty) ||
        _startDate != null ||
        _endDate != null;
  }
  
  // Build filter summary
  Widget _buildFilterSummary() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OpticoreColors.blue50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OpticoreColors.blue200),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: OpticoreColors.blue700, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filters applied: ${_getFilterSummary()}',
              style: TextStyle(
                color: OpticoreColors.blue700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            style: TextButton.styleFrom(
              foregroundColor: OpticoreColors.blue700,
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('Clear', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
  
  // Get filter summary text
  String _getFilterSummary() {
    List<String> filters = [];
    
    if (_selectedStatus != null) filters.add('Status: $_selectedStatus');
    if (_selectedPaymentMethod != null) filters.add('Payment: $_selectedPaymentMethod');
    if (_searchQuery != null && _searchQuery!.isNotEmpty) filters.add('Search: $_searchQuery');
    if (_startDate != null && _endDate != null) {
      filters.add('Date: ${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}');
    }
    
    return filters.join(', ');
  }
  
  // Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: OpticoreColors.blue500),
          SizedBox(height: 16),
          Text(
            'Loading sales history...',
            style: TextStyle(
              color: OpticoreColors.gray600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build error state
  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: OpticoreColors.red500,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Sales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: OpticoreColors.gray800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: OpticoreColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadSalesData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: OpticoreColors.blue500,
                foregroundColor: Colors.white,
              ),
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: OpticoreColors.gray500,
            ),
            SizedBox(height: 16),
            Text(
              _hasActiveFilters() ? 'No Sales Found' : 'No Sales Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: OpticoreColors.gray800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your filters or search criteria'
                  : 'Sales will appear here once you start making transactions',
              style: TextStyle(
                color: OpticoreColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            if (_hasActiveFilters())
              OutlinedButton.icon(
                onPressed: _clearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: OpticoreColors.blue500,
                  side: BorderSide(color: OpticoreColors.blue500),
                ),
                icon: Icon(Icons.clear),
                label: Text('Clear Filters'),
              ),
          ],
        ),
      ),
    );
  }
  
  // Build sales list
  Widget _buildSalesList() {
    return RefreshIndicator(
      onRefresh: () => _loadSalesData(isRefresh: true),
      color: OpticoreColors.blue500,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _salesData!.data.length,
        itemBuilder: (context, index) {
          final sale = _salesData!.data[index];
          return _buildSaleCard(sale);
        },
      ),
    );
  }
  
  // Build individual sale card
  Widget _buildSaleCard(Sale sale) {
    final isPrinting = _printingStates[sale.id] ?? false;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SaleDetailsScreen(saleId: sale.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with receipt number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Receipt #${sale.receiptNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: OpticoreColors.gray800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(sale.status),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Customer and date info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: OpticoreColors.gray600,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sale.customer?.name?.isEmpty == false ? sale.customer!.name : 'Walk-in Customer',
                      style: TextStyle(
                        color: OpticoreColors.gray700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: OpticoreColors.gray600,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(sale.createdAt),
                    style: TextStyle(
                      color: OpticoreColors.gray600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Amount and payment method
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          color: OpticoreColors.gray600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$_currencySymbol ${sale.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: OpticoreColors.blue700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          color: OpticoreColors.gray600,
                          fontSize: 12,
                        ),
                      ),
                      _buildPaymentMethodChip(sale.paymentMethod),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              Divider(height: 1),
              SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SaleDetailsScreen(saleId: sale.id),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OpticoreColors.blue500,
                        side: BorderSide(color: OpticoreColors.blue500),
                      ),
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text('View Details'),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  // Print button with Consumer for reactive updates
                  Expanded(
                    child: Consumer<ThermalPrinterService>(
                      builder: (context, printerService, child) {
                        return ElevatedButton.icon(
                          onPressed: isPrinting 
                              ? null 
                              : () => _printSaleReceipt(sale),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: printerService.isConnected 
                                ? OpticoreColors.green500 
                                : OpticoreColors.orange500,
                            foregroundColor: Colors.white,
                          ),
                          icon: isPrinting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  printerService.isConnected 
                                      ? Icons.print 
                                      : Icons.print_disabled, 
                                  size: 18,
                                ),
                          label: Text(
                            isPrinting 
                                ? 'Printing...' 
                                : printerService.isConnected 
                                ? 'Print Receipt' 
                                : 'Setup Printer',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build status chip
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = OpticoreColors.green500;
        break;
      case 'voided':
        color = OpticoreColors.red500;
        break;
      case 'pending':
        color = OpticoreColors.orange500;
        break;
      default:
        color = OpticoreColors.gray500;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Build payment method chip
  Widget _buildPaymentMethodChip(String paymentMethod) {
    IconData icon;
    Color color;
    
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        icon = Icons.payments;
        color = OpticoreColors.green500;
        break;
      case 'card':
        icon = Icons.credit_card;
        color = OpticoreColors.blue500;
        break;
      case 'credit':
        icon = Icons.account_balance_wallet;
        color = OpticoreColors.orange500;
        break;
      case 'mobile':
        icon = Icons.phone_android;
        color = Colors.purple;
        break;
      default:
        icon = Icons.payment;
        color = OpticoreColors.gray500;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            paymentMethod.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build pagination
  Widget _buildPagination() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          OutlinedButton.icon(
            onPressed: _currentPage > 1 ? _loadPreviousPage : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: OpticoreColors.blue500,
              side: BorderSide(color: OpticoreColors.blue500),
            ),
            icon: Icon(Icons.chevron_left, size: 18),
            label: Text('Previous'),
          ),
          
          // Page info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: OpticoreColors.blue50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_currentPage of ${_salesData!.lastPage}',
              style: TextStyle(
                color: OpticoreColors.blue700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Next button
          OutlinedButton.icon(
            onPressed: (_salesData!.currentPage < _salesData!.lastPage) ? _loadNextPage : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: OpticoreColors.blue500,
              side: BorderSide(color: OpticoreColors.blue500),
            ),
            icon: Icon(Icons.chevron_right, size: 18),
            label: Text('Next'),
          ),
        ],
      ),
    );
  }
  
  // Format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  // Show search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery ?? '';
        return AlertDialog(
          title: Text('Search Sales'),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'Search by receipt number, customer name...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => tempQuery = value,
            controller: TextEditingController(text: tempQuery),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery.isEmpty ? null : tempQuery;
                });
                Navigator.pop(context);
                _applyFilters();
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }
  
  // Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempStatus = _selectedStatus;
        String? tempPaymentMethod = _selectedPaymentMethod;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Filter Sales'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status filter
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Status'),
                    value: tempStatus,
                    items: ['Completed', 'Voided', 'Pending']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) => setDialogState(() => tempStatus = value),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Payment method filter
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Payment Method'),
                    value: tempPaymentMethod,
                    items: ['Cash', 'Card', 'Credit', 'Mobile']
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) => setDialogState(() => tempPaymentMethod = value),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Date range selector
                  ListTile(
                    title: Text('Date Range'),
                    subtitle: _startDate != null && _endDate != null
                        ? Text('${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}')
                        : Text('Select date range'),
                    trailing: Icon(Icons.date_range),
                    onTap: _selectDateRange,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedPaymentMethod = null;
                      _startDate = null;
                      _endDate = null;
                    });
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = tempStatus;
                      _selectedPaymentMethod = tempPaymentMethod;
                    });
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
