import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../services/auto_entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';

/// 从剪贴板（或分享）识别到一笔账时弹出的确认条。
/// 确认后调用方负责入账，这里只返回用户的选择。
Future<bool> showQuickCapture(
  BuildContext context,
  AutoEntryIntent intent, {
  String from = '剪贴板',
}) async {
  final AppStore store = context.read<AppStore>();
  final AppCategory? category =
      store.findCategoryByName(intent.categoryName, intent.type);
  final Color accent = intent.type == EntryType.expense
      ? AppColors.expense
      : AppColors.income;

  final bool? confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final AppPalette p = sheetContext.palette;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Icon(Icons.bolt_rounded, size: 18, color: AppColors.brand),
                    const SizedBox(width: 6),
                    Text(
                      '识别到一笔${intent.type.label}',
                      style: AppText.section.copyWith(
                        color: p.text,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '来自$from',
                      style: AppText.caption.copyWith(color: p.sub),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    if (category != null)
                      CategoryAvatar(category: category, size: 44)
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: p.fill,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.help_outline_rounded,
                            size: 20, color: p.sub),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            intent.note.isEmpty
                                ? (category?.name ?? '未分类')
                                : intent.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              color: p.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${category?.name ?? '未分类'} · '
                            '${intent.time == null ? '今天' : fmtDateTime(intent.time!)}',
                            style: AppText.caption.copyWith(color: p.sub),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${intent.type == EntryType.expense ? '-' : '+'}¥${fmtMoney(intent.amount ?? 0)}',
                      style: AppText.amount.copyWith(
                        color: accent,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('忽略'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('确认入账'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}
