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
        title: const Text('Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product.name}'),
            const SizedBox(height: 8),
            Text('Current stock: ${product.stock}'),
            Text('Minimum stock: ${product.minStock}'),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: 'New Stock',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop({
              'stock': int.tryParse(stockController.text) ?? product.stock,
              'notes': notesController.text,
            }),
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
          const SnackBar(
            content: Text('Stock updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh list
        _loadLowStockProducts();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
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
        backgroundColor: Colors.orange.shade500,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLowStockProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _lowStockProducts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No low stock products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All products have sufficient stock levels',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_lowStockProducts.length} products need restock',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: Colors.red.shade800,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Low Stock Alert',
                                      style: TextStyle(
                                        color: Colors.red.shade800,
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
                            child: ListView.builder(
                              itemCount: _lowStockProducts.length,
                              itemBuilder: (context, index) {
                                final product = _lowStockProducts[index];
                                final categoryName = product.category != null 
                                    ? product.category['name'] ?? 'Unknown Category'
                                    : 'Unknown Category';
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.red.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Product image or placeholder
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: product.image != null
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        product.image!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return const Icon(Icons.inventory_2_outlined);
                                                        },
                                                      ),
                                                    )
                                                  : const Icon(Icons.inventory_2_outlined),
                                            ),
                                            const SizedBox(width: 16),
                                            
                                            // Product info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    categoryName,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'SKU: ${product.sku}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Price
                                            Text(
                                              '${widget.currencySymbol}${product.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Stock info with progress bar
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Current Stock: ${product.stock}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Min Stock: ${product.minStock}',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  LinearProgressIndicator(
                                                    value: product.minStock > 0
                                                        ? (product.stock / product.minStock).clamp(0.0, 1.0)
                                                        : 0,
                                                    backgroundColor: Colors.grey.shade300,
                                                    color: _getStockStatusColor(product),
                                                    minHeight: 8,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                                              backgroundColor: Colors.orange.shade500,
                                              foregroundColor: Colors.white,
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
    );
  }
  
  // Helper method to get color based on stock level
  Color _getStockStatusColor(Product product) {
    if (product.stock == 0) {
      return Colors.red;
    } else if (product.stock <= product.minStock * 0.5) {
      return Colors.orange;
    } else {
      return Colors.yellow.shade700;
    }
  }
}