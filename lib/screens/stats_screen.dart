import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  EntryType _type = EntryType.expense;

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final AppPalette p = context.palette;
    final DateTime month = store.selectedMonth;
    final Map<String, double> totals = store.categoryTotals(month, _type);
    final double total = totals.values.fold<double>(
      0,
      (double sum, double v) => sum + v,
    );
    final List<MonthSummary> months = store.recentMonths(6);
    final Color accent =
        _type == EntryType.expense ? AppColors.expense : AppColors.income;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('统计', style: AppText.title.copyWith(color: p.text)),
            const Spacer(),
            const MonthSwitcher(compact: true),
          ],
        ),
        const SizedBox(height: 16),
        _TypeSwitch(
          type: _type,
          onChanged: (EntryType t) => setState(() => _type = t),
          palette: p,
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    _type == EntryType.expense ? '支出结构' : '收入结构',
                    style: AppText.section.copyWith(color: p.text),
                  ),
                  const Spacer(),
                  Text(
                    '${totals.length} 个分类',
                    style: AppText.caption.copyWith(color: p.sub),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (total <= 0)
                EmptyState(
                  icon: Icons.pie_chart_outline_rounded,
                  title: '${fmtMonth(month)}还没有${_type.label}',
                  subtitle: '换个月份看看，或先记一笔',
                )
              else ...<Widget>[
                DonutChart(
                  slices: totals.entries
                      .map(
                        (MapEntry<String, double> e) => DonutSlice(
                          color: store.categoryOf(e.key).displayColor,
                          value: e.value,
                        ),
                      )
                      .toList(),
                  size: 168,
                  stroke: 20,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '合计${_type.label}',
                        style: AppText.caption.copyWith(color: p.sub),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¥${fmtCompact(total)}',
                        style: AppText.title.copyWith(
                          color: p.text,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...totals.entries.map(
                  (MapEntry<String, double> e) => _RankRow(
                    category: store.categoryOf(e.key),
                    amount: e.value,
                    total: total,
                    accent: accent,
                    palette: p,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('近 6 个月收支', style: AppText.section.copyWith(color: p.text)),
              const SizedBox(height: 14),
              TrendBars(months: months),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch({
    required this.type,
    required this.onChanged,
    required this.palette,
  });

  final EntryType type;
  final ValueChanged<EntryType> onChanged;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Pill(
          label: '支出',
          icon: Icons.north_east_rounded,
          selected: type == EntryType.expense,
          accent: AppColors.expense,
          onTap: () => onChanged(EntryType.expense),
        ),
        const SizedBox(width: 8),
        Pill(
          label: '收入',
          icon: Icons.south_west_rounded,
          selected: type == EntryType.income,
          accent: AppColors.income,
          onTap: () => onChanged(EntryType.income),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.accent,
    required this.palette,
  });

  final AppCategory category;
  final double amount;
  final double total;
  final Color accent;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final double ratio = total <= 0 ? 0 : amount / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: category.displayColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: AppText.body.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                fmtPercent(ratio),
                style: AppText.caption.copyWith(color: palette.sub),
              ),
              const Spacer(),
              Text(
                '¥${fmtMoney(amount)}',
                style: AppText.amount.copyWith(color: palette.text),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: palette.fill,
              valueColor: AlwaysStoppedAnimation<Color>(
                category.displayColor.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
