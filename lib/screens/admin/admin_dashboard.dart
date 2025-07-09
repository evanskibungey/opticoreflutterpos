import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:pos_app/screens/admin/settings_screen.dart';
import 'package:pos_app/screens/admin/printer_settings_screen.dart';
import 'package:pos_app/screens/credit/credit_customers_screen.dart';
import 'package:pos_app/screens/reports/inventory_report_screen.dart';
import 'package:pos_app/screens/sales/sale_details_screen.dart';
import 'package:pos_app/screens/sales/sales_history_screen.dart';
import 'package:pos_app/widget/reports_dashboard_widget.dart';
import 'package:pos_app/widget/printer_status_widget.dart';
import 'package:pos_app/services/thermal_printer_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import 'package:pos_app/screens/admin/category_list_screen.dart';
import 'package:pos_app/screens/admin/product/low_stock_screen.dart';
import 'package:pos_app/screens/admin/product/product_list_screen.dart';
import 'package:pos_app/screens/pos/pos_sales_screen.dart';
import 'package:pos_app/screens/reports/sales_report_screen.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import 'user_management.dart';
import '../../screens/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  dynamic _dashboardData;
  String? _errorMessage;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Helper method to safely parse a value to double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse a value to int
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  // Helper function to safely format amounts that could be strings or numbers
  String _formatAmount(dynamic amount, String currencySymbol) {
    return '$currencySymbol ${_parseDouble(amount).toStringAsFixed(2)}';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboardData = await _dashboardService.getAdminDashboardData();

      // Add a small delay to make the loading animation visible
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Close dialog first
                  Navigator.of(dialogContext).pop();

                  // Show a loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    // Cancel any pending requests and clear caches if needed
                    // If you have other services that need cleanup, add them here

                    // Perform the logout operation
                    await _authService.logout();

                    // Close the loading dialog if it's showing
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }

                    // Navigate to login screen and clear all previous routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) =>
                          false, // This predicate removes all previous routes
                    );
                  } catch (e) {
                    // Handle any errors during logout
                    // Close the loading dialog if it's showing
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error during logout: ${e.toString()}'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Logout"),
              ),
            ],
          ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeScaleTransition(animation: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            if (_dashboardData != null) ...[
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.store, color: Color(0xFFEEEEEE), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _dashboardData.settings['company_name'] ?? 'Company',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Text('Admin Dashboard'),
            ],
          ],
        ),
        actions: [
          // Printer status indicator in app bar
          AppBarPrinterStatus(showText: false),
          
          // Notification button
          IconButton(
            icon: Badge(
              label: Text('3'),
              child: const Icon(Icons.notifications_outlined, size: 24),
            ),
            onPressed: () {
              // Handle notifications
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notifications will be implemented soon'),
                  backgroundColor: theme.colorScheme.secondary,
                ),
              );
            },
          ),
          // Profile button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Show profile options
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => _buildProfileSheet(context),
                );
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 20, color: Color(0xFF2C3E50)),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body:
          _isLoading
              ? _buildLoadingShimmer()
              : _errorMessage != null
              ? _buildErrorState()
              : AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildDashboardContent(),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _navigateTo(POSSalesScreen());
        },
        backgroundColor: theme.colorScheme.secondary,
        icon: const Icon(Icons.point_of_sale),
        label: const Text('Open POS'),
      ),
    );
  }

  Widget _buildProfileSheet(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF2C3E50),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Admin User',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'admin@example.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: theme.colorScheme.secondary,
            ),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.secondary,
            ),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),

          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Admin Panel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dashboardData != null
                      ? _dashboardData.settings['company_name'] ?? 'Company'
                      : 'Loading...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildDrawerItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.people_outline,
            title: 'User Management',
            onTap: () {
              Navigator.pop(context);
              _navigateTo(UserManagementScreen());
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'INVENTORY',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.category_outlined,
            title: 'Categories',
            onTap: () {
              Navigator.pop(context);
              _navigateTo(CategoryListScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.inventory_2_outlined,
            title: 'Products',
            onTap: () {
              Navigator.pop(context);
              _navigateTo(ProductListScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.warning_amber_outlined,
            title: 'Low Stock',
            badge: _dashboardData?.stats['low_stock_products'] ?? 0,
            badgeColor: theme.colorScheme.error,
            onTap: () {
              Navigator.pop(context);
              _navigateTo(
                LowStockScreen(
                  currencySymbol:
                      _dashboardData?.settings['currency_symbol'] ?? '\$',
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // REPORTS section in drawer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'REPORTS',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.analytics_outlined,
            title: 'Sales Reports',
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const SalesReportScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory Reports',
            onTap: () {
              Navigator.pop(context);
              // Navigate to inventory report screen
              _navigateTo(const InventoryReportScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.people_outlined,
            title: 'User Reports',
            onTap: () {
              Navigator.pop(context);
              // Navigate to user report screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('User Reports will be implemented soon'),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'SALES',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.point_of_sale,
            title: 'Point of Sale',
            isNew: true,
            onTap: () {
              Navigator.pop(context);
              _navigateTo(POSSalesScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long_outlined,
            title: 'Sales History',
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const SalesHistoryScreen());
            },
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(),
          ),
          _buildDrawerItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Credit Management',
            onTap: () {
              Navigator.pop(context);
              _navigateTo(const CreditCustomersScreen());
            },
          ),

          // Enhanced printer settings with status indicator
          Consumer<ThermalPrinterService>(
            builder: (context, printerService, child) {
              return _buildDrawerItem(
                icon: printerService.isConnected ? Icons.print : Icons.print_disabled,
                title: 'Printer Settings',
                badge: printerService.isConnected ? null : 1,
                badgeColor: Colors.orange,
                iconColor: printerService.isConnected ? Colors.green : Colors.orange,
                onTap: () {
                  Navigator.pop(context); // Close the drawer first
                  // Navigate to printer settings screen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()),
                  );
                },
              );
            },
          ),
          
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context); // Close the drawer first

              // Navigate to settings screen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            textColor: theme.colorScheme.error,
            iconColor: theme.colorScheme.error,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    bool isSelected = false,
    bool isNew = false,
    int? badge,
    Color? badgeColor,
    Color? textColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isSelected
                  ? theme.colorScheme.secondary
                  : iconColor ?? Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
                isSelected
                    ? theme.colorScheme.secondary
                    : textColor ?? Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing:
            isNew
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : badge != null && badge > 0
                ? Badge(
                  label: Text(badge.toString()),
                  backgroundColor: badgeColor ?? theme.colorScheme.secondary,
                )
                : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        selectedTileColor:
            isSelected
                ? theme.colorScheme.secondary.withOpacity(0.1)
                : Colors.transparent,
        onTap: onTap,
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card shimmer
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),

            // Section title shimmer
            Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Sales cards shimmer
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio:
                  1.2, // Adjusted to match the real implementation
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                4,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Another section title shimmer
            Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Stats cards shimmer
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio:
                  0.85, // Adjusted to match the real implementation
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                3,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chart shimmer
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),

            // More section titles and lists
            Container(
              height: 24,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // List shimmer
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            // Reports section shimmer
            const SizedBox(height: 24),
            Container(
              height: 24,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardData == null) {
      return const Center(child: Text('No data available'));
    }

    final theme = Theme.of(context);
    final currencySymbol = _dashboardData.settings['currency_symbol'] ?? '\$';
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: theme.colorScheme.secondary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOut,
                ),
              ),
              child: FadeTransition(
                opacity: _animationController,
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                elevation: 0,
                color: theme.colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_emotions,
                            color: Colors.white.withOpacity(0.9),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Welcome back!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Here\'s what\'s happening with your business today.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              _navigateTo(POSSalesScreen());
                            },
                            icon: const Icon(Icons.point_of_sale, size: 18),
                            label: const Text('New Sale'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              _navigateTo(const InventoryReportScreen());
                            },
                            icon: const Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                            ),
                            label: const Text('Inventory'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // System Status Section (NEW - includes printer status)
              Text(
                'System Status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Printer Status Widget
                  Expanded(
                    child: PrinterStatusWidget(
                      showLabel: true,
                      isCompact: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Could add more status widgets here
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_done,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'System Status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Sales Overview
              Text(
                'Sales Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildSalesOverview(currencySymbol: currencySymbol),
              const SizedBox(height: 24),

              // Business Stats
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Business Stats',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _loadDashboardData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsOverview(currencySymbol: currencySymbol),
              const SizedBox(height: 24),

              // Sales Trend Chart
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: theme.colorScheme.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sales Trend',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: 'This Month',
                            items:
                                [
                                  'This Week',
                                  'This Month',
                                  'This Quarter',
                                  'This Year',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              // Update chart period
                            },
                            style: theme.textTheme.bodyMedium,
                            underline: Container(),
                            icon: const Icon(Icons.keyboard_arrow_down),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildSalesTrendChart(currencySymbol: currencySymbol),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Two column layout for top products and payment methods on wider screens
              if (isWideScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Selling Products',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTopProductsList(currencySymbol: currencySymbol),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Methods',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentMethodsChart(
                            currencySymbol: currencySymbol,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Products
                    Text(
                      'Top Selling Products',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTopProductsList(currencySymbol: currencySymbol),
                    const SizedBox(height: 24),

                    // Payment Methods
                    Text(
                      'Payment Methods',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethodsChart(currencySymbol: currencySymbol),
                  ],
                ),
              const SizedBox(height: 24),

              // Recent Sales
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Sales',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _navigateTo(const SalesHistoryScreen());
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecentSalesList(currencySymbol: currencySymbol),
              const SizedBox(height: 24),

              // Reports Section (NEW)
              Text(
                'Reports',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const ReportsDashboardWidget(),
              const SizedBox(height: 24),

              // Low Stock Products Alert
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.error,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Low Stock Alert',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLowStockProductsList(),
                    if (_dashboardData.lowStockProducts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _navigateTo(
                              LowStockScreen(currencySymbol: currencySymbol),
                            );
                          },
                          icon: const Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                          ),
                          label: const Text('Manage Inventory'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Printer Connection Retry Widget
              const SizedBox(height: 16),
              PrinterConnectionRetry(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Sales Overview Implementation (keeping existing implementation for brevity)
  Widget _buildSalesOverview({required String currencySymbol}) {
    final theme = Theme.of(context);
    final salesStats = _dashboardData.salesStats;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Today\'s Sales',
          value: '${salesStats['today']['count']}',
          icon: Icons.calendar_today,
          color: theme.colorScheme.secondary,
          subtitle: _formatAmount(
            salesStats['today']['amount'],
            currencySymbol,
          ),
        ),
        _buildStatCard(
          title: 'This Week\'s Sales',
          value: '${salesStats['week']['count']}',
          icon: Icons.calendar_view_week,
          color: theme.colorScheme.tertiary,
          subtitle: _formatAmount(salesStats['week']['amount'], currencySymbol),
        ),
        _buildStatCard(
          title: 'This Month\'s Sales',
          value: '${salesStats['month']['count']}',
          icon: Icons.calendar_month,
          color: const Color(0xFF5E72E4),
          subtitle: _formatAmount(
            salesStats['month']['amount'],
            currencySymbol,
          ),
        ),
        _buildStatCard(
          title: 'Average Sale',
          value: '',
          icon: Icons.show_chart,
          color: const Color(0xFF8E44AD),
          subtitle: _formatAmount(salesStats['average_sale'], currencySymbol),
        ),
      ],
    );
  }

  Widget _buildStatsOverview({required String currencySymbol}) {
    final theme = Theme.of(context);
    final stats = _dashboardData.stats;

    String totalStockValue = _formatAmount(
      _dashboardData.totalStockValue,
      currencySymbol,
    );

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatsCard(
          title: 'Total Users',
          value: '${stats['total_users']}',
          icon: Icons.people,
          color: theme.colorScheme.secondary,
          details: [
            '${stats['active_users']} Active',
            '${stats['total_cashiers']} Cashiers',
          ],
        ),
        _buildStatsCard(
          title: 'Total Products',
          value: '${stats['total_products']}',
          icon: Icons.inventory_2,
          color: theme.colorScheme.tertiary,
          details: [
            'Value: $totalStockValue',
            '${stats['active_products']} Active',
          ],
        ),
        _buildStatsCard(
          title: 'Low Stock',
          value: '${stats['low_stock_products']}',
          icon: Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          details: [
            'Threshold: ${_dashboardData.settings['low_stock_threshold'] ?? "N/A"}',
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    String? subtitle2,
    String? trend,
    bool isPositiveTrend = true,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isPositiveTrend
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositiveTrend
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: isPositiveTrend ? Colors.green : Colors.red,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isPositiveTrend ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (value.isNotEmpty)
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              subtitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle2 != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<String> details,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children:
                    details
                        .map(
                          (detail) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: theme.textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder methods (implement the rest based on your existing implementation)
  Widget _buildSalesTrendChart({required String currencySymbol}) {
    return Container(height: 200, child: Center(child: Text('Sales Trend Chart')));
  }

  Widget _buildPaymentMethodsChart({required String currencySymbol}) {
    return Container(height: 200, child: Center(child: Text('Payment Methods Chart')));
  }

  Widget _buildTopProductsList({required String currencySymbol}) {
    return Container(height: 200, child: Center(child: Text('Top Products List')));
  }

  Widget _buildRecentSalesList({required String currencySymbol}) {
    return Container(height: 200, child: Center(child: Text('Recent Sales List')));
  }

  Widget _buildLowStockProductsList() {
    return Container(height: 100, child: Center(child: Text('Low Stock Products')));
  }
}
