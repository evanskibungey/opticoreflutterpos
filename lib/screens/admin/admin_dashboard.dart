import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos_app/screens/admin/settings_screen.dart';
import 'package:pos_app/screens/credit/credit_customers_screen.dart';
import 'package:pos_app/screens/reports/inventory_report_screen.dart';
import 'package:pos_app/screens/sales/sale_details_screen.dart';
import 'package:pos_app/screens/sales/sales_history_screen.dart';
import 'package:pos_app/widget/reports_dashboard_widget.dart';
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Sales Overview with adjusted sizing to prevent overflow
  Widget _buildSalesOverview({required String currencySymbol}) {
    final theme = Theme.of(context);
    final salesStats = _dashboardData.salesStats;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      // Increased ratio to make cards wider relative to height (prevents overflow)
      childAspectRatio: 1.2, // Changed from 1.05 to 1.2
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
          // Removed trend to save space
        ),
        _buildStatCard(
          title: 'This Week\'s Sales',
          value: '${salesStats['week']['count']}',
          icon: Icons.calendar_view_week,
          color: theme.colorScheme.tertiary,
          subtitle: _formatAmount(salesStats['week']['amount'], currencySymbol),
          // Removed trend to save space
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
          // Removed trend to save space
        ),
        _buildStatCard(
          title: 'Average Sale',
          value: '',
          icon: Icons.show_chart,
          color: const Color(0xFF8E44AD),
          subtitle: _formatAmount(salesStats['average_sale'], currencySymbol),
          // Removed subtitle2 to save space
        ),
      ],
    );
  }

  // FIXED: Stats Overview with adjusted sizing to prevent overflow
  Widget _buildStatsOverview({required String currencySymbol}) {
    final theme = Theme.of(context);
    final stats = _dashboardData.stats;

    // Parse total stock value which might be a string
    String totalStockValue = _formatAmount(
      _dashboardData.totalStockValue,
      currencySymbol,
    );

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      // Decreased ratio to give more height relative to width (prevents overflow)
      childAspectRatio: 0.85, // Changed from 1.05 to 0.85
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

  // FIXED: Stat Card with optimized layout to prevent overflow
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
        // Reduced padding to save space
        padding: const EdgeInsets.all(12.0), // Changed from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Added this to prevent expansion
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      8,
                    ), // Reduced from 10 to 8
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ), // Reduced from 20 to 16
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ), // Reduced padding
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
                          size: 10, // Reduced from 12 to 10
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 9, // Reduced from 10 to 9
                            fontWeight: FontWeight.bold,
                            color: isPositiveTrend ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8), // Reduced from 16 to 8
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                // Changed from bodyMedium to bodySmall
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Reduced from 8 to 4
            if (value.isNotEmpty)
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  // Changed from headlineSmall to titleLarge
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              subtitle,
              style: theme.textTheme.titleSmall?.copyWith(
                // Changed from titleMedium to titleSmall
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle2 != null) ...[
              const SizedBox(height: 2), // Reduced from 4 to 2
              Text(
                subtitle2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 10, // Added explicit smaller font size
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

  // FIXED: Stats Card with optimized layout to prevent overflow
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
        // Reduced padding to save space
        padding: const EdgeInsets.all(12.0), // Changed from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Prevent expansion
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8 to 6
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8), // Reduced from 10 to 8
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ), // Reduced from 20 to 16
            ),
            const SizedBox(height: 8), // Reduced from 16 to 8
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                // Changed from bodyMedium to bodySmall
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Reduced from 8 to 4
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                // Changed from headlineSmall to titleLarge
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8), // Reduced from 12 to 8
            const Divider(height: 1), // Reduced height
            const SizedBox(height: 4), // Reduced from 8 to 4
            // Make this section scrollable if needed
            Expanded(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children:
                    details
                        .map(
                          (detail) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 4,
                            ), // Reduced from 6 to 4
                            child: Row(
                              children: [
                                Container(
                                  width: 4, // Reduced from 6 to 4
                                  height: 4, // Reduced from 6 to 4
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4), // Reduced from 8 to 4
                                Expanded(
                                  child: Text(
                                    detail,
                                    style:
                                        theme
                                            .textTheme
                                            .bodySmall, // Changed from bodyMedium to bodySmall
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

  Widget _buildSalesTrendChart({required String currencySymbol}) {
    final theme = Theme.of(context);
    final salesTrendData = _dashboardData.salesTrendData;
    final labels = salesTrendData['labels'] as List? ?? [];
    final counts = salesTrendData['counts'] as List? ?? [];
    final amounts = salesTrendData['amounts'] as List? ?? [];

    // Create data points for the chart
    final List<FlSpot> countSpots = [];
    final List<FlSpot> amountSpots = [];

    // Find max values for scaling
    double maxCount = 0;
    double maxAmount = 0;

    for (int i = 0; i < counts.length; i++) {
      // Safely parse values which could be strings or numbers
      double count = _parseDouble(counts[i]);
      double amount = _parseDouble(amounts[i]);

      countSpots.add(FlSpot(i.toDouble(), count));
      amountSpots.add(FlSpot(i.toDouble(), amount));

      if (count > maxCount) maxCount = count;
      if (amount > maxAmount) maxAmount = amount;
    }

    // Ensure max values are at least 1 to avoid division by zero
    maxCount = maxCount == 0 ? 1 : maxCount;
    maxAmount = maxAmount == 0 ? 1 : maxAmount;

    return Container(
      height: 320,
      padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  // Scale amounts for right axis
                  double scaledValue = (value / maxCount) * maxAmount;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      '$currencySymbol ${scaledValue.toInt()}',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  // Only show some x labels to avoid overcrowding
                  if (value.toInt() % 3 != 0) {
                    return const SizedBox.shrink();
                  }
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        labels[value.toInt()].toString(),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: theme.colorScheme.primary,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final dataIndex = touchedSpot.x.toInt();

                  if (touchedSpot.barIndex == 0) {
                    return LineTooltipItem(
                      'Orders: ${counts[dataIndex]}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '\nDate: ${labels[dataIndex]}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return LineTooltipItem(
                      'Revenue: $currencySymbol ${_parseDouble(amounts[dataIndex]).toStringAsFixed(2)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '\nDate: ${labels[dataIndex]}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }
                }).toList();
              },
            ),
          ),
          minX: 0,
          maxX: labels.length.toDouble() - 1,
          minY: 0,
          maxY: maxCount * 1.1, // Add 10% padding
          lineBarsData: [
            // Sales count line
            LineChartBarData(
              spots: countSpots,
              isCurved: true,
              color: theme.colorScheme.secondary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.secondary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
                checkToShowDot: (spot, barData) => spot.x.toInt() % 3 == 0,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.secondary.withOpacity(0.2),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.4),
                    theme.colorScheme.secondary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Sales amount line (scaled to match count scale)
            LineChartBarData(
              spots:
                  amountSpots
                      .map(
                        (spot) =>
                            FlSpot(spot.x, (spot.y / maxAmount) * maxCount),
                      )
                      .toList(),
              isCurved: true,
              color: theme.colorScheme.tertiary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.tertiary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
                checkToShowDot: (spot, barData) => spot.x.toInt() % 3 == 0,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.tertiary.withOpacity(0.2),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.tertiary.withOpacity(0.4),
                    theme.colorScheme.tertiary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsChart({required String currencySymbol}) {
    final theme = Theme.of(context);
    final paymentMethods = _dashboardData.salesByPaymentMethod;

    // Prepare data for the pie chart
    double total = 0;
    for (var method in paymentMethods) {
      total += _parseDouble(method.total);
    }

    // If there's no data, show a placeholder
    if (total == 0 || paymentMethods.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 280,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No payment data available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start recording sales to see payment method distribution',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Define colors for different payment methods
    Map<String, Color> methodColors = {
      'cash': const Color(0xFF4CAF50), // Green
      'card': const Color(0xFF2196F3), // Blue
      'credit': const Color(0xFFFF9800), // Orange
      'mobile': const Color(0xFF9C27B0), // Purple
      'bank': const Color(0xFF795548), // Brown
      'check': const Color(0xFF607D8B), // Blue-Grey
      'other': Colors.grey, // Grey
    };

    // Create an explicit list of PieChartSectionData
    List<PieChartSectionData> sections = [];

    // Create explicit list of legend items
    List<Widget> legendItems = [];

    // Process each payment method
    for (var method in paymentMethods) {
      String methodName = method.method.toString().toLowerCase();
      Color color = methodColors[methodName] ?? Colors.grey;

      double methodTotal = _parseDouble(method.total);
      double percentage = (methodTotal / total) * 100;

      sections.add(
        PieChartSectionData(
          color: color,
          value: methodTotal,
          title: '',
          radius: 100,
          badgeWidget: Container(),
          badgePositionPercentageOffset: 0.98,
        ),
      );

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  method.method.toString().toUpperCase(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatAmount(method.total, currencySymbol),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Based on ${_dashboardData.salesStats['month']['count']} sales this month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Can implement touch interactivity here if needed
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 1,
                  centerSpaceRadius: 40,
                  sections: sections,
                  centerSpaceColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Column(children: legendItems),
          ],
        ),
      ),
    );
  }

  // FIXED: TopProducts List without category access
  Widget _buildTopProductsList({required String currencySymbol}) {
    final theme = Theme.of(context);
    final topProducts = _dashboardData.topProducts;

    if (topProducts.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No product sales data available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start recording sales to see your top products',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with "View All" link
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top ${topProducts.length} Products',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _navigateTo(ProductListScreen());
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table header
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'PRODUCT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'QUANTITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'REVENUE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Table body
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              itemBuilder: (context, index) {
                final product = topProducts[index];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                // Product indicator dot or index badge
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        index < 3
                                            ? [
                                              const Color(0xFFFFD700), // Gold
                                              const Color(0xFFC0C0C0), // Silver
                                              const Color(0xFFCD7F32), // Bronze
                                            ][index]
                                            : theme.colorScheme.primary
                                                .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          index < 3
                                              ? Colors.white
                                              : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${product.totalQuantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatAmount(
                                product.totalRevenue,
                                currencySymbol,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < topProducts.length - 1)
                      const Divider(height: 1),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesList({required String currencySymbol}) {
    final theme = Theme.of(context);
    final recentSales = _dashboardData.recentSales;

    if (recentSales.isEmpty) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No recent sales data available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recent sales will appear here as they are made',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSales.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final sale = recentSales[index];

                // Determine payment method icon
                IconData paymentIcon;
                Color paymentColor;

                switch (sale.paymentMethod.toLowerCase()) {
                  case 'cash':
                    paymentIcon = Icons.payments_outlined;
                    paymentColor = Colors.green;
                    break;
                  case 'card':
                  case 'credit card':
                    paymentIcon = Icons.credit_card;
                    paymentColor = Colors.blue;
                    break;
                  case 'mobile':
                  case 'mobile money':
                    paymentIcon = Icons.phone_android;
                    paymentColor = Colors.purple;
                    break;
                  case 'credit':
                    paymentIcon = Icons.account_balance_wallet_outlined;
                    paymentColor = Colors.orange;
                    break;
                  default:
                    paymentIcon = Icons.payments_outlined;
                    paymentColor = Colors.grey;
                }

                return InkWell(
                  onTap: () {
                    _navigateTo(SaleDetailsScreen(saleId: sale.id));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Payment method icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: paymentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            paymentIcon,
                            color: paymentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Sale details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sale.customerName.isEmpty
                                        ? 'Walk-in Customer'
                                        : sale.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _formatAmount(
                                      sale.totalAmount,
                                      currencySymbol,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Receipt #${sale.receiptNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    sale.createdAt,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
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
                );
              },
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: () {
                  _navigateTo(const SalesHistoryScreen());
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  side: BorderSide(color: theme.colorScheme.secondary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('View All Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: LowStockProducts List with proper category access
  Widget _buildLowStockProductsList() {
    final theme = Theme.of(context);
    final lowStockProducts = _dashboardData.lowStockProducts;

    if (lowStockProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
              const SizedBox(height: 8),
              Text(
                'All products are well stocked',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lowStockProducts.length > 3 ? 3 : lowStockProducts.length,
      itemBuilder: (context, index) {
        final product = lowStockProducts[index];

        // Calculate stock percentage relative to minimum stock
        double stockPercentage = product.stock / product.minStock;
        stockPercentage = stockPercentage > 1 ? 1 : stockPercentage;

        // Get category name from the category map
        String categoryName = product.category['name'] ?? 'Uncategorized';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Product image or icon placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 16),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Stock progress indicator
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: stockPercentage,
                              backgroundColor: Colors.grey.shade200,
                              color:
                                  stockPercentage < 0.3
                                      ? Colors.red
                                      : stockPercentage < 0.7
                                      ? Colors.orange
                                      : Colors.green,
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${product.stock}/${product.minStock}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                stockPercentage < 0.3
                                    ? Colors.red
                                    : stockPercentage < 0.7
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Update button
              IconButton(
                onPressed: () {
                  _navigateTo(
                    LowStockScreen(
                      currencySymbol:
                          _dashboardData.settings['currency_symbol'] ?? '\$',
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                color: theme.colorScheme.error,
                tooltip: 'Update Stock',
              ),
            ],
          ),
        );
      },
    );
  }
}
