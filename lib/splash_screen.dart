import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _elevationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateUser();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _elevationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _elevationController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
    _elevationController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _elevationController.dispose();
    super.dispose();
  }

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 4));
    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;
    final isLargeScreen = size.height > 800;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
              colorScheme.secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Top Material card with elevation
                        SizedBox(
                          height: isSmallScreen ? 80 : (isLargeScreen ? 120 : 100),
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: AnimatedBuilder(
                                animation: _elevationAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -8 * _elevationAnimation.value),
                                    child: Material(
                                      elevation: 8 + (12 * _elevationAnimation.value),
                                      borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 20 : 28,
                                      ),
                                      color: colorScheme.surface.withOpacity(0.9),
                                      child: Container(
                                        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 20 : 28,
                                          ),
                                          border: Border.all(
                                            color: colorScheme.outline.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.account_balance_wallet,
                                          size: isSmallScreen ? 40 : 60,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        // Main content with Material surface
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                                  // Enhanced logo with Material elevation
                                  AnimatedBuilder(
                                    animation: _elevationAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, -4 * _elevationAnimation.value),
                                        child: Material(
                                          elevation: 16 + (8 * _elevationAnimation.value),
                                          borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 30 : 40,
                                          ),
                                          color: colorScheme.surface,
                                          child: Container(
                                            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                isSmallScreen ? 30 : 40,
                                              ),
                                              border: Border.all(
                                                color: colorScheme.outline.withOpacity(0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: ScaleTransition(
                                              scale: _scaleAnimation,
                                              child: Icon(
                                                Icons.account_balance_wallet,
                                                size: isSmallScreen ? 60 : 80,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 20 : 32),
                                  
                                  // App name with Material typography
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 16 : 24,
                                    ),
                                    child: Text(
              "FinGenAI",
                                      style: (isSmallScreen 
                                        ? Theme.of(context).textTheme.headlineLarge
                                        : Theme.of(context).textTheme.displayMedium)?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.onSurface,
                                        letterSpacing: isSmallScreen ? 1.5 : 2.0,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 2),
                                            blurRadius: 8,
                                            color: colorScheme.shadow.withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                  
                                  // Subtitle with Material design
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 20 : 32,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 12 : 16,
                                        vertical: isSmallScreen ? 6 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 16 : 20,
                                        ),
                                        border: Border.all(
                                          color: colorScheme.outline.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "Smart Financial Intelligence",
                                        style: (isSmallScreen
                                          ? Theme.of(context).textTheme.bodyMedium
                                          : Theme.of(context).textTheme.bodyLarge)?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurfaceVariant,
                                          letterSpacing: isSmallScreen ? 0.3 : 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: isSmallScreen ? 24 : 40),
                                  
                                  // Enhanced loading indicator with Material design
                                  Material(
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 20 : 24,
                                    ),
                                    color: colorScheme.surface,
                                    child: Container(
                                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 20 : 24,
                                        ),
                                        border: Border.all(
                                          color: colorScheme.outline.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: SizedBox(
                                        width: isSmallScreen ? 24 : 32,
                                        height: isSmallScreen ? 24 : 32,
                                        child: CircularProgressIndicator(
                                          color: colorScheme.primary,
                                          strokeWidth: isSmallScreen ? 2.5 : 3,
                                          backgroundColor: colorScheme.surfaceVariant,
              ),
            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Bottom Material chips
                        SizedBox(
                          height: isSmallScreen ? 60 : 80,
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final chipWidth = (constraints.maxWidth - 40) / 3;
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildMaterialChip(
                                        colorScheme, 
                                        "AI", 
                                        Icons.psychology,
                                        chipWidth,
                                        isSmallScreen,
                                      ),
                                      _buildMaterialChip(
                                        colorScheme, 
                                        "Finance", 
                                        Icons.trending_up,
                                        chipWidth,
                                        isSmallScreen,
                                      ),
                                      _buildMaterialChip(
                                        colorScheme, 
                                        "Smart", 
                                        Icons.lightbulb,
                                        chipWidth,
                                        isSmallScreen,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialChip(
    ColorScheme colorScheme, 
    String label, 
    IconData icon,
    double width,
    bool isSmallScreen,
  ) {
    return SizedBox(
      width: width,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        color: colorScheme.surface,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isSmallScreen ? 14 : 16,
                color: colorScheme.primary,
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Flexible(
                child: Text(
                  label,
                  style: (isSmallScreen
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodySmall)?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}
