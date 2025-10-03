import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
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
  bool _isEditMode = false;
  bool _isSaving = false;

  // Controllers for editable fields
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;

          // Populate controllers with current data
          if (user != null) {
            _nameController.text = user.fullName ?? user.name ?? '';
            _nicController.text = user.nic ?? '';
            _selectedGender = user.gender;
            _selectedDate = user.dateOfBirth;
          }
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

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Cancel edit - reload original data
        if (_currentUser != null) {
          _nameController.text = _currentUser!.fullName ?? _currentUser!.name ?? '';
          _nicController.text = _currentUser!.nic ?? '';
          _selectedGender = _currentUser!.gender;
          _selectedDate = _currentUser!.dateOfBirth;
          _selectedImage = null; // Reset selected image
        }
      }
    });
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveProfile() async {
    if (_currentUser == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      print('🔵 ProfilePage: Saving profile changes');

      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final fullName = _nameController.text.trim();
      final genderValue = _selectedGender?.toLowerCase();

      // Handle profile picture if selected
      String? profilePictureUrl = _currentUser!.profilePictureUrl;
      if (_selectedImage != null) {
        // Upload to Supabase Storage
        print('🔵 ProfilePage: Uploading profile picture to Supabase...');
        final uploadedUrl = await SupabaseService.uploadProfilePicture(
          _selectedImage!.path,
          _currentUser!.id,
        );

        if (uploadedUrl != null) {
          profilePictureUrl = uploadedUrl;
          print('🟢 ProfilePage: Profile picture uploaded successfully');
        } else {
          print('⚠️ ProfilePage: Profile picture upload failed, using local path');
          profilePictureUrl = _selectedImage!.path;
        }
      }

      // Try to save to Supabase
      try {
        await SupabaseService.createOrUpdateUserProfile(
          mobileNumber: _currentUser!.mobileNumber,
          firstName: firstName,
          lastName: lastName,
          fullName: fullName,
          nic: _nicController.text.trim(),
          dateOfBirth: _selectedDate,
          gender: genderValue,
          profilePictureUrl: profilePictureUrl,
        );
        print('🟢 ProfilePage: Profile updated in Supabase');
      } catch (e) {
        print('⚠️ ProfilePage: Supabase update failed: $e');
        // Continue to save locally
      }

      // Update local user model
      final updatedUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        nic: _nicController.text.trim(),
        dateOfBirth: _selectedDate,
        gender: genderValue,
        profilePictureUrl: profilePictureUrl,
      );

      await AuthService.updateUserProfile(updatedUser);
      print('🟢 ProfilePage: Profile updated locally');

      // Reload user data
      _loadUserData();

      if (mounted) {
        setState(() {
          _isEditMode = false;
          _isSaving = false;
          _selectedImage = null; // Clear selected image
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _changePhoneNumber() async {
    final newPhoneController = TextEditingController();
    final otpController = TextEditingController();

    // Step 1: Enter new phone number
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Change Phone Number',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your new phone number to receive OTP',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'New Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPhone = newPhoneController.text.trim();
                if (newPhone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter phone number')),
                  );
                  return;
                }

                // Send OTP
                final result = await AuthService.sendOTP(newPhone);
                if (result['success']) {
                  Navigator.of(context).pop();

                  // Step 2: Verify OTP
                  _verifyPhoneChangeOTP(newPhone, otpController);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to send OTP'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text(
                'Send OTP',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _verifyPhoneChangeOTP(String newPhone, TextEditingController otpController) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Verify OTP',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the OTP sent to $newPhone',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'OTP Code',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text.trim();
                if (otp.isEmpty || otp.length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid 6-digit OTP')),
                  );
                  return;
                }

                // Verify OTP
                final isValid = await AuthService.verifyOTP(newPhone, otp);
                if (isValid && _currentUser != null) {
                  // Update phone number in database
                  await AuthService.updatePhoneNumber(_currentUser!.mobileNumber, newPhone);

                  Navigator.of(context).pop();

                  // Reload user data
                  _loadUserData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Phone number updated successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Invalid OTP. Please try again.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text(
                'Verify',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkSurface
                            : AppColors.surface,
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
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
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
                  navigator.pop(); // Close loading dialog
                  navigator.pushAndRemoveUntil(
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              color: AppColors.primaryOrange,
              onPressed: _toggleEditMode,
              tooltip: 'Edit Profile',
            )
          else ...[
            if (_isSaving)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.error,
                onPressed: _toggleEditMode,
                tooltip: 'Cancel',
              ),
              IconButton(
                icon: const Icon(Icons.check),
                color: AppColors.success,
                onPressed: _saveProfile,
                tooltip: 'Save',
              ),
            ],
          ],
        ],
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try logging in again',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
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
                      GestureDetector(
                        onTap: _isEditMode ? _pickProfilePicture : null,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isEditMode
                                      ? AppColors.primaryOrange
                                      : AppColors.primaryOrange.withValues(alpha: 0.5),
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
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (_currentUser?.profilePictureUrl != null
                                        ? (_currentUser!.profilePictureUrl!.startsWith('http')
                                            ? NetworkImage(_currentUser!.profilePictureUrl!)
                                            : (File(_currentUser!.profilePictureUrl!).existsSync()
                                                ? FileImage(File(_currentUser!.profilePictureUrl!))
                                                : null))
                                        : null) as ImageProvider?,
                                child: (_selectedImage == null && _currentUser?.profilePictureUrl == null)
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppColors.primaryOrange,
                                      )
                                    : null,
                              ),
                            ),
                            if (_isEditMode)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? AppColors.darkBackground
                                          : AppColors.backgroundPrimary,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // User Name
                      Text(
                        _currentUser?.name ?? 'Unknown User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
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
                      // Name field (editable)
                      _buildEditableCard(
                        icon: Icons.person,
                        title: 'Full Name',
                        controller: _nameController,
                        isEditing: _isEditMode,
                      ),

                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.phone,
                        title: 'Mobile Number',
                        value: _currentUser?.mobileNumber ?? 'Not provided',
                        trailing: !_isEditMode
                            ? IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: AppColors.primaryOrange,
                                onPressed: () => _changePhoneNumber(),
                              )
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // NIC field (editable)
                      _buildEditableCard(
                        icon: Icons.badge,
                        title: 'NIC Number',
                        controller: _nicController,
                        isEditing: _isEditMode,
                      ),

                      const SizedBox(height: 16),

                      // Date of Birth (editable with date picker)
                      _buildDatePickerCard(
                        icon: Icons.cake,
                        title: 'Date of Birth',
                        date: _selectedDate,
                        isEditing: _isEditMode,
                        onTap: () => _selectDate(context),
                      ),

                      const SizedBox(height: 16),

                      // Gender (editable with dropdown)
                      _buildGenderCard(
                        icon: _selectedGender == 'male' ? Icons.male : Icons.female,
                        title: 'Gender',
                        gender: _selectedGender,
                        isEditing: _isEditMode,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),

                      if (_currentUser?.role == UserRole.employee) ...[
                        const SizedBox(height: 16),
                        // ADM Code (NOT editable)
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkSurface
                              : AppColors.surface,
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
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
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
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildEditableCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? AppColors.primaryOrange.withValues(alpha: 0.5)
              : AppColors.secondaryBlue.withValues(alpha: 0.2),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditing)
                  TextField(
                    controller: controller,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Enter $title',
                    ),
                  )
                else
                  Text(
                    controller.text.isEmpty ? 'Not provided' : controller.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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

  Widget _buildDatePickerCard({
    required IconData icon,
    required String title,
    required DateTime? date,
    required bool isEditing,
    required VoidCallback onTap,
  }) {
    final dateText = date != null
        ? DateFormat('dd/MM/yyyy').format(date)
        : 'Not provided';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? AppColors.primaryOrange.withValues(alpha: 0.5)
              : AppColors.secondaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: isEditing ? onTap : null,
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditing)
              Icon(
                Icons.calendar_today,
                color: AppColors.primaryOrange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required IconData icon,
    required String title,
    required String? gender,
    required bool isEditing,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? AppColors.primaryOrange.withValues(alpha: 0.5)
              : AppColors.secondaryBlue.withValues(alpha: 0.2),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditing)
                  DropdownButtonFormField<String>(
                    initialValue: gender?.toLowerCase(),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                      DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                    ],
                    onChanged: onChanged,
                  )
                else
                  Text(
                    gender != null
                        ? (gender == 'prefer_not_to_say'
                            ? 'Prefer not to say'
                            : gender[0].toUpperCase() + gender.substring(1))
                        : 'Not provided',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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