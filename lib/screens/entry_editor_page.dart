import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../services/auto_entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

/// 记一笔：金额键盘 + 分类 + 备注 + 时间，一屏完成。
class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({super.key, this.draft, this.editing});

  /// 外部入口（URL Scheme / 智能识别）带来的预填内容
  final AutoEntryIntent? draft;

  /// 正在编辑已有账目
  final MoneyEntry? editing;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final TextEditingController _noteCtrl = TextEditingController();
  final FocusNode _noteFocus = FocusNode();

  late EntryType _type;
  String? _categoryId;
  late DateTime _time;
  String _amountText = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final AppStore store = context.read<AppStore>();
    final MoneyEntry? editing = widget.editing;
    final AutoEntryIntent? draft = widget.draft;

    if (editing != null) {
      _type = editing.type;
      _categoryId = editing.categoryId;
      _time = editing.time;
      _noteCtrl.text = editing.note;
      _amountText = _formatAmountText(editing.amount);
    } else if (draft != null) {
      _type = draft.type;
      _categoryId = store.findCategoryByName(draft.categoryName, _type)?.id;
      _time = draft.time ?? DateTime.now();
      _noteCtrl.text = draft.note;
      if (draft.amount != null) {
        _amountText = _formatAmountText(draft.amount!);
      }
    } else {
      _type = EntryType.expense;
      _time = DateTime.now();
    }

    _categoryId ??= _defaultCategoryId(store, _type);

    _noteFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// 优先用上次用过的分类，减少一次点击
  String? _defaultCategoryId(AppStore store, EntryType type) {
    final List<AppCategory> list = store.categoriesOf(type);
    if (list.isEmpty) return null;
    final String? remembered = store.lastCategoryOf(type);
    if (remembered != null &&
        list.any((AppCategory c) => c.id == remembered)) {
      return remembered;
    }
    return list.first.id;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  String _formatAmountText(double v) {
    final String s = v.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    if (s.endsWith('0')) return s.substring(0, s.length - 1);
    return s;
  }

  void _switchType(EntryType type) {
    if (type == _type) return;
    final AppStore store = context.read<AppStore>();
    setState(() {
      _type = type;
      _categoryId = _defaultCategoryId(store, type);
    });
  }

  void _onKey(String key) {
    setState(() {
      if (key == 'clear') {
        _amountText = '';
        return;
      }
      if (key == 'del') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
        return;
      }
      if (key == '.') {
        if (!_amountText.contains('.')) {
          _amountText = _amountText.isEmpty ? '0.' : '$_amountText.';
        }
        return;
      }
      if (key == '00') {
        if (_amountText.isEmpty) {
          _amountText = '0';
        } else if (!_amountText.contains('.')) {
          final String digits = _amountText.replaceAll('.', '');
          if (digits.length < 8) {
            _amountText = _amountText == '0' ? '0' : '${_amountText}00';
          }
        }
        return;
      }
      // 数字
      if (_amountText == '0') {
        _amountText = key;
        return;
      }
      if (_amountText.contains('.')) {
        final List<String> parts = _amountText.split('.');
        if (parts.length > 1 && parts[1].length >= 2) return;
      }
      if (_amountText.replaceAll('.', '').length >= 8) return;
      _amountText = '$_amountText$key';
    });
  }

  void _applyQuickNote(String label) {
    final AppStore store = context.read<AppStore>();
    const Map<String, String> map = <String, String>{
      '早餐': 'food',
      '午餐': 'food',
      '晚餐': 'food',
      '打车': 'transport',
      '买菜': 'shopping',
      '咖啡': 'food',
    };
    setState(() {
      _noteCtrl.text = label;
      final String? id = map[label];
      if (id != null && _type == EntryType.expense) {
        final bool exists = store
            .categoriesOf(EntryType.expense)
            .any((AppCategory c) => c.id == id);
        if (exists) _categoryId = id;
      }
    });
  }

  Future<void> _pickTime() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: '选择日期',
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
      helpText: '选择时间',
    );
    if (!mounted) return;
    setState(() {
      _time = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _time.hour,
        time?.minute ?? _time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final AppStore store = context.read<AppStore>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    final double? amount = double.tryParse(_amountText);
    if (amount == null || amount <= 0) {
      showAppSnack(context, '先输入金额吧');
      return;
    }
    if (_categoryId == null) {
      showAppSnack(context, '选一个分类再保存');
      return;
    }
    setState(() => _saving = true);

    final String note = _noteCtrl.text.trim();
    if (widget.editing != null) {
      await store.updateEntry(
        widget.editing!.copyWith(
          type: _type,
          categoryId: _categoryId,
          amount: double.parse(amount.toStringAsFixed(2)),
          time: _time,
          note: note,
        ),
      );
    } else {
      await store.addEntry(
        MoneyEntry(
          id: 'e_${DateTime.now().microsecondsSinceEpoch}',
          type: _type,
          categoryId: _categoryId!,
          amount: double.parse(amount.toStringAsFixed(2)),
          time: _time,
          note: note,
          source: widget.draft?.source ?? EntrySource.manual,
        ),
      );
    }

    if (!mounted) return;
    await store.rememberCategory(_type, _categoryId!);
    if (!mounted) return;
    navigator.pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2000),
        content: Row(
          children: <Widget>[
            const Icon(Icons.check_circle_rounded,
                size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              widget.editing != null
                  ? '已更新这笔账'
                  : '已记一笔 ${_type.label} ¥${fmtMoney(amount)}',
              style: AppText.body.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final AppStore store = context.watch<AppStore>();
    final List<AppCategory> categories = store.categoriesOf(_type);
    final Color accent =
        _type == EntryType.expense ? AppColors.expense : AppColors.income;
    final bool showKeypad = !_noteFocus.hasFocus;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '关闭',
        ),
        title: Text(widget.editing != null ? '编辑账目' : '记一笔'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: Text(
                '保存',
                style: AppText.section.copyWith(
                  color: AppColors.brand,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                children: <Widget>[
                  _TypeToggle(
                    type: _type,
                    onChanged: _switchType,
                    palette: p,
                  ),
                  const SizedBox(height: 18),
                  _AmountDisplay(
                    text: _amountText,
                    accent: accent,
                    palette: p,
                    type: _type,
                  ),
                  const SizedBox(height: 6),
                  Divider(color: p.line),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Text('分类',
                          style: AppText.small.copyWith(
                            color: p.sub,
                            fontWeight: FontWeight.w600,
                          )),
                      const Spacer(),
                      Text(
                        '${categories.length} 个可选',
                        style: AppText.caption.copyWith(color: p.sub),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CategoryGrid(
                    categories: categories,
                    selectedId: _categoryId,
                    onSelect: (String id) =>
                        setState(() => _categoryId = id),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteCtrl,
                    focusNode: _noteFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _noteFocus.unfocus(),
                    style: AppText.body.copyWith(color: p.text),
                    decoration: const InputDecoration(
                      hintText: '备注一下（可选）',
                      prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: kQuickNotes
                          .map(
                            (String label) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Pill(
                                label: label,
                                dense: true,
                                onTap: () => _applyQuickNote(label),
                                icon: Icons.bolt_rounded,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TimeRow(time: _time, onTap: _pickTime, palette: p),
                ],
              ),
            ),
            if (showKeypad)
              _Keypad(
                onKey: _onKey,
                onDone: _save,
                palette: p,
                accent: accent,
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.type,
    required this.onChanged,
    required this.palette,
  });

  final EntryType type;
  final ValueChanged<EntryType> onChanged;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          _tab(EntryType.expense, '支出', AppColors.expense),
          _tab(EntryType.income, '收入', AppColors.income),
        ],
      ),
    );
  }

  Widget _tab(EntryType value, String label, Color color) {
    final bool selected = type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? palette.card : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.small.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? color : palette.sub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.text,
    required this.accent,
    required this.palette,
    required this.type,
  });

  final String text;
  final Color accent;
  final AppPalette palette;
  final EntryType type;

  @override
  Widget build(BuildContext context) {
    final bool empty = text.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            '¥',
            style: AppText.title.copyWith(
              color: empty ? palette.sub : accent,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                empty ? '0.00' : text,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: -0.8,
                  color: empty ? palette.sub.withValues(alpha: 0.55) : accent,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ),
          Text(
            type.label,
            style: AppText.caption.copyWith(color: palette.sub),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<AppCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 6,
      childAspectRatio: 0.86,
      padding: EdgeInsets.zero,
      children: categories.map((AppCategory c) {
        final bool selected = c.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(c.id),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.displayColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CategoryAvatar(
                  category: c,
                  size: 42,
                  filled: selected,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: selected ? p.text : p.sub,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.time,
    required this.onTap,
    required this.palette,
  });

  final DateTime time;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: palette.fill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.schedule_rounded, size: 18, color: palette.sub),
            const SizedBox(width: 8),
            Text(
              '${fmtDayLabel(time)} ${fmtHM(time)}',
              style: AppText.body.copyWith(color: palette.text),
            ),
            const Spacer(),
            Text(
              '修改时间',
              style: AppText.caption.copyWith(color: palette.sub),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: palette.sub),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onKey,
    required this.onDone,
    required this.palette,
    required this.accent,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onDone;
  final AppPalette palette;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _row(<String>['1', '2', '3']),
          _row(<String>['4', '5', '6']),
          _row(<String>['7', '8', '9']),
          _row(<String>['.', '0', 'del']),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                minimumSize: const Size(0, 46),
              ),
              child: const Text('完成 · 记这一笔'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Row(
      children: keys
          .map((String key) => Expanded(child: _key(key)))
          .toList(),
    );
  }

  Widget _key(String key) {
    final bool isDel = key == 'del';
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: _keyBody(key, isDel),
      ),
    );
  }

  Widget _keyBody(String key, bool isDel) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onKey(key),
        onLongPress: isDel
            ? () => onKey('clear')
            : (key == '0' ? () => onKey('00') : null),
        child: Center(
          child: isDel
              ? Icon(Icons.backspace_outlined,
                  size: 21, color: palette.sub)
              : Text(
                  key,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: palette.text,
                  ),
                ),
        ),
      ),
    );
  }
}
