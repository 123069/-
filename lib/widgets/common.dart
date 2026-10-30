import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// 基础卡片：圆角 + 柔和阴影 + 可选点击
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = 22,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: p.softShadow,
      ),
      child: child,
    );
    final Widget wrapped = margin == null
        ? body
        : Padding(padding: margin!, child: body);
    if (onTap == null) return wrapped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: wrapped,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppText.section.copyWith(color: p.text)),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(subtitle!,
                      style: AppText.small.copyWith(color: p.sub)),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 42,
    this.filled = false,
  });

  final AppCategory category;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color c = category.displayColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(
        category.displayIcon,
        size: size * 0.48,
        color: filled ? Colors.white : c,
      ),
    );
  }
}

/// 可选中的胶囊按钮
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.accent,
    this.icon,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color color = accent ?? AppColors.brand;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 16,
          vertical: dense ? 7 : 10,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : p.fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon,
                  size: dense ? 14 : 16,
                  color: selected ? color : p.sub),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppText.small.copyWith(
                fontSize: dense ? 12 : 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? color : p.sub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 月份切换（首页 / 统计 / 预算共用一份 store 状态）
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    this.onDark = false,
    this.compact = false,
  });

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final DateTime month = store.selectedMonth;
    final DateTime current = nowMonth();
    final bool canGoNext =
        month.year < current.year ||
        (month.year == current.year && month.month < current.month);
    final Color fg = onDark ? Colors.white : context.palette.text;
    final Color fgSoft =
        onDark ? Colors.white.withValues(alpha: 0.65) : context.palette.sub;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _arrow(
          icon: Icons.chevron_left_rounded,
          color: fgSoft,
          onTap: () => store.setMonth(
            DateTime(month.year, month.month - 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            fmtMonth(month),
            style: AppText.small.copyWith(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
        _arrow(
          icon: Icons.chevron_right_rounded,
          color: canGoNext ? fgSoft : fgSoft.withValues(alpha: 0.3),
          onTap: canGoNext
              ? () => store.setMonth(DateTime(month.year, month.month + 1))
              : null,
        ),
        if (!compact)
          GestureDetector(
            onTap: () => store.setMonth(current),
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '回到本月',
                style: AppText.caption.copyWith(color: fgSoft),
              ),
            ),
          ),
      ],
    );
  }

  Widget _arrow({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) =>
      InkResponse(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: color),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.receipt_long_rounded,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: p.fill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: p.sub, size: 26),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: p.text,
                fontWeight: FontWeight.w600,
              )),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(color: p.sub),
            ),
          ],
        ],
      ),
    );
  }
}

/// 环形进度（预算使用率）
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 136,
    this.stroke = 12,
    this.colors = const <Color>[AppColors.brand, Color(0xFF6C4CF1)],
    required this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0.0, 1.0),
          stroke: stroke,
          colors: colors,
          track: context.palette.fill,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.stroke,
    required this.colors,
    required this.track,
  });

  final double value;
  final double stroke;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (value <= 0) return;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: colors,
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.colors != colors || old.track != track;
}

class DonutSlice {
  const DonutSlice({required this.color, required this.value, this.label = ''});

  final Color color;
  final double value;
  final String label;
}

/// 支出分类占比环图
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 150,
    this.stroke = 18,
    this.center,
  });

  final List<DonutSlice> slices;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(slices: slices, stroke: stroke),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices, required this.stroke});

  final List<DonutSlice> slices;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = slices.fold<double>(
      0,
      (double sum, DonutSlice s) => sum + s.value,
    );
    if (total <= 0) return;

    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - stroke) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double gap = slices.length > 1 ? 0.035 : 0;
    double start = -math.pi / 2;

    for (final DonutSlice slice in slices) {
      final double sweep = (slice.value / total) * math.pi * 2;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = slice.color;
      if (sweep > gap * 2) {
        canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint);
      } else if (sweep > 0.004) {
        canvas.drawArc(rect, start, sweep, false, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.stroke != stroke;
}

/// 近几个月收支趋势
class TrendBars extends StatelessWidget {
  const TrendBars({super.key, required this.months, this.height = 118});

  final List<MonthSummary> months;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    double maxValue = 0;
    for (final MonthSummary m in months) {
      maxValue = math.max(maxValue, math.max(m.expense, m.income));
    }
    if (maxValue <= 0) maxValue = 1;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            _legendDot(AppColors.expense, '支出', p.sub),
            const SizedBox(width: 12),
            _legendDot(AppColors.income, '收入', p.sub),
            const Spacer(),
            Text(
              '单位：元',
              style: AppText.caption.copyWith(color: p.sub),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((MonthSummary m) {
              final bool isCurrent = identical(m, months.last);
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _bar(m.expense, maxValue, AppColors.expense,
                            height: height - 26, highlight: isCurrent),
                        const SizedBox(width: 3),
                        _bar(m.income, maxValue, AppColors.income,
                            height: height - 26, highlight: isCurrent),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: months.map((MonthSummary m) {
            final bool isCurrent = identical(m, months.last);
            return Expanded(
              child: Text(
                fmtMonthShort(m.month),
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(
                  color: isCurrent ? p.text : p.sub,
                  fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label, Color textColor) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: AppText.caption.copyWith(color: textColor)),
        ],
      );

  Widget _bar(
    double value,
    double maxValue,
    Color color, {
    required double height,
    required bool highlight,
  }) {
    final double ratio = value <= 0 ? 0 : (value / maxValue).clamp(0.0, 1.0);
    final double h = value <= 0 ? 3 : (4 + ratio * height);
    return Container(
      width: 9,
      height: h,
      decoration: BoxDecoration(
        color: highlight ? color : color.withValues(alpha: 0.35),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

/// 列表里的一条账目
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.category,
    this.onTap,
    this.showDate = false,
  });

  final MoneyEntry entry;
  final AppCategory category;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Color amountColor =
        entry.isExpense ? p.text : AppColors.income;
    final String when = showDate
        ? fmtDateTime(entry.time)
        : '${fmtHM(entry.time)} · ${entry.source}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: <Widget>[
            CategoryAvatar(category: category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        category.name,
                        style: AppText.body.copyWith(
                          color: p.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (entry.note.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            entry.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.small.copyWith(color: p.sub),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    when,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: p.sub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.isExpense ? '-' : '+'}${fmtMoney(entry.amount)}',
              style: AppText.amount.copyWith(color: amountColor),
            ),
          ],
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {IconData? icon}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(milliseconds: 2200),
      content: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: AppText.body.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

const List<String> kQuickNotes = <String>['早餐', '午餐', '晚餐', '打车', '买菜', '咖啡'];
