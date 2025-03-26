import 'package:flutter/material.dart';
import 'package:pos_app/models/product.dart';
import 'package:pos_app/services/product_service.dart';

class StockMovementScreen extends StatefulWidget {
  final Product product;
  final String currencySymbol;

  const StockMovementScreen({
    Key? key,
    required this.product,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  _StockMovementScreenState createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final ProductService _productService = ProductService();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _movements = [];
  dynamic _productDetails;

  @override
  void initState() {
    super.initState();
    _loadStockMovements();
  }

  Future<void> _loadStockMovements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _productService.getStockMovements(widget.product.id);

      setState(() {
        _movements = result['data'] ?? [];
        _productDetails = result['product'];
        _isLoading = false;
      });
    } catch (e) {
      print('Stock movement screen error: $e');
      setState(() {
        _errorMessage =
            'Failed to load stock movements. Please try again later.';
        _isLoading = false;
        _movements = []; // Ensure this is initialized even on error
      });
    }
  }

  // Helper method to format dates
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  // Helper to get movement type color
  Color _getMovementColor(String type) {
    switch (type.toLowerCase()) {
      case 'in':
        return Colors.green;
      case 'out':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper to get readable reference type
  String _getReadableReferenceType(String? refType) {
    if (refType == null) return 'Unknown';

    // Convert snake_case or camelCase to readable format
    String result = refType
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([A-Z])'), (Match m) => ' ${m.group(0)}');

    // Capitalize first letter
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock History: ${widget.product.name}'),
        backgroundColor: Colors.orange.shade500,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStockMovements,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                children: [
                  // Product info card
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    widget.product.image != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            widget.product.image!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.inventory_2_outlined,
                                              );
                                            },
                                          ),
                                        )
                                        : const Icon(
                                          Icons.inventory_2_outlined,
                                        ),
                              ),
                              const SizedBox(width: 16),

                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SKU: ${widget.product.sku}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Category: ${widget.product.category != null ? widget.product.category['name'] : 'Unknown'}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Stock info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStockInfoItem(
                                'Current Stock',
                                '${widget.product.stock}',
                                Colors.blue,
                              ),
                              _buildStockInfoItem(
                                'Min Stock',
                                '${widget.product.minStock}',
                                Colors.orange,
                              ),
                              _buildStockInfoItem(
                                'Price',
                                '${widget.currencySymbol}${widget.product.price}',
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Header for stock movement list
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock Movement History (${_movements.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Here you could navigate to the stock update screen if desired
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Update Stock'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stock movement list
                  Expanded(
                    child:
                        _movements.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _errorMessage != null
                                        ? Icons.error_outline
                                        : Icons.history,
                                    size: 64,
                                    color:
                                        _errorMessage != null
                                            ? Colors.red.shade300
                                            : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage ?? 'No stock movements found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _errorMessage != null
                                              ? Colors.red.shade700
                                              : null,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ElevatedButton.icon(
                                        onPressed: _loadStockMovements,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Try Again'),
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _movements.length,
                              itemBuilder: (context, index) {
                                final movement = _movements[index];
                                final type =
                                    movement['type'] as String? ?? 'unknown';
                                final quantity = movement['quantity'] ?? 0;
                                final refType =
                                    movement['reference_type'] as String? ??
                                    'manual';
                                final createdAt =
                                    movement['created_at'] as String? ?? '';
                                final notes =
                                    movement['notes'] as String? ?? '';

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getMovementColor(
                                        type,
                                      ).withOpacity(0.2),
                                      child: Icon(
                                        type.toLowerCase() == 'in'
                                            ? Icons.add
                                            : Icons.remove,
                                        color: _getMovementColor(type),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          type.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getMovementColor(type),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${type.toLowerCase() == 'in' ? '+' : '-'}$quantity units',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getReadableReferenceType(refType),
                                        ),
                                        if (notes.isNotEmpty)
                                          Text(
                                            notes,
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        Text(
                                          'Date: ${_formatDate(createdAt)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: notes.isNotEmpty,
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStockInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }
}
