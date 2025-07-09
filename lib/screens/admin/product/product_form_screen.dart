import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos_app/models/category.dart';
import 'package:pos_app/models/product.dart';
import 'package:pos_app/services/product_service.dart';


class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final String currencySymbol;

  const ProductFormScreen({
    Key? key,
    this.product,
    required this.categories,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  
  // Opticore theme colors
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color darkBlue = const Color(0xFF2563EB);
  final Color lightBlue = const Color(0xFFEFF6FF);
  final Color grayBg = const Color(0xFFF9FAFB);
  final Color borderGray = const Color(0xFFE5E7EB);
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _minSellingPriceController = TextEditingController(); // New controller
  final TextEditingController _maxSellingPriceController = TextEditingController(); // New controller
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  
  // Form state
  int? _selectedCategoryId;
  String _status = 'active';
  File? _imageFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    
    // If editing an existing product, populate the form
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _costPriceController.text = widget.product!.costPrice.toString();
      _minSellingPriceController.text = widget.product!.minSellingPrice?.toString() ?? '';
      _maxSellingPriceController.text = widget.product!.maxSellingPrice?.toString() ?? '';
      _stockController.text = widget.product!.stock.toString();
      _minStockController.text = widget.product!.minStock.toString();
      _selectedCategoryId = widget.product!.categoryId;
      _status = widget.product!.status;
      _currentImageUrl = widget.product!.image;
    } else {
      // Default values for new product
      _stockController.text = '0';
      _minStockController.text = '0';
      
      // Set default category if available
      if (widget.categories.isNotEmpty) {
        _selectedCategoryId = widget.categories.first.id;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _minSellingPriceController.dispose();
    _maxSellingPriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  // Validate the form inputs
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return false;
    }
    
    // Validate price ranges
    final price = double.tryParse(_priceController.text) ?? 0;
    final minPrice = _minSellingPriceController.text.isNotEmpty 
        ? double.tryParse(_minSellingPriceController.text) 
        : null;
    final maxPrice = _maxSellingPriceController.text.isNotEmpty 
        ? double.tryParse(_maxSellingPriceController.text) 
        : null;
    
    if (minPrice != null && minPrice > price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimum selling price must be less than or equal to selling price'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return false;
    }
    
    if (maxPrice != null && maxPrice < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum selling price must be greater than or equal to selling price'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return false;
    }
    
    return true;
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
  
  // Show dialog to pick image source
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source', style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: primaryBlue),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primaryBlue),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Save product (create or update)
  Future<void> _saveProduct() async {
    if (!_validateForm()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Prepare product data
      final Map<String, dynamic> productData = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'category_id': _selectedCategoryId,
        'price': double.parse(_priceController.text),
        'cost_price': double.parse(_costPriceController.text),
        'min_selling_price': _minSellingPriceController.text.isNotEmpty 
            ? double.parse(_minSellingPriceController.text) 
            : null,
        'max_selling_price': _maxSellingPriceController.text.isNotEmpty 
            ? double.parse(_maxSellingPriceController.text) 
            : null,
        'stock': int.parse(_stockController.text),
        'min_stock': int.parse(_minStockController.text),
        'status': _status,
      };
      
      if (widget.product != null) {
        // Update existing product
        await _productService.updateProduct(
          widget.product!.id,
          productData,
          _imageFile,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product updated successfully'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Create new product
        await _productService.createProduct(
          productData,
          _imageFile,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product created successfully'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      
      // Return to previous screen
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: primaryBlue,
        elevation: 2,
      ),
      body: Container(
        color: grayBg,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryBlue))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image - Card with shadow
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: lightBlue,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderGray),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: _imageFile != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(
                                                _imageFile!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : _currentImageUrl != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    _currentImageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Center(
                                                        child: Icon(
                                                          Icons.image_not_supported,
                                                          size: 50,
                                                          color: Colors.grey[400],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 50,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                    ),
                                    Positioned(
                                      bottom: -10,
                                      right: -10,
                                      child: InkWell(
                                        onTap: _showImageSourceDialog,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primaryBlue,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to change image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form fields in a Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name field
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Product Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderGray),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: primaryBlue, width: 2),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter product name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Description field
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: 'Description (optional)',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderGray),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: primaryBlue, width: 2),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              
                              // Category dropdown
                              DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderGray),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: primaryBlue, width: 2),
                                  ),
                                ),
                                value: _selectedCategoryId,
                                items: widget.categories.map((category) {
                                  return DropdownMenuItem<int>(
                                    value: category.id,
                                    child: Text(category.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a category';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Price fields
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceController,
                                      decoration: InputDecoration(
                                        labelText: 'Selling Price',
                                        prefixText: widget.currencySymbol,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: borderGray),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: primaryBlue, width: 2),
                                        ),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid price';
                                        }
                                        if (double.parse(value) <= 0) {
                                          return 'Must be > 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _costPriceController,
                                      decoration: InputDecoration(
                                        labelText: 'Cost Price',
                                        prefixText: widget.currencySymbol,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: borderGray),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: primaryBlue, width: 2),
                                        ),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Invalid price';
                                        }
                                        if (double.parse(value) < 0) {
                                          return 'Must be >= 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Price Range Fields
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: lightBlue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: primaryBlue.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          color: primaryBlue,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Price Range (Optional)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Set minimum and maximum selling prices to allow flexible pricing during sales.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _minSellingPriceController,
                                            decoration: InputDecoration(
                                              labelText: 'Min Selling Price',
                                              prefixText: widget.currencySymbol,
                                              hintText: 'Optional',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: borderGray),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: primaryBlue, width: 2),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                            ],
                                            validator: (value) {
                                              if (value != null && value.isNotEmpty) {
                                                if (double.tryParse(value) == null) {
                                                  return 'Invalid price';
                                                }
                                                if (double.parse(value) < 0) {
                                                  return 'Must be >= 0';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _maxSellingPriceController,
                                            decoration: InputDecoration(
                                              labelText: 'Max Selling Price',
                                              prefixText: widget.currencySymbol,
                                              hintText: 'Optional',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: borderGray),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: primaryBlue, width: 2),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                            ],
                                            validator: (value) {
                                              if (value != null && value.isNotEmpty) {
                                                if (double.tryParse(value) == null) {
                                                  return 'Invalid price';
                                                }
                                                if (double.parse(value) < 0) {
                                                  return 'Must be >= 0';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Stock fields
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _stockController,
                                      decoration: InputDecoration(
                                        labelText: 'Current Stock',
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
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                        if (int.parse(value) < 0) {
                                          return 'Must be >= 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _minStockController,
                                      decoration: InputDecoration(
                                        labelText: 'Min Stock Level',
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
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Invalid number';
                                        }
                                        if (int.parse(value) < 0) {
                                          return 'Must be >= 0';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Status - Card with radio buttons
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Active'),
                                      value: 'active',
                                      groupValue: _status,
                                      activeColor: primaryBlue,
                                      onChanged: (value) {
                                        setState(() {
                                          _status = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Inactive'),
                                      value: 'inactive',
                                      groupValue: _status,
                                      activeColor: primaryBlue,
                                      onChanged: (value) {
                                        setState(() {
                                          _status = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Product info if editing
                      if (isEditing) ...[
                        Card(
                          elevation: 1,
                          color: lightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: primaryBlue.withOpacity(0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SKU: ${widget.product!.sku}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Serial: ${widget.product!.serialNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            isEditing ? 'Update Product' : 'Create Product',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}