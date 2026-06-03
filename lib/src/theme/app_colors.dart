import 'package:pamsimas_app/pamsimas_app.dart';

/// Static color palette used across the entire app.
///
/// All raw hex color values should be defined here so they can be
/// referenced from any screen without duplication.
abstract final class AppPalette {
  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primaryBlue   = Color(0xFF1565C0);
  static const Color lightBlue     = Color(0xFF42A5F5);

  // ── Background / Surface ─────────────────────────────────────────────────
  static const Color bgGrey        = Color(0xFFF2F4F7);
  static const Color bgGreyLight   = Color(0xFFF3F4F6);
  static const Color fillGrey      = Color(0xFFF9FAFB);
  static const Color readonlyBlue  = Color(0xFFF0F4FF);
  static const Color bgBluePale    = Color(0xFFE3F2FD);
  static const Color bgBlueLight   = Color(0xFFE8F0FE);
  static const Color bgGreenPale   = Color(0xFFE8F5E9);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textDark      = Color(0xFF1A1A2E);
  static const Color textLabel     = Color(0xFF374151);
  static const Color textGrey      = Color(0xFF6B7280);
  static const Color textGreyLight = Color(0xFF9CA3AF);
  static const Color textGreyMuted = Color(0xFFBDBDBD);
  static const Color textHint      = Color(0xFFB0BEC5);
  static const Color textHintLight = Color(0xFFD1D5DB);

  // ── Border ───────────────────────────────────────────────────────────────
  static const Color borderGrey    = Color(0xFFE5E7EB);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color errorRed      = Color(0xFFC62828);
  static const Color successGreen  = Color(0xFF2E7D32);
  static const Color teal          = Color(0xFF00897B);
  static const Color orange        = Color(0xFFE65100);
}

/// {@template app_colors}
/// Custom color tokens beyond Material's [ColorScheme].
///
/// Provides semantic colors for success, warning, and info states
/// along with their on-color variants.
/// {@endtemplate}
class AppColors extends ThemeExtension<AppColors> {
  /// {@macro app_colors}
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  /// The color used for success states.
  final Color success;

  /// The color used for content on top of [success].
  final Color onSuccess;

  /// The color used for warning states.
  final Color warning;

  /// The color used for content on top of [warning].
  final Color onWarning;

  /// The color used for informational states.
  final Color info;

  /// The color used for content on top of [info].
  final Color onInfo;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}
