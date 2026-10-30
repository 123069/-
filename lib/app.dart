import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/app_store.dart';
import 'models/category.dart';
import 'models/entry.dart';
import 'screens/entry_editor_page.dart';
import 'screens/shell.dart';
import 'services/auto_entry.dart';
import 'services/deep_link_service.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';
import 'widgets/quick_capture_sheet.dart';

class QingzhangApp extends StatefulWidget {
  const QingzhangApp({super.key});

  @override
  State<QingzhangApp> createState() => _QingzhangAppState();
}

class _QingzhangAppState extends State<QingzhangApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String>? _linkSub;
  String? _lastClipboardText;
  bool _clipboardBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DeepLinkService.startListening();
    _linkSub = DeepLinkService.links.listen(_handleLink);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final String? initial = await DeepLinkService.initialLink();
      if (initial != null) {
        await _handleLink(initial);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  /// 回到 App 时看一眼剪贴板：如果刚复制的是支付短信/通知，就直接弹确认条。
  /// 这是 iOS 上最接近「不用动手」的做法（系统不允许读其他 App 的通知）。
  Future<void> _checkClipboard() async {
    if (kIsWeb || _clipboardBusy) return;
    final AppStore store = context.read<AppStore>();
    if (!store.clipboardAuto) return;
    if (_navigatorKey.currentState?.canPop() ?? false) return;

    _clipboardBusy = true;
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      final String? text = data?.text?.trim();
      if (text == null || text.isEmpty || text == _lastClipboardText) return;
      _lastClipboardText = text;
      final AutoEntryIntent? intent = ReceiptTextParser.parse(text);
      if (intent == null || intent.amount == null) return;
      if (!mounted) return;
      final bool ok = await showQuickCapture(context, intent);
      if (!ok) return;
      await _saveIntent(store, intent, source: EntrySource.clipboard);
    } catch (_) {
      // 读剪贴板失败（权限/空内容）就静默跳过，不打扰用户
    } finally {
      _clipboardBusy = false;
    }
  }

  Future<void> _saveIntent(
    AppStore store,
    AutoEntryIntent intent, {
    required String source,
  }) async {
    final MoneyEntry entry = intent.toEntry(store);
    await store.addEntry(entry);
    final AppCategory category = store.categoryOf(entry.categoryId);
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: <Widget>[
            const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '已自动记账 · ${category.name} ${fmtMoney(entry.amount)} 元',
                style: AppText.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 外部链接进来：带金额就直接入账（真正的「不用手动输入」），
  /// 只带分类/备注就打开记账页预填。
  Future<void> _handleLink(String raw) async {
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null) return;
    final AutoEntryIntent? intent = AutoEntryIntent.fromUri(uri);
    if (intent == null || !mounted) return;

    final AppStore store = context.read<AppStore>();
    if (intent.autoSave && intent.canSaveDirectly) {
      await _saveIntent(store, intent, source: EntrySource.shortcut);
    } else {
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => EntryEditorPage(draft: intent),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStore store = context.watch<AppStore>();
    return MaterialApp(
      title: '清账',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: store.themeMode,
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const HomeShell(),
    );
  }
}
