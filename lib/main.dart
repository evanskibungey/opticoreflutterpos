import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/thermal_printer_service.dart';

void main() {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Thermal Printer Service as a singleton provider
        ChangeNotifierProvider<ThermalPrinterService>(
          create: (context) => ThermalPrinterService.instance,
          lazy: false, // Initialize immediately to enable auto-reconnection
        ),
        // Add other providers here as needed
        // Example: ChangeNotifierProvider<AuthService>(create: (context) => AuthService()),
        // Example: ChangeNotifierProvider<SettingsService>(create: (context) => SettingsService()),
      ],
      child: Consumer<ThermalPrinterService>(
        builder: (context, printerService, child) {
          return MaterialApp(
            title: 'Opticore POS',
            debugShowCheckedModeBanner: false,
            theme: _buildAppTheme(context),
            home: const SplashScreen(),
            // Add global navigator observers for better state management
            navigatorObservers: [
              _AppNavigatorObserver(),
            ],
          );
        },
      ),
    );
  }

  /// Build the main app theme with Opticore branding
  ThemeData _buildAppTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        primary: const Color(0xFF3B82F6), // Blue-500
        secondary: const Color(0xFF2563EB), // Blue-600
        tertiary: const Color(0xFF60A5FA), // Blue-400
        error: const Color(0xFFEF4444), // Red
        background: const Color(0xFFF9FAFB), // Light grey background
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF3B82F6), // Blue-500
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: GoogleFonts.figtreeTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          backgroundColor: const Color(0xFF3B82F6), // Blue-500 for buttons
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3B82F6), // Blue-500
          side: const BorderSide(color: Color(0xFF3B82F6)), // Blue-500
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF3B82F6), // Blue-500
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
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
          borderSide: const BorderSide(
            color: Color(0xFF3B82F6),
            width: 2,
          ), // Blue-500
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      dividerTheme: const DividerThemeData(
        space: 20,
        thickness: 1,
        color: Color(0xFFE5E7EB), // Gray-200
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFF6FF), // Blue-50
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(color: const Color(0xFF1D4ED8)), // Blue-700
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Gray-50
      visualDensity: VisualDensity.adaptivePlatformDensity,
      drawerTheme: DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF3B82F6), // Blue-500
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF3B82F6), // Blue-500
      ),
      tabBarTheme: TabBarTheme(
        labelColor: const Color(0xFF3B82F6), // Blue-500
        unselectedLabelColor: Colors.grey.shade600,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF3B82F6), // Blue-500
              width: 2,
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3B82F6), // Blue-500
        unselectedItemColor: Colors.grey.shade600,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      // Add snackbar theme for consistent styling
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937), // Gray-800
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      // Add dialog theme for consistent styling
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937), // Gray-800
        ),
        contentTextStyle: GoogleFonts.figtree(
          fontSize: 16,
          color: const Color(0xFF4B5563), // Gray-600
        ),
      ),
      // Add bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Custom navigator observer to handle app state changes and printer management
class _AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRouteChange(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  /// Handle route changes to manage printer connection states
  void _handleRouteChange(Route<dynamic> route) {
    // Get the route name
    final routeName = route.settings.name ?? route.toString();
    
    // If navigating to printer-related screens, ensure printer service is ready
    if (routeName.contains('printer') || 
        routeName.contains('receipt') || 
        routeName.contains('pos') ||
        routeName.contains('sales')) {
      
      // We could trigger printer status checks here if needed
      // This is useful for screens that heavily rely on printer functionality
      _checkPrinterStatusForRoute(routeName);
    }
  }

  /// Check printer status for specific routes
  void _checkPrinterStatusForRoute(String routeName) {
    // This method can be used to implement route-specific printer logic
    // For example, auto-reconnection attempts when entering POS screens
    
    // Note: We avoid directly accessing the printer service here to prevent
    // context issues. Instead, the screens themselves should handle printer
    // status checks in their initState or build methods.
    
    print('Route changed to: $routeName - Printer status should be checked');
  }
}

/// Global error handler for the application
class GlobalErrorHandler {
  static void handleError(Object error, StackTrace stackTrace) {
    // Log the error
    debugPrint('Global error: $error');
    debugPrint('Stack trace: $stackTrace');
    
    // You could send errors to a crash reporting service here
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  
  /// Handle printer-specific errors globally
  static void handlePrinterError(String error, {String? context}) {
    debugPrint('Printer error${context != null ? ' in $context' : ''}: $error');
    
    // You could implement global printer error handling here
    // Such as showing persistent notifications or auto-retry logic
  }
}

/// Extension to provide easy access to printer service from any widget
extension BuildContextExtensions on BuildContext {
  /// Get the printer service instance
  ThermalPrinterService get printerService => read<ThermalPrinterService>();
  
  /// Watch printer service for reactive updates
  ThermalPrinterService get watchPrinterService => watch<ThermalPrinterService>();
  
  /// Check if printer is connected
  bool get isPrinterConnected => read<ThermalPrinterService>().isConnected;
  
  /// Get current printer status
  PrinterConnectionStatus get printerStatus => read<ThermalPrinterService>().connectionStatus;
}

/// App-wide constants for consistent styling and behavior
class AppConstants {
  // Printer settings
  static const int defaultPrinterPort = 9100;
  static const Duration printerConnectionTimeout = Duration(seconds: 10);
  static const Duration printerReconnectDelay = Duration(seconds: 3);
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 2.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color secondaryBlue = Color(0xFF2563EB);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF97316);
  
  // Text styles
  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2937),
  );
  
  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF374151),
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Color(0xFF4B5563),
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF6B7280),
  );
}

/// Utility class for app-wide helper functions
class AppUtils {
  /// Format currency amounts consistently
  static String formatCurrency(double amount, {String symbol = 'KSh'}) {
    return '$symbol ${amount.toStringAsFixed(2)}';
  }
  
  /// Format date consistently across the app
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Format date and time consistently
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Show consistent snackbar messages
  static void showSnackBar(
    BuildContext context, 
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: Colors.white,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: AppConstants.successGreen,
    );
  }
  
  /// Show error message
  static void showError(BuildContext context, String message, {VoidCallback? retry}) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: AppConstants.errorRed,
      duration: const Duration(seconds: 5),
      actionLabel: retry != null ? 'RETRY' : null,
      onAction: retry,
    );
  }
  
  /// Show warning message
  static void showWarning(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: AppConstants.warningOrange,
    );
  }
  
  /// Show printer error with setup option
  static void showPrinterError(BuildContext context, String message) {
    showSnackBar(
      context, 
      message, 
      backgroundColor: AppConstants.errorRed,
      duration: const Duration(seconds: 5),
      actionLabel: 'SETUP',
      onAction: () {
        // Navigate to printer settings
        Navigator.pushNamed(context, '/printer-settings');
      },
    );
  }
}
