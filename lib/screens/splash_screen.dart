import 'package:flutter/material.dart';
import 'package:pos_app/utils/lpg_cylinder_painter.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'cashier/cashier_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade animation
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Scale animation for the logo
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    // Slide animation for text
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    // Rotation animation for the cylinder decorations
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate loading time
    final user = await _authService.getCurrentUser();

    Widget nextScreen;
    if (user != null) {
      if (user.isAdmin()) {
        nextScreen = const AdminDashboard();
      } else if (user.isCashier()) {
        nextScreen = const CashierDashboard();
      } else {
        nextScreen = const LoginScreen();
      }
    } else {
      nextScreen = const LoginScreen();
    }

    // Navigate to the determined screen and remove splash from history
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFFD35400),  // Deeper orange
                  const Color(0xFFE67E22),  // Medium orange
                  const Color(0xFFF39C12),  // Lighter orange/amber
                ],
              ),
            ),
          ),
          
          // Background pattern (diagonal lines)
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pattern.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          
          // Decorative large cylinders
          Positioned(
            top: -screenSize.height * 0.15,
            right: -screenSize.width * 0.2,
            child: RotationTransition(
              turns: _rotateAnimation,
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: LPGCylinderPainter(
                    baseColor: Colors.white,
                    borderColor: Colors.white70,
                  ),
                  size: Size(screenSize.width * 0.6, screenSize.width * 0.6),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: -screenSize.height * 0.1,
            left: -screenSize.width * 0.2,
            child: RotationTransition(
              turns: Tween<double>(begin: 0, end: -0.05).animate(_controller),
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: LPGCylinderPainter(
                    baseColor: Colors.white,
                    borderColor: Colors.white70,
                  ),
                  size: Size(screenSize.width * 0.5, screenSize.width * 0.5),
                ),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top spacer
                  const Spacer(flex: 1),
                  
                  // Logo and main content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo with animations
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: CustomPaint(
                              painter: LPGCylinderPainter(
                                baseColor: Colors.white,
                                borderColor: Colors.white70,
                                showShadow: true,
                              ),
                              size: const Size(160, 160),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // App Name with Slide and Fade Animations
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  "ELDO GAS",
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 3,
                                    height: 0.9,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black45,
                                        offset: const Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Tagline
                                Text(
                                  "POINT OF SALE SYSTEM",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.85),
                                    letterSpacing: 4,
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Horizontal divider
                                Container(
                                  width: 80,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom spacer
                  const Spacer(flex: 2),
                  
                  // Loading Indicator with Animation at bottom
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Loading text
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            "LOADING",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        
                        // Progress indicator
                        Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Version info
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 0.7).animate(_fadeAnimation),
                    child: Text(
                      "v1.0.0",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

