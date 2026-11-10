import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Fixed component sizes.
abstract final class AppSize {
  /// Every button: 52 high.
  static const double button = 52;

  /// Minimum touch target.
  static const double touch = 44;
}

/// The one Material theme. Every Material widget the app uses is restyled here, so no screen
/// shows an unstyled default.
ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: body,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.primary,
      primary: C.primary,
      onPrimary: Colors.white,
      secondary: C.secondary,
      surface: C.surface,
      error: C.red,
    ),
    scaffoldBackgroundColor: C.bg,
  );
  final t = base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink);
  return base.copyWith(
    textTheme: AppTypography.textTheme(t),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      titleTextStyle: TextStyle(fontFamily: display, fontSize: 20, fontWeight: FontWeight.w800, color: C.ink),
    ),
    cardTheme: CardThemeData(
      color: C.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(R.card),
        side: const BorderSide(color: C.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppSize.button, AppSize.button),
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.line,
        disabledForegroundColor: C.disabled,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.control)),
        textStyle: const TextStyle(fontFamily: body, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSize.button, AppSize.button),
        foregroundColor: C.primary,
        backgroundColor: C.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        side: const BorderSide(color: C.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.control)),
        textStyle: const TextStyle(fontFamily: body, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.primary,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.control)),
        textStyle: const TextStyle(fontFamily: body, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    // Inputs: white box, radius 16, the label floating on the top border (Labeled).
    // Borders: grey-green (3:1 on white), deep green when focused, muted terracotta on error.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      isDense: false,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      labelStyle: const TextStyle(color: C.ink2, fontWeight: FontWeight.w600),
      floatingLabelStyle: const TextStyle(color: C.primary, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: C.ink3),
      errorStyle: const TextStyle(color: C.red, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.35),
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _fieldLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _fieldLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: C.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _fieldError, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: _fieldError, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: const BorderSide(color: C.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: C.primarySoft,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.control)),
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(fontFamily: body, fontSize: 12, fontWeight: FontWeight.w600, color: s.contains(WidgetState.selected) ? C.primary : C.ink2),
      ),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.primary : C.ink2)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(44, 48),
        backgroundColor: C.surface,
        foregroundColor: C.ink2,
        selectedBackgroundColor: C.primary,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: C.line),
        textStyle: const TextStyle(fontFamily: body, fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.control)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: C.surface,
      selectedColor: C.primarySoft,
      side: const BorderSide(color: C.line),
      labelStyle: const TextStyle(fontFamily: body, fontSize: 14, fontWeight: FontWeight.w500, color: C.ink),
      shape: const StadiumBorder(),
    ),
    dividerTheme: const DividerThemeData(color: C.line, space: 1),
    listTileTheme: const ListTileThemeData(iconColor: C.primary, minVerticalPadding: 12),
    checkboxTheme: CheckboxThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.primary : C.line),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.primary, linearTrackColor: C.primarySoft),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.control)),
    ),
  );
}

const double _fieldRadius = 16;
const _fieldLine = Color(0xFF7D9282); // muted grey-green
const _fieldError = Color(0xFFB5543C); // muted terracotta red
