import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../../models/category.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category; // Null for create, non-null for edit

  const CategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  _CategoryFormScreenState createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final CategoryService _categoryService = CategoryService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'active';
  
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get _isEditMode => widget.category != null;

  // Opticore theme colors
  final Color _primaryColor = const Color(0xFF3B82F6); // blue-500
  final Color _primaryDarkColor = const Color(0xFF2563EB); // blue-600
  final Color _successColor = const Color(0xFF10B981); // green-500
  final Color _dangerColor = const Color(0xFFEF4444); // red-500
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFF9FAFB); // gray-50

  @override
  void initState() {
    super.initState();
    // If editing, populate the form with category data
    if (_isEditMode) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _status = widget.category!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_isEditMode) {
        // Update existing category
        await _categoryService.updateCategory(
          widget.category!.id,
          _nameController.text,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
          _status,
        );
        
        // Show success message and return to list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Category updated successfully'),
              backgroundColor: _successColor,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new category
        await _categoryService.createCategory(
          _nameController.text,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
          _status,
        );
        
        // Show success message and return to list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Category created successfully'),
              backgroundColor: _successColor,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Category' : 'Add Category'),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // Show delete confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category'),
                    content: const Text('Are you sure you want to delete this category?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: Text(
                          'Delete',
                          style: TextStyle(color: _dangerColor),
                        ),
                        onPressed: () {
                          // Handle delete logic here
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Return to list
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Main form card with shadow
            Container(
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message if any
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _dangerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _dangerColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: _dangerColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: _dangerColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Title
                  Text(
                    _isEditMode ? 'Category Details' : 'New Category',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'Enter category name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                      prefixIcon: Icon(Icons.category, color: _primaryColor),
                      floatingLabelStyle: TextStyle(color: _primaryColor),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Enter category description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _primaryColor),
                      ),
                      prefixIcon: Icon(Icons.description, color: _primaryColor),
                      floatingLabelStyle: TextStyle(color: _primaryColor),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  
                  // Status selector
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        // Active status option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _status = 'active';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _status == 'active' 
                                    ? _successColor.withOpacity(0.1) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.horizontal(
                                  left: const Radius.circular(7),
                                ),
                                border: _status == 'active'
                                    ? Border.all(
                                        color: _successColor,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: _status == 'active' ? _successColor : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontWeight: _status == 'active' ? FontWeight.bold : FontWeight.normal,
                                      color: _status == 'active' ? _successColor : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Divider
                        Container(
                          width: 1,
                          height: 48,
                          color: Colors.grey.shade300,
                        ),
                        
                        // Inactive status option
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _status = 'inactive';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _status == 'inactive' 
                                    ? _dangerColor.withOpacity(0.1) 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.horizontal(
                                  right: const Radius.circular(7),
                                ),
                                border: _status == 'inactive'
                                    ? Border.all(
                                        color: _dangerColor,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color: _status == 'inactive' ? _dangerColor : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Inactive',
                                    style: TextStyle(
                                      fontWeight: _status == 'inactive' ? FontWeight.bold : FontWeight.normal,
                                      color: _status == 'inactive' ? _dangerColor : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit button with gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryDarkColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEditMode ? Icons.save : Icons.add,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEditMode ? 'Update Category' : 'Create Category',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}