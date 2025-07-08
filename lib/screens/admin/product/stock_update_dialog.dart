import 'package:flutter/material.dart';
import 'package:pos_app/models/product.dart';


class StockUpdateDialog extends StatefulWidget {
  final Product product;
  final String currencySymbol;

  const StockUpdateDialog({
    Key? key,
    required this.product,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  _StockUpdateDialogState createState() => _StockUpdateDialogState();
}

class _StockUpdateDialogState extends State<StockUpdateDialog> {
  // Opticore theme colors
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color darkBlue = const Color(0xFF2563EB);
  final Color lightBlue = const Color(0xFFEFF6FF);
  final Color grayBg = const Color(0xFFF9FAFB);
  final Color borderGray = const Color(0xFFE5E7EB);
  
  late TextEditingController _stockController;
  final TextEditingController _notesController = TextEditingController();
  final List<String> _stockOperations = ['Set to', 'Add', 'Remove'];
  String _selectedOperation = 'Set to';
  int _calculatedStock = 0;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _calculatedStock = widget.product.stock;
    _updateCalculatedStock();
  }

  @override
  void dispose() {
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCalculatedStock() {
    final int inputValue = int.tryParse(_stockController.text) ?? 0;
    
    setState(() {
      switch (_selectedOperation) {
        case 'Set to':
          _calculatedStock = inputValue;
          break;
        case 'Add':
          _calculatedStock = widget.product.stock + inputValue;
          break;
        case 'Remove':
          _calculatedStock = widget.product.stock - inputValue;
          // Ensure stock doesn't go negative
          if (_calculatedStock < 0) _calculatedStock = 0;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Update Stock',
        style: TextStyle(
          color: Colors.grey[900],
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info in a styled container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryBlue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product: ${widget.product.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${widget.product.sku}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current stock: ${widget.product.stock}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderGray),
                        ),
                        child: Text(
                          'Min stock: ${widget.product.minStock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Operation type selector with improved styling
            Row(
              children: [
                Text(
                  'Operation:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedOperation,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    items: _stockOperations.map((operation) {
                      return DropdownMenuItem<String>(
                        value: operation,
                        child: Text(operation),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedOperation = value;
                          // Reset input value to make it more intuitive
                          if (value == 'Set to') {
                            _stockController.text = widget.product.stock.toString();
                          } else {
                            _stockController.text = '0';
                          }
                          _updateCalculatedStock();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stock input with improved styling
            TextField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: _selectedOperation == 'Set to' 
                  ? 'New Stock Value' 
                  : (_selectedOperation == 'Add' ? 'Add to Stock' : 'Remove from Stock'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryBlue, width: 2),
                ),
                helperText: _selectedOperation == 'Set to'
                  ? 'Enter the total new stock value'
                  : (_selectedOperation == 'Add' 
                    ? 'Enter amount to add to current stock'
                    : 'Enter amount to remove from current stock'),
                helperStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateCalculatedStock(),
            ),
            const SizedBox(height: 16),
            
            // Calculated result with improved styling
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: grayBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderGray),
              ),
              child: Row(
                children: [
                  Text(
                    'Resulting stock:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500, 
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _calculatedStock < widget.product.minStock 
                        ? Colors.red[50] 
                        : Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _calculatedStock < widget.product.minStock 
                          ? Colors.red[200]! 
                          : Colors.green[200]!,
                      ),
                    ),
                    child: Text(
                      '$_calculatedStock',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _calculatedStock < widget.product.minStock 
                          ? Colors.red[700] 
                          : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes with improved styling
            TextField(
              controller: _notesController,
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
                hintText: 'Reason for adjustment',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              maxLines: 3,
            ),
          ],
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
            Navigator.of(context).pop({
              'stock': _calculatedStock,
              'notes': _notesController.text,
              'operation': _selectedOperation,
              'input_value': int.tryParse(_stockController.text) ?? 0,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('UPDATE STOCK'),
        ),
      ],
    );
  }
}