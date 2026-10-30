import 'package:flutter/material.dart';

/// 清账的配色与主题。
///
/// 设计取向：大留白 + 卡片 + 单一品牌色（清蓝），支出/收入只用两种语义色，
/// 分类则使用一组低饱和的分类色，保证「一眼看出是哪类花销」。
class AppColors {
  AppColors._();

  // 品牌色
  static const Color brand = Color(0xFF3B62F6);
  static const Color brandDeep = Color(0xFF2743C4);
  static const Color brandSoft = Color(0xFFE8EDFF);

  // 语义色（支出偏珊瑚红、收入偏青绿，符合中文记账习惯）
  static const Color expense = Color(0xFFE8553F);
  static const Color income = Color(0xFF12A26B);
  static const Color warn = Color(0xFFF2A03D);

  // 浅色
  static const Color lightBg = Color(0xFFF4F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightLine = Color(0xFFEDEFF5);
  static const Color lightText = Color(0xFF141821);
  static const Color lightSub = Color(0xFF8B92A3);

  // 深色
  static const Color darkBg = Color(0xFF0C0F14);
  static const Color darkCard = Color(0xFF161A21);
  static const Color darkLine = Color(0xFF252B35);
  static const Color darkText = Color(0xFFEDEFF4);
  static const Color darkSub = Color(0xFF8C95A6);

  /// 分类色板
  static const List<Color> categorical = <Color>[
    Color(0xFFFF7A45),
    Color(0xFF4C8DFF),
    Color(0xFFB36BFF),
    Color(0xFF2FB2B0),
    Color(0xFF5AC8FA),
    Color(0xFFFF6B9A),
    Color(0xFFFFC53D),
    Color(0xFF34C759),
    Color(0xFFFF9F0A),
    Color(0xFF8E8E93),
    Color(0xFF12A26B),
    Color(0xFF7D8CA3),
  ];
}

/// 当前主题下的语义色，避免每个组件都写一遍三元表达式。
class AppPalette {
  const AppPalette({required this.isDark});

  final bool isDark;

  static AppPalette of(BuildContext context) =>
      AppPalette(isDark: Theme.of(context).brightness == Brightness.dark);

  Color get bg => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get card => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get line => isDark ? AppColors.darkLine : AppColors.lightLine;
  Color get text => isDark ? AppColors.darkText : AppColors.lightText;
  Color get sub => isDark ? AppColors.darkSub : AppColors.lightSub;

  /// 输入框、胶囊按钮等次级底色
  Color get fill => isDark ? const Color(0xFF1E232C) : const Color(0xFFF3F4F8);

  Color get cardShadow =>
      isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF9AA6C2).withValues(alpha: 0.16);

  List<BoxShadow> get softShadow => <BoxShadow>[
        BoxShadow(
          color: cardShadow,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// 字号与字形
class AppText {
  AppText._();

  static const TextStyle display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.6,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle section = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(fontSize: 14, height: 1.45);

  static const TextStyle small = TextStyle(fontSize: 12, height: 1.35);

  static const TextStyle caption = TextStyle(fontSize: 11, height: 1.3);

  static const TextStyle amount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle heroAmount = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.05,
    letterSpacing: -0.5,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    const Color seed = AppColors.brand;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.brandDeep,
      surface: isDark ? AppColors.darkCard : AppColors.lightCard,
      onSurface: isDark ? AppColors.darkText : AppColors.lightText,
      error: AppColors.expense,
    );

    final Color bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final Color text = isDark ? AppColors.darkText : AppColors.lightText;
    final Color sub = isDark ? AppColors.darkSub : AppColors.lightSub;
    final Color line = isDark ? AppColors.darkLine : AppColors.lightLine;

    final Typography typography = Typography.material2021();
    final TextTheme base = isDark ? typography.white : typography.black;
    final TextTheme textTheme = base.apply(
      bodyColor: text,
      displayColor: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title.copyWith(color: text),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E232C) : const Color(0xFFF3F4F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppText.body.copyWith(color: sub),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          textStyle: AppText.section.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: line),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2A303B) : const Color(0xFF1E232D),
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brand,
        selectionColor: AppColors.brandSoft,
        selectionHandleColor: AppColors.brand,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => AppPalette.of(this);
  Color get cText => palette.text;
  Color get cSub => palette.sub;
  Color get cBg => palette.bg;
  Color get cCard => palette.card;
  Color get cLine => palette.line;
}
