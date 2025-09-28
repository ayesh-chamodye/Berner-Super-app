import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/enhanced_logo.dart';
import 'auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthWrapper(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondaryBlue.withValues(alpha: 0.1),
              AppColors.primaryOrange.withValues(alpha: 0.1),
              AppColors.backgroundPrimary,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Enhanced Logo with animations
                      const EnhancedLogo(
                        width: 200,
                        height: 200,
                        animated: true,
                        glowEffect: true,
                      ),

                      const SizedBox(height: 40),

                      // App Title
                      Text(
                        'BURNER',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'SUPER APP',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.secondaryBlue,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading indicator
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryOrange,
                          ),
                          backgroundColor: AppColors.secondaryBlue.withValues(alpha: 0.3),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Loading...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}