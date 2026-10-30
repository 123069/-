import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/automation_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/deposits_screen.dart';
import '../screens/entry_editor_page.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../theme/app_theme.dart';

/// 底部导航：首页 / 统计 / 预算 / 设置，中间是「记一笔」。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<String> _titles = <String>['首页', '统计', '预算', '设置'];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web 预览时可以用 ?tab=stats / budget / settings / automation 直接打开某一页
      final String? tab = Uri.base.queryParameters['tab'];
      _index = switch (tab) {
        'stats' => 1,
        'budget' => 2,
        'settings' => 3,
        _ => 0,
      };
      if (tab == 'automation') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AutomationScreen()),
          );
        });
      }
      if (tab == 'deposits') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DepositsScreen()),
          );
        });
      }
    }
  }

  void _openEditor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EntryEditorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: <Widget>[
            HomeScreen(onOpenStats: () => setState(() => _index = 1)),
            const StatsScreen(),
            const BudgetScreen(),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        titles: _titles,
        onSelect: (int i) => setState(() => _index = i),
        onAdd: _openEditor,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.titles,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final List<String> titles;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  static const List<IconData> _icons = <IconData>[
    Icons.donut_large_rounded,
    Icons.pie_chart_rounded,
    Icons.savings_rounded,
    Icons.tune_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final List<Widget> items = <Widget>[];
    for (int i = 0; i < 4; i++) {
      if (i == 2) {
        items.add(
          _AddButton(onTap: onAdd, palette: p),
        );
      }
      items.add(
        Expanded(
          child: _NavItem(
            icon: _icons[i],
            label: titles[i],
            selected: index == i,
            onTap: () => onSelect(i),
            palette: p,
          ),
        ),
      );
    }

    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
          child: SizedBox(
            height: 62,
            child: Row(children: items),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.brand : palette.sub;
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppText.caption.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.palette});

  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[AppColors.brand, Color(0xFF6C4CF1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.add_rounded, size: 18, color: Colors.white),
                SizedBox(width: 3),
                Text(
                  '记一笔',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
