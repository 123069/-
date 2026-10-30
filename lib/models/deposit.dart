import 'dart:math' as math;

/// 一次利率调整记录（银行调息、余额宝七日年化变化等）
class RatePoint {
  const RatePoint({required this.date, required this.rate});

  final DateTime date;
  final double rate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date.toIso8601String(),
        'rate': rate,
      };

  factory RatePoint.fromJson(Map<String, dynamic> json) => RatePoint(
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
        rate: (json['rate'] as num?)?.toDouble() ?? 0,
      );
}

/// 一笔存款 / 理财：本金 + 年化利率 + 起息日，利息按天折算（单利）。
///
/// 余额宝这类按日复利的，用单利近似误差很小，展示上不纠结。
class Deposit {
  const Deposit({
    required this.id,
    required this.name,
    required this.principal,
    required this.annualRate,
    required this.startDate,
    this.maturityDate,
    this.note = '',
    this.history = const <RatePoint>[],
  });

  final String id;
  final String name;

  /// 本金（元）
  final double principal;

  /// 年化利率，3.15 表示 3.15%
  final double annualRate;
  final DateTime startDate;

  /// 到期日（活期/余额宝可以为空）
  final DateTime? maturityDate;
  final String note;
  final List<RatePoint> history;

  double get dailyInterest => principal * annualRate / 100 / 365;

  double get annualInterest => principal * annualRate / 100;

  /// 已计息天数（没起息算 0，到期后不再增长）
  int daysElapsed([DateTime? now]) {
    final DateTime today = now ?? DateTime.now();
    int days = today.difference(startDate).inDays;
    if (days < 0) return 0;
    final DateTime? end = maturityDate;
    if (end != null) {
      final int total = end.difference(startDate).inDays;
      days = math.min(days, math.max(total, 0));
    }
    return days;
  }

  /// 累计利息
  double accruedInterest([DateTime? now]) => dailyInterest * daysElapsed(now);

  /// 本月已产生的利息（按当月已过天数估算）
  double monthlyInterest([DateTime? now]) {
    final DateTime today = now ?? DateTime.now();
    if (today.isBefore(startDate)) return 0;
    final int days = math.min(today.day, daysElapsed(today));
    return dailyInterest * days;
  }

  /// 到期利息（没有到期日时为 null）
  double? get interestAtMaturity {
    final DateTime? end = maturityDate;
    if (end == null) return null;
    final int days = end.difference(startDate).inDays;
    if (days <= 0) return null;
    return dailyInterest * days;
  }

  double? get amountAtMaturity {
    final double? interest = interestAtMaturity;
    return interest == null ? null : principal + interest;
  }

  bool get matured {
    final DateTime? end = maturityDate;
    return end != null && DateTime.now().isAfter(end);
  }

  /// 剩余天数（没有到期日返回 null）
  int? get daysToMaturity {
    final DateTime? end = maturityDate;
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays;
  }

  Deposit copyWith({
    String? name,
    double? principal,
    double? annualRate,
    DateTime? startDate,
    DateTime? maturityDate,
    bool clearMaturity = false,
    String? note,
    List<RatePoint>? history,
  }) =>
      Deposit(
        id: id,
        name: name ?? this.name,
        principal: principal ?? this.principal,
        annualRate: annualRate ?? this.annualRate,
        startDate: startDate ?? this.startDate,
        maturityDate: clearMaturity ? null : (maturityDate ?? this.maturityDate),
        note: note ?? this.note,
        history: history ?? this.history,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'principal': principal,
        'annualRate': annualRate,
        'startDate': startDate.toIso8601String(),
        'maturityDate': maturityDate?.toIso8601String(),
        'note': note,
        'history': history.map((RatePoint p) => p.toJson()).toList(),
      };

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
        id: json['id'] as String,
        name: json['name'] as String? ?? '存款',
        principal: (json['principal'] as num?)?.toDouble() ?? 0,
        annualRate: (json['annualRate'] as num?)?.toDouble() ?? 0,
        startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ??
            DateTime.now(),
        maturityDate: DateTime.tryParse(json['maturityDate'] as String? ?? ''),
        note: json['note'] as String? ?? '',
        history: ((json['history'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => RatePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 所有存款的汇总
class DepositSummary {
  const DepositSummary({
    required this.count,
    required this.principal,
    required this.annualInterest,
    required this.accruedInterest,
    required this.monthlyInterest,
    required this.todayInterest,
    required this.weightedRate,
  });

  final int count;
  final double principal;
  final double annualInterest;
  final double accruedInterest;
  final double monthlyInterest;
  final double todayInterest;

  /// 综合年化（按本金加权）
  final double weightedRate;

  bool get isEmpty => count == 0;
}
