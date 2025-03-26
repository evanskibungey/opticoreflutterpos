// lib/screens/reports/sales_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/services/report_service.dart';
import '../../models/report_models.dart';
import '../../models/sale.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  _SalesReportScreenState createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final ReportService _reportService = ReportService();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = false;
  int _currentPage = 1;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  String _currencySymbol = 'ksh'; // Changed to ksh
  String? _requestId;
  
  // Filter options - changed default to 'today'
  String _selectedDateRange = 'today'; // Changed from 'this_month'
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPaymentMethod;
  int? _selectedCashierId;
  
  // Available options for filters
  final List<Map<String, dynamic>> _dateRangeOptions = [
    {'value': 'today', 'label': 'Today'},
    {'value': 'yesterday', 'label': 'Yesterday'},
    {'value': 'this_week', 'label': 'This Week'},
    {'value': 'last_week', 'label': 'Last Week'},
    {'value': 'this_month', 'label': 'This Month'},
    {'value': 'last_month', 'label': 'Last Month'},
    {'value': 'custom', 'label': 'Custom Range'},
  ];
  
  final List<Map<String, dynamic>> _paymentMethodOptions = [
    {'value': '', 'label': 'All Payment Methods'},
    {'value': 'cash', 'label': 'Cash'},
    {'value': 'card', 'label': 'Card'},
    {'value': 'credit', 'label': 'Credit'},
    {'value': 'mobile', 'label': 'Mobile Money'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadReport();
  }
  
  @override
  void dispose() {
    // Clean up resources
    _reportService.cancelAllRequests();
    super.dispose();
  }
  
  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1; // Reset to first page when applying new filters
    });
    
    // Cancel any previous request
    if (_requestId != null) {
      _reportService.cancelAllRequests();
    }
    
    _requestId = 'sales_report_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // Create filter from current selections with pagination
      final filter = SalesReportFilter(
        dateRange: _selectedDateRange,
        startDate: _startDate,
        endDate: _endDate,
        paymentMethod: _selectedPaymentMethod,
        cashierId: _selectedCashierId,
        page: _currentPage,
        perPage: 50, // Reasonable page size
      );
      
      // Fetch report data
      final reportData = await _reportService.getSalesReport(
        filter,
        requestId: _requestId,
      );
      
      setState(() {
        _reportData = reportData;
        _isLoading = false;
        _hasMoreData = reportData['hasMorePages'] ?? false;
      });
    } catch (e) {
      // Check if this is a cancellation or a real error
      if (e.toString().contains('cancelled')) {
        // Request was cancelled, just return
        return;
      }
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Method to load more sales when scrolling
  Future<void> _loadMoreSales() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final nextPage = (_currentPage + 1);
      _requestId = 'sales_more_${DateTime.now().millisecondsSinceEpoch}';
      
      final filter = SalesReportFilter(
        dateRange: _selectedDateRange,
        startDate: _startDate,
        endDate: _endDate,
        paymentMethod: _selectedPaymentMethod,
        cashierId: _selectedCashierId,
        page: nextPage,
        perPage: 50,
      );
      
      final moreData = await _reportService.getSalesReport(
        filter,
        requestId: _requestId,
        useCache: false, // Don't use cache for pagination
      );
      
      final List<Sale> moreSales = moreData['sales'] ?? [];
      
      setState(() {
        // Append new sales to existing list
        if (_reportData != null) {
          final List<Sale> currentSales = _reportData!['sales'] ?? [];
          currentSales.addAll(moreSales);
          _reportData!['sales'] = currentSales;
        }
        
        _currentPage = nextPage;
        _hasMoreData = moreData['hasMorePages'] ?? false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  Future<void> _exportReport() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Create filter from current selections
      final filter = SalesReportFilter(
        dateRange: _selectedDateRange,
        startDate: _startDate,
        endDate: _endDate,
        paymentMethod: _selectedPaymentMethod,
        cashierId: _selectedCashierId,
        page: 1, // Export all data
        perPage: 1000, // Large page size for export
      );
      
      // Export the report
      final filePath = await _reportService.exportSalesReport(filter);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Share the file
      await _reportService.shareReportFile(filePath);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report exported successfully')),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export report: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          // Export button
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export Report',
            onPressed: _isLoading ? null : _exportReport,
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildReportView(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_errorMessage ?? 'Unknown error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReport,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportView() {
    if (_reportData == null) {
      return const Center(child: Text('No report data available'));
    }
    
    final summary = _reportData!['summary'] as SalesReportSummary;
    final sales = _reportData!['sales'] as List<Sale>? ?? [];
    
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter card
            _buildFiltersCard(),
            const SizedBox(height: 16),
            
            // Summary card
            _buildSummaryCard(summary),
            const SizedBox(height: 16),
            
            // Top Products card
            _buildTopProductsCard(summary.topProducts),
            const SizedBox(height: 16),
            
            // Top Categories card
            _buildTopCategoriesCard(summary.topCategories),
            const SizedBox(height: 16),
            
            // Sales list card
            _buildSalesListCard(sales),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFiltersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Date Range dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Date Range',
                border: OutlineInputBorder(),
              ),
              value: _selectedDateRange,
              items: _dateRangeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDateRange = value!;
                  // If not custom, clear the custom date range
                  if (value != 'custom') {
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
            ),
            
            // Show date pickers if custom date range is selected
            if (_selectedDateRange == 'custom') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (pickedDate != null) {
                          setState(() {
                            _startDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate != null
                              ? _dateFormatter.format(_startDate!)
                              : 'Select Start Date',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        
                        if (pickedDate != null) {
                          setState(() {
                            _endDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endDate != null
                              ? _dateFormatter.format(_endDate!)
                              : 'Select End Date',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Payment Method dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              value: _selectedPaymentMethod ?? '',
              items: _paymentMethodOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!.isEmpty ? null : value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Cashier dropdown (if cashiers are available)
            if (_reportData != null && (_reportData!['cashiers'] as List).isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Cashier',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCashierId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Cashiers'),
                  ),
                  ...(_reportData!['cashiers'] as List).map((cashier) {
                    return DropdownMenuItem<int?>(
                      value: cashier['id'],
                      child: Text(cashier['name']),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCashierId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Apply filters button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadReport,
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(SalesReportSummary summary) {
    final numberFormat = NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Summary stats
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    Icons.receipt,
                    'Total Sales',
                    summary.totalSales.toString(),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    Icons.attach_money,
                    'Total Revenue',
                    numberFormat.format(summary.totalRevenue),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    Icons.shopping_cart,
                    'Items Sold',
                    summary.totalItems.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildTopProductsCard(List<TopProduct> topProducts) {
    final numberFormat = NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2);
    
    if (topProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Products',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('No product data available for the selected period'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Products table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(40),
                  1: IntrinsicColumnWidth(flex: 3),
                  2: IntrinsicColumnWidth(flex: 2),
                  3: IntrinsicColumnWidth(flex: 2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  // Data rows
                  ...topProducts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    
                    return TableRow(
                      decoration: index % 2 == 0
                          ? null
                          : BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${index + 1}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(product.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(product.totalQuantity.toString()),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(numberFormat.format(product.totalRevenue)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopCategoriesCard(List<TopCategory> topCategories) {
    final numberFormat = NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2);
    
    if (topCategories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('No category data available for the selected period'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Categories table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(40),
                  1: IntrinsicColumnWidth(flex: 3),
                  2: IntrinsicColumnWidth(flex: 2),
                  3: IntrinsicColumnWidth(flex: 2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  // Data rows
                  ...topCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final category = entry.value;
                    
                    return TableRow(
                      decoration: index % 2 == 0
                          ? null
                          : BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${index + 1}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(category.name),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(category.totalQuantity.toString()),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(numberFormat.format(category.totalRevenue)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSalesListCard(List<Sale> sales) {
    if (sales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales List',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('No sales found matching the selected filters'),
              ),
            ],
          ),
        ),
      );
    }
    
    final numberFormat = NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales List',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_isLoadingMore)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sales list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sales.length + (_hasMoreData ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                // Load more when reaching near the end
                if (index >= sales.length - 3 && !_isLoadingMore && _hasMoreData) {
                  _loadMoreSales();
                }
                
                // Show loading indicator at the end
                if (index == sales.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                
                // Regular sale item
                final sale = sales[index];
                
                return ListTile(
                  title: Text(
                    'Receipt #${sale.receiptNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Customer: ${sale.customer?.name ?? 'Walk-in'} | '
                    'Items: ${sale.items?.length ?? 0}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        numberFormat.format(sale.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getFormattedDate(sale.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  leading: _getPaymentMethodIcon(sale.paymentMethod),
                  onTap: () {
                    // Navigate to sale details
                    // You could implement this to show a detailed view
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getPaymentMethodIcon(String paymentMethod) {
    final Color iconColor = Theme.of(context).primaryColor;
    
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(Icons.payments, color: iconColor),
        );
      case 'card':
        return CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: const Icon(Icons.credit_card, color: Colors.blue),
        );
      case 'credit':
        return CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: const Icon(Icons.account_balance_wallet, color: Colors.orange),
        );
      case 'mobile':
        return CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.1),
          child: const Icon(Icons.phone_android, color: Colors.purple),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey.withOpacity(0.1),
          child: const Icon(Icons.paid, color: Colors.grey),
        );
    }
  }
  
  String _getFormattedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}