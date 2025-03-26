import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/services/report_service.dart';
import 'package:pos_app/services/settings_service.dart';
import '../../models/report_models.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({Key? key}) : super(key: key);

  @override
  _InventoryReportScreenState createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  final ReportService _reportService = ReportService();
  final SettingsService _settingsService = SettingsService();
  final ProductService _productService = ProductService();
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = false;
  int _currentPage = 1;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;
  String _currencySymbol = 'Ksh'; // Default currency symbol
  String? _requestId;
  String _searchQuery = '';
  bool _isGridView = false;
  String _sortBy = 'name'; // Default sort field
  bool _sortAscending = true; // Default sort direction
  
  // Filter options
  String? _selectedCategory;
  String _selectedStockStatus = 'all'; // 'all', 'in', 'low', 'out'
  
  // Quick filters
  bool _showLowStock = false;
  bool _showOutOfStock = false;
  
  // Available options for filters
  List<Map<String, dynamic>> _stockStatusOptions = [
    {'value': 'all', 'label': 'All Stock Levels'},
    {'value': 'in', 'label': 'In Stock'},
    {'value': 'low', 'label': 'Low Stock'},
    {'value': 'out', 'label': 'Out of Stock'},
  ];
  
  List<Map<String, dynamic>> _categoriesOptions = [
    {'id': null, 'name': 'All Categories'},
  ];

  // Controller for search field
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadReport();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _reportService.cancelAllRequests();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    try {
      // Get the currency symbol from settings
      final settings = await _settingsService.getSettings();
      setState(() {
        _currencySymbol = settings['currency_symbol'] ?? 'Ksh';
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
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
    
    _requestId = 'inventory_report_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      // Create filter from current selections with pagination
      final filter = InventoryReportFilter(
        category: _selectedCategory,
        stockStatus: _selectedStockStatus != 'all' ? _selectedStockStatus : null,
        page: _currentPage,
        perPage: 50, // Reasonable page size
      );
      
      // Fetch report data
      final reportData = await _reportService.getInventoryReport(
        filter,
        requestId: _requestId,
      );
      
      // Debug the API response structure
      print('API Response Structure: ${reportData.keys}');
      print('Products Count: ${(reportData['products'] as List?)?.length ?? 0}');
      print('Has More Pages: ${reportData['hasMorePages']}');
      print('Current Page: ${reportData['current_page']}');
      print('Last Page: ${reportData['last_page']}');
      
      // Update categories options from the response
      if (reportData['categories'] != null) {
        setState(() {
          _categoriesOptions = [
            {'id': null, 'name': 'All Categories'},
            ...List<Map<String, dynamic>>.from(reportData['categories']),
          ];
        });
      }
      
      setState(() {
        _reportData = reportData;
        _isLoading = false;
        // Use the hasMorePages property now provided by the API
        _hasMoreData = reportData['hasMorePages'] ?? false;
        
        // If hasMorePages is still null, try alternative property names
        if (reportData['hasMorePages'] == null) {
          // Try to determine pagination status from other properties
          final currentPage = reportData['current_page'] as int?;
          final lastPage = reportData['last_page'] as int?;
          if (currentPage != null && lastPage != null) {
            _hasMoreData = currentPage < lastPage;
          }
        }
      });
    } catch (e) {
      // Check if this is a cancellation or a real error
      if (e.toString().contains('cancelled')) {
        // Request was cancelled, just return
        return;
      }
      
      print('Error loading inventory report: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Method to load more products when scrolling
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final nextPage = (_currentPage + 1);
      _requestId = 'inventory_more_${DateTime.now().millisecondsSinceEpoch}';
      
      final filter = InventoryReportFilter(
        category: _selectedCategory,
        stockStatus: _selectedStockStatus != 'all' ? _selectedStockStatus : null,
        page: nextPage,
        perPage: 50,
      );
      
      final moreData = await _reportService.getInventoryReport(
        filter,
        requestId: _requestId,
        useCache: false, // Don't use cache for pagination
      );
      
      // Debug pagination information
      print('Load More - Page $nextPage');
      print('Has More Pages: ${moreData['hasMorePages']}');
      print('Current Page: ${moreData['current_page']}');
      print('Last Page: ${moreData['last_page']}');
      
      final List<Product> moreProducts = moreData['products'] ?? [];
      print('Loaded ${moreProducts.length} more products');
      
      setState(() {
        // Append new products to existing list
        if (_reportData != null) {
          final List<Product> currentProducts = _reportData!['products'] ?? [];
          currentProducts.addAll(moreProducts);
          _reportData!['products'] = currentProducts;
        }
        
        _currentPage = nextPage;
        // Use the hasMorePages property now provided by the API
        _hasMoreData = moreData['hasMorePages'] ?? false;
        
        // Fallback logic if hasMorePages is null
        if (moreData['hasMorePages'] == null) {
          final currentPage = moreData['current_page'] as int?;
          final lastPage = moreData['last_page'] as int?;
          if (currentPage != null && lastPage != null) {
            _hasMoreData = currentPage < lastPage;
          }
        }
        
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more products: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  // Filter products by search query
  List<Product> _getFilteredProducts(List<Product> allProducts) {
    if (_searchQuery.isEmpty && !_showLowStock && !_showOutOfStock) {
      return allProducts;
    }
    
    return allProducts.where((product) {
      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty || 
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.sku.toLowerCase().contains(_searchQuery.toLowerCase());
          
      // Apply quick filters
      final matchesLowStock = !_showLowStock || 
          (product.stock > 0 && product.stock <= product.minStock);
      
      final matchesOutOfStock = !_showOutOfStock || product.stock <= 0;
      
      return matchesSearch && matchesLowStock && matchesOutOfStock;
    }).toList();
  }
  
  // Sort products based on current sort preferences
  List<Product> _getSortedProducts(List<Product> products) {
    final sortedProducts = List<Product>.from(products);
    
    switch (_sortBy) {
      case 'name':
        sortedProducts.sort((a, b) => _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case 'sku':
        sortedProducts.sort((a, b) => _sortAscending
            ? a.sku.compareTo(b.sku)
            : b.sku.compareTo(a.sku));
        break;
      case 'stock':
        sortedProducts.sort((a, b) => _sortAscending
            ? a.stock.compareTo(b.stock)
            : b.stock.compareTo(a.stock));
        break;
      case 'price':
        sortedProducts.sort((a, b) => _sortAscending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case 'value':
        sortedProducts.sort((a, b) {
          final aValue = a.stock * a.price;
          final bValue = b.stock * b.price;
          return _sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        });
        break;
    }
    
    return sortedProducts;
  }
  
  // Export report
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
      final filter = InventoryReportFilter(
        category: _selectedCategory,
        stockStatus: _selectedStockStatus != 'all' ? _selectedStockStatus : null,
        page: 1, // Export all data
        perPage: 1000, // Large page size for export
      );
      
      // Export the report
      final filePath = await _reportService.exportInventoryReport(filter);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Share the file
      await _reportService.shareReportFile(filePath);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory report exported successfully')),
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
  
  // Stock update functionality
  void _showStockUpdateDialog(Product product) {
    int newStock = product.stock;
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.edit_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Update Stock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'SKU: ${product.sku}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Stock:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor(product).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStockStatusColor(product).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            product.stock.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStockStatusColor(product),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'New Stock Level',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: product.stock.toString(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      hintText: 'Enter new stock value',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a stock value';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        newStock = int.parse(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  Navigator.of(context).pop(newStock);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('UPDATE'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null) {
        _updateProductStock(product.id, value);
      }
    });
  }

  Future<void> _updateProductStock(int productId, int newStock) async {
    try {
      // Show loading indicator
      _showLoadingDialog('Updating stock...');
      
      // Use the existing ProductService.updateStock method
      final updatedProduct = await _productService.updateStock(
        productId,
        newStock,
        'Manual adjustment from Inventory Report' // Notes parameter
      );
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Stock updated successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      // Reload the report to show updated data
      _loadReport();
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to update stock: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper function to get color based on stock status
  Color _getStockStatusColor(Product product) {
    if (product.stock <= 0) {
      return Colors.red;
    } else if (product.stock <= product.minStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        elevation: 0,
        actions: [
          // View toggle
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: _isLoading ? null : () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
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
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'clear_filters') {
                setState(() {
                  _selectedCategory = null;
                  _selectedStockStatus = 'all';
                  _showLowStock = false;
                  _showOutOfStock = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
                _loadReport();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_off, size: 20, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Clear all filters'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 16),
                  Text('Loading inventory data...'),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildReportView(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReport,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.refresh),
              label: Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportView() {
    if (_reportData == null) {
      return const Center(child: Text('No report data available'));
    }
    
    final summary = _reportData!['summary'] as InventoryReportSummary;
    List<Product> products = _reportData!['products'] as List<Product>? ?? [];
    
    // Apply search filter and quick filters
    final filteredProducts = _getFilteredProducts(products);
    
    // Apply sorting
    final sortedProducts = _getSortedProducts(filteredProducts);
    
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Quick filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Filter toggle
                ActionChip(
                  avatar: Icon(
                    Icons.filter_list,
                    size: 18,
                    color: Colors.blue,
                  ),
                  label: Text('Filters'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => _buildFiltersBottomSheet(),
                    );
                  },
                ),
                const SizedBox(width: 8),
                
                // Low stock filter chip
                FilterChip(
                  label: Text('Low Stock'),
                  selected: _showLowStock,
                  selectedColor: Colors.orange.withOpacity(0.2),
                  checkmarkColor: Colors.orange,
                  avatar: Icon(
                    Icons.warning_amber_outlined,
                    size: 18,
                    color: _showLowStock ? Colors.orange : Colors.grey,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _showLowStock = selected;
                      if (selected) {
                        // Uncheck conflicting filter
                        _showOutOfStock = false;
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                
                // Out of stock filter chip
                FilterChip(
                  label: Text('Out of Stock'),
                  selected: _showOutOfStock,
                  selectedColor: Colors.red.withOpacity(0.2),
                  checkmarkColor: Colors.red,
                  avatar: Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 18,
                    color: _showOutOfStock ? Colors.red : Colors.grey,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _showOutOfStock = selected;
                      if (selected) {
                        // Uncheck conflicting filter
                        _showLowStock = false;
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                
                // Sort dropdown
                Container(
                  height: 32,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isDense: true,
                      icon: Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                      ),
                      hint: Text('Sort by'),
                      items: [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'sku', child: Text('SKU')),
                        DropdownMenuItem(value: 'stock', child: Text('Stock')),
                        DropdownMenuItem(value: 'price', child: Text('Price')),
                        DropdownMenuItem(value: 'value', child: Text('Value')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            if (_sortBy == value) {
                              // Toggle direction if same field
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = value;
                              _sortAscending = true;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Results count and loading indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${sortedProducts.length} items',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                if (_isLoadingMore)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  ),
              ],
            ),
          ),
          
          // Summary cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _buildSummaryCards(summary),
          ),
          
          // Products list
          Expanded(
            child: _isGridView
                ? _buildProductsGrid(sortedProducts)
                : _buildProductsList(sortedProducts),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFiltersBottomSheet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Reset'),
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _selectedStockStatus = 'all';
                  });
                  Navigator.pop(context);
                  _loadReport();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Category',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          
          // Category dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: InputBorder.none,
                ),
                isExpanded: true,
                value: _selectedCategory,
                items: _categoriesOptions.map((option) {
                  return DropdownMenuItem<String?>(
                    value: option['id']?.toString(),
                    child: Text(option['name'] ?? 'All Categories'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Stock Status',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          
          // Stock Status dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: InputBorder.none,
                ),
                isExpanded: true,
                value: _selectedStockStatus,
                items: _stockStatusOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(option['label']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStockStatus = value!;
                  });
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Apply filters button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadReport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'APPLY FILTERS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCards(InventoryReportSummary summary) {
    final numberFormat = NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2);
    
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSummaryCard(
            'Total Products',
            summary.totalProducts.toString(),
            Icons.inventory_2_outlined,
            Colors.blue,
          ),
          _buildSummaryCard(
            'Total Value',
            numberFormat.format(summary.totalValue),
            Icons.monetization_on_outlined,
            Colors.green,
          ),
          _buildSummaryCard(
            'Low Stock',
            summary.lowStockCount.toString(),
            Icons.warning_amber_outlined,
            Colors.orange,
          ),
          _buildSummaryCard(
            'Out of Stock',
            summary.outOfStockCount.toString(),
            Icons.remove_shopping_cart_outlined,
            Colors.red,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              // Optional: Add a trend indicator
              Icon(
                Icons.trending_up, // or trending_down based on your data
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  




  Widget _buildProductsList(List<Product> products) {
    final numberFormat = NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2);
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // Load more when reaching near the end
        if (index >= products.length - 5 && !_isLoadingMore && _hasMoreData) {
          _loadMoreProducts();
        }
        
        // Show loading indicator at the end
        if (index == products.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Regular product item
        final product = products[index];
        
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showStockUpdateDialog(product),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image or placeholder
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product.image != null && product.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey,
                                size: 30,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey,
                            size: 30,
                          ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'SKU: ${product.sku}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Stock status indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStockStatusColor(product).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getStockStatusColor(product).withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    product.stock <= 0
                                        ? Icons.inventory
                                        : Icons.inventory_2,
                                    size: 16,
                                    color: _getStockStatusColor(product),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    product.stock.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getStockStatusColor(product),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Additional product info in a row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    product.getCategoryName(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    numberFormat.format(product.price),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Value',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    numberFormat.format(product.stock * product.price),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Edit button
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Update Stock',
                      color: Colors.blue,
                      onPressed: () => _showStockUpdateDialog(product),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    final numberFormat = NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2);
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // Load more when reaching near the end
        if (index >= products.length - 4 && !_isLoadingMore && _hasMoreData) {
          _loadMoreProducts();
        }
        
        // Show loading indicator at the end
        if (index == products.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Regular product item
        final product = products[index];
        
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showStockUpdateDialog(product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product image or placeholder
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.grey[200],
                          child: product.image != null && product.image!.isNotEmpty
                              ? Image.network(
                                  product.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                        ),
                        
                        // Stock status badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStockStatusColor(product).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              product.stock <= 0
                                  ? 'Out of Stock'
                                  : product.stock <= product.minStock
                                      ? 'Low Stock'
                                      : 'In Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        
                        // Edit button
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              iconSize: 18,
                              padding: EdgeInsets.all(6),
                              constraints: BoxConstraints(),
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Update Stock',
                              color: Colors.blue,
                              onPressed: () => _showStockUpdateDialog(product),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Product details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        Spacer(),
                        
                        // Price and stock row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  numberFormat.format(product.price),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Stock',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  product.stock.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _getStockStatusColor(product),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}