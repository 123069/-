import 'category.dart';

/// 记账来源，用于在列表里标示「这笔是怎么来的」
class EntrySource {
  EntrySource._();

  static const String manual = '手动';
  static const String shortcut = '快捷指令';
  static const String import = '账单导入';
  static const String clipboard = '智能识别';
  static const String demo = '示例';
}

class MoneyEntry {
  const MoneyEntry({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.time,
    this.note = '',
    this.source = EntrySource.manual,
  });

  final String id;
  final EntryType type;
  final String categoryId;

  /// 金额（元，正数；方向由 type 决定）
  final double amount;
  final DateTime time;
  final String note;
  final String source;

  bool get isExpense => type == EntryType.expense;

  MoneyEntry copyWith({
    EntryType? type,
    String? categoryId,
    double? amount,
    DateTime? time,
    String? note,
    String? source,
  }) =>
      MoneyEntry(
        id: id,
        type: type ?? this.type,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        time: time ?? this.time,
        note: note ?? this.note,
        source: source ?? this.source,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.key,
        'categoryId': categoryId,
        'amount': amount,
        'time': time.toIso8601String(),
        'note': note,
        'source': source,
      };

  factory MoneyEntry.fromJson(Map<String, dynamic> json) => MoneyEntry(
        id: json['id'] as String,
        type: entryTypeFromKey(json['type'] as String?),
        categoryId: json['categoryId'] as String? ?? 'other_expense',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        note: json['note'] as String? ?? '',
        source: json['source'] as String? ?? EntrySource.manual,
      );
}

/// 某个月的汇总
class MonthSummary {
  const MonthSummary({
    required this.month,
    required this.income,
    required this.expense,
    required this.budget,
    required this.count,
    required this.byCategory,
  });

  final DateTime month;
  final double income;
  final double expense;
  final double budget;
  final int count;

  /// 分类 id -> 金额（支出，按金额降序）
  final Map<String, double> byCategory;

  double get remaining => budget - expense;
  double get balance => income - expense;
  double get usage => budget <= 0 ? 0 : (expense / budget);
  bool get overBudget => budget > 0 && expense > budget;
}
