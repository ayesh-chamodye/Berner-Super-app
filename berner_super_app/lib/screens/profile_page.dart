import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/enhanced_logo.dart';
import 'auth/auth_wrapper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          backgroundColor: AppColors.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Logging out...',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                // Clear user session
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (mounted) {
                  Navigator.of(context).pop(); // Close loading dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : _currentUser == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try logging in again',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                        ),
                        child: const Text(
                          'Go to Login',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Image Section
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryOrange,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.1),
                          backgroundImage: _currentUser?.profilePicturePath != null
                              ? AssetImage(_currentUser!.profilePicturePath!)
                              : null,
                          child: _currentUser?.profilePicturePath == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primaryOrange,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // User Name
                      Text(
                        _currentUser?.name ?? 'Unknown User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // User Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _currentUser?.role == UserRole.employee
                              ? AppColors.primaryOrange.withValues(alpha: 0.1)
                              : AppColors.secondaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _currentUser?.role == UserRole.employee
                                ? AppColors.primaryOrange
                                : AppColors.secondaryBlue,
                          ),
                        ),
                        child: Text(
                          _currentUser?.role == UserRole.employee ? 'Employee' : 'Customer',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _currentUser?.role == UserRole.employee
                                ? AppColors.primaryOrange
                                : AppColors.secondaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Profile Information Cards
                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Mobile Number',
                        value: _currentUser?.mobileNumber ?? 'Not provided',
                      ),

                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.badge,
                        title: 'NIC Number',
                        value: _currentUser?.nic ?? 'Not provided',
                      ),

                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.cake,
                        title: 'Date of Birth',
                        value: _currentUser?.dateOfBirth != null
                            ? '${_currentUser!.dateOfBirth!.day}/${_currentUser!.dateOfBirth!.month}/${_currentUser!.dateOfBirth!.year}'
                            : 'Not provided',
                      ),

                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: _currentUser?.gender == 'male' ? Icons.male : Icons.female,
                        title: 'Gender',
                        value: _currentUser?.gender?.toUpperCase() ?? 'Not provided',
                      ),

                      if (_currentUser?.role == UserRole.employee) ...[
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.admin_panel_settings,
                          title: 'ADM Code',
                          value: _currentUser?.admCode ?? 'Not provided',
                        ),
                      ],

                      const SizedBox(height: 40),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Logout',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // App Version Info with Enhanced Logo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryOrange.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const CompactEnhancedLogo(
                              size: 40,
                              showGlow: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Burner Super App',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version 1.0.0',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}