import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const List<int> _quickBudgets = <int>[2000, 3000, 5000, 8000];

  Future<void> _applyQuick(int value) async {
    final AppStore store = context.read<AppStore>();
    await store.setBudget(store.selectedMonth, value.toDouble());
    if (!mounted) return;
    showAppSnack(
      context,
      '${fmtMonth(store.selectedMonth)}预算已设为 ¥${fmtMoney(value.toDouble())}',
      icon: Icons.savings_rounded,
    );
  }

  Future<void> _saveCustom(String raw) async {
    final AppStore store = context.read<AppStore>();
    final double? value = double.tryParse(raw.trim());
    if (value == null || value <= 0) {
      showAppSnack(context, '请输入大于 0 的金额');
      return;
    }
    await store.setBudget(store.selectedMonth, value);
    if (!mounted) return;
    showAppSnack(context, '预算已保存', icon: Icons.check_circle_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final AppPalette p = context.palette;
    final DateTime month = store.selectedMonth;
    final MonthSummary summary = store.summaryOf(month);
    final double budget = summary.budget;
    final double remaining = summary.remaining;
    final int daysLeft = store.daysLeftInMonth(month);
    final double dailyAvailable =
        remaining <= 0 ? 0 : remaining / (daysLeft <= 0 ? 1 : daysLeft);
    final double usage = budget <= 0 ? 0 : summary.expense / budget;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('预算', style: AppText.title.copyWith(color: p.text)),
            const Spacer(),
            const MonthSwitcher(compact: true),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  ProgressRing(
                    value: usage,
                    size: 120,
                    stroke: 11,
                    colors: summary.overBudget
                        ? const <Color>[Color(0xFFFF8A65), AppColors.expense]
                        : const <Color>[AppColors.brand, Color(0xFF6C4CF1)],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          fmtPercent(usage),
                          style: AppText.title.copyWith(
                            color: p.text,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          '已用',
                          style: AppText.caption.copyWith(color: p.sub),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        _KV(
                          label: '本月预算',
                          value: budget <= 0 ? '未设置' : '¥${fmtMoney(budget)}',
                          palette: p,
                        ),
                        const SizedBox(height: 12),
                        _KV(
                          label: '已支出',
                          value: '¥${fmtMoney(summary.expense)}',
                          palette: p,
                        ),
                        const SizedBox(height: 12),
                        _KV(
                          label: summary.overBudget ? '已超出' : '剩余可用',
                          value: '¥${fmtMoney(remaining.abs())}',
                          palette: p,
                          color: summary.overBudget
                              ? AppColors.expense
                              : AppColors.income,
                          bold: true,
                        ),
                        const SizedBox(height: 12),
                        _KV(
                          label: '日均可用',
                          value: '¥${fmtMoney(dailyAvailable)}',
                          palette: p,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (budget <= 0) ...<Widget>[
                const SizedBox(height: 16),
                _Banner(
                  icon: Icons.info_outline_rounded,
                  text: '还没有设置预算，先定一个数，清账帮你盯着。',
                  color: AppColors.brand,
                  palette: p,
                ),
              ] else if (summary.overBudget) ...<Widget>[
                const SizedBox(height: 16),
                _Banner(
                  icon: Icons.warning_amber_rounded,
                  text:
                      '本月已超支 ¥${fmtMoney(summary.expense - budget)}，建议先放缓非必要开销。',
                  color: AppColors.expense,
                  palette: p,
                ),
              ] else if (daysLeft > 0) ...<Widget>[
                const SizedBox(height: 16),
                _Banner(
                  icon: Icons.tips_and_updates_outlined,
                  text:
                      '还剩 $daysLeft 天，每天花不超过 ¥${fmtMoney(dailyAvailable)} 就能守住预算。',
                  color: AppColors.income,
                  palette: p,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '设置${fmtMonth(month)}预算',
                style: AppText.section.copyWith(color: p.text),
              ),
              const SizedBox(height: 4),
              Text(
                '快捷设置',
                style: AppText.caption.copyWith(color: p.sub),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickBudgets
                    .map(
                      (int v) => Pill(
                        label: '¥$v',
                        selected: budget.round() == v,
                        onTap: () => _applyQuick(v),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey<String>('budget_${monthKey(month)}'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                initialValue: budget > 0 ? budget.toStringAsFixed(0) : '',
                style: AppText.body.copyWith(color: p.text),
                decoration: const InputDecoration(
                  hintText: '自定义金额，例如 4500',
                  prefixIcon: Icon(Icons.edit_rounded, size: 18),
                ),
                onFieldSubmitted: _saveCustom,
                onChanged: (String v) => _draft = v,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _saveCustom(_draft),
                  child: const Text('保存预算'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '预算按月保存；没有单独设置的月份，会沿用最近一次的金额。',
                style: AppText.caption.copyWith(color: p.sub),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _draft = '';
}

class _KV extends StatelessWidget {
  const _KV({
    required this.label,
    required this.value,
    required this.palette,
    this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final AppPalette palette;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label, style: AppText.caption.copyWith(color: palette.sub)),
        const Spacer(),
        Text(
          value,
          style: AppText.amount.copyWith(
            color: color ?? palette.text,
            fontSize: bold ? 16 : 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    required this.palette,
  });

  final IconData icon;
  final String text;
  final Color color;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.small.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
