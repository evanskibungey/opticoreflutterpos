// lib/widgets/reports_dashboard_widget.dart
import 'package:flutter/material.dart';
import '../screens/reports/sales_report_screen.dart';
// You'll need to create these other report screens
// import '../screens/reports/inventory_report_screen.dart';
// import '../screens/reports/users_report_screen.dart';
// import '../screens/reports/stock_movements_report_screen.dart';

class ReportsDashboardWidget extends StatelessWidget {
  const ReportsDashboardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen width to make responsive adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    // Adjust grid settings based on screen size
    final crossAxisCount = isSmallScreen ? 1 : 2;
    // Increased aspect ratio for more height to prevent overflow
    final childAspectRatio = isSmallScreen ? 3.5 : (screenWidth > 600 ? 2.0 : 1.2); 
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Reports',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // Report options grid with improved responsiveness
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio, // More height to prevent overflow
              children: [
                _buildReportCard(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Sales Report',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesReportScreen(),
                      ),
                    );
                  },
                ),
                _buildReportCard(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Inventory Report',
                  color: Colors.green,
                  onTap: () {
                    // Navigate to inventory report
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Inventory report will be available soon'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  },
                ),
                _buildReportCard(
                  context,
                  icon: Icons.people,
                  title: 'Users Report',
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to users report
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Users report will be available soon'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  },
                ),
                _buildReportCard(
                  context,
                  icon: Icons.local_shipping,
                  title: 'Stock Movements',
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to stock movements report
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Stock movements report will be available soon'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Determine if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          // Simple solid color background to avoid potential issues
          color: Colors.white,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isSmallScreen ? 8 : 10, // Reduced vertical padding
        ),
        child: isSmallScreen
            // Horizontal layout for small screens - simplified
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            // Vertical layout for larger screens - simplified
            : Center( // Center everything
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Take minimum space needed
                  mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                  children: [
                    // Icon with background
                    Container(
                      padding: const EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24, // Reduced size
                      ),
                    ),
                    const SizedBox(height: 8), // Reduced spacing
                    // Title text
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Limit to one line to prevent overflow
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}