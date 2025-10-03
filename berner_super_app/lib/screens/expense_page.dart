import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Food';
  File? _selectedImage;
  File? _mileageImage;
  final ImagePicker _picker = ImagePicker();

  // Upload history log with approval status (loaded from Supabase)
  List<Map<String, dynamic>> _uploadHistory = [];
  bool _isLoadingHistory = true;
  bool _isSavingExpense = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Food',
      'icon': Icons.restaurant,
      'color': AppColors.success,
    },
    {
      'name': 'Fuel',
      'icon': Icons.local_gas_station,
      'color': AppColors.error,
    },
    {
      'name': 'Other',
      'icon': Icons.category,
      'color': AppColors.accent1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenseHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Load expense history from Supabase
  Future<void> _loadExpenseHistory() async {
    try {
      setState(() {
        _isLoadingHistory = true;
      });

      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        print('⚠️ ExpensePage: No current user found');
        return;
      }

      print('🔵 ExpensePage: Loading expense history for user ${currentUser.id}');
      final expenses = await SupabaseService.getUserExpenses(currentUser.id);

      setState(() {
        _uploadHistory = expenses.map((expense) {
          return {
            'id': expense['id'],
            'amount': expense['amount']?.toString() ?? '0',
            'category': expense['category_name'] ?? 'Other',
            'description': expense['description'] ?? 'No description',
            'timestamp': DateTime.parse(expense['created_at'] ?? expense['expense_date']),
            'status': expense['is_approved'] == true ? 'approved' :
                     (expense['status'] == 'rejected' ? 'rejected' : 'pending'),
            'imagePath': _getReceiptPath(expense),
            'mileageImagePath': _getMileagePath(expense),
          };
        }).toList();
        _isLoadingHistory = false;
      });

      print('🟢 ExpensePage: Loaded ${_uploadHistory.length} expenses');
    } catch (e) {
      print('❌ ExpensePage: Error loading expense history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  String? _getReceiptPath(Map<String, dynamic> expense) {
    if (expense['expense_attachments'] != null && expense['expense_attachments'] is List) {
      final attachments = expense['expense_attachments'] as List;
      final receipt = attachments.firstWhere(
        (a) => a['is_receipt'] == true,
        orElse: () => null,
      );
      return receipt?['file_url'];
    }
    return null;
  }

  String? _getMileagePath(Map<String, dynamic> expense) {
    if (expense['expense_attachments'] != null && expense['expense_attachments'] is List) {
      final attachments = expense['expense_attachments'] as List;
      final mileage = attachments.firstWhere(
        (a) => a['is_receipt'] == false,
        orElse: () => null,
      );
      return mileage?['file_url'];
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickMileageImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _mileageImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking mileage image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Receipt Image Source',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    'Camera',
                    Icons.camera_alt,
                    () => _pickImage(ImageSource.camera),
                  ),
                  _buildImageSourceOption(
                    'Gallery',
                    Icons.photo_library,
                    () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showMileageImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Mileage Image Source',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMileageImageSourceOption(
                    'Camera',
                    Icons.camera_alt,
                    () => _pickMileageImage(ImageSource.camera),
                  ),
                  _buildMileageImageSourceOption(
                    'Gallery',
                    Icons.photo_library,
                    () => _pickMileageImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.primaryOrange.withValues(alpha: 0.2)
              : AppColors.primaryOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primaryOrange.withValues(alpha: 0.5)
                : AppColors.primaryOrange.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMileageImageSourceOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.secondaryBlue.withValues(alpha: 0.2)
              : AppColors.secondaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.secondaryBlue.withValues(alpha: 0.5)
                : AppColors.secondaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.secondaryBlue,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.secondaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSavingExpense = true;
      });

      try {
        final currentUser = await AuthService.getCurrentUser();
        if (currentUser == null) {
          throw Exception('User not logged in');
        }

        print('🔵 ExpensePage: Creating expense...');

        final amount = double.parse(_amountController.text);
        final description = _descriptionController.text.isEmpty
            ? 'No description'
            : _descriptionController.text;

        // Create expense in Supabase
        final expenseId = await SupabaseService.createExpense(
          userId: currentUser.id,
          title: '$_selectedCategory expense',
          amount: amount,
          categoryName: _selectedCategory,
          description: description,
          expenseDate: DateTime.now(),
        );

        if (expenseId == null) {
          throw Exception('Failed to create expense');
        }

        print('🟢 ExpensePage: Expense created with ID: $expenseId');

        // Upload receipt image if selected
        String? receiptUrl;
        if (_selectedImage != null) {
          print('🔵 ExpensePage: Uploading receipt image...');
          receiptUrl = await SupabaseService.uploadExpenseReceipt(
            _selectedImage!.path,
            expenseId,
          );

          if (receiptUrl != null) {
            // Save receipt attachment
            final storagePath = 'expense_receipts/expense_${expenseId}_receipt.jpg';
            await SupabaseService.client
                .from('expense_attachments')
                .insert({
              'expense_id': expenseId,
              'file_name': 'receipt_$expenseId.jpg',
              'file_path': storagePath,
              'file_url': receiptUrl,
              'storage_bucket': 'expense-receipts',
              'storage_path': storagePath,
              'is_receipt': true,
            });
            print('🟢 ExpensePage: Receipt uploaded');
          } else {
            print('⚠️ ExpensePage: Receipt upload failed - URL is null');
          }
        }

        // Upload mileage image if selected
        String? mileageUrl;
        if (_mileageImage != null) {
          print('🔵 ExpensePage: Uploading mileage image...');
          try {
            final fileName = 'expense_${expenseId}_mileage.jpg';
            final storagePath = 'expense_receipts/$fileName';
            final bytes = await _mileageImage!.readAsBytes();

            print('🔵 ExpensePage: Uploading ${bytes.length} bytes to $storagePath');

            await SupabaseService.client.storage
                .from('expense-receipts')
                .uploadBinary(
                  storagePath,
                  bytes,
                  fileOptions: FileOptions(upsert: true, contentType: 'image/jpeg'),
                );

            mileageUrl = SupabaseService.client.storage
                .from('expense-receipts')
                .getPublicUrl(storagePath);

            print('🟢 ExpensePage: Mileage uploaded, URL: $mileageUrl');

            // Save mileage attachment
            await SupabaseService.client
                .from('expense_attachments')
                .insert({
              'expense_id': expenseId,
              'file_name': fileName,
              'file_path': storagePath,
              'file_url': mileageUrl,
              'storage_bucket': 'expense-receipts',
              'storage_path': storagePath,
              'is_receipt': false,
            });
            print('🟢 ExpensePage: Mileage attachment saved to database');
          } catch (uploadError) {
            print('❌ ExpensePage: Failed to upload mileage image: $uploadError');
            // Don't fail the entire expense save if mileage upload fails
          }
        }

        // Reload history to show new expense
        await _loadExpenseHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense saved: LKR ${_amountController.text} for $_selectedCategory',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );

          // Clear form
          _amountController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedImage = null;
            _mileageImage = null;
            _selectedCategory = 'Food';
            _isSavingExpense = false;
          });
        }
      } catch (e) {
        print('❌ ExpensePage: Error saving expense: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving expense: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );

          setState(() {
            _isSavingExpense = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Text(
                'Amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  prefixIcon: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        "LKR",
        style: TextStyle(
          color: Colors.deepOrange,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['name'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category['name'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category['color']
                              : category['color'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: category['color'],
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              category['icon'],
                              color: isSelected ? Colors.white : category['color'],
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category['name'],
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: isSelected ? Colors.white : category['color'],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Description Input
              Text(
                'Description (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note about this expense...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Image Upload Section
              Text(
                'Receipt/Bill Image',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (_selectedImage == null)
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2C2C2C)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondaryBlue,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: AppColors.secondaryBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload receipt',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.secondaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Camera or Gallery',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              // Mileage Image Upload Section (only for Fuel category)
              if (_selectedCategory == 'Fuel') ...[
                const SizedBox(height: 24),
                Text(
                  'Mileage Image (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (_mileageImage == null)
                  GestureDetector(
                    onTap: _showMileageImageSourceDialog,
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkSurface
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent2,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.speed,
                            size: 40,
                            color: AppColors.accent2,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Upload Mileage Reading',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.accent2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Camera or Gallery',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _mileageImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mileageImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _showMileageImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent2,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Expense',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Upload History Log
              if (_uploadHistory.isNotEmpty) ...[
                const Divider(height: 40),
                Text(
                  'Upload History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ...(_uploadHistory.take(5).map((expense) => _buildHistoryItem(expense))),
                if (_uploadHistory.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Showing latest 5 of ${_uploadHistory.length} expenses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> expense) {
    final category = _categories.firstWhere(
      (cat) => cat['name'] == expense['category'],
      orElse: () => _categories.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondaryBlue.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: category['color'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              category['icon'],
              color: category['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Expense Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\LKR${expense['amount']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatTimestamp(expense['timestamp']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  expense['category'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: category['color'],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expense['description'] != 'No description') ...[
                  const SizedBox(height: 4),
                  Text(
                    expense['description'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Status badge and image indicators
          Column(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(expense['status']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(expense['status']),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(expense['status']),
                      color: _getStatusColor(expense['status']),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(expense['status']),
                      style: TextStyle(
                        color: _getStatusColor(expense['status']),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Image indicators
              Row(
                children: [
                  if (expense['imagePath'] != null)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ),
                  if (expense['mileageImagePath'] != null)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.speed,
                        color: AppColors.accent2,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.accent1;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}