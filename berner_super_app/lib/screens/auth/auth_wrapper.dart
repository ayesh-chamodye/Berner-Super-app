import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../home_page.dart';
import '../splash_screen.dart';
import 'login_page.dart';
import 'profile_setup_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      UserModel? user;

      if (isLoggedIn) {
        user = await AuthService.getCurrentUser();
      }

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    if (!_isLoggedIn || _currentUser == null) {
      return const LoginPage();
    }

    // Check if profile is complete
    if (!_currentUser!.isProfileComplete) {
      return ProfileSetupPage(user: _currentUser!);
    }

    return const HomePage();
  }
}