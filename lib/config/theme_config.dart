import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
// THEME CONFIGURATION - Sistema de Dark/Light Mode
// ═══════════════════════════════════════════════════════════════════

class AppTheme {
  // ─────────────── COLORES BASE ───────────────

  // Colores por ROL
  static const Color primaryBlue = Color(0xFF135BEC);      // Admin Empresa, Workers
  static const Color primaryPurple = Color(0xFF7C3AED);    // Super Admin
  static const Color primaryPink = Color(0xFFEC4899);      // Acento
  static const Color primaryOrange = Color(0xFFF59E0B);    // Warnings

  // Colores de ESTADO
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // ─────────────── MODO OSCURO ───────────────

  static const Color darkBackground = Color(0xFF101622);
  static const Color darkCard = Color(0xFF192233);
  static const Color darkBorder = Color(0xFF324467);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF92a4c9);
  static const Color darkTextTertiary = Color(0xFF64748b);

  // ─────────────── MODO CLARO ───────────────

  static const Color lightBackground = Color(0xFFF6F6F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF64748b);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // ─────────────── GRADIENTES ───────────────

  static const List<Color> gradientBlue = [
    Color(0xFF0A6CFF),
    Color(0xFF11C3FF),
  ];

  static const List<Color> gradientPurple = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
  ];

  static const List<Color> gradientPink = [
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
  ];

  static const List<Color> gradientOrange = [
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
  ];

  // ─────────────── DESIGN TOKENS ───────────────

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusCircle = 999.0;

  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 12.0;
  static const double spaceRegular = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double spaceXXLarge = 48.0;

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 22.0;
  static const double fontSizeXXLarge = 28.0;
  static const double fontSizeHuge = 34.0;

  // Icon Sizes
  static const double iconSmall = 20.0;
  static const double iconRegular = 24.0;
  static const double iconMedium = 28.0;
  static const double iconLarge = 32.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;

  // ─────────────── THEME DATA ───────────────

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: primaryPurple,
        error: dangerRed,
        surface: lightCard,
      ),
      cardColor: lightCard,
      dividerColor: lightBorder,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: elevationNone,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLarge,
            vertical: spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceRegular,
            vertical: spaceSmall,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeRegular,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceRegular,
          vertical: spaceMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: dangerRed),
        ),
        labelStyle: const TextStyle(color: lightTextSecondary),
        hintStyle: const TextStyle(color: lightTextTertiary),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: fontSizeHuge,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMedium,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeRegular,
          color: lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        secondary: primaryPurple,
        error: dangerRed,
        surface: darkCard,
      ),
      cardColor: darkCard,
      dividerColor: darkBorder,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: elevationNone,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLarge,
            vertical: spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceRegular,
            vertical: spaceSmall,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeRegular,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceRegular,
          vertical: spaceMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: dangerRed),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextTertiary),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryBlue,
        unselectedItemColor: darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: fontSizeHuge,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeMedium,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeRegular,
          color: darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// THEME PROVIDER - Manejo de estado del tema
// ═══════════════════════════════════════════════════════════════════

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
