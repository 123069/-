import 'package:flutter_test/flutter_test.dart';
import 'package:qingzhang/models/category.dart';
import 'package:qingzhang/services/auto_entry.dart';
import 'package:qingzhang/services/bill_import.dart';

void main() {
  test('解析银行消费短信', () {
    final AutoEntryIntent? intent = ReceiptTextParser.parse(
      '【招商银行】您账户30日14:20支出人民币36.50元，余额1,024.00',
    );
    expect(intent, isNotNull);
    expect(intent!.amount, 36.5);
    expect(intent.type, EntryType.expense);
  });

  test('解析微信收款通知', () {
    final AutoEntryIntent? intent =
        ReceiptTextParser.parse('微信支付：收款到账 ¥128.00 来自 张三');
    expect(intent, isNotNull);
    expect(intent!.type, EntryType.income);
    expect(intent.amount, 128.0);
  });

  test('解析 qingzhang://add 深链', () {
    final Uri uri = Uri.parse(
      'qingzhang://add?amount=25.5&type=expense&category=%E9%A4%90%E9%A5%AE&note=%E5%8D%88%E9%A4%90',
    );
    final AutoEntryIntent? intent = AutoEntryIntent.fromUri(uri);
    expect(intent, isNotNull);
    expect(intent!.amount, 25.5);
    expect(intent.categoryName, '餐饮');
    expect(intent.note, '午餐');
    expect(intent.type, EntryType.expense);
    expect(intent.autoSave, isTrue);
  });

  test('没有金额的链接不直接入账', () {
    final AutoEntryIntent? intent =
        AutoEntryIntent.fromUri(Uri.parse('qingzhang://add?type=income'));
    expect(intent, isNotNull);
    expect(intent!.canSaveDirectly, isFalse);
  });

  test('CSV 账单解析：跳过不计收支与已关闭订单', () {
    const String csv = '交易时间,交易分类,交易对方,商品说明,收/支,金额,交易状态\n'
        '2026-03-01 08:12:33,餐饮美食,星巴克,拿铁,支出,32.00,交易成功\n'
        '2026-03-02 09:00:00,转账红包,张三,红包,收入,200.00,交易成功\n'
        '2026-03-03 10:00:00,其他,关闭订单,x,不计收支,10.00,交易成功\n'
        '2026-03-04 10:00:00,其他,失败订单,x,支出,20.00,交易关闭\n';
    final ImportResult result = BillImporter.parse(csv);
    expect(result.ok, isTrue);
    expect(result.rows.length, 2);
    expect(result.rows.first.amount, 32.0);
    expect(result.rows.first.type, EntryType.expense);
    expect(result.rows.last.type, EntryType.income);
  });

  test('金额格式化', () {
    expect(AutoEntryIntent.parseAmount('¥1,025.50'), 1025.5);
    expect(AutoEntryIntent.parseAmount('-12'), isNull);
  });
}
