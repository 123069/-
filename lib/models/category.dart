import 'package:flutter/material.dart';

/// 收 / 支
enum EntryType { expense, income }

extension EntryTypeX on EntryType {
  bool get isExpense => this == EntryType.expense;
  String get label => isExpense ? '支出' : '收入';
  String get key => isExpense ? 'expense' : 'income';
}

EntryType entryTypeFromKey(String? key) =>
    key == 'income' ? EntryType.income : EntryType.expense;

/// 分类图标池（用 Material 图标，保证 iOS / Android / Web 一致）
const Map<String, IconData> kCategoryIcons = <String, IconData>{
  'food': Icons.restaurant_rounded,
  'coffee': Icons.local_cafe_rounded,
  'bus': Icons.directions_bus_rounded,
  'car': Icons.local_taxi_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'home': Icons.home_rounded,
  'phone': Icons.smartphone_rounded,
  'movie': Icons.movie_rounded,
  'medical': Icons.medical_services_rounded,
  'school': Icons.school_rounded,
  'gift': Icons.card_giftcard_rounded,
  'pets': Icons.pets_rounded,
  'sports': Icons.sports_basketball_rounded,
  'travel': Icons.flight_takeoff_rounded,
  'salary': Icons.payments_rounded,
  'bonus': Icons.emoji_events_rounded,
  'work': Icons.work_rounded,
  'invest': Icons.trending_up_rounded,
  'redpacket': Icons.redeem_rounded,
  'more': Icons.more_horiz_rounded,
};

class AppCategory {
  const AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.builtin = true,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final EntryType type;
  final bool builtin;

  Color get displayColor => Color(color);
  IconData get displayIcon => kCategoryIcons[icon] ?? Icons.sell_rounded;
  bool get isExpense => type == EntryType.expense;
  bool get isIncome => type == EntryType.income;

  AppCategory copyWith({
    String? name,
    String? icon,
    int? color,
    EntryType? type,
  }) =>
      AppCategory(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        type: type ?? this.type,
        builtin: builtin,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'type': type.key,
        'builtin': builtin,
      };

  factory AppCategory.fromJson(Map<String, dynamic> json) => AppCategory(
        id: json['id'] as String,
        name: json['name'] as String? ?? '未命名',
        icon: json['icon'] as String? ?? 'more',
        color: (json['color'] as num?)?.toInt() ?? 0xFF8E8E93,
        type: entryTypeFromKey(json['type'] as String?),
        builtin: json['builtin'] as bool? ?? false,
      );
}

List<AppCategory> defaultCategories() => <AppCategory>[
      ..._expenseDefaults,
      ..._incomeDefaults,
    ];

const List<AppCategory> _expenseDefaults = <AppCategory>[
  AppCategory(id: 'food', name: '餐饮', icon: 'food', color: 0xFFFF7A45, type: EntryType.expense),
  AppCategory(id: 'transport', name: '交通', icon: 'bus', color: 0xFF4C8DFF, type: EntryType.expense),
  AppCategory(id: 'shopping', name: '购物', icon: 'shopping', color: 0xFFB36BFF, type: EntryType.expense),
  AppCategory(id: 'housing', name: '居住', icon: 'home', color: 0xFF2FB2B0, type: EntryType.expense),
  AppCategory(id: 'telecom', name: '通讯', icon: 'phone', color: 0xFF5AC8FA, type: EntryType.expense),
  AppCategory(id: 'fun', name: '娱乐', icon: 'movie', color: 0xFFFF6B9A, type: EntryType.expense),
  AppCategory(id: 'medical', name: '医疗', icon: 'medical', color: 0xFFFFC53D, type: EntryType.expense),
  AppCategory(id: 'study', name: '学习', icon: 'school', color: 0xFF34C759, type: EntryType.expense),
  AppCategory(id: 'social', name: '人情', icon: 'gift', color: 0xFFFF9F0A, type: EntryType.expense),
  AppCategory(id: 'other_expense', name: '其他', icon: 'more', color: 0xFF8E8E93, type: EntryType.expense),
];

const List<AppCategory> _incomeDefaults = <AppCategory>[
  AppCategory(id: 'salary', name: '工资', icon: 'salary', color: 0xFF12A26B, type: EntryType.income),
  AppCategory(id: 'bonus', name: '奖金', icon: 'bonus', color: 0xFF34C759, type: EntryType.income),
  AppCategory(id: 'parttime', name: '兼职', icon: 'work', color: 0xFF2FB2B0, type: EntryType.income),
  AppCategory(id: 'invest', name: '理财', icon: 'invest', color: 0xFF5AC8FA, type: EntryType.income),
  AppCategory(id: 'redpacket', name: '红包', icon: 'redpacket', color: 0xFFFF6B9A, type: EntryType.income),
  AppCategory(id: 'other_income', name: '其他收入', icon: 'more', color: 0xFF8E8E93, type: EntryType.income),
];
