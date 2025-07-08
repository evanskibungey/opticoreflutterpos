import 'package:flutter/material.dart';
import 'package:pos_app/models/product.dart';
import 'package:pos_app/services/product_service.dart';

class LowStockScreen extends StatefulWidget {
  final String currencySymbol;
  
  const LowStockScreen({
    Key? key,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  _LowStockScreenState createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  final ProductService _productService = ProductService();
  
  List<Product> _lowStockProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Opticore theme colors
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color darkBlue = const Color(0xFF2563EB);
  final Color lightBlue = const Color(0xFFEFF6FF);
  final Color grayBg = const Color(0xFFF9FAFB);
  final Color borderGray = const Color(0xFFE5E7EB);
  
  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
  }

  Future<void> _loadLowStockProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.getLowStockProducts();
      setState(() {
        _lowStockProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load low stock products: $e';
        _isLoading = false;
      });
    }
  }

  // Update product stock
  Future<void> _updateStock(Product product) async {
    // Controller for new stock value
    final TextEditingController stockController = TextEditingController(text: product.stock.toString());
    final TextEditingController notesController = TextEditingController();
    
    // Show dialog to input new stock value
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock', style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product.name}', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Current stock: ${product.stock}'),
            Text('Minimum stock: ${product.minStock}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'New Stock',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop({
              'stock': int.tryParse(stockController.text) ?? product.stock,
              'notes': notesController.text,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );

    // If user submitted new stock value
    if (result != null) {
      try {
        await _productService.updateStock(
          product.id,
          result['stock'],
          result['notes'].isNotEmpty ? result['notes'] : null,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Stock updated successfully'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Refresh list
        _loadLowStockProducts();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Products'),
        backgroundColor: primaryBlue,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLowStockProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        color: grayBg,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLowStockProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _lowStockProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.green[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No low stock products',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All products have sufficient stock levels',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary header
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: borderGray),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_lowStockProducts.length} products need restock',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red[100]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                        color: Colors.red[800],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Low Stock Alert',
                                        style: TextStyle(
                                          color: Colors.red[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Products list
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _loadLowStockProducts,
                              color: primaryBlue,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _lowStockProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _lowStockProducts[index];
                                  final categoryName = product.category != null 
                                      ? product.category['name'] ?? 'Unknown Category'
                                      : 'Unknown Category';
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.red[100]!,
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 2,
                                    shadowColor: Colors.black.withOpacity(0.1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              // Product image or placeholder
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: lightBlue,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: borderGray),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.05),
                                                      blurRadius: 2,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: product.image != null
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(10),
                                                        child: Image.network(
                                                          product.image!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Icon(
                                                              Icons.inventory_2_outlined,
                                                              color: primaryBlue,
                                                            );
                                                          },
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.inventory_2_outlined,
                                                        color: primaryBlue,
                                                      ),
                                              ),
                                              const SizedBox(width: 16),
                                              
                                              // Product info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.grey[900],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: lightBlue,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        categoryName,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: primaryBlue,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'SKU: ${product.sku}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Price
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: primaryBlue.withOpacity(0.2),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.05),
                                                      blurRadius: 2,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  '${widget.currencySymbol}${product.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: primaryBlue,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // Stock info with progress bar
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: grayBg,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: borderGray),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Current Stock: ${product.stock}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey[900],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(color: borderGray),
                                                      ),
                                                      child: Text(
                                                        'Min Stock: ${product.minStock}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[700],
                                                          fontWeight: FontWeight.w500
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: product.minStock > 0
                                                        ? (product.stock / product.minStock).clamp(0.0, 1.0)
                                                        : 0,
                                                    backgroundColor: Colors.grey[300],
                                                    color: _getStockStatusColor(product),
                                                    minHeight: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Action button
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _updateStock(product),
                                              icon: const Icon(Icons.add_shopping_cart),
                                              label: const Text('Restock Now'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryBlue,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                elevation: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
  
  // Helper method to get color based on stock level
  Color _getStockStatusColor(Product product) {
    if (product.stock == 0) {
      return Colors.red[600]!;
    } else if (product.stock <= product.minStock * 0.5) {
      return Colors.orange[600]!;
    } else {
      return Colors.yellow[700]!;
    }
  }
}