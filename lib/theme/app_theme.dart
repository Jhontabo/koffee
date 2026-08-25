import 'package:flutter/material.dart';

class AppPalette {
  // Primary Coffee Tones
  static const Color espresso = Color(0xFF2E1C14);
  static const Color espressoDark = Color(0xFF1F120D);
  static const Color cocoa = Color(0xFF4E342E);
  static const Color cocoaLight = Color(0xFF6D4C41);
  static const Color caramel = Color(0xFFD49757);
  static const Color caramelLight = Color(0xFFF3E5D4);
  static const Color caramelDark = Color(0xFFB07535);

  // Background & Surfaces
  static const Color background = Color(0xFFF6F1EB);
  static const Color backgroundSubtle = Color(0xFFECE4DA);
  static const Color surface = Colors.white;
  static const Color crema = Color(0xFFFAF7F2);
  static const Color cardBorder = Color(0xFFEADBCE);

  // Accent & Semantic
  static const Color leaf = Color(0xFF2E7D47);
  static const Color leafLight = Color(0xFFE8F5EC);
  static const Color leafDark = Color(0xFF1E5631);
  static const Color berry = Color(0xFFC62828);
  static const Color berryLight = Color(0xFFFFEBEE);
  static const Color textPrimary = Color(0xFF211714);
  static const Color textSecondary = Color(0xFF756A63);
  static const Color textMuted = Color(0xFFA0948D);
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.espresso, AppPalette.cocoa],
  );

  static const LinearGradient caramel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.caramel, AppPalette.caramelDark],
  );

  static const LinearGradient leaf = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.leaf, AppPalette.leafDark],
  );

  static const LinearGradient card = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFFCFAF7)],
  );

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppPalette.background, Color(0xFFEDE4D9)],
  );
}

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.espresso,
      onPrimary: Colors.white,
      secondary: AppPalette.caramel,
      onSecondary: Colors.white,
      tertiary: AppPalette.leaf,
      onTertiary: Colors.white,
      error: AppPalette.berry,
      onError: Colors.white,
      surface: AppPalette.surface,
      onSurface: AppPalette.textPrimary,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppPalette.crema,
      surfaceContainer: AppPalette.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppPalette.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppPalette.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: AppPalette.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: AppPalette.textMuted,
          fontSize: 14,
        ),
        prefixIconColor: AppPalette.cocoa,
        suffixIconColor: AppPalette.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.caramel, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.berry, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.berry, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.espresso,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.espresso,
          side: const BorderSide(color: AppPalette.cardBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.caramelDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppPalette.caramel.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppPalette.espresso, size: 24);
          }
          return const IconThemeData(color: AppPalette.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppPalette.espresso : AppPalette.textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          );
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFD2C1B5),
        indicatorColor: AppPalette.caramel,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppPalette.textPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.espresso,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.espresso,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
