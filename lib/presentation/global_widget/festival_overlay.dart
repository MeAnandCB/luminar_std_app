import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

enum FestivalTheme {
  none,
  independenceDay,
  onam,
  christmas,
  vishu,
  valentinesDay,
  mothersDay,
}

class FestivalThemeInfo {
  final FestivalTheme theme;
  final String? titleOverride;

  FestivalThemeInfo({required this.theme, this.titleOverride});
}

class FestivalDateManager {
  // Legacy list kept for backward compatibility
  static final List<String> onamDays = [
    "Happy Atham!",
    "Happy Chithira!",
    "Happy Chodi!",
    "Happy Vishakam!",
    "Happy Anizham!",
    "Happy Thrikketta!",
    "Happy Moolam!",
    "Happy Pooradam!",
    "Happy Uthradom!",
    "Happy Thiruvonam!",
  ];

  // Onam Atham dates by year (update annually)
  static final Map<int, DateTime> _athamDates = {
    2025: DateTime(2025, 8, 22),
    2026: DateTime(2026, 9, 10), // approximate — confirm when official
  };

  /// Returns how many days into Onam we are (0 = Atham, 9 = Thiruvonam).
  /// Returns -1...-7 for teaser period before Atham.
  /// Returns null if not in Onam season.
  static int? getOnamDayOffset() {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final atham = _athamDates[now.year];
    if (atham == null) return null;
    final diff = today.difference(atham).inDays;
    if (diff >= 0 && diff < 10) return diff;       // active days 0-9
    if (diff >= -7 && diff < 0) return diff;       // teaser -7 to -1
    return null;
  }

  /// Returns a day-specific title for the overlay banner during Onam.
  static String getOnamDayTitle() {
    final offset = getOnamDayOffset();
    if (offset == null) return 'Happy Onam!';
    if (offset < 0) return 'Onam is Coming!';
    return onamDays[offset];
  }

  static FestivalThemeInfo getCurrentThemeInfo() {
    final now = DateTime.now();

    // Independence Day: Aug 15
    if (now.month == 8 && now.day == 15) {
      return FestivalThemeInfo(theme: FestivalTheme.independenceDay);
    }
    // Christmas: Dec 24-26
    if (now.month == 12 && now.day >= 24 && now.day <= 26) {
      return FestivalThemeInfo(theme: FestivalTheme.christmas);
    }
    // Valentine's Day: Feb 14
    if (now.month == 2 && now.day == 14) {
      return FestivalThemeInfo(theme: FestivalTheme.valentinesDay);
    }
    // Mother's Day: May 10th
    if (now.month == 5 && now.day == 10) {
      return FestivalThemeInfo(theme: FestivalTheme.mothersDay);
    }
    // Vishu: April 14
    if (now.month == 4 && now.day == 14) {
      return FestivalThemeInfo(theme: FestivalTheme.vishu);
    }
    // Onam: 10-day window + 7-day teaser
    if (getOnamDayOffset() != null) {
      return FestivalThemeInfo(
        theme: FestivalTheme.onam,
        titleOverride: getOnamDayTitle(),
      );
    }

    return FestivalThemeInfo(theme: FestivalTheme.none);
  }

  static String getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return "$weekday, $month ${now.day}";
  }

  static final Map<FestivalTheme, FestivalConfig> configs = {
    FestivalTheme.independenceDay: const FestivalConfig(
      title: "Happy Independence Day!",
      backgroundColor: Color(0xFFFFF7ED), // Soft warm saffron tint
      bannerGradient: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
      icon: "🇮🇳",
    ),
    FestivalTheme.onam: const FestivalConfig(
      title: "Happy Onam!",
      backgroundColor: Color(0xFFFEF9C3), // Soft gold/yellow tint
      bannerGradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      icon: "🌸",
    ),
    FestivalTheme.christmas: const FestivalConfig(
      title: "Merry Christmas!",
      backgroundColor: Color(0xFFF0FDF4), // Soft mint tint
      bannerGradient: [Color(0xFFDC2626), Color(0xFF16A34A)],
      icon: "🎄",
    ),
    FestivalTheme.vishu: const FestivalConfig(
      title: "Happy Vishu!",
      backgroundColor: Color(0xFFFFFBEB), // Soft yellow tint
      bannerGradient: [Color(0xFFFDE047), Color(0xFFEAB308)],
      icon: "✨",
    ),
    FestivalTheme.valentinesDay: const FestivalConfig(
      title: "Happy Valentine's Day!",
      backgroundColor: Color(0xFFFFF1F2), // Soft pink tint
      bannerGradient: [Color(0xFFF43F5E), Color(0xFFE11D48)],
      icon: "💖",
    ),
    FestivalTheme.mothersDay: const FestivalConfig(
      title: "Happy Mother's Day!",
      backgroundColor: Color(0xFFFDF4FF), // Soft purple/pink tint
      bannerGradient: [Color(0xFFD946EF), Color(0xFFC026D3)],
      icon: "👩‍👧",
    ),
  };
}

class FestivalConfig {
  final String title;
  final Color backgroundColor;
  final List<Color> bannerGradient;
  final String icon;

  const FestivalConfig({
    required this.title,
    required this.backgroundColor,
    required this.bannerGradient,
    required this.icon,
  });
}

class FestivalOverlay extends StatefulWidget {
  final Widget child;
  final FestivalTheme theme;
  final String? titleOverride;
  final Color defaultBackgroundColor;

  const FestivalOverlay({
    super.key,
    required this.child,
    this.theme = FestivalTheme.none,
    this.titleOverride,
    required this.defaultBackgroundColor,
  });

  @override
  State<FestivalOverlay> createState() => _FestivalOverlayState();
}

class _FestivalOverlayState extends State<FestivalOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _bannerController;

  // Configuration for festivals
  final Map<FestivalTheme, FestivalConfig> _configs = {
    FestivalTheme.independenceDay: const FestivalConfig(
      title: "Happy Independence Day!",
      backgroundColor: Color(0xFFFFF7ED), // Soft warm saffron tint
      bannerGradient: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
      icon: "🇮🇳",
    ),
    FestivalTheme.onam: const FestivalConfig(
      title: "Happy Onam!",
      backgroundColor: Color(0xFFFEF9C3), // Soft gold/yellow tint
      bannerGradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      icon: "🌸",
    ),
    FestivalTheme.christmas: const FestivalConfig(
      title: "Merry Christmas!",
      backgroundColor: Color(0xFFF0FDF4), // Soft mint tint
      bannerGradient: [Color(0xFFDC2626), Color(0xFF16A34A)],
      icon: "🎄",
    ),
    FestivalTheme.vishu: const FestivalConfig(
      title: "Happy Vishu!",
      backgroundColor: Color(0xFFFFFBEB), // Soft yellow tint
      bannerGradient: [Color(0xFFFDE047), Color(0xFFEAB308)],
      icon: "✨",
    ),
    FestivalTheme.valentinesDay: const FestivalConfig(
      title: "Happy Valentine's Day!",
      backgroundColor: Color(0xFFFFF1F2), // Soft pink tint
      bannerGradient: [Color(0xFFF43F5E), Color(0xFFE11D48)],
      icon: "💖",
    ),
    FestivalTheme.mothersDay: const FestivalConfig(
      title: "Happy Mother's Day!",
      backgroundColor: Color(0xFFFDF4FF), // Soft purple/pink tint
      bannerGradient: [Color(0xFFD946EF), Color(0xFFC026D3)],
      icon: "👩‍👧",
    ),
  };

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.theme != FestivalTheme.none) {
      // Delay slightly for dramatic entry
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _bannerController.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant FestivalOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      if (widget.theme == FestivalTheme.none) {
        _bannerController.reverse();
      } else {
        _bannerController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _configs[widget.theme];
    final activeBgColor =
        config?.backgroundColor ?? widget.defaultBackgroundColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      color: activeBgColor,
      child: Column(
        children: [
          // 1. Animated Banner (Pushes content down)
          if (config != null)
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: _bannerController,
                curve: Curves.elasticOut,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            config?.bannerGradient ??
                            const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (config != null)
                              Text(
                                config.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            if (config != null) const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                widget.titleOverride ?? config.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      widget.theme ==
                                          FestivalTheme.independenceDay
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  letterSpacing: 0.5,
                                  shadows:
                                      widget.theme ==
                                          FestivalTheme.independenceDay
                                      ? []
                                      : [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (config != null) const SizedBox(width: 12),
                            if (config != null)
                              Text(
                                config.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 2. The Main Screen Content
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
