import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/enhanced_logo.dart';
import 'otp_verification_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  final UserRole selectedRole;

  const SignupPage({super.key, required this.selectedRole});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }

    // Remove any spaces or special characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length != 10) {
      return 'Mobile number must be 10 digits';
    }

    if (!cleaned.startsWith('0')) {
      return 'Mobile number must start with 0';
    }

    return null;
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mobileNumber = _mobileController.text.trim();

      // Check if mobile number is already registered
      final isRegistered = await AuthService.isMobileRegistered(mobileNumber);
      if (isRegistered) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobile number already registered. Please login instead.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Send OTP
      final otp = await AuthService.sendOTP(mobileNumber);

      if (mounted) {
        // Navigate to OTP verification
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              mobileNumber: mobileNumber,
              isSignup: true,
              selectedRole: widget.selectedRole,
              demoOTP: otp, // Remove in production
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo and Title
              Center(
                child: Column(
                  children: [
                    const EnhancedLogo(
                      width: 120,
                      height: 120,
                      animated: false,
                      glowEffect: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'BURNER',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SUPER APP',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.secondaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Welcome Text
              Text(
                'Create ${widget.selectedRole.displayName} Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.selectedRole == UserRole.employee
                      ? AppColors.primaryOrange.withValues(alpha: 0.1)
                      : AppColors.secondaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.selectedRole == UserRole.employee
                        ? AppColors.primaryOrange.withValues(alpha: 0.3)
                        : AppColors.secondaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.selectedRole == UserRole.employee ? Icons.work : Icons.person,
                      size: 16,
                      color: widget.selectedRole == UserRole.employee
                          ? AppColors.primaryOrange
                          : AppColors.secondaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.selectedRole.displayName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.selectedRole == UserRole.employee
                            ? AppColors.primaryOrange
                            : AppColors.secondaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your mobile number to get started',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Number',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: '0771234567',
                        prefixIcon: Icon(
                          Icons.phone,
                          color: AppColors.primaryOrange,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.secondaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primaryOrange,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: _validateMobile,
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Send OTP',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Login',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.secondaryBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We\'ll send you a verification code via SMS to confirm your mobile number.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}