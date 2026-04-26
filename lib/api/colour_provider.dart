import 'package:GitSync/api/manager/storage.dart';
import 'package:GitSync/global.dart';
import 'package:flutter/material.dart';

/// Fixed M3 seed used as a fallback when dynamic Material You wallpaper
/// extraction is unavailable (e.g., pre-Android 12 or iOS).
const Color kFallbackSeedColor = Color(0xFF4A90D9);

class Colours {
  // system = null
  // dark   = true
  // light  = false
  bool darkMode = true;

  Color get primaryLight => darkMode ? Color(0xFFFFFFFF) : Color(0xFF141414);
  Color get secondaryLight => darkMode ? Color(0xFFAAAAAA) : Color(0xFF1C1C1C);
  Color get tertiaryLight => darkMode ? Color(0xFF646464) : Color(0xFF2B2B2B);

  Color get primaryDark => darkMode ? Color(0xFF141414) : Color(0xFFFFFFFF);
  Color get secondaryDark => darkMode ? Color(0xFF1C1C1C) : Color(0xFFDDDDDD);
  Color get tertiaryDark => darkMode ? Color(0xFF2B2B2B) : Color(0xFFBBBBBB);

  Color get primaryPositive => darkMode ? Color(0xFF85F48E) : Color(0xFF3B8E59);
  Color get secondaryPositive => darkMode ? Color(0xFF4F7051) : Color(0xFFA7F3D0);
  Color get tertiaryPositive => darkMode ? Color(0xFFA7F3D0) : Color(0xFF3E7D45);

  Color get primaryNegative => darkMode ? Color(0xFFC22424) : Color(0xFFB21F1F);
  Color get secondaryNegative => darkMode ? Color(0xFF8A1B1B) : Color(0xFFC44D4D);
  Color get tertiaryNegative => darkMode ? Color(0xFFFDA4AF) : Color(0xFF8A1B1B);

  Color get primaryWarning => darkMode ? Color(0xFFFFC107) : Color(0xFF8A5B00);
  Color get secondaryWarning => darkMode ? Color(0xFFFFA000) : Color(0xFFFFE082);
  Color get tertiaryWarning => darkMode ? Color(0xFFFFE082) : Color(0xFFB06A00);

  Color get primaryInfo => darkMode ? Color(0xFF2196F3) : Color(0xFF1976D2);
  Color get secondaryInfo => darkMode ? Color(0xFF1976D2) : Color(0xFF90CAF9);
  Color get tertiaryInfo => darkMode ? Color(0xFF90CAF9) : Color(0xFF0A4B8D);

  // -------------------------------------------------------------------
  // M3 color-role getters. These align with Material You ColorScheme
  // semantics so widgets can reach for them without needing the full
  // Theme.of(context).colorScheme lookup. They map to the semantic
  // tonal slots described by the M3 spec.
  // -------------------------------------------------------------------
  Color get surfaceContainer => darkMode ? const Color(0xFF1F1F1F) : const Color(0xFFEFEFEF);
  Color get surfaceContainerHigh => darkMode ? const Color(0xFF272727) : const Color(0xFFE6E6E6);
  Color get surfaceContainerHighest => darkMode ? const Color(0xFF2F2F2F) : const Color(0xFFDEDEDE);
  Color get onSurfaceVariant => darkMode ? const Color(0xFFCAC4D0) : const Color(0xFF49454F);

  // Container tonal slots, aligned to the existing semantic palette so
  // they coexist with positive/negative/warning/info colors.
  Color get primaryContainer => darkMode ? const Color(0xFF1E3A5F) : const Color(0xFFD1E4FF);
  Color get onPrimaryContainer => darkMode ? const Color(0xFFD1E4FF) : const Color(0xFF001D36);

  Color get secondaryContainer => darkMode ? const Color(0xFF1E4A2E) : const Color(0xFFA7F3D0);
  Color get onSecondaryContainer => darkMode ? const Color(0xFFA7F3D0) : const Color(0xFF002107);

  Color get tertiaryContainer => darkMode ? const Color(0xFF7A4F00) : const Color(0xFFFFE082);
  Color get onTertiaryContainer => darkMode ? const Color(0xFFFFE082) : const Color(0xFF261900);

  Color get errorContainer => darkMode ? const Color(0xFF93000A) : const Color(0xFFFFDAD6);
  Color get onErrorContainer => darkMode ? const Color(0xFFFFDAD6) : const Color(0xFF410002);

  // Premium page palette
  Color get premiumBg => darkMode ? Color(0xFF0A1F14) : Color(0xFFF0F9F1);
  Color get premiumSurface => darkMode ? Color(0xFF122A1C) : Color(0xFFDCEEDE);
  Color get premiumBorder => darkMode ? Color(0xFF1E4A2E) : Color(0xFFA5D6A7);
  Color get premiumAccent => darkMode ? Color(0xFFA7F3D0) : Color(0xFF2E7D32);
  Color get premiumTextSecondary => darkMode ? Color(0xFF8BAF9A) : Color(0xFF4E7C5B);

  // Showcase tooltip palette
  Color get showcaseBg => darkMode ? Color(0xFF111D2E) : Color(0xFFE8EDF4);
  Color get showcaseTitle => darkMode ? Color(0xFFFFFFFF) : Color(0xFF111D2E);
  Color get showcaseDesc => darkMode ? Color(0xFF94A3B8) : Color(0xFF475569);
  Color get showcaseBtnPrimary => darkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB);
  Color get showcaseBtnSecondary => darkMode ? Color(0xFF1E3A5F) : Color(0xFFBFDBFE);
  Color get showcaseBtnText => darkMode ? Color(0xFF0A1628) : Color(0xFFFFFFFF);
  Color get showcaseBorder => darkMode ? Color(0xFF1E3A5F) : Color(0xFFBFDBFE);
  Color get showcaseFeatureIcon => darkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB);

  Future<void> reloadTheme(BuildContext context) async {
    final newDarkMode = await repoManager.getBoolNullable(StorageKey.repoman_themeMode);
    darkMode = newDarkMode ?? MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// Builds an M3 [ColorScheme] from a seed. If [dynamicScheme] is provided
  /// (for example from the dynamic_color package on Android 12+), it is
  /// returned harmonized; otherwise the fixed seed fallback is used.
  ColorScheme buildColorScheme({ColorScheme? dynamicScheme}) {
    final brightness = darkMode ? Brightness.dark : Brightness.light;
    if (dynamicScheme != null) {
      return dynamicScheme;
    }
    return ColorScheme.fromSeed(seedColor: kFallbackSeedColor, brightness: brightness);
  }
}

/// A [ThemeExtension] that exposes the custom semantic colors used
/// throughout the app. Widgets can prefer this over the global
/// `colours` singleton via `Theme.of(context).extension<AppColours>()`.
@immutable
class AppColours extends ThemeExtension<AppColours> {
  const AppColours({
    required this.positive,
    required this.onPositive,
    required this.negative,
    required this.onNegative,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.onSurfaceVariant,
  });

  final Color positive;
  final Color onPositive;
  final Color negative;
  final Color onNegative;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color onSurfaceVariant;

  /// Builds an [AppColours] extension from the current global [Colours]
  /// palette. Kept as a convenience so the singleton remains the source
  /// of truth until widgets are migrated.
  factory AppColours.fromColours(Colours c) => AppColours(
    positive: c.primaryPositive,
    onPositive: c.darkMode ? const Color(0xFF003914) : const Color(0xFFFFFFFF),
    negative: c.primaryNegative,
    onNegative: c.darkMode ? const Color(0xFF690005) : const Color(0xFFFFFFFF),
    warning: c.primaryWarning,
    onWarning: c.darkMode ? const Color(0xFF402D00) : const Color(0xFFFFFFFF),
    info: c.primaryInfo,
    onInfo: c.darkMode ? const Color(0xFF003258) : const Color(0xFFFFFFFF),
    surfaceContainer: c.surfaceContainer,
    surfaceContainerHigh: c.surfaceContainerHigh,
    surfaceContainerHighest: c.surfaceContainerHighest,
    onSurfaceVariant: c.onSurfaceVariant,
  );

  @override
  AppColours copyWith({
    Color? positive,
    Color? onPositive,
    Color? negative,
    Color? onNegative,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? onSurfaceVariant,
  }) =>
      AppColours(
        positive: positive ?? this.positive,
        onPositive: onPositive ?? this.onPositive,
        negative: negative ?? this.negative,
        onNegative: onNegative ?? this.onNegative,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        info: info ?? this.info,
        onInfo: onInfo ?? this.onInfo,
        surfaceContainer: surfaceContainer ?? this.surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      );

  @override
  AppColours lerp(ThemeExtension<AppColours>? other, double t) {
    if (other is! AppColours) return this;
    return AppColours(
      positive: Color.lerp(positive, other.positive, t)!,
      onPositive: Color.lerp(onPositive, other.onPositive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      onNegative: Color.lerp(onNegative, other.onNegative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
    );
  }
}
