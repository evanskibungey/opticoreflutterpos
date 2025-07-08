import 'package:flutter/material.dart';
import 'package:pos_app/screens/pos/receipt_screen.dart';
import 'package:pos_app/services/pos_service.dart';

// Re-use the CartItem class from POSSalesScreen
import 'package:pos_app/screens/pos/pos_sales_screen.dart';

/// Opticore theme colors - matching web version
class OpticoreColors {
  // Main blues
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);

  // Grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Additional colors
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color green500 = Color(0xFF10B981);
}

class CartScreen extends StatefulWidget {
  final List<CartItem> cart;
  final Function(List<CartItem>) onCartUpdated;
  final String currencySymbol;

  const CartScreen({
    Key? key,
    required this.cart,
    required this.onCartUpdated,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late final List<CartItem> _cart;
  String _paymentMethod = 'cash';
  Map<String, String> _customerDetails = {'name': '', 'phone': ''};
  bool _isProcessingSale = false;
  final PosService _posService = PosService();
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _cart = List.from(widget.cart);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Calculate cart total
  double get _cartTotal {
    return _cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Update parent screen cart state
  void _updateParentCart() {
    widget.onCartUpdated(_cart);
  }

  // Remove item from cart
  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
    _updateParentCart();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.remove_shopping_cart, color: Colors.white),
            SizedBox(width: 12),
            Text('Item removed from cart'),
          ],
        ),
        backgroundColor: OpticoreColors.red600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Update item quantity
  void _updateQuantity(int index, int change) {
    final item = _cart[index];
    final newQuantity = item.quantity + change;

    if (newQuantity <= 0) {
      _removeFromCart(index);
      return;
    }

    if (newQuantity > item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Cannot add more. Only ${item.stock} available in stock.'),
              ),
            ],
          ),
          backgroundColor: OpticoreColors.red600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() {
      _cart[index].quantity = newQuantity;
    });
    _updateParentCart();
  }

  // Clear cart
  void _clearCart() {
    setState(() {
      _cart.clear();
    });
    _updateParentCart();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.white),
            SizedBox(width: 12),
            Text('Cart has been cleared'),
          ],
        ),
        backgroundColor: OpticoreColors.blue500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Show customer details form for credit sales
  void _showCustomerDetailsForm() {
    // Get keyboard height to adjust bottom sheet
    final viewInsets = MediaQuery.of(context).viewInsets;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: OpticoreColors.blue50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add,
                          color: OpticoreColors.blue700,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: OpticoreColors.gray800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      labelStyle: TextStyle(
                        color: OpticoreColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: OpticoreColors.gray300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: OpticoreColors.gray300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: OpticoreColors.blue500, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person, color: OpticoreColors.blue500),
                      filled: true,
                      fillColor: OpticoreColors.gray50,
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    onChanged: (value) {
                      _customerDetails['name'] = value;
                    },
                    controller: TextEditingController(
                      text: _customerDetails['name'],
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: OpticoreColors.gray800,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(
                        color: OpticoreColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: OpticoreColors.gray300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: OpticoreColors.gray300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: OpticoreColors.blue500, width: 2),
                      ),
                      prefixIcon: Icon(Icons.phone, color: OpticoreColors.blue500),
                      filled: true,
                      fillColor: OpticoreColors.gray50,
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      _customerDetails['phone'] = value;
                    },
                    controller: TextEditingController(
                      text: _customerDetails['phone'],
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: OpticoreColors.gray800,
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OpticoreColors.blue500,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 1,
                          ),
                          child: Text(
                            'Save Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Process the sale
  Future<void> _processSale() async {
    // Validate cart is not empty
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Your cart is empty'),
            ],
          ),
          backgroundColor: OpticoreColors.red600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Validate customer details for credit sales
    if (_paymentMethod == 'credit') {
      if (_customerDetails['name']!.isEmpty || _customerDetails['phone']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Please enter customer details for credit sale'),
                ),
              ],
            ),
            backgroundColor: OpticoreColors.red600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
    }

    // Start processing
    setState(() {
      _isProcessingSale = true;
    });

    try {
      // Convert cart items to format expected by API
      final cartItems = _cart
          .map(
            (item) => {
              'id': item.id,
              'quantity': item.quantity,
              'price': item.price,
            },
          )
          .toList();

      // Process the sale through PosService
      final result = await _posService.processSale(
        cartItems: cartItems,
        paymentMethod: _paymentMethod,
        customerDetails: _paymentMethod == 'credit' ? _customerDetails : null,
      );

      // Clear the cart
      _cart.clear();
      _updateParentCart();

      // Show receipt screen
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(
            receiptNumber: result['receipt_number'],
            receiptData: result['receipt_data'],
            onClose: () {
              // Return to product screen on close
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Error processing sale: $e'),
              ),
            ],
          ),
          backgroundColor: OpticoreColors.red600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSale = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    // Create the Opticore gradient for the app bar
    final opticoreGradient = LinearGradient(
      colors: [
        OpticoreColors.blue500,
        OpticoreColors.blue600,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Scaffold(
      backgroundColor: OpticoreColors.gray50,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, size: 22),
            SizedBox(width: 8),
            Text(
              'Shopping Cart',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: opticoreGradient),
        ),
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            _animationController.reverse().then((_) {
              Navigator.pop(context);
            });
          },
        ),
        actions: [
          if (_cart.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.delete_sweep, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: OpticoreColors.red500,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Clear Cart?',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: OpticoreColors.gray800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Are you sure you want to remove all items from your cart?',
                          style: TextStyle(
                            color: OpticoreColors.gray700,
                            fontSize: 16,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: OpticoreColors.gray700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OpticoreColors.red500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.delete, size: 18),
                            label: Text(
                              'Clear',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              _clearCart();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                tooltip: 'Clear Cart',
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _cart.isEmpty
            ? _buildEmptyCartState(context)
            : _buildCartContent(context, isSmallScreen, opticoreGradient),
      ),
    );
  }

  // Extracted methods to reduce duplication and improve readability
  
  // Empty cart state widget
  Widget _buildEmptyCartState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [OpticoreColors.gray50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: OpticoreColors.blue50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: OpticoreColors.blue500.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: OpticoreColors.blue300,
                ),
              ),
              SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: OpticoreColors.gray800,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Add products to start a new sale',
                  style: TextStyle(
                    fontSize: 16,
                    color: OpticoreColors.gray600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: OpticoreColors.blue500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                  shadowColor: OpticoreColors.blue200,
                ),
                icon: Icon(Icons.add_shopping_cart),
                label: Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cart content with items
  Widget _buildCartContent(BuildContext context, bool isSmallScreen, LinearGradient opticoreGradient) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [OpticoreColors.gray50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Cart summary card - Opticore styled
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    OpticoreColors.blue500,
                    OpticoreColors.blue600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: OpticoreColors.blue500.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cart items count with icon
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _cart.length.toString(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Total amount with icon
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${widget.currencySymbol} ${_cartTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cart items list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  
                  // Create staggered animation for each item
                  final Animation<double> animation = CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index * 0.05,
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  );
                  
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(
                      opacity: animation,
                      child: Dismissible(
                        key: Key(item.id.toString() + index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [OpticoreColors.red400, OpticoreColors.red600],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Remove",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          _removeFromCart(index);
                        },
                        child: _buildCartItemCard(item, index, isSmallScreen),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Payment options and checkout section - Opticore styled
            _buildPaymentSection(isSmallScreen),
          ],
        ),
      ),
    );
  }

  // Cart item card
  Widget _buildCartItemCard(CartItem item, int index, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: OpticoreColors.gray200, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12.0 : 16.0, 
          vertical: 12.0
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product icon with Opticore styled container
                Container(
                  width: isSmallScreen ? 50 : 60,
                  height: isSmallScreen ? 50 : 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OpticoreColors.blue50,
                        Color(0xFFDDEBFD), // Custom light blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: OpticoreColors.blue700,
                    size: isSmallScreen ? 25 : 30,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                          color: OpticoreColors.gray800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      
                      // Category and serial badges - Opticore styled
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: OpticoreColors.blue50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: OpticoreColors.blue200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item.categoryName,
                              style: TextStyle(
                                fontSize: 10,
                                color: OpticoreColors.blue700,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.serialNumber != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: OpticoreColors.blue50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: OpticoreColors.blue200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tag,
                                    size: 10,
                                    color: OpticoreColors.blue700,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.serialNumber!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: OpticoreColors.blue700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Responsive price and quantity layout
            LayoutBuilder(
              builder: (context, constraints) {
                // For very small screens, stack vertically
                if (constraints.maxWidth < 280) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit price
                      Row(
                        children: [
                          Text(
                            '${widget.currencySymbol} ',
                            style: TextStyle(
                              color: OpticoreColors.gray600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: OpticoreColors.blue700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            ' × ',
                            style: TextStyle(
                              color: OpticoreColors.gray500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      
                      // Quantity controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuantityControls(item, index),
                          
                          // Total price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: OpticoreColors.gray500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${widget.currencySymbol} ${(item.price * item.quantity).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: OpticoreColors.blue700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                }
                
                // For larger screens, use the original layout with a row
                return Row(
                  children: [
                    // Unit price
                    Text(
                      '${widget.currencySymbol} ',
                      style: TextStyle(
                        color: OpticoreColors.gray600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: OpticoreColors.blue700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      ' × ',
                      style: TextStyle(
                        color: OpticoreColors.gray500,
                        fontSize: 16,
                      ),
                    ),
                    
                    // Quantity controls
                    _buildQuantityControls(item, index),
                    
                    Spacer(),
                    
                    // Total price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Item Total',
                          style: TextStyle(
                            fontSize: 10,
                            color: OpticoreColors.gray500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${widget.currencySymbol} ${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: OpticoreColors.blue700,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build quantity controls widget - Opticore styled
  Widget _buildQuantityControls(CartItem item, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: OpticoreColors.gray300,
          width: 1,
        ),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(7),
              bottomLeft: Radius.circular(7),
            ),
            child: InkWell(
              onTap: () => _updateQuantity(index, -1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                bottomLeft: Radius.circular(7),
              ),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OpticoreColors.gray100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: OpticoreColors.gray700,
                ),
              ),
            ),
          ),
          Container(
            width: 32,
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: OpticoreColors.gray300),
                right: BorderSide(color: OpticoreColors.gray300),
              ),
            ),
            child: Text(
              item.quantity.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: OpticoreColors.gray800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            child: InkWell(
              onTap: () => _updateQuantity(index, 1),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OpticoreColors.gray100,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: OpticoreColors.gray700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Payment section with options and checkout button - Opticore styled
  Widget _buildPaymentSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -4),
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  size: 18,
                  color: OpticoreColors.gray700,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: OpticoreColors.gray800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Payment methods
          LayoutBuilder(
            builder: (context, constraints) {
              // For very small screens, stack payment options vertically
              if (constraints.maxWidth < 280) {
                return Column(
                  children: [
                    _buildPaymentOption('cash', 'Cash Payment', Icons.payments_outlined),
                    SizedBox(height: 12),
                    _buildPaymentOption('credit', 'Credit Sale', Icons.credit_card),
                  ],
                );
              }
              
              // For larger screens, use row layout
              return Row(
                children: [
                  Expanded(
                    child: _buildPaymentOption('cash', 'Cash Payment', Icons.payments_outlined),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildPaymentOption('credit', 'Credit Sale', Icons.credit_card),
                  ),
                ],
              );
            }
          ),

          // Credit customer details
          if (_paymentMethod == 'credit') ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OpticoreColors.blue50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OpticoreColors.blue200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: OpticoreColors.blue800,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Customer: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: OpticoreColors.blue800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _customerDetails['name']!.isEmpty
                              ? 'Not specified'
                              : _customerDetails['name']!,
                          style: TextStyle(
                            color: OpticoreColors.blue800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: OpticoreColors.blue200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 12,
                            color: OpticoreColors.blue800,
                          ),
                        ),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: _showCustomerDetailsForm,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: OpticoreColors.blue800,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Phone: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: OpticoreColors.blue800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _customerDetails['phone']!.isEmpty
                              ? 'Not specified'
                              : _customerDetails['phone']!,
                          style: TextStyle(
                            color: OpticoreColors.blue800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 20),

          // Checkout button - Opticore styled gradient button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessingSale ? null : _processSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: OpticoreColors.blue500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: OpticoreColors.gray300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                padding: EdgeInsets.zero,
              ),
              child: _isProcessingSale
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            OpticoreColors.blue500,
                            OpticoreColors.blue600,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _buildCheckoutButtonContent(isSmallScreen),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build payment option button - Opticore styled
  Widget _buildPaymentOption(String method, String label, IconData icon) {
    final bool isSelected = _paymentMethod == method;
    
    return InkWell(
      onTap: () {
        setState(() {
          _paymentMethod = method;
        });
        if (method == 'credit') {
          _showCustomerDetailsForm();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? OpticoreColors.blue500
                : OpticoreColors.gray300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? OpticoreColors.blue50
              : Colors.white,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? OpticoreColors.blue200
                    : OpticoreColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? OpticoreColors.blue700
                    : OpticoreColors.gray600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? OpticoreColors.blue700
                    : OpticoreColors.gray600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  // Build checkout button content with responsive design - Opticore styled
  Widget _buildCheckoutButtonContent(bool isSmallScreen) {
    if (isSmallScreen) {
      // Simplified version for small screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_checkout, size: 18),
          SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Complete (${widget.currencySymbol}${_cartTotal.toStringAsFixed(2)})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // Normal version for larger screens
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_checkout, size: 20),
          SizedBox(width: 12),
          Text(
            'Complete Sale',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.currencySymbol}${_cartTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}