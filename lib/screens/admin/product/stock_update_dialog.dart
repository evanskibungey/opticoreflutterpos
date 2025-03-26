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
      title: const Text('Update Stock'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product info
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
            Text(
              'Current stock: ${widget.product.stock}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Min stock level: ${widget.product.minStock}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            
            const Divider(height: 24),
            
            // Operation type selector
            Row(
              children: [
                const Text('Operation:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedOperation,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
            
            // Stock input
            TextField(
              controller: _stockController,
              decoration: InputDecoration(
                labelText: _selectedOperation == 'Set to' 
                  ? 'New Stock Value' 
                  : (_selectedOperation == 'Add' ? 'Add to Stock' : 'Remove from Stock'),
                border: const OutlineInputBorder(),
                helperText: _selectedOperation == 'Set to'
                  ? 'Enter the total new stock value'
                  : (_selectedOperation == 'Add' 
                    ? 'Enter amount to add to current stock'
                    : 'Enter amount to remove from current stock'),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateCalculatedStock(),
            ),
            const SizedBox(height: 8),
            
            // Calculated result
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Text(
                    'Resulting stock:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '$_calculatedStock',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _calculatedStock < widget.product.minStock 
                        ? Colors.red 
                        : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                hintText: 'Reason for adjustment',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
            backgroundColor: Colors.orange.shade500,
            foregroundColor: Colors.white,
          ),
          child: const Text('UPDATE STOCK'),
        ),
      ],
    );
  }
}