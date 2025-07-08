import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opticore POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
      ),
      home: const SplashScreen(),
    );
  }
}
