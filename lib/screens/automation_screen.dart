import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../services/auto_entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'import_screen.dart';

/// 「免手动记账」总入口：一键链接、智能识别、账单导入，以及能力边界说明。
class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _pasteCtrl = TextEditingController();
  EntryType _type = EntryType.expense;
  AutoEntryIntent? _parsed;
  bool _parsedFromPaste = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _pasteCtrl.dispose();
    super.dispose();
  }

  String _buildLink() {
    final String amount = _amountCtrl.text.trim();
    final String note = _noteCtrl.text.trim();
    final List<String> parts = <String>['type=${_type.key}'];
    if (amount.isNotEmpty) parts.add('amount=$amount');
    if (note.isNotEmpty) parts.add('note=${Uri.encodeComponent(note)}');
    return 'qingzhang://add?${parts.join('&')}';
  }

  Future<void> _copy(String text, String tip) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppSnack(context, tip, icon: Icons.content_copy_rounded);
  }

  Future<void> _readClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data?.text == null || data!.text!.trim().isEmpty) {
      showAppSnack(context, '剪贴板里没有文字');
      return;
    }
    _pasteCtrl.text = data.text!;
    _parsePaste();
  }

  void _parsePaste() {
    final AutoEntryIntent? intent = ReceiptTextParser.parse(_pasteCtrl.text);
    setState(() {
      _parsed = intent;
      _parsedFromPaste = true;
    });
    if (intent == null) {
      showAppSnack(context, '没识别到金额，试试复制支付短信或账单那一行');
    }
  }

  Future<void> _commitParsed() async {
    final AutoEntryIntent? intent = _parsed;
    if (intent == null || intent.amount == null) return;
    final AppStore store = context.read<AppStore>();
    final MoneyEntry entry = intent.toEntry(store);
    await store.addEntry(entry);
    if (!mounted) return;
    showAppSnack(
      context,
      '已入账 ${store.categoryOf(entry.categoryId).name} ¥${fmtMoney(entry.amount)}',
      icon: Icons.check_circle_rounded,
    );
    setState(() {
      _parsed = null;
      _pasteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('自动记账'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF2F55E8), Color(0xFF6C4CF1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '付款、收款都能自动进账',
                      style: AppText.section
                          .copyWith(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '清账提供三条「不用手输」的路径：一键链接、复制即识别、账单批量导入。'
                  'iOS 不允许读取其他 App 的支付通知，所以完全零点击的方案需要用链接或账单实现。',
                  style: AppText.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '① 一键链接（推荐）', subtitle: '配一个快捷指令，点一下就记好'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '生成你的专属链接',
                  style: AppText.section.copyWith(color: p.text),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Pill(
                      label: '支出',
                      selected: _type == EntryType.expense,
                      accent: AppColors.expense,
                      onTap: () => setState(() => _type = EntryType.expense),
                    ),
                    const SizedBox(width: 8),
                    Pill(
                      label: '收入',
                      selected: _type == EntryType.income,
                      accent: AppColors.income,
                      onTap: () => setState(() => _type = EntryType.income),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(hintText: '金额（可留空）'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(hintText: '备注（可留空）'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    _buildLink(),
                    style: AppText.small.copyWith(
                      color: p.text,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _copy(_buildLink(), '链接已复制'),
                        icon: const Icon(Icons.link_rounded, size: 17),
                        label: const Text('复制链接'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _StepList(
                  steps: <String>[
                    '打开「快捷指令」App → 新建快捷指令 → 添加操作「打开 URL」',
                    '把上面复制的链接粘进去（金额留空时，会打开记账页让你补一个数）',
                    '命名成「随手记一笔」，在 设置 → 辅助功能 → 触控 → 轻点背面 里绑定它',
                    '想更省事：自动化里设置「打开支付宝/微信时」运行它',
                  ],
                  palette: p,
                ),
                const SizedBox(height: 6),
                Text(
                  '在 iOS 模拟器里可以直接验证：打开终端执行 '
                  'xcrun simctl openurl booted "qingzhang://add?amount=25&category=餐饮"',
                  style: AppText.caption.copyWith(color: p.sub, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '② 复制即识别', subtitle: '把支付短信 / 通知文本复制过来'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _pasteCtrl,
                  maxLines: 4,
                  minLines: 3,
                  style: AppText.body.copyWith(color: p.text),
                  decoration: const InputDecoration(
                    hintText: '例：【招商银行】您账户30日14:20支出人民币36.50元，余额1,024.00',
                  ),
                  onChanged: (_) {
                    if (_parsed != null) setState(() => _parsed = null);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _readClipboard,
                        icon: const Icon(Icons.content_paste_rounded,
                            size: 16),
                        label: const Text('粘贴并识别'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _parsePaste,
                        icon: const Icon(Icons.auto_fix_high_rounded,
                            size: 16),
                        label: const Text('识别这段文字'),
                      ),
                    ),
                  ],
                ),
                if (_parsedFromPaste && _parsed != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _ParsedPreview(
                    intent: _parsed!,
                    store: context.read<AppStore>(),
                    palette: p,
                    onConfirm: _commitParsed,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '③ 账单批量导入', subtitle: '支付宝 / 微信 / 银行 的 CSV'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '一个月导一次，几十笔流水一次入账，最接近「零手动」的稳定方案。',
                  style: AppText.small.copyWith(color: p.sub, height: 1.6),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ImportScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 17),
                    label: const Text('去导入账单'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '为什么不能像安卓那样全自动？', subtitle: '能力边界'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Note(
                  icon: Icons.block_rounded,
                  color: AppColors.warn,
                  title: 'iOS 不允许读取支付通知',
                  body:
                      '微信、支付宝、银行的支付通知属于其他 App 的数据，'
                      '系统没有开放给第三方读取的接口；短信也只有在「信息过滤扩展」里才能看到内容。',
                  palette: p,
                ),
                const SizedBox(height: 12),
                _Note(
                  icon: Icons.android_rounded,
                  color: AppColors.income,
                  title: '安卓可以做到真正的自动',
                  body:
                      '通过 NotificationListenerService 监听微信/支付宝的收款、付款通知，'
                      '自动解析金额直接入账。需要加一段原生代码，属于后续可以扩展的方向。',
                  palette: p,
                ),
                const SizedBox(height: 12),
                _Note(
                  icon: Icons.screenshot_rounded,
                  color: AppColors.brand,
                  title: '进阶：截图识别',
                  body:
                      'iOS 可用 Vision 框架在本地识别截图里的金额与商户，'
                      '配合「分享到清账」就能做到「截个图就记好」。',
                  palette: p,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedPreview extends StatelessWidget {
  const _ParsedPreview({
    required this.intent,
    required this.store,
    required this.palette,
    required this.onConfirm,
  });

  final AutoEntryIntent intent;
  final AppStore store;
  final AppPalette palette;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final AppCategory? category =
        store.findCategoryByName(intent.categoryName, intent.type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.brand),
              const SizedBox(width: 6),
              Text('识别结果',
                  style: AppText.small.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  )),
              const Spacer(),
              Text(
                intent.type.label,
                style: AppText.caption.copyWith(
                  color: intent.type == EntryType.expense
                      ? AppColors.expense
                      : AppColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '¥${fmtMoney(intent.amount ?? 0)}',
                style: AppText.title.copyWith(color: palette.text),
              ),
              const SizedBox(width: 10),
              Text(
                category?.name ?? '未分类',
                style: AppText.caption.copyWith(color: palette.sub),
              ),
              const Spacer(),
              Text(
                intent.time == null
                    ? '今天'
                    : fmtDateTime(intent.time!),
                style: AppText.caption.copyWith(color: palette.sub),
              ),
            ],
          ),
          if (intent.note.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              intent.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.small.copyWith(color: palette.sub),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onConfirm,
              child: const Text('确认入账'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps, required this.palette});

  final List<String> steps;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: AppText.caption.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    steps[i],
                    style: AppText.small.copyWith(
                      color: palette.sub,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.palette,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: AppText.small.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: AppText.caption.copyWith(
                  color: palette.sub,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
