import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/supabase_service.dart';
import 'expense_page.dart';
import 'profile_page.dart';
import 'weather_screen.dart';
import 'support_tickets_page.dart';
import 'notifications_page.dart';
import 'about_app_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentSliderIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();
  UserModel? _currentUser;
  List<Map<String, dynamic>> _banners = [];
  bool _isLoadingBanners = true;
  int _unreadNotificationCount = 0;

  // Fallback local images if no banners from DB
  final List<String> _fallbackImages = [
    'assets/images/slider1.svg',
    'assets/images/slider2.svg',
    'assets/images/slider3.svg',
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 0 && hour < 12) {
  return 'Good Morning! ☀️';
} else if (hour >= 12 && hour < 15) {
  return 'Good Afternoon! 🌤️';
} else if (hour >= 15 && hour < 18) {
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
    _loadBanners();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;

      final count = await SupabaseService.getUnreadNotificationCount(user.id.toString());
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
    }
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await SupabaseService.getActiveBanners();

      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      print('Error loading banners: $e');
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
        });
      }
    }
  }

  List<dynamic> get _displayItems {
    if (_banners.isNotEmpty) {
      return _banners;
    }
    return _fallbackImages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/images/berner_white.png'
                : 'assets/images/berner_dark.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: false,
        actions: [
          // Theme Toggle Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return IconButton(
                  onPressed: () {
                    themeService.toggleTheme();
                  },
                  icon: Icon(
                    themeService.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  ),
                  iconSize: 26,
                  tooltip: themeService.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                );
              },
            ),
          ),
          // Notification Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsPage(),
                      ),
                    );
                    // Reload unread count after returning from notifications page
                    _loadUnreadNotificationCount();
                  },
                  icon: const Icon(Icons.notifications_outlined),
                  iconSize: 26,
                ),
                // Notification badge - only show if there are unread notifications
                if (_unreadNotificationCount > 0)
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
                        _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingBanners
                      ? Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _displayItems.isEmpty
                          ? Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                              ),
                              child: const Center(
                                child: Text('No banners available'),
                              ),
                            )
                          : CarouselSlider(
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
                              items: _displayItems.map((item) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    final bool isFromDatabase = item is Map<String, dynamic>;
                                    final String imageUrl = isFromDatabase
                                        ? item['image_url'] ?? ''
                                        : item as String;

                                    return GestureDetector(
                                      onTap: isFromDatabase
                                          ? () {
                                              // Handle banner click
                                              if (item['link_url'] != null) {
                                                print('Banner clicked: ${item['title']}');
                                                // TODO: Navigate based on link_type
                                              }
                                            }
                                          : null,
                                      child: Container(
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
                                          child: isFromDatabase
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value: loadingProgress.expectedTotalBytes != null
                                                            ? loadingProgress.cumulativeBytesLoaded /
                                                                loadingProgress.expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(Icons.broken_image, size: 50),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : SvgPicture.asset(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                  const SizedBox(height: 16),
                  // Slider Indicators
                  if (!_isLoadingBanners && _displayItems.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _displayItems.asMap().entries.map((entry) {
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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

            //Partners section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Our Partners',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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
                    children: _partners(),
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

  List<Widget> _partners() {
    List<Widget> partners = [];
    partners.addAll([
      _buildImageQuickActionCard(
        context,
        'Berner',
        'assets/images/berner.png',
      ),
      _buildImageQuickActionCard(
        context,
        'Menzerna',
        'assets/images/menzerna.png',
      ),
      _buildImageQuickActionCard(
        context,
        'Yato',        
        'assets/images/yato.png',
      ),      
      _buildImageQuickActionCard(
        context,
        'Car System',
        'assets/images/car_system.png',
      ),
      _buildImageQuickActionCard(
        context,
        'Blue Chem',
        'assets/images/chem.png',
      )
    ]);
    return partners;
  }
  List<Widget> _buildQuickActionButtons() {
    List<Widget> buttons = [];

    // Add expenses button only for employees
    if (_currentUser?.role == UserRole.employee) {
      buttons.add(
        _buildQuickActionCard(
          context,
          'Expenses',
          AppColors.error,
          icon: Icons.receipt_long,
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

    // Add weather button as the second button (always visible)
    buttons.add(
      _buildQuickActionCard(
        context,
        'Weather',
        AppColors.accent2,
        icon: Icons.wb_sunny,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeatherScreen(),
            ),
          );
        },
      ),
    );

    // Add common buttons for all users
    buttons.addAll([      
      _buildQuickActionCard(
        context,
        'Payments',
        AppColors.secondaryBlue,
        icon: Icons.payment,
      ),
      _buildQuickActionCard(
        context,
        'Support',
        AppColors.success,
        icon: Icons.support_agent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SupportTicketsPage(),
            ),
          );
        },
      ),
      _buildQuickActionCard(
        context,
        'Settings',
        AppColors.accent1,
        icon: Icons.settings,
      ),
    ]);

    // Add more button to fill the grid
    if (_currentUser?.role == UserRole.customer) {
      buttons.add(
        _buildQuickActionCard(
          context,
          'Profile',
          AppColors.secondaryBlue,
          icon: Icons.person_outline,
        ),
      );
    }

    buttons.add(
      _buildQuickActionCard(
        context,
        'More',
        AppColors.textSecondary,
        icon: Icons.more_horiz,
      ),
    );

    buttons.add(
      _buildQuickActionCard(
        context,
        'About App',
        AppColors.primaryOrange,
        icon: Icons.info_outline,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AboutAppPage(),
            ),
          );
        },
      ),
    );

    return buttons;
  }




  Widget _buildQuickActionCard(
    BuildContext context,
    String title,    
    Color color, {
       IconData? icon,
    String? imagePath,
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
              content: Text('$title Comming Soon!'),
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
              if (imagePath != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: imagePath.endsWith('.svg')
                      ? SvgPicture.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            color,
                            BlendMode.srcIn,
                          ),
                        )
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $imagePath');
                            print('Error: $error');
                            return Icon(
                              Icons.image_not_supported,
                              size: 32,
                              color: color,
                            );
                          },
                        ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 32,
                  color: color,
                )
              else
                Icon(
                  Icons.apps,
                  size: 32,
                  color: color,
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
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

  // New method for image background buttons
  Widget _buildImageQuickActionCard(
    BuildContext context,
    String title,
    String imagePath, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title Coming Soon!'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: imagePath.endsWith('.svg')
                  ? SvgPicture.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $imagePath');
                        print('Error: $error');
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
            ),
            // Gradient overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            // Title at bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}