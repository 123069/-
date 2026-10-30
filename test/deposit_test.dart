import 'package:flutter_test/flutter_test.dart';
import 'package:qingzhang/models/deposit.dart';
import 'package:qingzhang/services/auto_entry.dart';

void main() {
  test('按天计算利息', () {
    final DateTime start = DateTime(2026, 1, 1);
    final Deposit d = Deposit(
      id: 'd1',
      name: '测试定期',
      principal: 36500,
      annualRate: 5,
      startDate: start,
    );
    expect(d.dailyInterest, closeTo(5.0, 0.0001));
    expect(d.annualInterest, closeTo(1825.0, 0.0001));
    expect(d.daysElapsed(start.add(const Duration(days: 100))), 100);
    expect(d.accruedInterest(start.add(const Duration(days: 100))),
        closeTo(500.0, 0.01));
  });

  test('到期后不再计息', () {
    final DateTime start = DateTime(2025, 1, 1);
    final DateTime maturity = DateTime(2026, 1, 1);
    final Deposit d = Deposit(
      id: 'd2',
      name: '一年定期',
      principal: 10000,
      annualRate: 3,
      startDate: start,
      maturityDate: maturity,
    );
    final int total = maturity.difference(start).inDays;
    expect(d.daysElapsed(DateTime(2026, 6, 1)), total);
    expect(d.interestAtMaturity, closeTo(d.dailyInterest * total, 0.01));
    expect(d.matured, isTrue);
  });

  test('起存晚于今天时利息为 0', () {
    final Deposit d = Deposit(
      id: 'd3',
      name: '未来存款',
      principal: 1000,
      annualRate: 2,
      startDate: DateTime.now().add(const Duration(days: 10)),
    );
    expect(d.daysElapsed(), 0);
    expect(d.accruedInterest(), 0);
  });

  test('从文本里提取年化利率', () {
    expect(ReceiptTextParser.extractRate('余额宝七日年化 1.85%'), 1.85);
    expect(ReceiptTextParser.extractRate('年利率3.15％'), 3.15);
    expect(ReceiptTextParser.extractRate('没有百分比'), isNull);
    expect(ReceiptTextParser.extractRate('99%'), isNull);
  });
}
