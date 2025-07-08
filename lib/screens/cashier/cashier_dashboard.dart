import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/report_service.dart'; // Added import for ReportService
import '../../models/dashboard_models.dart';
import '../../models/report_models.dart'; // Added import for report models
import '../../screens/login_screen.dart';
import '../../screens/pos/pos_sales_screen.dart';
import '../../screens/sales/sales_history_screen.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({Key? key}) : super(key: key);

  @override
  _CashierDashboardState createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  final ReportService _reportService = ReportService(); // Added ReportService instance
  bool _isLoading = true;
  CashierDashboardData? _dashboardData;
  String? _errorMessage;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _salesReportData; // Added to store sales report data

  // Theme colors
  final Color _primaryColor = const Color(0xFF3B82F6); // blue-500
  final Color _primaryDarkColor = const Color(0xFF2563EB); // blue-600
  final Color _successColor = const Color(0xFF10B981); // green-500
  final Color _dangerColor = const Color(0xFFEF4444); // red-500
  final Color _warningColor = const Color(0xFFF59E0B); // amber-500
  final Color _infoColor = const Color(0xFF6366F1); // indigo-500
  final Color _surfaceColor = Colors.white;
  final Color _backgroundColor = const Color(0xFFF9FAFB); // gray-50

  // Default currency symbol - will be overridden with data from API
  String _currencySymbol = 'KSh';

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
    _reportService.cancelAllRequests(); // Cancel any active report requests
    super.dispose();
  }

  // Format date to readable form
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  // Helper method to safely format amounts that could be strings or numbers
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    if (amount is double) return amount.toStringAsFixed(2);
    if (amount is int) return amount.toDouble().toStringAsFixed(2);
    if (amount is String) {
      try {
        return double.parse(amount).toStringAsFixed(2);
      } catch (e) {
        return '0.00';
      }
    }
    return '0.00';
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load dashboard data
      final dashboardData = await _dashboardService.getCashierDashboardData();

      // Create a filter for today's sales data
      final todaySalesFilter = SalesReportFilter(
        dateRange: 'today', // Use 'today' to match the report screen's default
        page: 1,
        perPage: 50, // Reasonable number for summary
      );
      
      // Fetch today's sales report data
      final salesReportData = await _reportService.getSalesReport(
        todaySalesFilter,
        requestId: 'dashboard_today_sales',
        useCache: false, // Ensure we get fresh data
      );

      // Add a small delay to make the loading animation visible
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _salesReportData = salesReportData;
          
          // Get currency symbol from settings if available
          _currencySymbol = dashboardData.settings['currency_symbol'] ?? 'KSh';
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
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Show loading indicator
              Navigator.of(dialogContext).pop(); // Close dialog first
              
              // Show a loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                // Cancel any pending report requests
                _reportService.cancelAllRequests();
                
                // Clear any caches if needed
                _reportService.clearCache();
                
                // Perform the logout operation
                await _authService.logout();
                
                // Close the loading dialog if it's showing
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                
                // Navigate to login screen and clear all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false, // This predicate removes all previous routes
                );
              } catch (e) {
                // Handle any errors during logout
                // Close the loading dialog if it's showing
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error during logout: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _navigateToPOS() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => POSSalesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeScaleTransition(animation: animation, child: child);
        },
      ),
    );
  }

  void _navigateToSalesHistory() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SalesHistoryScreen(),
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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            if (_dashboardData != null) ...[
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _dashboardData!.settings['company_name'] ?? 'Company',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const Text('Cashier Dashboard'),
            ],
          ],
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          // Notifications button
          IconButton(
            icon: Badge(
              label: Text(_dashboardData?.lowStockCount?.toString() ?? '0'),
              isLabelVisible: (_dashboardData?.lowStockCount ?? 0) > 0,
              child: const Icon(Icons.notifications_outlined, size: 24),
            ),
            onPressed: () {
              // Show low stock notification
              if ((_dashboardData?.lowStockCount ?? 0) > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_dashboardData!.lowStockCount} products are low in stock. Please notify manager.'),
                    backgroundColor: _warningColor,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('No new notifications'),
                    backgroundColor: _infoColor,
                  ),
                );
              }
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
      body: _isLoading
          ? _buildLoadingShimmer()
          : _errorMessage != null
              ? _buildErrorState()
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildDashboardContent(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToPOS,
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.point_of_sale),
        label: const Text('New Sale'),
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
            backgroundColor: Color(0xFF3B82F6),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Cashier User',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'cashier@example.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: _primaryColor,
            ),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: _dangerColor),
            title: Text(
              'Logout',
              style: TextStyle(
                color: _dangerColor,
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
            decoration: BoxDecoration(color: _primaryColor),
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
                  'Cashier Panel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dashboardData != null
                      ? _dashboardData!.settings['company_name'] ?? 'Company'
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
            icon: Icons.point_of_sale,
            title: 'POS Terminal',
            onTap: () {
              Navigator.pop(context);
              _navigateToPOS();
            },
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long_outlined,
            title: 'Sales History',
            onTap: () {
              Navigator.pop(context);
              _navigateToSalesHistory();
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(),
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            textColor: _dangerColor,
            iconColor: _dangerColor,
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
          color: isSelected ? _primaryColor : iconColor ?? Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? _primaryColor : textColor ?? Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: isNew
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _infoColor,
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
                    backgroundColor: badgeColor ?? _primaryColor,
                  )
                : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        selectedTileColor: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
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
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
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

            // Quick actions shimmer
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent sales title shimmer
            Container(
              height: 24,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),

            // Recent sales list shimmer
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
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
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: _dangerColor,
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
                backgroundColor: _primaryColor,
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
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    final theme = Theme.of(context);
    
    // Get sales stats from the report service data instead of dashboard data
    final int todaySalesCount = _salesReportData != null && _salesReportData!.containsKey('summary') 
        ? (_salesReportData!['summary'] as SalesReportSummary).totalSales 
        : 0;
    
    final double todaySalesAmount = _salesReportData != null && _salesReportData!.containsKey('summary') 
        ? (_salesReportData!['summary'] as SalesReportSummary).totalRevenue 
        : 0.0;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: _primaryColor,
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
              // Welcome card with today's date
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor,
                        _primaryDarkColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _navigateToPOS,
                        icon: const Icon(Icons.point_of_sale),
                        label: const Text('Start New Sale'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Today's Summary section
              Row(
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    color: _primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Today\'s Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Sales overview cards - Using data from the report service
              Row(
                children: [
                  // Today's Sales Count
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.receipt,
                                    color: _successColor,
                                    size: 20,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: TextStyle(
                                      color: _successColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sales Count',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$todaySalesCount',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Transactions',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Today's Revenue
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.attach_money,
                                    color: _primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: TextStyle(
                                      color: _primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Revenue',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_currencySymbol ${_formatAmount(todaySalesAmount)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Revenue',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions section
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: _primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quick action cards
              Row(
                children: [
                  // New Sale card
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: _navigateToPOS,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.point_of_sale,
                                  color: _primaryColor,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'New Sale',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a new transaction',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // View Sales History card
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: _navigateToSalesHistory,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _infoColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: _infoColor,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sales History',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'View past transactions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent Sales section
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: _primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Sales',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _navigateToSalesHistory,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Recent sales list - Now we could use sales from the report if needed
              _buildRecentSalesList(),
              
              // If low stock alert is present, show it
              if (_dashboardData!.lowStockAlert) ...[
                const SizedBox(height: 24),
                _buildLowStockAlert(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSalesList() {
    // Option to use either dashboard data or sales report data for recent sales
    final recentSales = _dashboardData!.recentSales;

    if (recentSales.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'No recent sales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make your first sale of the day!',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToPOS,
                icon: const Icon(Icons.add),
                label: const Text('New Sale'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSales.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final sale = recentSales[index];
                
                // Format the time
                String displayTime = sale.time;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    child: Icon(Icons.receipt, color: _primaryColor),
                  ),
                  title: Text(
                    'Receipt #${sale.receiptNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${sale.items} items • $displayTime',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: Text(
                    '$_currencySymbol ${sale.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _successColor,
                    ),
                  ),
                  onTap: () {
                    // View sale details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Viewing details of receipt #${sale.receiptNumber}'),
                        action: SnackBarAction(
                          label: 'View',
                          onPressed: _navigateToSalesHistory,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Card(
      elevation: 0,
      color: _warningColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _warningColor,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Low Stock Alert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _warningColor,
                    ),
                  ),
                  Text(
                    '${_dashboardData!.lowStockCount} products are running low on stock. Please notify manager.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}