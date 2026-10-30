import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'automation_screen.dart';
import 'categories_screen.dart';
import 'deposits_screen.dart';
import 'import_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    final AppPalette p = context.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: <Widget>[
        Text('设置', style: AppText.title.copyWith(color: p.text)),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('外观', style: AppText.section.copyWith(color: p.text)),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _ThemePill(
                    label: '跟随系统',
                    icon: Icons.brightness_auto_rounded,
                    selected: store.themeMode == ThemeMode.system,
                    onTap: () => store.setThemeMode(ThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  _ThemePill(
                    label: '浅色',
                    icon: Icons.light_mode_rounded,
                    selected: store.themeMode == ThemeMode.light,
                    onTap: () => store.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemePill(
                    label: '深色',
                    icon: Icons.dark_mode_rounded,
                    selected: store.themeMode == ThemeMode.dark,
                    onTap: () => store.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: <Widget>[
              _SwitchTile(
                icon: Icons.content_paste_search_rounded,
                iconColor: AppColors.income,
                title: '智能剪贴板',
                subtitle: '回到 App 时自动识别刚复制的支付短信/通知',
                value: store.clipboardAuto,
                onChanged: store.setClipboardAuto,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: <Widget>[
              _Tile(
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF12A26B),
                title: '存款与利息',
                subtitle: '本金 + 年化利率，按天算收益',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DepositsScreen(),
                  ),
                ),
              ),
              Divider(height: 1, color: p.line),
              _Tile(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.brand,
                title: '自动记账（免手动）',
                subtitle: '快捷指令 / 链接 / 智能识别 / 账单导入',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AutomationScreen(),
                  ),
                ),
              ),
              Divider(height: 1, color: p.line),
              _Tile(
                icon: Icons.upload_file_rounded,
                iconColor: AppColors.income,
                title: '账单导入',
                subtitle: '支付宝 / 微信 / 银行 CSV 一次导入',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ImportScreen(),
                  ),
                ),
              ),
              Divider(height: 1, color: p.line),
              _Tile(
                icon: Icons.sell_rounded,
                iconColor: const Color(0xFFFF9F0A),
                title: '分类管理',
                subtitle: '改名字、换颜色和图标',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoriesScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: <Widget>[
              _Tile(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF6C4CF1),
                title: '恢复示例数据',
                subtitle: '重置为三个月的演示账目',
                onTap: () => _confirm(
                  context,
                  title: '恢复示例数据？',
                  message: '当前账目会被示例数据替换，分类和预算设置也会恢复默认。',
                  confirmText: '恢复',
                  onConfirm: () async {
                    await store.resetSampleData();
                    if (!context.mounted) return;
                    showAppSnack(context, '已恢复示例数据',
                        icon: Icons.check_circle_rounded);
                  },
                ),
              ),
              Divider(height: 1, color: p.line),
              _Tile(
                icon: Icons.content_copy_rounded,
                iconColor: const Color(0xFF4C8DFF),
                title: '导出数据',
                subtitle: '以 JSON 复制到剪贴板，方便备份',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: store.exportJson()),
                  );
                  if (!context.mounted) return;
                  showAppSnack(context, '数据已复制到剪贴板',
                      icon: Icons.content_copy_rounded);
                },
              ),
              Divider(height: 1, color: p.line),
              _Tile(
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.expense,
                title: '清空所有账目',
                subtitle: '保留分类与预算设置',
                onTap: () => _confirm(
                  context,
                  title: '清空所有账目？',
                  message: '这会删除全部收支记录，且无法恢复。',
                  confirmText: '清空',
                  danger: true,
                  onConfirm: () async {
                    await store.clearAllEntries();
                    if (!context.mounted) return;
                    showAppSnack(context, '账目已清空',
                        icon: Icons.delete_outline_rounded);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[AppColors.brand, Color(0xFF6C4CF1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('清账',
                          style: AppText.section.copyWith(color: p.text)),
                      Text('v1.0.0 · 本地记账',
                          style: AppText.caption.copyWith(color: p.sub)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '所有数据只保存在这台设备上，不上传、不需要登录。'
                '共 ${store.entries.length} 条记录、${store.categories.length} 个分类。',
                style: AppText.small.copyWith(color: p.sub, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required Future<void> Function() onConfirm,
    bool danger = false,
  }) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: danger ? AppColors.expense : AppColors.brand,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    if (ok == true) await onConfirm();
  }
}

class _ThemePill extends StatelessWidget {
  const _ThemePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brand.withValues(alpha: 0.1)
                : context.palette.fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.brand.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon,
                  size: 18,
                  color: selected ? AppColors.brand : context.palette.sub),
              const SizedBox(height: 5),
              Text(
                label,
                style: AppText.caption.copyWith(
                  color: selected ? AppColors.brand : context.palette.sub,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: AppText.body.copyWith(
                        color: p.text,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: p.sub)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.sub),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              Text(title,
                  style: AppText.body.copyWith(
                    color: p.text,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                style: AppText.caption.copyWith(color: p.sub),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
