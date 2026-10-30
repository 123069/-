import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../screens/entry_editor_page.dart';
import 'common.dart';

/// 点击一条账目弹出的详情面板：查看 / 编辑 / 删除（可撤销）
Future<void> showEntrySheet(BuildContext context, MoneyEntry entry) async {
  final AppStore store = context.read<AppStore>();
  final NavigatorState navigator = Navigator.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final AppPalette p = sheetContext.palette;
      final AppCategory category = store.categoryOf(entry.categoryId);
      final Color amountColor =
          entry.isExpense ? AppColors.expense : AppColors.income;

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
              children: <Widget>[
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    CategoryAvatar(category: category, size: 50),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            entry.note.isEmpty ? category.name : entry.note,
                            style: AppText.section.copyWith(
                              color: p.text,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category.name} · ${fmtDateTime(entry.time)} · ${entry.source}',
                            style: AppText.caption.copyWith(color: p.sub),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '${entry.isExpense ? '-' : '+'}¥${fmtMoney(entry.amount)}',
                          style: AppText.amount.copyWith(
                            color: amountColor,
                            fontSize: 19,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.type.label,
                          style: AppText.caption.copyWith(color: p.sub),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: p.line),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          navigator.push(
                            MaterialPageRoute<void>(
                              builder: (_) => EntryEditorPage(editing: entry),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded, size: 17),
                        label: const Text('编辑'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await store.deleteEntry(entry.id);
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '已删除这笔账',
                                style:
                                    AppText.body.copyWith(color: Colors.white),
                              ),
                              action: SnackBarAction(
                                label: '撤销',
                                textColor: const Color(0xFF8FB0FF),
                                onPressed: () => store.addEntry(entry),
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.expense,
                          side: BorderSide(
                            color: AppColors.expense.withValues(alpha: 0.35),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 17),
                        label: const Text('删除'),
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
}
