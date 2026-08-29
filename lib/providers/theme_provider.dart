import 'package:flutter/material.dart';
import 'dart:async';
import 'package:crows_nest/services/database_service.dart';

enum AppThemeMode {
  oceanicDark,
  cyberTwilight,
  nordicLight,
  crimsonCorsair,
  emeraldAbyss,
  goldenDune,
  autoChronometer, // Cycles through all 6 themes every 2 hours
  solarCircadian,  // Automatically shifts based on natural Solar Time of Day (Dawn, Daylight, Sunset, Twilight, Night, Abyss)
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentThemeMode = AppThemeMode.oceanicDark;
  final DatabaseService _db = DatabaseService();
  Timer? _autoShiftTimer;
  AppThemeMode? _lastAutoTheme;

  ThemeProvider() {
    _loadSavedTheme();
    _startAutoShiftTimer();
  }

  void _startAutoShiftTimer() {
    _autoShiftTimer?.cancel();
    _autoShiftTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentThemeMode == AppThemeMode.autoChronometer ||
          _currentThemeMode == AppThemeMode.solarCircadian) {
        final currentAuto = activeEffectiveThemeMode;
        if (currentAuto != _lastAutoTheme) {
          _lastAutoTheme = currentAuto;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _autoShiftTimer?.cancel();
    super.dispose();
  }

  AppThemeMode get currentThemeMode => _currentThemeMode;

  /// Returns the actual active theme taking into account 2-hour automatic shifts or Solar time of day
  AppThemeMode get activeEffectiveThemeMode {
    if (_currentThemeMode == AppThemeMode.autoChronometer) {
      return getAutoThemeForTime(DateTime.now());
    }
    if (_currentThemeMode == AppThemeMode.solarCircadian) {
      return getSolarThemeForTime(DateTime.now());
    }
    return _currentThemeMode;
  }

  /// Calculates the 2-hour auto theme for any given DateTime
  AppThemeMode getAutoThemeForTime(DateTime time) {
    // 2-hour cycle slots (0 to 5) across the day
    final slot = (time.hour ~/ 2) % 6;
    switch (slot) {
      case 0: // 00:00 - 01:59 & 12:00 - 13:59
        return AppThemeMode.oceanicDark;
      case 1: // 02:00 - 03:59 & 14:00 - 15:59
        return AppThemeMode.emeraldAbyss;
      case 2: // 04:00 - 05:59 & 16:00 - 17:59
        return AppThemeMode.cyberTwilight;
      case 3: // 06:00 - 07:59 & 18:00 - 19:59 (Golden hour / Sunrise & Sunset)
        return AppThemeMode.goldenDune;
      case 4: // 08:00 - 09:59 & 20:00 - 21:59
        return AppThemeMode.nordicLight;
      case 5: // 10:00 - 11:59 & 22:00 - 23:59
      default:
        return AppThemeMode.crimsonCorsair;
    }
  }

  /// Calculates the Solar Time-of-Day theme based on user's exact requested 6-theme progression:
  /// 1. 06:00 - 09:59: Nordic Sea Mist (Morning Daylight)
  /// 2. 10:00 - 13:59: Golden Dune (Sunlit Midday)
  /// 3. 14:00 - 17:59: Midnight Oceanic (Afternoon Ocean)
  /// 4. 18:00 - 21:59: Cyber Horizon (Twilight & Neon Dusk)
  /// 5. 22:00 - 01:59: Crimson Corsair (Late Night Crimson)
  /// 6. 02:00 - 05:59: Emerald Abyss (Witching Hours / Deep Abyss)
  AppThemeMode getSolarThemeForTime(DateTime time) {
    final hour = time.hour;

    // 06:00 - 09:59: 1. Nordic theme
    if (hour >= 6 && hour < 10) {
      return AppThemeMode.nordicLight;
    }
    // 10:00 - 13:59: 2. Golden theme
    else if (hour >= 10 && hour < 14) {
      return AppThemeMode.goldenDune;
    }
    // 14:00 - 17:59: 3. Midnight Oceanic theme
    else if (hour >= 14 && hour < 18) {
      return AppThemeMode.oceanicDark;
    }
    // 18:00 - 21:59: 4. Cyber theme
    else if (hour >= 18 && hour < 22) {
      return AppThemeMode.cyberTwilight;
    }
    // 22:00 - 01:59: 5. Crimson theme
    else if (hour >= 22 || hour < 2) {
      return AppThemeMode.crimsonCorsair;
    }
    // 02:00 - 05:59: 6. Emerald theme
    else {
      return AppThemeMode.emeraldAbyss;
    }
  }

  String getSolarPhaseName(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 10) {
      return 'Morning (06:00-10:00)';
    } else if (hour >= 10 && hour < 14) {
      return 'Midday (10:00-14:00)';
    } else if (hour >= 14 && hour < 18) {
      return 'Afternoon (14:00-18:00)';
    } else if (hour >= 18 && hour < 22) {
      return 'Twilight (18:00-22:00)';
    } else if (hour >= 22 || hour < 2) {
      return 'Late Night (22:00-02:00)';
    } else {
      return 'Abyss (02:00-06:00)';
    }
  }

  Future<void> _loadSavedTheme() async {
    try {
      final savedTheme = await _db.getSetting('app_theme');
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'cyberTwilight':
            _currentThemeMode = AppThemeMode.cyberTwilight;
            break;
          case 'nordicLight':
            _currentThemeMode = AppThemeMode.nordicLight;
            break;
          case 'crimsonCorsair':
            _currentThemeMode = AppThemeMode.crimsonCorsair;
            break;
          case 'emeraldAbyss':
            _currentThemeMode = AppThemeMode.emeraldAbyss;
            break;
          case 'goldenDune':
            _currentThemeMode = AppThemeMode.goldenDune;
            break;
          case 'autoChronometer':
            _currentThemeMode = AppThemeMode.autoChronometer;
            break;
          case 'solarCircadian':
            _currentThemeMode = AppThemeMode.solarCircadian;
            break;
          case 'oceanicDark':
          default:
            _currentThemeMode = AppThemeMode.oceanicDark;
            break;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  String get currentThemeName {
    switch (_currentThemeMode) {
      case AppThemeMode.oceanicDark:
        return 'Midnight Oceanic';
      case AppThemeMode.cyberTwilight:
        return 'Cyber Horizon';
      case AppThemeMode.nordicLight:
        return 'Nordic Sea Mist';
      case AppThemeMode.crimsonCorsair:
        return 'Crimson Corsair';
      case AppThemeMode.emeraldAbyss:
        return 'Emerald Abyss';
      case AppThemeMode.goldenDune:
        return 'Golden Dune';
      case AppThemeMode.autoChronometer:
        final activeName = _getThemeNameForMode(activeEffectiveThemeMode);
        return 'Chronometer Shift ($activeName)';
      case AppThemeMode.solarCircadian:
        final phase = getSolarPhaseName(DateTime.now());
        final activeName = _getThemeNameForMode(activeEffectiveThemeMode);
        return 'Solar Tides ($phase • $activeName)';
    }
  }

  String _getThemeNameForMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.oceanicDark:
        return 'Midnight Oceanic';
      case AppThemeMode.cyberTwilight:
        return 'Cyber Horizon';
      case AppThemeMode.nordicLight:
        return 'Nordic Sea Mist';
      case AppThemeMode.crimsonCorsair:
        return 'Crimson Corsair';
      case AppThemeMode.emeraldAbyss:
        return 'Emerald Abyss';
      case AppThemeMode.goldenDune:
        return 'Golden Dune';
      case AppThemeMode.autoChronometer:
        return 'Chronometer Shift';
      case AppThemeMode.solarCircadian:
        return 'Solar Tides';
    }
  }

  String get currentThemeDescription {
    switch (_currentThemeMode) {
      case AppThemeMode.oceanicDark:
        return 'Deep nautical midnight with brass gold & cyan accents';
      case AppThemeMode.cyberTwilight:
        return 'Futuristic synthwave obsidian with neon purple & electric cyan';
      case AppThemeMode.nordicLight:
        return 'Crisp sea mist alabaster with marine teal & warm slate';
      case AppThemeMode.crimsonCorsair:
        return 'Bold obsidian with pirate crimson red & burnished gold accents';
      case AppThemeMode.emeraldAbyss:
        return 'Deep sea abyss with bioluminescent emerald & mint neon glow';
      case AppThemeMode.goldenDune:
        return 'Warm sunlit ivory with desert sand & terracotta sunset accents';
      case AppThemeMode.autoChronometer:
        return 'Dynamic 2-hour nautical watch cycle shifting between all 6 themes automatically';
      case AppThemeMode.solarCircadian:
        return 'Solar 6-Phase Tides: Nordic (Morning) ➔ Golden (Midday) ➔ Midnight Oceanic (Afternoon) ➔ Cyber (Twilight) ➔ Crimson (Late Night) ➔ Emerald (Abyss)';
    }
  }

  IconData get currentThemeIcon {
    switch (_currentThemeMode) {
      case AppThemeMode.oceanicDark:
        return Icons.nights_stay_rounded;
      case AppThemeMode.cyberTwilight:
        return Icons.auto_awesome_rounded;
      case AppThemeMode.nordicLight:
        return Icons.wb_sunny_rounded;
      case AppThemeMode.crimsonCorsair:
        return Icons.local_fire_department_rounded;
      case AppThemeMode.emeraldAbyss:
        return Icons.water_drop_rounded;
      case AppThemeMode.goldenDune:
        return Icons.wb_twilight_rounded;
      case AppThemeMode.autoChronometer:
        return Icons.timelapse_rounded;
      case AppThemeMode.solarCircadian:
        return Icons.wb_sunny_outlined;
    }
  }

  void setTheme(AppThemeMode mode) {
    if (_currentThemeMode != mode) {
      _currentThemeMode = mode;
      _lastAutoTheme = activeEffectiveThemeMode;
      notifyListeners();
      _saveTheme(mode);
    }
  }

  Future<void> _saveTheme(AppThemeMode mode) async {
    try {
      String modeStr = 'oceanicDark';
      switch (mode) {
        case AppThemeMode.cyberTwilight:
          modeStr = 'cyberTwilight';
          break;
        case AppThemeMode.nordicLight:
          modeStr = 'nordicLight';
          break;
        case AppThemeMode.crimsonCorsair:
          modeStr = 'crimsonCorsair';
          break;
        case AppThemeMode.emeraldAbyss:
          modeStr = 'emeraldAbyss';
          break;
        case AppThemeMode.goldenDune:
          modeStr = 'goldenDune';
          break;
        case AppThemeMode.autoChronometer:
          modeStr = 'autoChronometer';
          break;
        case AppThemeMode.solarCircadian:
          modeStr = 'solarCircadian';
          break;
        case AppThemeMode.oceanicDark:
          modeStr = 'oceanicDark';
          break;
      }
      await _db.setSetting('app_theme', modeStr);
    } catch (_) {}
  }

  void toggleNextTheme() {
    switch (_currentThemeMode) {
      case AppThemeMode.oceanicDark:
        setTheme(AppThemeMode.cyberTwilight);
        break;
      case AppThemeMode.cyberTwilight:
        setTheme(AppThemeMode.nordicLight);
        break;
      case AppThemeMode.nordicLight:
        setTheme(AppThemeMode.crimsonCorsair);
        break;
      case AppThemeMode.crimsonCorsair:
        setTheme(AppThemeMode.emeraldAbyss);
        break;
      case AppThemeMode.emeraldAbyss:
        setTheme(AppThemeMode.goldenDune);
        break;
      case AppThemeMode.goldenDune:
        setTheme(AppThemeMode.autoChronometer);
        break;
      case AppThemeMode.autoChronometer:
        setTheme(AppThemeMode.solarCircadian);
        break;
      case AppThemeMode.solarCircadian:
        setTheme(AppThemeMode.oceanicDark);
        break;
    }
  }

  ThemeData get themeData {
    switch (activeEffectiveThemeMode) {
      case AppThemeMode.oceanicDark:
        return _buildOceanicDarkTheme();
      case AppThemeMode.cyberTwilight:
        return _buildCyberTwilightTheme();
      case AppThemeMode.nordicLight:
        return _buildNordicLightTheme();
      case AppThemeMode.crimsonCorsair:
        return _buildCrimsonCorsairTheme();
      case AppThemeMode.emeraldAbyss:
        return _buildEmeraldAbyssTheme();
      case AppThemeMode.goldenDune:
      default:
        return _buildGoldenDuneTheme();
    }
  }

  // 1. Midnight Oceanic (Dark Nautical)
  ThemeData _buildOceanicDarkTheme() {
    const primary = Color(0xFF38B6FF);
    const secondary = Color(0xFFF6AE2D);
    const background = Color(0xFF0A1128);
    const surface = Color(0xFF101F42);
    const surfaceContainer = Color(0xFF172A59);
    const onSurface = Color(0xFFE8EEF5);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Color(0xFF001E36),
      primaryContainer: Color(0xFF1E3D59),
      onPrimaryContainer: Color(0xFFC7E7FF),
      secondary: secondary,
      onSecondary: Color(0xFF3E2800),
      secondaryContainer: Color(0xFF5B3D00),
      onSecondaryContainer: Color(0xFFFFDFA0),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: Color(0xFFB0C4DE),
      outline: Color(0xFF2A4365),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF080D21),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E3563), width: 1),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF080D21),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2A4365), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Color(0xFF1C1300),
        elevation: 6,
      ),
    );
  }

  // 2. Cyber Horizon (Synthwave Twilight)
  ThemeData _buildCyberTwilightTheme() {
    const primary = Color(0xFF8C52FF);
    const secondary = Color(0xFF00E5FF);
    const tertiary = Color(0xFFFF5376);
    const background = Color(0xFF0F0E17);
    const surface = Color(0xFF1A1829);
    const surfaceContainer = Color(0xFF25223A);
    const onSurface = Color(0xFFF3F0FF);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF381E72),
      onPrimaryContainer: Color(0xFFEADBFF),
      secondary: secondary,
      onSecondary: Color(0xFF00363D),
      secondaryContainer: Color(0xFF004F58),
      onSecondaryContainer: Color(0xFF97F0FF),
      tertiary: tertiary,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: Color(0xFFC4BEE0),
      outline: Color(0xFF3D375A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0A12),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF372E5A), width: 1.2),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0D0C15),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF8C52FF), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  // 3. Nordic Sea Mist (Modern Light)
  ThemeData _buildNordicLightTheme() {
    const primary = Color(0xFF0D9488);
    const secondary = Color(0xFF0284C7);
    const background = Color(0xFFF4F7FB);
    const surface = Colors.white;
    const surfaceContainer = Color(0xFFE2E8F0);
    const onSurface = Color(0xFF0F172A);

    final colorScheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCCFBF1),
      onPrimaryContainer: Color(0xFF115E59),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0F2FE),
      onSecondaryContainer: Color(0xFF0369A1),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFCBD5E1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // 4. Crimson Corsair (Pirate Obsidian & Blood Orange/Crimson)
  ThemeData _buildCrimsonCorsairTheme() {
    const primary = Color(0xFFFF3366);
    const secondary = Color(0xFFFFB703);
    const background = Color(0xFF140D0F);
    const surface = Color(0xFF221418);
    const surfaceContainer = Color(0xFF331C22);
    const onSurface = Color(0xFFFFF0F3);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF680020),
      onPrimaryContainer: Color(0xFFFFD9E0),
      secondary: secondary,
      onSecondary: Color(0xFF3E2800),
      secondaryContainer: Color(0xFF5B3D00),
      onSecondaryContainer: Color(0xFFFFE088),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: Color(0xFFD4B8BE),
      outline: Color(0xFF5A2A35),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF100A0C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFFF3366),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF4D1D27), width: 1.2),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF100A0C),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF3366), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  // 5. Emerald Abyss (Deep Sea Bioluminescence)
  ThemeData _buildEmeraldAbyssTheme() {
    const primary = Color(0xFF00F5D4);
    const secondary = Color(0xFF70E000);
    const background = Color(0xFF071411);
    const surface = Color(0xFF0E241F);
    const surfaceContainer = Color(0xFF15362E);
    const onSurface = Color(0xFFE8FFF9);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Color(0xFF003830),
      primaryContainer: Color(0xFF005045),
      onPrimaryContainer: Color(0xFF70FFEB),
      secondary: secondary,
      onSecondary: Color(0xFF1A3800),
      secondaryContainer: Color(0xFF2D5C00),
      onSecondaryContainer: Color(0xFFACFF53),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: Color(0xFFA5CFC5),
      outline: Color(0xFF1E5246),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF05100D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF00F5D4),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1B4E43), width: 1.2),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF05100D),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00F5D4), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Color(0xFF003830),
        elevation: 6,
      ),
    );
  }

  // 6. Golden Dune (Sandbar Sunset Warm Light)
  ThemeData _buildGoldenDuneTheme() {
    const primary = Color(0xFFD97706);
    const secondary = Color(0xFFEA580C);
    const background = Color(0xFFFAF6EE);
    const surface = Colors.white;
    const surfaceContainer = Color(0xFFF2EADC);
    const onSurface = Color(0xFF291E10);

    final colorScheme = const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFEF3C7),
      onPrimaryContainer: Color(0xFF92400E),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFEDD5),
      onSecondaryContainer: Color(0xFF9A3412),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: Color(0xFF786C5E),
      outline: Color(0xFFDDD2C0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF291E10),
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF92400E),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE8DEC9), width: 1),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFDDD2C0), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
