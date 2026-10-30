import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final AppPalette p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('分类管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: '新增分类',
            onPressed: () => _openEditor(context, null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: <Widget>[
          for (final EntryType type in EntryType.values) ...<Widget>[
            SectionHeader(
              title: type == EntryType.expense ? '支出分类' : '收入分类',
              subtitle: '点一下改名字、颜色或图标',
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: <Widget>[
                  for (final AppCategory c in store.categoriesOf(type))
                    InkWell(
                      onTap: () => _openEditor(context, c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        child: Row(
                          children: <Widget>[
                            CategoryAvatar(category: c, size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                c.name,
                                style: AppText.body.copyWith(color: p.text),
                              ),
                            ),
                            Text(
                              c.displayColor
                                  .toARGB32()
                                  .toRadixString(16)
                                  .substring(2)
                                  .toUpperCase(),
                              style: AppText.caption.copyWith(
                                color: p.sub,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: p.sub),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, AppCategory? existing) async {
    final AppStore store = context.read<AppStore>();
    final AppCategory? result = await showDialog<AppCategory>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _CategoryDialog(category: existing),
    );
    if (result == null) return;
    await store.saveCategory(result);
    if (!context.mounted) return;
    showAppSnack(context, '分类已保存', icon: Icons.check_circle_rounded);
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final AppCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameCtrl;
  late int _color;
  late String _icon;
  late EntryType _type;

  @override
  void initState() {
    super.initState();
    final AppCategory? c = widget.category;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _color = c?.color ?? AppColors.categorical.first.toARGB32();
    _icon = c?.icon ?? 'more';
    _type = c?.type ?? EntryType.expense;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool isNew = widget.category == null;

    return AlertDialog(
      title: Text(isNew ? '新增分类' : '编辑分类'),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nameCtrl,
                autofocus: isNew,
                style: AppText.body.copyWith(color: p.text),
                decoration: const InputDecoration(hintText: '分类名称'),
              ),
              const SizedBox(height: 14),
              Text('颜色', style: AppText.caption.copyWith(color: p.sub)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppColors.categorical.map((Color c) {
                  final bool selected =
                      c.toARGB32() == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c.toARGB32()),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? p.text : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('图标', style: AppText.caption.copyWith(color: p.sub)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCategoryIcons.entries.map(
                  (MapEntry<String, IconData> e) {
                    final bool selected = e.key == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = e.key),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(_color).withValues(alpha: 0.16)
                              : p.fill,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: selected
                                ? Color(_color)
                                : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        child: Icon(
                          e.value,
                          size: 18,
                          color: selected ? Color(_color) : p.sub,
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
              if (isNew) ...<Widget>[
                const SizedBox(height: 16),
                Text('归属', style: AppText.caption.copyWith(color: p.sub)),
                const SizedBox(height: 8),
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
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final String name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final AppCategory base = widget.category ??
                AppCategory(
                  id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  icon: _icon,
                  color: _color,
                  type: _type,
                  builtin: false,
                );
            Navigator.of(context).pop(
              base.copyWith(
                name: name,
                icon: _icon,
                color: _color,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
