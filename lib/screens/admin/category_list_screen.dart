import 'package:flutter/material.dart';
import '../../services/category_service.dart';
import '../../models/category.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({Key? key}) : super(key: key);

  @override
  _CategoryListScreenState createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter and sort state
  String? _statusFilter;
  String _sortBy = 'name';
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;

  // Opticore theme colors
  final Color _primaryColor = const Color(0xFF3B82F6); // blue-500
  final Color _primaryDarkColor = const Color(0xFF2563EB); // blue-600
  final Color _successColor = const Color(0xFF10B981); // green-500
  final Color _dangerColor = const Color(0xFFEF4444); // red-500
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFF9FAFB); // gray-50
  final Color _secondaryColor = const Color(0xFF6366F1); // indigo-500

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load categories with current filters
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _categoryService.getCategories(
        search: _searchController.text,
        status: _statusFilter,
        sort: _sortBy,
        page: _currentPage,
      );
      
      setState(() {
        _categories = result['categories'];
        _currentPage = result['current_page'];
        _lastPage = result['last_page'];
        _totalItems = result['total'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
        _isLoading = false;
      });
    }
  }

  // Handler for search
  void _handleSearch() {
    _currentPage = 1; // Reset to first page on new search
    _loadCategories();
  }

  // Handler for status filter change
  void _handleStatusFilterChange(String? newValue) {
    setState(() {
      _statusFilter = newValue;
      _currentPage = 1; // Reset to first page on filter change
    });
    _loadCategories();
  }

  // Handler for sort change
  void _handleSortChange(String newValue) {
    setState(() {
      _sortBy = newValue;
      _currentPage = 1; // Reset to first page on sort change
    });
    _loadCategories();
  }

  // Navigate to edit category
  void _editCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(category: category),
      ),
    ).then((_) => _loadCategories()); // Refresh list after returning
  }

  // Navigate to add category
  void _addCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(),
      ),
    ).then((_) => _loadCategories()); // Refresh list after returning
  }

  // Delete category
  Future<void> _deleteCategory(Category category) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: _dangerColor),
            child: const Text('DELETE'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // If user confirmed deletion
    if (confirm == true) {
      try {
        await _categoryService.deleteCategory(category.id);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category deleted successfully'),
              backgroundColor: _successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        
        // Refresh list
        _loadCategories();
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: _dangerColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filters container with shadow
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch();
                      },
                    ),
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
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
                const SizedBox(height: 16),
                
                // Filters row
                Row(
                  children: [
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: TextStyle(color: Colors.grey.shade700),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        dropdownColor: Colors.white,
                        value: _statusFilter,
                        icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive, size: 18, color: _primaryColor),
                                const SizedBox(width: 8),
                                Text('All', style: TextStyle(color: Colors.grey.shade800)),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'active',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 18, color: _successColor),
                                const SizedBox(width: 8),
                                Text('Active', style: TextStyle(color: Colors.grey.shade800)),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'inactive',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, size: 18, color: _dangerColor),
                                const SizedBox(width: 8),
                                Text('Inactive', style: TextStyle(color: Colors.grey.shade800)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: _handleStatusFilterChange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Sort by dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Sort By',
                          labelStyle: TextStyle(color: Colors.grey.shade700),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        dropdownColor: Colors.white,
                        value: _sortBy,
                        icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'name',
                            child: Row(
                              children: [
                                Icon(Icons.sort_by_alpha, size: 18, color: _primaryColor),
                                const SizedBox(width: 8),
                                Text('Name', style: TextStyle(color: Colors.grey.shade800)),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String>(
                            value: 'created_at',
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: _primaryColor),
                                const SizedBox(width: 8),
                                Text('Newest', style: TextStyle(color: Colors.grey.shade800)),
                              ],
                            ),
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 16, color: _primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Total: $_totalItems',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Pagination info
                if (!_isLoading && _lastPage > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Page $_currentPage of $_lastPage',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Main content - category list or loading indicator
          Expanded(
            child: _buildMainContent(),
          ),
          
          // Pagination controls
          if (!_isLoading && _lastPage > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // First page button
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    tooltip: 'First Page',
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage = 1;
                            });
                            _loadCategories();
                          }
                        : null,
                    color: _currentPage > 1 ? _primaryColor : Colors.grey.shade400,
                  ),
                  // Previous page button
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous Page',
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadCategories();
                          }
                        : null,
                    color: _currentPage > 1 ? _primaryColor : Colors.grey.shade400,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_currentPage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Next page button
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next Page',
                    onPressed: _currentPage < _lastPage
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadCategories();
                          }
                        : null,
                    color: _currentPage < _lastPage ? _primaryColor : Colors.grey.shade400,
                  ),
                  // Last page button
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    tooltip: 'Last Page',
                    onPressed: _currentPage < _lastPage
                        ? () {
                            setState(() {
                              _currentPage = _lastPage;
                            });
                            _loadCategories();
                          }
                        : null,
                    color: _currentPage < _lastPage ? _primaryColor : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        elevation: 4,
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading categories...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: _dangerColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                color: _dangerColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              color: Colors.grey.shade400,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No Categories Found',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _statusFilter = null;
                  _sortBy = 'name';
                  _currentPage = 1;
                });
                _loadCategories();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Category List
    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: _primaryColor,
      child: ListView.builder(
        itemCount: _categories.length,
        padding: const EdgeInsets.only(bottom: 80), // Extra padding for FAB
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: category.status == 'active' ? _successColor : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 8),
                // Category name
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCategory(category);
                    } else if (value == 'delete') {
                      _deleteCategory(category);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: _primaryColor, size: 18),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: _dangerColor, size: 18),
                          const SizedBox(width: 8),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Description
            if (category.description != null && category.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 4, bottom: 8),
                child: Text(
                  category.description!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Stats row
            Row(
              children: [
                const SizedBox(width: 20), // Align with description
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: category.status == 'active'
                        ? _successColor.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: category.status == 'active'
                          ? _successColor.withOpacity(0.3)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.status == 'active' ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: category.status == 'active' ? _successColor : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category.status.toUpperCase(),
                        style: TextStyle(
                          color: category.status == 'active' ? _successColor : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                
                // Product count chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _secondaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 14,
                        color: _secondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${category.productsCount} products',
                        style: TextStyle(
                          color: _secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Quick action buttons
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _editCategory(category),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.edit,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _deleteCategory(category),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.delete,
                        color: _dangerColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}