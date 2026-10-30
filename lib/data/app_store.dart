import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/deposit.dart';
import '../models/entry.dart';
import '../utils/formatters.dart';
import 'sample_data.dart';

/// 全部状态都在这里：账目、分类、预算、主题、当前查看月份。
/// 数据以单份 JSON 存在本地（SharedPreferences），无后端、无登录。
class AppStore extends ChangeNotifier {
  static const String _docKey = 'qingzhang.doc.v1';

  final List<MoneyEntry> _entries = <MoneyEntry>[];
  final List<Deposit> _deposits = <Deposit>[];
  List<AppCategory> _categories = defaultCategories();
  final Map<String, double> _budgets = <String, double>{};
  final Map<String, String> _lastCategory = <String, String>{};
  double _fallbackBudget = 6000;
  ThemeMode _themeMode = ThemeMode.system;
  bool _clipboardAuto = true;
  DateTime _month = nowMonth();
  bool _ready = false;
  SharedPreferences? _prefs;

  bool get ready => _ready;
  List<MoneyEntry> get entries => List<MoneyEntry>.unmodifiable(_entries);
  List<Deposit> get deposits => List<Deposit>.unmodifiable(_deposits);
  List<AppCategory> get categories =>
      List<AppCategory>.unmodifiable(_categories);
  ThemeMode get themeMode => _themeMode;
  bool get clipboardAuto => _clipboardAuto;
  DateTime get selectedMonth => _month;
  double get defaultBudget => _fallbackBudget;

  AppCategory get unknownCategory => const AppCategory(
        id: '__unknown',
        name: '未分类',
        icon: 'more',
        color: 0xFF8E8E93,
        type: EntryType.expense,
      );

  // ── 生命周期 ─────────────────────────────────────────────

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
    final String? raw = _prefs?.getString(_docKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _applyDoc(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _seed();
      }
    } else {
      _seed();
    }
    _sortEntries();
    _ready = true;
    notifyListeners();
  }

  void _seed() {
    _entries
      ..clear()
      ..addAll(buildSampleEntries());
    _deposits
      ..clear()
      ..addAll(buildSampleDeposits());
    _categories = defaultCategories();
    _budgets
      ..clear()
      ..addAll(<String, double>{monthKey(DateTime.now()): 6000});
    _fallbackBudget = 6000;
    _themeMode = ThemeMode.system;
    _clipboardAuto = true;
    _month = nowMonth();
  }

  void _applyDoc(Map<String, dynamic> doc) {
    final List<dynamic> rawEntries =
        (doc['entries'] as List<dynamic>?) ?? <dynamic>[];
    _entries
      ..clear()
      ..addAll(rawEntries.map(
        (dynamic e) => MoneyEntry.fromJson(e as Map<String, dynamic>),
      ));

    final List<dynamic> rawCats =
        (doc['categories'] as List<dynamic>?) ?? <dynamic>[];
    if (rawCats.isEmpty) {
      _categories = defaultCategories();
    } else {
      _categories = rawCats
          .map((dynamic c) => AppCategory.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    _budgets.clear();
    final Map<String, dynamic>? rawBudgets =
        doc['budgets'] as Map<String, dynamic>?;
    rawBudgets?.forEach((String k, dynamic v) {
      if (v is num) _budgets[k] = v.toDouble();
    });

    _lastCategory.clear();
    final Map<String, dynamic>? rawLast =
        doc['lastCategory'] as Map<String, dynamic>?;
    rawLast?.forEach((String k, dynamic v) {
      if (v is String) _lastCategory[k] = v;
    });

    _fallbackBudget = (doc['fallbackBudget'] as num?)?.toDouble() ?? 6000;
    _themeMode = _themeModeFromKey(doc['themeMode'] as String?);
    _clipboardAuto = doc['clipboardAuto'] as bool? ?? true;

    final List<dynamic> rawDeposits =
        (doc['deposits'] as List<dynamic>?) ?? <dynamic>[];
    _deposits
      ..clear()
      ..addAll(rawDeposits.map(
        (dynamic d) => Deposit.fromJson(d as Map<String, dynamic>),
      ));
  }

  Map<String, dynamic> _toDoc() => <String, dynamic>{
        'version': 1,
        'entries': _entries.map((MoneyEntry e) => e.toJson()).toList(),
        'deposits': _deposits.map((Deposit d) => d.toJson()).toList(),
        'categories': _categories.map((AppCategory c) => c.toJson()).toList(),
        'budgets': _budgets,
        'lastCategory': _lastCategory,
        'fallbackBudget': _fallbackBudget,
        'themeMode': _themeModeKey(_themeMode),
        'clipboardAuto': _clipboardAuto,
      };

  Future<void> _persist() async {
    try {
      await _prefs?.setString(_docKey, jsonEncode(_toDoc()));
    } catch (_) {
      // 本地存储失败不影响当前会话，下一次操作会再试。
    }
  }

  static String _themeModeKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _themeModeFromKey(String? key) {
    switch (key) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ── 查询 ─────────────────────────────────────────────────

  List<AppCategory> categoriesOf(EntryType type) =>
      _categories.where((AppCategory c) => c.type == type).toList();

  AppCategory categoryOf(String id) => _categories.firstWhere(
        (AppCategory c) => c.id == id,
        orElse: () => unknownCategory,
      );

  AppCategory? findCategoryByName(String? name, EntryType type) {
    if (name == null || name.trim().isEmpty) return null;
    final String target = name.trim();
    final List<AppCategory> pool = categoriesOf(type);
    for (final AppCategory c in pool) {
      if (c.name == target || c.id == target) return c;
    }
    for (final AppCategory c in pool) {
      if (target.contains(c.name) || c.name.contains(target)) return c;
    }
    return null;
  }

  double budgetOf(DateTime month) =>
      _budgets[monthKey(month)] ?? _fallbackBudget;

  /// 上次用过的分类，记一笔时默认选中，少点一下
  String? lastCategoryOf(EntryType type) => _lastCategory[type.key];

  Future<void> rememberCategory(EntryType type, String categoryId) async {
    if (_lastCategory[type.key] == categoryId) return;
    _lastCategory[type.key] = categoryId;
    await _persist();
  }

  List<MoneyEntry> entriesOfMonth(DateTime month) {
    final DateTime m = monthStart(month);
    return _entries
        .where((MoneyEntry e) =>
            e.time.year == m.year && e.time.month == m.month)
        .toList()
      ..sort((MoneyEntry a, MoneyEntry b) => b.time.compareTo(a.time));
  }

  List<MoneyEntry> recentEntries([int limit = 6]) {
    final List<MoneyEntry> sorted = List<MoneyEntry>.from(_entries)
      ..sort((MoneyEntry a, MoneyEntry b) => b.time.compareTo(a.time));
    return sorted.take(limit).toList();
  }

  MonthSummary summaryOf(DateTime month) {
    final DateTime m = monthStart(month);
    double income = 0;
    double expense = 0;
    int count = 0;
    final Map<String, double> byCategory = <String, double>{};
    for (final MoneyEntry e in _entries) {
      if (e.time.year != m.year || e.time.month != m.month) continue;
      count++;
      if (e.isExpense) {
        expense += e.amount;
        byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
      } else {
        income += e.amount;
      }
    }
    final List<MapEntry<String, double>> sorted = byCategory.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));
    return MonthSummary(
      month: m,
      income: income,
      expense: expense,
      budget: budgetOf(m),
      count: count,
      byCategory: Map<String, double>.fromEntries(sorted),
    );
  }

  /// 某月某个方向（支出 / 收入）的分类合计，按金额降序
  Map<String, double> categoryTotals(DateTime month, EntryType type) {
    final DateTime m = monthStart(month);
    final Map<String, double> map = <String, double>{};
    for (final MoneyEntry e in _entries) {
      if (e.time.year != m.year || e.time.month != m.month) continue;
      if (e.type != type) continue;
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    final List<MapEntry<String, double>> sorted = map.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
          b.value.compareTo(a.value));
    return Map<String, double>.fromEntries(sorted);
  }

  /// 最近 [count] 个月（按时间升序，最后一个是当前选中月）
  List<MonthSummary> recentMonths([int count = 6]) {
    final List<MonthSummary> list = <MonthSummary>[];
    for (int i = count - 1; i >= 0; i--) {
      final DateTime m = DateTime(_month.year, _month.month - i);
      list.add(summaryOf(m));
    }
    return list;
  }

  /// 本月已过天数（用于日均）
  int elapsedDays(DateTime month) {
    final DateTime m = monthStart(month);
    final DateTime now = DateTime.now();
    if (m.year == now.year && m.month == now.month) return now.day;
    return daysInMonth(m);
  }

  double dailyAverage(DateTime month) {
    final MonthSummary s = summaryOf(month);
    final int days = elapsedDays(month);
    return days == 0 ? 0 : s.expense / days;
  }

  int daysLeftInMonth(DateTime month) {
    final DateTime m = monthStart(month);
    final DateTime now = DateTime.now();
    if (m.year == now.year && m.month == now.month) {
      return daysInMonth(m) - now.day + 1;
    }
    return daysInMonth(m);
  }

  /// 存款汇总：本金、年利息、累计利息、今日利息、加权年化
  DepositSummary get depositSummary {
    double principal = 0;
    double annual = 0;
    double accrued = 0;
    double monthly = 0;
    double today = 0;
    for (final Deposit d in _deposits) {
      principal += d.principal;
      annual += d.annualInterest;
      accrued += d.accruedInterest();
      monthly += d.monthlyInterest();
      today += d.dailyInterest;
    }
    return DepositSummary(
      count: _deposits.length,
      principal: principal,
      annualInterest: annual,
      accruedInterest: accrued,
      monthlyInterest: monthly,
      todayInterest: today,
      weightedRate: principal > 0 ? annual / principal * 100 : 0,
    );
  }

  // ── 写入 ─────────────────────────────────────────────────

  Future<MoneyEntry> addEntry(MoneyEntry entry) async {
    _entries.add(entry);
    _sortEntries();
    notifyListeners();
    await _persist();
    return entry;
  }

  Future<void> updateEntry(MoneyEntry entry) async {
    final int index = _entries.indexWhere((MoneyEntry e) => e.id == entry.id);
    if (index < 0) return;
    _entries[index] = entry;
    _sortEntries();
    notifyListeners();
    await _persist();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((MoneyEntry e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> setBudget(DateTime month, double amount) async {
    _budgets[monthKey(month)] = amount;
    _fallbackBudget = amount;
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> setClipboardAuto(bool enabled) async {
    _clipboardAuto = enabled;
    notifyListeners();
    await _persist();
  }

  Future<void> saveDeposit(Deposit deposit) async {
    final int index =
        _deposits.indexWhere((Deposit d) => d.id == deposit.id);
    if (index >= 0) {
      _deposits[index] = deposit;
    } else {
      _deposits.add(deposit);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteDeposit(String id) async {
    _deposits.removeWhere((Deposit d) => d.id == id);
    notifyListeners();
    await _persist();
  }

  void setMonth(DateTime month) {
    final DateTime m = monthStart(month);
    if (m.year == _month.year && m.month == _month.month) return;
    _month = m;
    notifyListeners();
  }

  Future<void> saveCategory(AppCategory category) async {
    final int index =
        _categories.indexWhere((AppCategory c) => c.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.add(category);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteCategory(String id) async {
    if (_categories.length <= 2) return;
    final AppCategory target = categoryOf(id);
    _categories.removeWhere((AppCategory c) => c.id == id);

    // 把用到该分类的账目迁移到「其他」
    final String fallbackId = target.isExpense
        ? (_categories.any((AppCategory c) => c.id == 'other_expense')
            ? 'other_expense'
            : _categories.first.id)
        : (_categories.any((AppCategory c) => c.id == 'other_income')
            ? 'other_income'
            : _categories.first.id);
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].categoryId == id) {
        _entries[i] = _entries[i].copyWith(categoryId: fallbackId);
      }
    }
    notifyListeners();
    await _persist();
  }

  Future<void> resetSampleData() async {
    _seed();
    _sortEntries();
    notifyListeners();
    await _persist();
  }

  Future<void> clearAllEntries() async {
    _entries.clear();
    notifyListeners();
    await _persist();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_toDoc());

  void _sortEntries() {
    _entries.sort((MoneyEntry a, MoneyEntry b) => b.time.compareTo(a.time));
  }
}
