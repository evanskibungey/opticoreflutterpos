// lib/screens/admin/sales/sales_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_app/models/sale.dart';
import 'package:pos_app/screens/sales/sale_details_screen.dart';

import 'package:pos_app/services/sale_service.dart';

// You'll need to implement this

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  _SalesHistoryScreenState createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SaleService _saleService = SaleService();
  final SettingsService _settingsService = SettingsService(); // You'll need to implement this
  final storage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  String? _errorMessage;
  Pagination<Sale>? _salesData;
  String _currencySymbol = 'Ksh'; // Default currency symbol
  
  // Filters
  String? _selectedStatus;
  String? _selectedPaymentMethod;
  String? _searchQuery;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Current page
  int _currentPage = 1;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSalesData();
  }
  
  // Load app settings
  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getSettings();
      if (mounted) {
        setState(() {
          _currencySymbol = settings['currency_symbol'] ?? 'Ksh';
        });
      }
    } catch (e) {
      // Fallback to default if settings can't be loaded
      setState(() {
        _currencySymbol = 'Ksh';
      });
    }
  }
  
  // Load sales data
  Future<void> _loadSalesData({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
      });
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Format dates if selected
      String? startDateStr;
      String? endDateStr;
      
      if (_startDate != null) {
        startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      
      if (_endDate != null) {
        endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      }
      
      final salesData = await _saleService.getSales(
        page: _currentPage,
        status: _selectedStatus,
        paymentMethod: _selectedPaymentMethod,
        search: _searchQuery,
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      setState(() {
        _salesData = salesData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Navigate to previous page
  void _previousPage() {
    if (_salesData != null && _currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadSalesData();
    }
  }
  
  // Navigate to next page
  void _nextPage() {
    if (_salesData != null && _currentPage < _salesData!.lastPage) {
      setState(() {
        _currentPage++;
      });
      _loadSalesData();
    }
  }
  
  // Show filter dialog
  void _showFilterDialog() {
    // Temporary variables to hold filter values
    String? tempStatus = _selectedStatus;
    String? tempPaymentMethod = _selectedPaymentMethod;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Sales'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status filter
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  value: tempStatus,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'voided', child: Text('Voided')),
                    // Add other statuses if needed
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Payment method filter
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  value: tempPaymentMethod,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'credit', child: Text('Credit')),
                    // Add other payment methods if needed
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      tempPaymentMethod = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Date range
                const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Start date
                ListTile(
                  title: Text(tempStartDate != null 
                      ? DateFormat('yyyy-MM-dd').format(tempStartDate!)
                      : 'Start Date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    
                    if (selectedDate != null) {
                      setDialogState(() {
                        tempStartDate = selectedDate;
                      });
                    }
                  },
                ),
                
                // End date
                ListTile(
                  title: Text(tempEndDate != null 
                      ? DateFormat('yyyy-MM-dd').format(tempEndDate!)
                      : 'End Date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: tempEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    
                    if (selectedDate != null) {
                      setDialogState(() {
                        tempEndDate = selectedDate;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            // Clear filters
            TextButton(
              onPressed: () {
                setDialogState(() {
                  tempStatus = null;
                  tempPaymentMethod = null;
                  tempStartDate = null;
                  tempEndDate = null;
                });
              },
              child: const Text('Clear'),
            ),
            // Cancel
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Apply filters
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedStatus = tempStatus;
                  _selectedPaymentMethod = tempPaymentMethod;
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                });
                Navigator.of(context).pop();
                _loadSalesData(resetPage: true);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SaleSearchDelegate(
                  onSearch: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _loadSalesData(resetPage: true);
                  },
                ),
              );
            },
            tooltip: 'Search',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading sales data...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading sales',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _loadSalesData(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildSalesList(),
    );
  }
  
  Widget _buildSalesList() {
    if (_salesData == null || _salesData!.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No sales found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedStatus != null || 
                _selectedPaymentMethod != null || 
                _startDate != null || 
                _endDate != null || 
                _searchQuery != null) ...[
              Text(
                'Try changing your filters',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedPaymentMethod = null;
                    _startDate = null;
                    _endDate = null;
                    _searchQuery = null;
                  });
                  _loadSalesData(resetPage: true);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ] else ...[
              Text(
                'No sales have been recorded yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Active filters display
        if (_selectedStatus != null || 
            _selectedPaymentMethod != null || 
            _startDate != null || 
            _endDate != null || 
            _searchQuery != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: theme.colorScheme.primaryContainer.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filters: ${_buildFilterText()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedPaymentMethod = null;
                      _startDate = null;
                      _endDate = null;
                      _searchQuery = null;
                    });
                    _loadSalesData(resetPage: true);
                  },
                  tooltip: 'Clear filters',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        
        // Sales list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadSalesData(),
            child: ListView.builder(
              itemCount: _salesData!.data.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final sale = _salesData!.data[index];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      ).then((_) {
                        // Refresh data when returning from details
                        _loadSalesData();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Receipt number and status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Receipt #${sale.receiptNumber}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusChip(sale.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Date and Customer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(sale.createdAt),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              if (sale.customer != null)
                                Expanded(
                                  child: Text(
                                    sale.customer!.name,
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Divider
                          Divider(color: Colors.grey.shade300),
                          
                          // Amount and Payment method
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$_currencySymbol ${sale.totalAmount.toStringAsFixed(2)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    sale.paymentMethod == 'cash'
                                        ? Icons.payments_outlined
                                        : Icons.credit_card,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatPaymentMethod(sale.paymentMethod),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Items summary if available
                          if (sale.items != null && sale.items!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${sale.items!.length} ${sale.items!.length == 1 ? 'item' : 'items'}, ${sale.items!.fold<int>(0, (sum, item) => sum + item.quantity)} ${sale.items!.fold<int>(0, (sum, item) => sum + item.quantity) == 1 ? 'unit' : 'units'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Pagination controls
        if (_salesData != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${(_currentPage - 1) * (_salesData!.perPage) + 1} - ${_currentPage * _salesData!.perPage > _salesData!.total ? _salesData!.total : _currentPage * _salesData!.perPage} of ${_salesData!.total}',
                  style: theme.textTheme.bodySmall,
                ),
                Row(
                  children: [
                    // Previous page button
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      tooltip: 'Previous page',
                      visualDensity: VisualDensity.compact,
                    ),
                    
                    // Page indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_currentPage / ${_salesData!.lastPage}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Next page button
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _salesData!.lastPage ? _nextPage : null,
                      tooltip: 'Next page',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  // Build status chip
  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText = status.toUpperCase();
    
    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.green;
        break;
      case 'voided':
        chipColor = Colors.red;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      default:
        chipColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Format payment method for display
  String _formatPaymentMethod(String method) {
    return method.substring(0, 1).toUpperCase() + method.substring(1);
  }
  
  // Format date for display
  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
  
  // Build filter text description
  String _buildFilterText() {
    List<String> filters = [];
    
    if (_selectedStatus != null) {
      filters.add('Status: ${_selectedStatus!.toUpperCase()}');
    }
    
    if (_selectedPaymentMethod != null) {
      filters.add('Payment: ${_formatPaymentMethod(_selectedPaymentMethod!)}');
    }
    
    if (_startDate != null && _endDate != null) {
      filters.add(
        'Date: ${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}',
      );
    } else if (_startDate != null) {
      filters.add('From: ${DateFormat('MMM d').format(_startDate!)}');
    } else if (_endDate != null) {
      filters.add('Until: ${DateFormat('MMM d').format(_endDate!)}');
    }
    
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filters.add('Search: $_searchQuery');
    }
    
    return filters.join(', ');
  }
}

// Search delegate for sales
class SaleSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;
  
  SaleSearchDelegate({required this.onSearch});
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isNotEmpty) {
      onSearch(query);
      close(context, query);
    }
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search by:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.receipt, color: theme.colorScheme.primary),
            title: const Text('Receipt Number'),
            subtitle: const Text('E.g., RCP-20230101-ABCDE'),
            onTap: () {
              showResults(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.person, color: theme.colorScheme.primary),
            title: const Text('Customer Name'),
            subtitle: const Text('E.g., John Doe'),
            onTap: () {
              showResults(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.phone, color: theme.colorScheme.primary),
            title: const Text('Customer Phone'),
            subtitle: const Text('E.g., 1234567890'),
            onTap: () {
              showResults(context);
            },
          ),
        ],
      ),
    );
  }
}

// You'll need to create a SettingsService class to get application settings
class SettingsService {
  final storage = const FlutterSecureStorage();
  
  Future<Map<String, dynamic>> getSettings() async {
    try {
      // This is a placeholder - replace with your actual implementation
      // You could fetch settings from your API or local storage
      return {
        'currency_symbol': 'Ksh',
        'company_name': 'Eldo Gas',
        // Add other settings as needed
      };
    } catch (e) {
      print('Error loading settings: $e');
      // Return defaults if loading fails
      return {
        'currency_symbol': 'Ksh',
        'company_name': 'Eldo Gas',
      };
    }
  }
}