import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/deposit.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/entry_sheet.dart';
import 'automation_screen.dart';
import 'deposits_screen.dart';
import '../models/category.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenStats});

  final VoidCallback? onOpenStats;

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final AppPalette p = context.palette;
    final MonthSummary summary = store.summaryOf(store.selectedMonth);
    final List<MoneyEntry> entries =
        store.entriesOfMonth(store.selectedMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: <Widget>[
        _Header(store: store),
        const SizedBox(height: 16),
        _HeroCard(summary: summary),
        const SizedBox(height: 14),
        _InsightRow(summary: summary, store: store),
        const SizedBox(height: 12),
        _DepositCard(summary: store.depositSummary),
        const SizedBox(height: 22),
        SectionHeader(
          title: '最近记录',
          subtitle: '本月共 ${summary.count} 笔',
          action: entries.isEmpty ? null : '全部',
          onAction: onOpenStats,
        ),
        if (entries.isEmpty)
          AppCard(
            child: EmptyState(
              title: '这个月还没有账目',
              subtitle: '点底部「记一笔」，或在设置里恢复示例数据',
              icon: Icons.edit_calendar_rounded,
            ),
          )
        else
          _RecentList(entries: entries.take(8).toList(), palette: p),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final DateTime now = DateTime.now();
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppColors.brand, Color(0xFF6C4CF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('清账',
                style: AppText.title.copyWith(color: p.text, fontSize: 19)),
            const SizedBox(height: 2),
            Text(
              '${greeting(now)} · ${now.month}月${now.day}日 ${weekdayName(now)}',
              style: AppText.caption.copyWith(color: p.sub),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AutomationScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.bolt_rounded,
                    size: 15, color: AppColors.brand),
                const SizedBox(width: 3),
                Text(
                  '自动记账',
                  style: AppText.caption.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final double usage = summary.usage.clamp(0.0, 1.0);
    final Color usageColor = summary.overBudget
        ? const Color(0xFFFFD9A8)
        : Colors.white;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF3B62F6), Color(0xFF6E4BF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.3),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -40,
              top: -55,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const MonthSwitcher(onDark: true, compact: true),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          summary.overBudget
                              ? '已超支'
                              : '已用 ${fmtPercent(summary.usage)}',
                          style: AppText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '本月支出',
                    style: AppText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Text(
                        '¥',
                        style: AppText.section.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fmtMoney(summary.expense),
                            style: AppText.heroAmount
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: usage,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(usageColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.budget <= 0
                        ? '还没有设置预算 · 去「预算」定一个'
                        : summary.overBudget
                            ? '预算 ¥${fmtCompact(summary.budget)} · 已超出 ¥${fmtCompact(summary.expense - summary.budget)}'
                            : '预算 ¥${fmtCompact(summary.budget)} · 剩余 ¥${fmtCompact(summary.remaining)}',
                    style: AppText.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      _HeroStat(
                        label: '本月收入',
                        value: '¥${fmtCompact(summary.income)}',
                      ),
                      _HeroStat(
                        label: '本月预算',
                        value: '¥${fmtCompact(summary.budget)}',
                      ),
                      _HeroStat(
                        label: summary.overBudget ? '超出' : '剩余',
                        value:
                            '¥${fmtCompact(summary.remaining.abs())}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppText.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppText.amount.copyWith(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.summary, required this.store});

  final MonthSummary summary;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final double daily = store.dailyAverage(summary.month);
    final List<MoneyEntry> monthEntries =
        store.entriesOfMonth(summary.month);
    final int expenseCount =
        monthEntries.where((MoneyEntry e) => e.isExpense).length;
    final int incomeCount = monthEntries.length - expenseCount;
    String topName = '—';
    String topValue = '暂无支出';
    if (summary.byCategory.isNotEmpty) {
      final String topId = summary.byCategory.keys.first;
      topName = store.categoryOf(topId).name;
      topValue = '¥${fmtCompact(summary.byCategory.values.first)}';
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: _MiniCard(
            label: '日均支出',
            value: '¥${fmtCompact(daily)}',
            sub: '已过 ${store.elapsedDays(summary.month)} 天',
            palette: p,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniCard(
            label: '记账笔数',
            value: '${summary.count}',
            sub: '支出 $expenseCount · 收入 $incomeCount',
            palette: p,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MiniCard(
            label: '最大开销',
            value: topName,
            sub: topValue,
            palette: p,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.palette,
  });

  final String label;
  final String value;
  final String sub;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: AppText.caption.copyWith(color: palette.sub)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.section.copyWith(
              color: palette.text,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: palette.sub),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.entries, required this.palette});

  final List<MoneyEntry> entries;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final List<Widget> children = <Widget>[];
    String lastDay = '';

    for (final MoneyEntry entry in entries) {
      final String day = fmtDate(entry.time);
      if (day != lastDay) {
        if (children.isNotEmpty) {
          children.add(Divider(height: 18, color: palette.line));
        } else {
          children.add(const SizedBox(height: 6));
        }
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2, top: 2),
            child: Row(
              children: <Widget>[
                Text(
                  fmtDayLabel(entry.time),
                  style: AppText.caption.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  weekdayName(entry.time),
                  style: AppText.caption.copyWith(color: palette.sub),
                ),
              ],
            ),
          ),
        );
        lastDay = day;
      }
      final AppCategory category = store.categoryOf(entry.categoryId);
      children.add(
        EntryTile(
          entry: entry,
          category: category,
          showDate: false,
          onTap: () => showEntrySheet(context, entry),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(children: children),
    );
  }
}

class _DepositCard extends StatelessWidget {
  const _DepositCard({required this.summary});

  final DepositSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool empty = summary.isEmpty;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const DepositsScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.savings_rounded,
                    size: 17, color: AppColors.income),
              ),
              const SizedBox(width: 9),
              Text(
                '存款与利息',
                style: AppText.small.copyWith(
                  color: p.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                empty ? '去添加' : '${summary.count} 笔 · 管理',
                style: AppText.caption.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 1),
              Icon(Icons.chevron_right_rounded, size: 16, color: p.sub),
            ],
          ),
          const SizedBox(height: 10),
          if (empty)
            Text(
              '把本金和年化利率记进来，按天帮你算利息',
              style: AppText.caption.copyWith(color: p.sub),
            )
          else ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '¥${fmtMoney(summary.principal)}',
                  style: AppText.title.copyWith(
                    color: p.text,
                    fontSize: 22,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '综合年化 ${summary.weightedRate.toStringAsFixed(2)}%',
                    style: AppText.caption.copyWith(
                      color: AppColors.income,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _DepositStat(
                  label: '今日利息',
                  value: '+¥${summary.todayInterest.toStringAsFixed(2)}',
                  color: AppColors.income,
                  palette: p,
                ),
                _DepositStat(
                  label: '本月利息',
                  value: '+¥${fmtCompact(summary.monthlyInterest)}',
                  palette: p,
                ),
                _DepositStat(
                  label: '累计利息',
                  value: '+¥${fmtCompact(summary.accruedInterest)}',
                  palette: p,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DepositStat extends StatelessWidget {
  const _DepositStat({
    required this.label,
    required this.value,
    required this.palette,
    this.color,
  });

  final String label;
  final String value;
  final AppPalette palette;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label,
              style: AppText.caption.copyWith(color: palette.sub)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.small.copyWith(
              color: color ?? palette.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
