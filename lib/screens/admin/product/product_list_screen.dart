import 'package:flutter/material.dart';
import 'package:pos_app/models/category.dart';
import 'package:pos_app/models/product.dart';
import 'package:pos_app/screens/admin/product/stock_movement_screen.dart';
import 'package:pos_app/screens/admin/product/stock_update_dialog.dart';
import 'package:pos_app/services/category_service.dart';
import 'package:pos_app/services/product_service.dart';

import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  // Opticore theme colors
  final Color _primaryBlue = const Color(0xFF3B82F6); // blue-500
  final Color _darkBlue = const Color(0xFF2563EB);    // blue-600

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter and sort state
  String? _statusFilter;
  int? _categoryFilter;
  String? _stockStatusFilter;
  String _sortBy = 'name';
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;

  // Settings
  String _currencySymbol = '\$';
  int _lowStockThreshold = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load app settings
  Future<void> _loadSettings() async {
    // In a real app, you'd load these from a settings service or API
    setState(() {
      _currencySymbol = '\$'; // Default currency symbol
      _lowStockThreshold = 5; // Default low stock threshold
    });
  }

  // Load categories for filter dropdown
  Future<void> _loadCategories() async {
    try {
      final result = await _categoryService.getCategories(status: 'active');
      setState(() {
        _categories = result['categories'];
      });
    } catch (e) {
      print('Error loading categories: $e');
      // Don't set error message, as this is a secondary functionality
    }
  }

  // Load products with current filters
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _productService.getProducts(
        search: _searchController.text,
        categoryId: _categoryFilter,
        status: _statusFilter,
        stockStatus: _stockStatusFilter,
        sort: _sortBy,
        page: _currentPage,
      );

      setState(() {
        _products = result['products'];
        _currentPage = result['current_page'];
        _lastPage = result['last_page'];
        _totalItems = result['total'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  // Handler for search
  void _handleSearch() {
    _currentPage = 1; // Reset to first page on new search
    _loadProducts();
  }

  // Handler for status filter change
  void _handleStatusFilterChange(String? newValue) {
    setState(() {
      _statusFilter = newValue;
      _currentPage = 1; // Reset to first page on filter change
    });
    _loadProducts();
  }

  // Handler for category filter change
  void _handleCategoryFilterChange(int? newValue) {
    setState(() {
      _categoryFilter = newValue;
      _currentPage = 1; // Reset to first page on filter change
    });
    _loadProducts();
  }

  // Handler for stock status filter change
  void _handleStockStatusFilterChange(String? newValue) {
    setState(() {
      _stockStatusFilter = newValue;
      _currentPage = 1; // Reset to first page on filter change
    });
    _loadProducts();
  }

  // Handler for sort change
  void _handleSortChange(String newValue) {
    setState(() {
      _sortBy = newValue;
      _currentPage = 1; // Reset to first page on sort change
    });
    _loadProducts();
  }

  // Navigate to edit product
  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductFormScreen(
              product: product,
              categories: _categories,
              currencySymbol: _currencySymbol,
            ),
      ),
    ).then((_) => _loadProducts()); // Refresh list after returning
  }

  // Navigate to add product
  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductFormScreen(
              categories: _categories,
              currencySymbol: _currencySymbol,
            ),
      ),
    ).then((_) => _loadProducts()); // Refresh list after returning
  }

  // Delete product
  Future<void> _deleteProduct(Product product) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text(
              'Are you sure you want to delete "${product.name}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    // If user confirmed deletion
    if (confirm == true) {
      try {
        await _productService.deleteProduct(product.id);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh list
        _loadProducts();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Update product stock
  // In ProductListScreen
Future<void> _updateStock(Product product) async {
  // Show the enhanced stock update dialog
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => StockUpdateDialog(
      product: product,
      currencySymbol: _currencySymbol,
    ),
  );

  // If user submitted stock update
  if (result != null) {
    try {
      // Construct notes with operation info for better tracking
      String notes = result['notes'] ?? '';
      if (result['operation'] != 'Set to') {
        String operationInfo =
            result['operation'] == 'Add'
                ? 'Added ${result['input_value']} to stock'
                : 'Removed ${result['input_value']} from stock';

        notes = notes.isEmpty ? operationInfo : '$operationInfo - $notes';
      }

      // Update on server
      final updatedProduct = await _productService.updateStock(
        product.id,
        result['stock'],
        notes.isNotEmpty ? notes : null,
      );
      
      // Update the product in the local list immediately
      setState(() {
        // Find and update the product in the existing list
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Stock updated successfully'),
          backgroundColor: Colors.green.shade600,
        ),
      );

      // Refresh list to ensure everything is up to date
      _loadProducts();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating stock: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: _primaryBlue,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_darkBlue, _primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryBlue, width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
                const SizedBox(height: 16),

                // First row of filters
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true, // Fix for overflow
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, // Reduced padding
                            vertical: 8,
                          ),
                        ),
                        value: _categoryFilter,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Categories', overflow: TextOverflow.ellipsis),
                          ),
                          ..._categories
                              .map(
                                (category) => DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(
                                    category.name,
                                    overflow: TextOverflow.ellipsis, // Handle long text
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                        onChanged: _handleCategoryFilterChange,
                      ),
                    ),
                    const SizedBox(width: 12), // Reduced spacing

                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true, // Fix for overflow
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, // Reduced padding
                            vertical: 8,
                          ),
                        ),
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'active',
                            child: Text('Active', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'inactive',
                            child: Text('Inactive', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: _handleStatusFilterChange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Second row of filters
                Row(
                  children: [
                    // Stock status filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true, // Fix for overflow
                        decoration: InputDecoration(
                          labelText: 'Stock',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, // Reduced padding
                            vertical: 8,
                          ),
                        ),
                        value: _stockStatusFilter,
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'in_stock',
                            child: Text('In Stock', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'low_stock',
                            child: Text('Low Stock', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'out_of_stock',
                            child: Text('Out of Stock', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: _handleStockStatusFilterChange,
                      ),
                    ),
                    const SizedBox(width: 12), // Reduced spacing

                    // Sort by dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true, // Fix for overflow
                        decoration: InputDecoration(
                          labelText: 'Sort By',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, // Reduced padding
                            vertical: 8,
                          ),
                        ),
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'name',
                            child: Text('Name', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'price',
                            child: Text('Price', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'stock',
                            child: Text('Stock', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'created_at',
                            child: Text('Newest', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _handleSortChange(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List header with count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: $_totalItems products',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                // Pagination info
                if (!_isLoading && _lastPage > 1)
                  Text(
                    'Page $_currentPage of $_lastPage',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          // Main content - product list or loading indicator
          Expanded(
            child:
                _isLoading
                    ? CircularProgressIndicator(color: _primaryBlue)
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                      color: _primaryBlue,
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final bool isLowStock = product.isLowStock();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side:
                                  isLowStock
                                      ? BorderSide(
                                        color: Colors.red.shade300,
                                        width: 1,
                                      )
                                      : BorderSide.none,
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading:
                                      product.image != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              '${product.image}',
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    color: _primaryBlue,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          : Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.inventory_2_outlined,
                                              color: _primaryBlue,
                                            ),
                                          ),
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    product.category != null
                                        ? product.category['name'] ??
                                            'Unknown Category'
                                        : 'Unknown Category',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          product.status == 'active'
                                              ? _primaryBlue
                                              : Colors.grey,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      product.status.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // SKU and price
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SKU: ${product.sku}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Price: $_currencySymbol${product.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _primaryBlue,
                                              ),
                                            ),
                                            // Show price range if product has flexible pricing
                                            if (product.hasFlexiblePricing()) ...[
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.green.shade200),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.tune,
                                                      size: 12,
                                                      color: Colors.green.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        'Range: ${product.getPriceRangeText(_currencySymbol)}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.green.shade600,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Stock
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.inventory,
                                                size: 16,
                                                color:
                                                    isLowStock
                                                        ? Colors.red.shade600
                                                        : Colors.green.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Stock: ${product.stock}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isLowStock
                                                          ? Colors.red.shade600
                                                          : Colors.green.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Min: ${product.minStock}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Use Wrap instead of ButtonBar to avoid overflow issues
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceEvenly,
                                    spacing: 8,
                                    children: [
                                      TextButton.icon(
                                        icon: Icon(Icons.edit, color: _primaryBlue),
                                        label: Text('Edit', style: TextStyle(color: _primaryBlue)),
                                        onPressed: () => _editProduct(product),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.inventory_2, color: _primaryBlue),
                                        tooltip: 'Stock Management',
                                        onSelected: (value) {
                                          if (value == 'update') {
                                            _updateStock(product);
                                          } else if (value == 'history') {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => StockMovementScreen(
                                                      product: product,
                                                      currencySymbol:
                                                          _currencySymbol,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              PopupMenuItem(
                                                value: 'update',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 20, color: _primaryBlue),
                                                    const SizedBox(width: 8),
                                                    const Text('Update Stock'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'history',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.history, size: 20, color: _primaryBlue),
                                                    const SizedBox(width: 8),
                                                    const Text('Stock History'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Delete'),
                                        onPressed: () => _deleteProduct(product),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),

          // Pagination controls
          if (!_isLoading && _lastPage > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: _currentPage > 1 ? _primaryBlue : Colors.grey.shade400,
                    ),
                    onPressed:
                        _currentPage > 1
                            ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _loadProducts();
                            }
                            : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      '$_currentPage / $_lastPage',
                      style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: _currentPage < _lastPage ? _primaryBlue : Colors.grey.shade400,
                    ),
                    onPressed:
                        _currentPage < _lastPage
                            ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _loadProducts();
                            }
                            : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: _primaryBlue,
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      ),
    );
  }
}