import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../services/bill_import.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

/// 账单导入：粘贴支付宝 / 微信 / 银行导出的 CSV，批量入账并自动去重。
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _ctrl = TextEditingController();
  ImportResult? _result;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _parse() {
    if (_ctrl.text.trim().isEmpty) {
      showAppSnack(context, '先粘贴账单内容');
      return;
    }
    final ImportResult result = BillImporter.parse(_ctrl.text);
    setState(() => _result = result);
    if (result.error != null) {
      showAppSnack(context, result.error!);
    }
  }

  void _fillDemo() {
    setState(() {
      _ctrl.text = _demoBillText();
      _result = null;
    });
  }

  Future<void> _import() async {
    final ImportResult? result = _result;
    if (result == null) return;
    final AppStore store = context.read<AppStore>();
    final List<ImportRow> rows =
        result.rows.where((ImportRow r) => r.selected).toList();
    if (rows.isEmpty) {
      showAppSnack(context, '没有勾选任何记录');
      return;
    }

    setState(() => _busy = true);
    final List<MoneyEntry> existing = store.entries;
    int added = 0;
    int duplicated = 0;

    for (final ImportRow row in rows) {
      final bool isDuplicate = existing.any(
        (MoneyEntry e) =>
            e.type == row.type &&
            (e.amount - row.amount).abs() < 0.001 &&
            e.time.difference(row.time).inMinutes.abs() <= 2,
      );
      if (isDuplicate) {
        duplicated++;
        continue;
      }
      final AppCategory? matched =
          store.findCategoryByName(row.categoryName, row.type);
      final List<AppCategory> pool = store.categoriesOf(row.type);
      final AppCategory category = matched ??
          (pool.isNotEmpty ? pool.first : store.unknownCategory);

      await store.addEntry(
        MoneyEntry(
          id: 'imp_${DateTime.now().microsecondsSinceEpoch}_$added',
          type: row.type,
          categoryId: category.id,
          amount: row.amount,
          time: row.time,
          note: row.note,
          source: EntrySource.import,
        ),
      );
      added++;
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = null;
      _ctrl.clear();
    });
    showAppSnack(
      context,
      duplicated > 0 ? '导入 $added 笔，跳过 $duplicated 笔重复' : '已导入 $added 笔账单',
      icon: Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final ImportResult? result = _result;
    final int selectedCount =
        result?.rows.where((ImportRow r) => r.selected).length ?? 0;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('账单导入'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('怎么拿到账单？',
                    style: AppText.section.copyWith(color: p.text)),
                const SizedBox(height: 10),
                _Hint(
                  title: '支付宝',
                  body: '我的 → 账单 → 右上角「…」→ 开具交易流水证明 → 选时间范围 → 发送到邮箱，得到 CSV。',
                  palette: p,
                ),
                const SizedBox(height: 10),
                _Hint(
                  title: '微信支付',
                  body: '我 → 服务 → 钱包 → 账单 → 常见问题 → 下载账单 → 选「用于个人对账」，解压后就是 CSV。',
                  palette: p,
                ),
                const SizedBox(height: 10),
                _Hint(
                  title: '银行',
                  body: '手机银行里搜索「交易明细」或「流水」，一般都能导出 CSV / Excel。',
                  palette: p,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('粘贴账单内容',
                    style: AppText.section.copyWith(color: p.text)),
                const SizedBox(height: 4),
                Text(
                  '表头需要同时有「时间」和「金额」两列，支付宝的 GBK 编码也能识别。',
                  style: AppText.caption.copyWith(color: p.sub),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ctrl,
                  minLines: 6,
                  maxLines: 12,
                  style: AppText.small.copyWith(
                    color: p.text,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: '交易时间,交易分类,交易对方,商品说明,收/支,金额\n2026-03-01 08:12,餐饮美食,星巴克,拿铁,支出,32.00',
                  ),
                  onChanged: (_) {
                    if (_result != null) setState(() => _result = null);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton(
                        onPressed: _parse,
                        child: const Text('解析账单'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _fillDemo,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('填示例'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (result != null) ...<Widget>[
            const SizedBox(height: 14),
            if (result.error != null)
              AppCard(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: '解析失败',
                  subtitle: result.error,
                ),
              )
            else
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text('解析出 ${result.rows.length} 笔',
                            style: AppText.section.copyWith(color: p.text)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            final bool all = result.rows
                                .every((ImportRow r) => r.selected);
                            for (final ImportRow r in result.rows) {
                              r.selected = !all;
                            }
                          }),
                          child: const Text('全选 / 全不选'),
                        ),
                      ],
                    ),
                    if (result.warnings.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          result.warnings.join('；'),
                          style: AppText.caption.copyWith(color: p.sub),
                        ),
                      ),
                    ...result.rows.asMap().entries.map(
                          (MapEntry<int, ImportRow> e) => _RowTile(
                            row: e.value,
                            onToggle: () => setState(
                              () => e.value.selected = !e.value.selected,
                            ),
                          ),
                        ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy || selectedCount == 0 ? null : _import,
                        child: Text(
                          _busy ? '正在导入…' : '导入选中的 $selectedCount 笔',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _demoBillText() {
    final DateTime now = DateTime.now();
    String day(int ago) {
      final DateTime d = now.subtract(Duration(days: ago));
      final String mm = d.month.toString().padLeft(2, '0');
      final String dd = d.day.toString().padLeft(2, '0');
      return '${d.year}-$mm-$dd';
    }

    return '交易时间,交易分类,交易对方,商品说明,收/支,金额,收/付款方式,交易状态\n'
        '${day(0)} 08:12:33,餐饮美食,瑞幸咖啡,生椰拿铁,支出,19.00,余额宝,交易成功\n'
        '${day(0)} 12:30:10,餐饮美食,美团外卖,黄焖鸡米饭,支出,34.00,花呗,交易成功\n'
        '${day(1)} 19:05:44,交通出行,滴滴出行,快车-3.2公里,支出,28.50,余额宝,交易成功\n'
        '${day(1)} 21:10:02,日用百货,全家便利店,零食饮料,支出,15.60,花呗,交易成功\n'
        '${day(2)} 09:30:00,转账红包,老同学,周末AA,收入,200.00,零钱,交易成功\n'
        '${day(3)} 13:22:10,餐饮美食,海底捞,朋友聚餐,支出,186.00,招商银行储蓄卡,交易成功';
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.title,
    required this.body,
    required this.palette,
  });

  final String title;
  final String body;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppText.small.copyWith(
            color: palette.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: AppText.caption.copyWith(color: palette.sub, height: 1.6),
        ),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row, required this.onToggle});

  final ImportRow row;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: <Widget>[
            Icon(
              row.selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: row.selected ? AppColors.brand : p.sub,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.note.isEmpty ? '未命名' : row.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small.copyWith(color: p.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fmtDateTime(row.time)} · ${row.categoryName ?? '未分类'}',
                    style: AppText.caption.copyWith(color: p.sub),
                  ),
                ],
              ),
            ),
            Text(
              '${row.type == EntryType.expense ? '-' : '+'}¥${fmtMoney(row.amount)}',
              style: AppText.small.copyWith(
                color: row.type == EntryType.expense
                    ? p.text
                    : AppColors.income,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
