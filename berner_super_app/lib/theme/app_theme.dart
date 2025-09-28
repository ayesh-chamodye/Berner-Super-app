import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryOrange = Color(0xFFF35E0C);
  static const Color secondaryBlue = Color(0xFF9AC1DE);

  // Variations of primary color
  static const Color primaryLight = Color(0xFFFF8A47);
  static const Color primaryDark = Color(0xFFD14000);

  // Variations of secondary color
  static const Color secondaryLight = Color(0xFFB8D4E8);
  static const Color secondaryDark = Color(0xFF7AA3C4);

  // Accent colors for eye-catching design
  static const Color accent1 = Color(0xFFFFE066);
  static const Color accent2 = Color(0xFF66E0FF);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;
  static const Color textAccent = Color(0xFFF35E0C);

  // Background colors
  static const Color backgroundPrimary = Colors.white;
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF8F9FA);
}

class AppTextStyles {
  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
    fontFamily: fontFamily,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
    fontFamily: fontFamily,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        secondary: AppColors.secondaryBlue,
        brightness: Brightness.light,
        surface: AppColors.surface,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnSecondary,
        onSurface: AppColors.textPrimary,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondaryBlue,
        foregroundColor: AppColors.textOnSecondary,
        elevation: 4,
        shadowColor: AppColors.secondaryBlue.withValues(alpha: 0.5),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textOnSecondary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textOnSecondary,
          size: 24,
        ),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 4,
          shadowColor: AppColors.primaryOrange.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          side: const BorderSide(
            color: AppColors.primaryOrange,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // InputDecoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondaryBlue,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondaryBlue,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.secondaryLight,
        thickness: 1,
        space: 16,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryLight,
        secondarySelectedColor: AppColors.secondaryLight,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // BottomNavigationBar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.surfaceVariant;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryOrange,
        inactiveTrackColor: AppColors.surfaceVariant,
        thumbColor: AppColors.primaryOrange,
        overlayColor: AppColors.primaryLight.withValues(alpha: 0.3),
        valueIndicatorColor: AppColors.primaryOrange,
        valueIndicatorTextStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryOrange,
        secondary: AppColors.secondaryBlue,
        brightness: Brightness.dark,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: Colors.white),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: Colors.white),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: Colors.white),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: Colors.white),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: Colors.white),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: Colors.white60),
      ),
    );
  }
}