import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'expense_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentSliderIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();
  UserModel? _currentUser;

  final List<String> sliderImages = [
    'assets/images/slider1.svg',
    'assets/images/slider2.svg',
    'assets/images/slider3.svg',
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning! ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon! 🌤️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening! 🌅';
    } else {
      return 'Good Night! 🌙';
    }
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Start your day with energy!';
    } else if (hour >= 12 && hour < 17) {
      return 'Hope you\'re having a productive day!';
    } else if (hour >= 17 && hour < 21) {
      return 'Time to relax and unwind!';
    } else {
      return 'Sweet dreams ahead!';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Burner Super App',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          // Notification Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications opened'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  iconSize: 26,
                ),
                // Notification badge
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '3',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile Button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryOrange,
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: const AssetImage('assets/images/profile_placeholder.png'),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOrange.withValues(alpha: 0.1),
                    AppColors.secondaryBlue.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGreetingMessage(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Image Slider Section
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Featured',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CarouselSlider(
                    carouselController: _carouselController,
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 4),
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.2,
                      viewportFraction: 0.9,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentSliderIndex = index;
                        });
                      },
                    ),
                    items: sliderImages.map((imagePath) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
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
                              child: SvgPicture.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Slider Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sliderImages.asMap().entries.map((entry) {
                      return Container(
                        width: _currentSliderIndex == entry.key ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentSliderIndex == entry.key
                              ? AppColors.primaryOrange
                              : AppColors.secondaryBlue.withValues(alpha: 0.3),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Quick Actions Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: _buildQuickActionButtons(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickActionButtons() {
    List<Widget> buttons = [];

    // Add expenses button only for employees
    if (_currentUser?.role == UserRole.employee) {
      buttons.add(
        _buildQuickActionCard(
          context,
          'Expenses',
          Icons.receipt_long,
          AppColors.error,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExpensePage(),
              ),
            );
          },
        ),
      );
    }

    // Add common buttons for all users
    buttons.addAll([
      _buildQuickActionCard(
        context,
        'Services',
        Icons.miscellaneous_services,
        AppColors.primaryOrange,
      ),
      _buildQuickActionCard(
        context,
        'Payments',
        Icons.payment,
        AppColors.secondaryBlue,
      ),
      _buildQuickActionCard(
        context,
        'Support',
        Icons.support_agent,
        AppColors.success,
      ),
      _buildQuickActionCard(
        context,
        'Settings',
        Icons.settings,
        AppColors.accent1,
      ),
    ]);

    // Add more button to fill the grid
    if (_currentUser?.role == UserRole.customer) {
      buttons.add(
        _buildQuickActionCard(
          context,
          'Profile',
          Icons.person_outline,
          AppColors.secondaryBlue,
        ),
      );
    }

    buttons.add(
      _buildQuickActionCard(
        context,
        'More',
        Icons.more_horiz,
        AppColors.textSecondary,
      ),
    );

    return buttons;
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title tapped'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}