import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/models/category.dart';
import 'package:pos_app/models/product.dart';
import 'package:pos_app/screens/pos/cart_screen.dart';
import 'package:pos_app/services/category_service.dart';
import 'package:pos_app/services/product_service.dart';
import 'package:pos_app/config/api_config.dart';
import 'package:pos_app/widget/NetworkImageHelper.dart';

class POSSalesScreen extends StatefulWidget {
  const POSSalesScreen({Key? key}) : super(key: key);

  @override
  _POSSalesScreenState createState() => _POSSalesScreenState();
}

class _POSSalesScreenState extends State<POSSalesScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  // Page state
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String? _errorMessage;

  // Products and categories
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;

  // Cart state
  List<CartItem> _cart = [];

  // Currency symbol
  String _currencySymbol = 'KSh';
  
  // Animation controller for product cards
  late AnimationController _animationController;

  // Scroll controller for GridView
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load products and categories
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allProducts = []; // Clear existing products
      _loadingProgress = 0.0;
    });

    try {
      // Load categories first
      final categoriesResult = await _categoryService.getCategories(
        status: 'active',
      );
      
      // Set categories immediately
      setState(() {
        _categories = categoriesResult['categories'];
      });

      // Load all pages of products
      await _loadAllProducts();
      
      // Update state after loading all products
      setState(() {
        _filteredProducts = _allProducts;
        _isLoading = false;
      });

      debugPrint(
        'Loaded ${_allProducts.length} products and ${_categories.length} categories',
      );
      
      // Reset animation controller
      _animationController.reset();
      _animationController.forward();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
      debugPrint('Error loading data: $e');
    }
  }

  // Load all pages of products
  Future<void> _loadAllProducts() async {
    int currentPage = 1;
    int lastPage = 1;
    bool hasMorePages = true;
    List<Product> allLoadedProducts = [];
    
    try {
      while (hasMorePages) {
        final productsResult = await _productService.getProducts(
          status: 'active',
          categoryId: _selectedCategoryId,
          page: currentPage,
          // Consider increasing the per_page parameter if supported by your API
          // perPage: 50, // Uncomment if your API supports this
        );
        
        // Add products from the current page
        final pageProducts = productsResult['products'] as List<Product>;
        allLoadedProducts.addAll(pageProducts);
        
        // Update pagination info
        currentPage = productsResult['current_page'];
        lastPage = productsResult['last_page'];
        
        // Check if we've reached the last page
        hasMorePages = currentPage < lastPage;
        
        // Move to next page
        currentPage++;
        
        // Update loading progress
        setState(() {
          _loadingProgress = currentPage / (lastPage + 1);
          // Add partial results to allow incremental display
          _allProducts = List.from(allLoadedProducts);
          _filteredProducts = _allProducts;
        });
        
        // Small delay to prevent API rate limiting if necessary
        await Future.delayed(Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('Error loading all products: $e');
      // If there was an error, we'll still use whatever products we've loaded so far
    }
    
    // Set the final complete result
    setState(() {
      _allProducts = allLoadedProducts;
      _filteredProducts = _allProducts;
      _loadingProgress = 1.0;
    });
  }

  // Filter products by search query only
  void _filterProducts() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        final query = _searchController.text.toLowerCase();
        _filteredProducts = _allProducts.where((product) {
          return product.name.toLowerCase().contains(query) ||
              product.sku.toLowerCase().contains(query) ||
              (product.serialNumber?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  // Add product to cart
  void _addToCart(Product product) {
    // Check if product has stock
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This product is out of stock'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if product is already in cart
    final existingItemIndex = _cart.indexWhere((item) => item.id == product.id);

    if (existingItemIndex >= 0) {
      // Check if adding one more would exceed stock
      if (_cart[existingItemIndex].quantity + 1 > product.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add more. Only ${product.stock} available in stock.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Increment quantity
      setState(() {
        _cart[existingItemIndex].quantity += 1;
      });
    } else {
      // Add new item to cart
      setState(() {
        _cart.add(
          CartItem(
            id: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
            stock: product.stock,
            categoryName: product.getCategoryName(),
            serialNumber: product.serialNumber,
            minSellingPrice: product.minSellingPrice,
            maxSellingPrice: product.maxSellingPrice,
          ),
        );
      });
    }

    // Show success snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '${product.name} added to cart',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () => _navigateToCart(),
        ),
      ),
    );
  }

  // Navigate to cart screen
  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cart: _cart,
          onCartUpdated: (updatedCart) {
            setState(() {
              _cart = updatedCart;
            });
          },
          currencySymbol: _currencySymbol,
        ),
      ),
    );
  }

  // Get cart count badge
  Widget _buildCartBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // Blue-50
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.shopping_cart, color: const Color(0xFF1D4ED8)), // Blue-700
            onPressed: _cart.isEmpty ? null : _navigateToCart,
          ),
        ),
        if (_cart.isNotEmpty)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444), // Red
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              constraints: BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '${_cart.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  // Product card widget - extracted for better performance
  Widget _buildProductCard(Product product, int index) {
    final bool isOutOfStock = product.stock <= 0;
    
    // Create animation delay based on index
    final delay = (index % 20) * 0.025; // Smaller delay for smoother loading
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
      ),
    );

    // Use RepaintBoundary to optimize rendering
    return RepaintBoundary(
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: Card(
            elevation: 2,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: isOutOfStock ? null : () => _addToCart(product),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stock badge
                  Stack(
                    children: [
                      // Image with rounded corners
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: NetworkImageHelper(
                            imageUrl: product.imageUrl,
                            productName: product.name,
                            fit: BoxFit.contain,
                            height: double.infinity,
                            width: double.infinity,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      
                      // Out of stock overlay
                      if (isOutOfStock)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'OUT OF STOCK',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                      // Stock indicator
                      if (!isOutOfStock && product.stock < 5)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6), // Blue-500
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              'Only ${product.stock} left',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Product details with improved spacing
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // Blue-50
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.getCategoryName(),
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF1D4ED8), // Blue-700
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Name with better typography
                          Flexible(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.grey.shade800,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Price and add button with better alignment
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Price section with flexible pricing indicator
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Price with larger text
                                    Text(
                                      '${_currencySymbol} ${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: const Color(0xFF1D4ED8), // Blue-700
                                      ),
                                    ),
                                    // Flexible pricing indicator
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
                                              size: 10,
                                              color: Colors.green.shade600,
                                            ),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                'Flexible',
                                                style: TextStyle(
                                                  fontSize: 9,
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
                              // Enhanced add to cart button
                              SizedBox(
                                height: 36,
                                width: 36,
                                child: ElevatedButton(
                                  onPressed: isOutOfStock
                                      ? null
                                      : () => _addToCart(product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6), // Blue-500
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                    elevation: 2,
                                    shadowColor: const Color(0xFFDEEBFF), // Blue-100
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Icon(
                                    Icons.add_shopping_cart,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Empty products placeholder
  Widget _buildEmptyProductsPlaceholder() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 72,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 24),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Try a different search term or category',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategoryId = null;
                });
                _loadData(); // Reload data from API
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6), // Blue-500
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.refresh),
              label: Text(
                'Reset Filters',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading indicator with progress
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress indicator showing loading progress
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  color: const Color(0xFF3B82F6), // Blue-500
                  strokeWidth: 3,
                ),
              ),
              // Show progress percentage in the center
              if (_loadingProgress > 0)
                Text(
                  '${(_loadingProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _loadingProgress > 0
              ? 'Loading products (${_allProducts.length} loaded)...'
              : 'Loading products...',
            style: TextStyle(
              color: const Color(0xFF1D4ED8), // Blue-700
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Error state widget
  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6), // Blue-500
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
              icon: Icon(Icons.refresh),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create a gradient for the app
    final mainGradient = LinearGradient(
      colors: [
        const Color(0xFF60A5FA), // Blue-400
        const Color(0xFF3B82F6), // Blue-500
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Gray-50
      appBar: AppBar(
        title: Text(
          'Point of Sale',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: mainGradient),
        ),
        elevation: 0,
        actions: [
          _buildCartBadge(),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Blue-50
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: const Color(0xFF1D4ED8)), // Blue-700
              onPressed: _loadData,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      floatingActionButton:
          _cart.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _navigateToCart,
                label: Row(
                  children: [
                    Text(
                      'View Cart',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cart.length}',
                        style: TextStyle(
                          color: const Color(0xFF1D4ED8), // Blue-700
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                icon: Icon(Icons.shopping_cart_checkout),
                backgroundColor: const Color(0xFF3B82F6), // Blue-500
                elevation: 4,
                extendedPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              )
              : null,
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                children: [
                  // Search and filter container with subtle gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEFF6FF), // Blue-50
                          Colors.white
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Search field with enhanced design
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: const Color(0xFF3B82F6), // Blue-500
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterProducts();
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onChanged: (_) => _filterProducts(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Category filter - horizontal scrollable list
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // "All Categories" chip
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                                child: FilterChip(
                                  label: Text(
                                    'All Categories',
                                    style: TextStyle(
                                      fontWeight: _selectedCategoryId == null
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _selectedCategoryId == null
                                          ? Colors.white
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                  selected: _selectedCategoryId == null,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategoryId = null;
                                      _searchController.clear();
                                    });
                                    _loadData(); // Reload data from API
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                  selectedColor: const Color(0xFF3B82F6), // Blue-500
                                  checkmarkColor: Colors.white,
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: _selectedCategoryId == null
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),

                              // Find Gas Refill category and display it first
                              ..._categories
                                  .where(
                                    (category) => category.name == 'Gas Refill',
                                  )
                                  .map((category) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: FilterChip(
                                        label: Text(
                                          category.name,
                                          style: TextStyle(
                                            fontWeight: _selectedCategoryId == category.id
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: _selectedCategoryId == category.id
                                                ? Colors.white
                                                : Colors.grey.shade800,
                                          ),
                                        ),
                                        selected: _selectedCategoryId == category.id,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedCategoryId =
                                                selected ? category.id : null;
                                            _searchController.clear();
                                          });
                                          _loadData(); // Reload data from API
                                        },
                                        backgroundColor: Colors.grey.shade100,
                                        selectedColor: const Color(0xFF3B82F6), // Blue-500
                                        checkmarkColor: Colors.white,
                                        shape: StadiumBorder(
                                          side: BorderSide(
                                            color: _selectedCategoryId == category.id
                                                ? Colors.transparent
                                                : Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    );
                                  })
                                  .toList(),

                              // Display all other categories afterward
                              ..._categories
                                  .where(
                                    (category) => category.name != 'Gas Refill',
                                  )
                                  .map((category) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: FilterChip(
                                        label: Text(
                                          category.name,
                                          style: TextStyle(
                                            fontWeight: _selectedCategoryId == category.id
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: _selectedCategoryId == category.id
                                                ? Colors.white
                                                : Colors.grey.shade800,
                                          ),
                                        ),
                                        selected: _selectedCategoryId == category.id,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedCategoryId =
                                                selected ? category.id : null;
                                            _searchController.clear();
                                          });
                                          _loadData(); // Reload data from API
                                        },
                                        backgroundColor: Colors.grey.shade100,
                                        selectedColor: const Color(0xFF3B82F6), // Blue-500
                                        checkmarkColor: Colors.white,
                                        shape: StadiumBorder(
                                          side: BorderSide(
                                            color: _selectedCategoryId == category.id
                                                ? Colors.transparent
                                                : Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Products grid
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? _buildEmptyProductsPlaceholder()
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              // Delayed card loading when scrolling for better performance
                              // Load more items as user scrolls
                              if (scrollInfo is ScrollEndNotification) {
                                // Check if animation controller has completed
                                if (!_animationController.isAnimating && 
                                    _animationController.isCompleted) {
                                  // Reset for next animation
                                  _animationController.reset();
                                  _animationController.forward();
                                }
                              }
                              return false;
                            },
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 800
                                    ? 4
                                    : MediaQuery.of(context).size.width > 600
                                        ? 3
                                        : 2,
                                childAspectRatio: 0.62,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredProducts.length,
                              cacheExtent: 500, // Increase cache to reduce rebuilds
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product, index);
                              },
                            ),
                          ),
                  ),
                ],
              ),
    );
  }
}

// Cart item model (shared between screens)
class CartItem {
  final int id;
  final String name;
  double price; // Made mutable for price adjustments
  final double originalPrice; // Store original price
  int quantity;
  final int stock;
  final String categoryName;
  final String? serialNumber;
  final double? minSellingPrice;
  final double? maxSellingPrice;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.stock,
    required this.categoryName,
    this.serialNumber,
    this.minSellingPrice,
    this.maxSellingPrice,
  }) : originalPrice = price;
  
  // Helper methods for price range functionality
  bool hasFlexiblePricing() {
    return minSellingPrice != null || maxSellingPrice != null;
  }
  
  bool isPriceInRange(double price) {
    if (!hasFlexiblePricing()) {
      return true; // No restrictions if no range is set
    }
    
    final minPrice = minSellingPrice ?? 0.0;
    final maxPrice = maxSellingPrice ?? double.infinity;
    
    return price >= minPrice && price <= maxPrice;
  }
  
  double getMinSellingPrice() {
    return minSellingPrice ?? 0.0;
  }
  
  double getMaxSellingPrice() {
    return maxSellingPrice ?? double.infinity;
  }
  
  void updatePrice(double newPrice) {
    if (isPriceInRange(newPrice)) {
      price = newPrice;
    }
  }
  
  void resetPrice() {
    price = originalPrice;
  }
  
  bool isPriceAdjusted() {
    return price != originalPrice;
  }
}