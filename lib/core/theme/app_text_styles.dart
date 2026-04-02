import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  AppTextStyles — single source of truth for all text in the Luminar app.
//
//  TYPE SCALE  (base unit = 1px)
//  ─────────────────────────────
//   9  → badge / micro label
//  10  → micro caption
//  11  → small label / hint
//  12  → caption / overline
//  13  → form label / sub-caption
//  14  → body 2 / secondary body
//  15  → input field text
//  16  → body 1 / stat value
//  18  → section title / card title
//  20  → heading 3
//  22  → heading 2 (screen titles)
//  24  → heading 1 (large headings)
//  28  → display 2
//  32  → display 1
//
//  WEIGHT CONVENTIONS
//  ─────────────────
//  w400 → body / captions
//  w500 → medium / labels
//  w600 → semi-bold / secondary headings
//  w700 → bold / card headings
//  w800 → extra-bold / screen titles
//  w900 → black / display / brand names
//
//  USAGE
//  ─────
//  Text('Hello', style: AppTextStyles.heading2)
//  Text('Hello', style: AppTextStyles.body1.white)       ← on dark bg
//  Text('Hello', style: AppTextStyles.label.copyWith(color: someColor))
// ══════════════════════════════════════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();

  // ── Display (Brand / Hero) ────────────────────────────────────────────────

  /// 32 · w900 — largest hero text, brand headers on splash
  static TextStyle get display1 => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// 28 · w900 — secondary hero / onboarding headline
  static TextStyle get display2 => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      );

  // ── Headings ──────────────────────────────────────────────────────────────

  /// 24 · w800 — page-level heading (e.g. "My Enrollments")
  static TextStyle get heading1 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// 22 · w800 — screen title (e.g. "Welcome Back", "Login")
  static TextStyle get heading2 => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// 20 · w700 — sub-page heading / card heading
  static TextStyle get heading3 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// 18 · w700 — section heading (e.g. "My Courses", "Financial Overview")
  static TextStyle get sectionTitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// 16 · w600 — sub-section / card title
  static TextStyle get subheading => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────────────────────────

  /// 16 · w400 — primary body text
  static TextStyle get body1 => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.55,
      );

  /// 14 · w400 — secondary body text / descriptions
  static TextStyle get body2 => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.55,
      );

  /// 15 · w400 — input field text (slightly smaller than body1)
  static TextStyle get inputText => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ── Labels ────────────────────────────────────────────────────────────────

  /// 13 · w600 — form field label / strong small label
  static TextStyle get formLabel => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// 13 · w500 — sub-label / helper text
  static TextStyle get label => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  /// 12 · w500 — standard caption / tag / time stamps
  static TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  /// 11 · w500 — small label (dates, enrollment IDs, secondary chips)
  static TextStyle get smallLabel => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  /// 10 · w400 — micro caption (timestamps, fine print)
  static TextStyle get micro => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        height: 1.4,
      );

  /// 9 · w700 — badge text (status chips, dot labels) — always uppercase
  static TextStyle get badge => TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: 0.4,
      );

  // ── Overline / Uppercase Labels ───────────────────────────────────────────

  /// 12 · w700 · spaced — section overline (e.g. "MY COURSES", "BATCH")
  static TextStyle get overline => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        height: 1.4,
        letterSpacing: 1.2,
      );

  /// 10 · w700 · spaced — tight overline for card field labels
  static TextStyle get overlineSmall => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        height: 1.3,
        letterSpacing: 1.0,
      );

  // ── Hint ──────────────────────────────────────────────────────────────────

  /// 14 · w400 — input placeholder / hint text
  static TextStyle get hint => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        height: 1.4,
      );

  // ── Buttons ───────────────────────────────────────────────────────────────

  /// 16 · w600 — standard button label
  static TextStyle get button => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  /// 14 · w600 — small / secondary button label
  static TextStyle get buttonSmall => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  /// 17 · w700 — large CTA button (Sign In, Continue)
  static TextStyle get buttonLarge => const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      );

  // ── Stats / Data Display ──────────────────────────────────────────────────

  /// 16 · w700 — stat value (numbers / highlights on cards)
  static TextStyle get statValue => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  /// 12 · w500 — stat label below the value
  static TextStyle get statLabel => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ── Navigation / Tab ──────────────────────────────────────────────────────

  /// 11 · w500 — bottom nav label
  static TextStyle get navLabel => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Splash / Brand specific ───────────────────────────────────────────────

  /// 26+ brand name on splash — always white, high letter spacing
  static TextStyle get brandName => const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 4,
        height: 1.2,
      );

  /// 12 · w500 — tagline / slogan pill on splash
  static TextStyle get tagline => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 0.2,
        height: 1.5,
      );

  /// 11 · w400 — version text (bottom-right of splash)
  static TextStyle get version => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.versionText,
        letterSpacing: 0.3,
      );

  // ── Legacy aliases (kept for backward compatibility) ──────────────────────
  // These map old names to the new scale so existing code doesn't break.

  /// @deprecated Use [sectionTitle]
  static TextStyle get headerName => sectionTitle.copyWith(fontSize: 18);

  /// @deprecated Use [body2]
  static TextStyle get headerSubtitle => body2;

  /// @deprecated Use [subheading]
  static TextStyle get activityTitle => subheading;

  /// @deprecated Use [body2]
  static TextStyle get activitySubtitle => body2;

  /// @deprecated Use [caption]
  static TextStyle get activityTime =>
      caption.copyWith(color: AppColors.textHint);

  /// @deprecated Use [body1]
  static TextStyle get bodyText => body1;

  /// @deprecated Use [body1]
  static TextStyle get bodyText1 => body1;

  /// @deprecated Use [body2]
  static TextStyle get bodyText2 => body2;

  /// @deprecated Use [body1]
  static TextStyle get subtitle1 => body1.copyWith(fontWeight: FontWeight.w400);

  /// @deprecated Use [hint]
  static TextStyle get hintText => hint;

  /// @deprecated Use [button]
  static TextStyle get buttonText => button;

  /// @deprecated Use [caption]
  static TextStyle get welcomeStatus =>
      caption.copyWith(color: AppColors.statusActive, fontWeight: FontWeight.w600);

  /// @deprecated Use [overline] or [label]
  static TextStyle get courseCardLabel =>
      smallLabel.copyWith(color: AppColors.textWhite70);

  /// @deprecated Use [heading3.white]
  static TextStyle get courseCardTitle =>
      heading3.copyWith(color: AppColors.textWhite);

  /// @deprecated Use [subheading.white]
  static TextStyle get courseCardValue =>
      subheading.copyWith(color: AppColors.textWhite);

  /// @deprecated Use [caption.white]
  static TextStyle get courseCardProgress =>
      caption.copyWith(color: AppColors.textWhite70);

  /// @deprecated Use [buttonSmall]
  static TextStyle get courseCardButton => buttonSmall;
}

// ══════════════════════════════════════════════════════════════════════════════
//  AppSpacing — standard spacing / sizing constants
//  Use these everywhere instead of hardcoded values.
//
//  SCALE:  2 · 4 · 6 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64
// ══════════════════════════════════════════════════════════════════════════════

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 6;
  static const double md  = 8;
  static const double lg  = 12;
  static const double xl  = 16;
  static const double xl2 = 20;
  static const double xl3 = 24;
  static const double xl4 = 32;
  static const double xl5 = 40;
  static const double xl6 = 48;
  static const double xl7 = 64;

  // Common SizedBox shortcuts
  static const Widget h2  = SizedBox(height: xxs);
  static const Widget h4  = SizedBox(height: xs);
  static const Widget h6  = SizedBox(height: sm);
  static const Widget h8  = SizedBox(height: md);
  static const Widget h12 = SizedBox(height: lg);
  static const Widget h16 = SizedBox(height: xl);
  static const Widget h20 = SizedBox(height: xl2);
  static const Widget h24 = SizedBox(height: xl3);
  static const Widget h32 = SizedBox(height: xl4);
  static const Widget h40 = SizedBox(height: xl5);

  static const Widget w4  = SizedBox(width: xs);
  static const Widget w6  = SizedBox(width: sm);
  static const Widget w8  = SizedBox(width: md);
  static const Widget w12 = SizedBox(width: lg);
  static const Widget w16 = SizedBox(width: xl);

  // Common EdgeInsets shortcuts
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: xl, vertical: xl);
  static const EdgeInsets cardPadding =
      EdgeInsets.all(xl);
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: sm);
  static const EdgeInsets badgePadding =
      EdgeInsets.symmetric(horizontal: md, vertical: xs);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: xl3, vertical: lg);
}

// ══════════════════════════════════════════════════════════════════════════════
//  AppRadius — standard border radius constants
// ══════════════════════════════════════════════════════════════════════════════

class AppRadius {
  AppRadius._();

  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xl2  = 24;
  static const double full = 999;

  static BorderRadius get xsAll   => BorderRadius.circular(xs);
  static BorderRadius get smAll   => BorderRadius.circular(sm);
  static BorderRadius get mdAll   => BorderRadius.circular(md);
  static BorderRadius get lgAll   => BorderRadius.circular(lg);
  static BorderRadius get xlAll   => BorderRadius.circular(xl);
  static BorderRadius get xl2All  => BorderRadius.circular(xl2);
  static BorderRadius get pill    => BorderRadius.circular(full);
}

// ══════════════════════════════════════════════════════════════════════════════
//  TextStyle extension — quick colour overrides on any style
//
//  Usage:
//    AppTextStyles.body1.white         → white text
//    AppTextStyles.sectionTitle.hint   → hint-coloured text
//    AppTextStyles.heading2.primary    → primary-colour text
// ══════════════════════════════════════════════════════════════════════════════

extension TextStyleX on TextStyle {
  TextStyle get white    => copyWith(color: Colors.white);
  TextStyle get white70  => copyWith(color: Colors.white70);
  TextStyle get primary  => copyWith(color: AppColors.primary);
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  TextStyle get hint     => copyWith(color: AppColors.textHint);
  TextStyle get error    => copyWith(color: AppColors.error);
  TextStyle get success  => copyWith(color: AppColors.statusActive);
  TextStyle get bold     => copyWith(fontWeight: FontWeight.w700);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium   => copyWith(fontWeight: FontWeight.w500);
}
