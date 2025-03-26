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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    // If user confirmed deletion
    if (confirm == true) {
      try {
        await _categoryService.deleteCategory(category.id);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh list
        _loadCategories();
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
        title: const Text('Categories'),
        backgroundColor: Colors.orange.shade500,
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
          // Search bar and filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        value: _statusFilter,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'inactive',
                            child: Text('Inactive'),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'name',
                            child: Text('Name'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'created_at',
                            child: Text('Newest'),
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
                  'Total: $_totalItems categories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                // Pagination info
                if (!_isLoading && _lastPage > 1)
                  Text(
                    'Page $_currentPage of $_lastPage',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          
          // Main content - category list or loading indicator
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _categories.isEmpty
                        ? const Center(child: Text('No categories found'))
                        : RefreshIndicator(
                            onRefresh: _loadCategories,
                            child: ListView.builder(
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      category.description ?? 'No description',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Status chip
                                        Chip(
                                          label: Text(
                                            category.status.toUpperCase(),
                                            style: TextStyle(
                                              color: category.status == 'active'
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: category.status == 'active'
                                              ? Colors.green
                                              : Colors.grey.shade300,
                                          padding: EdgeInsets.zero,
                                        ),
                                        const SizedBox(width: 8),
                                        
                                        // Product count
                                        Chip(
                                          label: Text(
                                            '${category.productsCount} products',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: Colors.blue.shade100,
                                          padding: EdgeInsets.zero,
                                        ),
                                        
                                        // Edit button
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _editCategory(category),
                                          color: Colors.blue,
                                        ),
                                        
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deleteCategory(category),
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
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
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadCategories();
                          }
                        : null,
                  ),
                  Text('$_currentPage / $_lastPage'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _lastPage
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadCategories();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Colors.orange.shade500,
        child: const Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }
}