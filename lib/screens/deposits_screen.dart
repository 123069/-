import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/deposit.dart';
import '../services/auto_entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

/// 存款 / 理财：本金 + 年化利率，自动算每日、每月、累计和到期利息。
class DepositsScreen extends StatelessWidget {
  const DepositsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final AppPalette p = context.palette;
    final DepositSummary summary = store.depositSummary;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('存款与利息'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '添加存款',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openEditor(context, null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: <Widget>[
          _SummaryCard(summary: summary, palette: p),
          const SizedBox(height: 18),
          SectionHeader(
            title: '我的存款',
            subtitle: summary.isEmpty ? '还没有添加' : '共 ${summary.count} 笔，点一下可修改',
          ),
          if (summary.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.savings_outlined,
                title: '添加第一笔存款',
                subtitle: '填入本金和年化利率，清账会按天帮你算利息',
              ),
            )
          else
            ...store.deposits.map(
              (Deposit d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DepositTile(
                  deposit: d,
                  palette: p,
                  onTap: () => _openEditor(context, d),
                ),
              ),
            ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 16, color: AppColors.warn),
                    const SizedBox(width: 6),
                    Text('关于「自动监控利率」',
                        style: AppText.small.copyWith(
                          color: p.text,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'iOS 不允许读取其他 App 的数据，所以没法实时盯着银行/余额宝的利率。'
                  '折中做法：把利率变动的那句话复制下来（例如「余额宝七日年化 1.85%」），'
                  '在编辑存款时点「从剪贴板读取」，比手输省事。'
                  '安卓版本可以通过通知监听做到自动获取。',
                  style: AppText.caption.copyWith(color: p.sub, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, Deposit? existing) async {
    final AppStore store = context.read<AppStore>();
    final Deposit? result = await showDialog<Deposit>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _DepositDialog(deposit: existing),
    );
    if (result == null) return;
    await store.saveDeposit(result);
    if (!context.mounted) return;
    showAppSnack(context, '已保存', icon: Icons.check_circle_rounded);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.palette});

  final DepositSummary summary;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.savings_rounded,
                    size: 18, color: AppColors.income),
              ),
              const SizedBox(width: 10),
              Text('本金合计',
                  style: AppText.caption.copyWith(color: palette.sub)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '综合年化 ${summary.weightedRate.toStringAsFixed(2)}%',
                  style: AppText.caption.copyWith(
                    color: AppColors.income,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '¥${fmtMoney(summary.principal)}',
            style: AppText.heroAmount.copyWith(
              color: palette.text,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: palette.line),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _Stat(label: '年利息', value: '¥${fmtCompact(summary.annualInterest)}'),
              _Stat(label: '本月利息', value: '¥${fmtCompact(summary.monthlyInterest)}'),
              _Stat(label: '累计利息', value: '¥${fmtCompact(summary.accruedInterest)}'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: palette.fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.trending_up_rounded,
                    size: 16, color: AppColors.income),
                const SizedBox(width: 8),
                Text(
                  '今天又赚了 ¥${fmtMoney(summary.todayInterest)}',
                  style: AppText.small.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '按 365 天单利估算',
                  style: AppText.caption.copyWith(color: palette.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppText.caption.copyWith(color: p.sub)),
          const SizedBox(height: 3),
          Text(value, style: AppText.amount.copyWith(color: p.text)),
        ],
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  const _DepositTile({
    required this.deposit,
    required this.palette,
    required this.onTap,
  });

  final Deposit deposit;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DateTime? end = deposit.maturityDate;
    final int? totalDays = end?.difference(deposit.startDate).inDays;
    final double progress = (totalDays == null || totalDays <= 0)
        ? 0
        : (deposit.daysElapsed() / totalDays).clamp(0.0, 1.0);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    size: 18, color: AppColors.income),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      deposit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      end == null
                          ? '${fmtDate(deposit.startDate)} 起 · 活期'
                          : '${fmtDate(deposit.startDate)} → ${fmtDate(end)}',
                      style: AppText.caption.copyWith(color: palette.sub),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '¥${fmtMoney(deposit.principal)}',
                    style: AppText.amount.copyWith(color: palette.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${deposit.annualRate.toStringAsFixed(2)}%',
                    style: AppText.caption.copyWith(
                      color: AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                '日息 ¥${deposit.dailyInterest.toStringAsFixed(2)}',
                style: AppText.caption.copyWith(color: palette.sub),
              ),
              const SizedBox(width: 12),
              Text(
                '累计 ¥${fmtCompact(deposit.accruedInterest())}',
                style: AppText.caption.copyWith(color: palette.sub),
              ),
              const Spacer(),
              if (deposit.matured)
                Text(
                  '已到期',
                  style: AppText.caption.copyWith(color: AppColors.warn),
                )
              else if (deposit.daysToMaturity != null)
                Text(
                  '还有 ${deposit.daysToMaturity} 天',
                  style: AppText.caption.copyWith(color: palette.sub),
                ),
            ],
          ),
          if (totalDays != null && totalDays > 0) ...<Widget>[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: palette.fill,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.income,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DepositDialog extends StatefulWidget {
  const _DepositDialog({this.deposit});

  final Deposit? deposit;

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _principalCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _startDate;
  DateTime? _maturityDate;

  @override
  void initState() {
    super.initState();
    final Deposit? d = widget.deposit;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _principalCtrl = TextEditingController(
      text: d == null ? '' : d.principal.toStringAsFixed(0),
    );
    _rateCtrl = TextEditingController(
      text: d == null ? '' : d.annualRate.toStringAsFixed(2),
    );
    _noteCtrl = TextEditingController(text: d?.note ?? '');
    _startDate = d?.startDate ?? DateTime.now();
    _maturityDate = d?.maturityDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool maturity}) async {
    final DateTime now = DateTime.now();
    final DateTime initial = maturity
        ? (_maturityDate ?? _startDate.add(const Duration(days: 365)))
        : _startDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 50),
      helpText: maturity ? '选择到期日' : '选择起存日',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (maturity) {
        _maturityDate = picked;
      } else {
        _startDate = picked;
      }
    });
  }

  Future<void> _readRateFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final double? rate = ReceiptTextParser.extractRate(data?.text ?? '');
    if (rate == null) {
      showAppSnack(context, '剪贴板里没找到「1.85%」这样的利率');
      return;
    }
    setState(() => _rateCtrl.text = rate.toStringAsFixed(2));
    showAppSnack(context, '已读取年化 $rate%');
  }

  void _save() {
    final String name = _nameCtrl.text.trim();
    final double? principal = double.tryParse(_principalCtrl.text.trim());
    final double? rate = double.tryParse(_rateCtrl.text.trim());
    if (name.isEmpty) {
      showAppSnack(context, '给这笔存款起个名字');
      return;
    }
    if (principal == null || principal <= 0) {
      showAppSnack(context, '本金要大于 0');
      return;
    }
    if (rate == null || rate <= 0 || rate > 30) {
      showAppSnack(context, '年化利率填 0.01 – 30 之间');
      return;
    }

    final Deposit base = widget.deposit ??
        Deposit(
          id: 'dep_${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          principal: principal,
          annualRate: rate,
          startDate: _startDate,
        );

    List<RatePoint> history = base.history;
    if (base.annualRate != rate) {
      history = <RatePoint>[
        ...history,
        RatePoint(date: DateTime.now(), rate: rate),
      ];
    }

    Navigator.of(context).pop(
      base.copyWith(
        name: name,
        principal: principal,
        annualRate: rate,
        startDate: _startDate,
        maturityDate: _maturityDate,
        clearMaturity: _maturityDate == null,
        note: _noteCtrl.text.trim(),
        history: history,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool isNew = widget.deposit == null;

    return AlertDialog(
      title: Text(isNew ? '添加存款' : '修改存款'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _nameCtrl,
                autofocus: isNew,
                style: AppText.body.copyWith(color: p.text),
                decoration: const InputDecoration(
                  hintText: '名称，例如 招商银行 3 年定期',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _principalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppText.body.copyWith(color: p.text),
                decoration: const InputDecoration(hintText: '本金（元）'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppText.body.copyWith(color: p.text),
                decoration: InputDecoration(
                  hintText: '年化利率 %，例如 3.15',
                  suffixIcon: IconButton(
                    tooltip: '从剪贴板读取利率',
                    onPressed: _readRateFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DateRow(
                label: '起存日',
                value: fmtDate(_startDate),
                onTap: () => _pickDate(maturity: false),
                palette: p,
              ),
              const SizedBox(height: 8),
              _DateRow(
                label: '到期日',
                value: _maturityDate == null
                    ? '不设（活期）'
                    : fmtDate(_maturityDate!),
                onTap: () => _pickDate(maturity: true),
                palette: p,
                onClear: _maturityDate == null
                    ? null
                    : () => setState(() => _maturityDate = null),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteCtrl,
                style: AppText.body.copyWith(color: p.text),
                decoration: const InputDecoration(hintText: '备注（可选）'),
              ),
              if (!isNew && widget.deposit!.history.length > 1) ...<Widget>[
                const SizedBox(height: 14),
                Text('利率变更记录',
                    style: AppText.caption.copyWith(color: p.sub)),
                const SizedBox(height: 6),
                ...widget.deposit!.history.reversed.take(4).map(
                      (RatePoint point) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '${fmtDate(point.date)} · ${point.rate.toStringAsFixed(2)}%',
                          style: AppText.caption.copyWith(color: p.sub),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (!isNew)
          TextButton(
            onPressed: () async {
              final NavigatorState navigator = Navigator.of(context);
              final AppStore store = context.read<AppStore>();
              final Deposit removed = widget.deposit!;
              navigator.pop();
              await store.deleteDeposit(removed.id);
              if (!context.mounted) return;
              showAppSnack(context, '已删除「${removed.name}」',
                  icon: Icons.delete_outline_rounded);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('删除'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.palette,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final AppPalette palette;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: palette.fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Text(label,
                style: AppText.caption.copyWith(color: palette.sub)),
            const SizedBox(width: 10),
            Text(value, style: AppText.small.copyWith(color: palette.text)),
            const Spacer(),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 16, color: palette.sub),
              )
            else
              Icon(Icons.calendar_today_rounded,
                  size: 15, color: palette.sub),
          ],
        ),
      ),
    );
  }
}
