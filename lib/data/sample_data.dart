import '../models/category.dart';
import '../models/deposit.dart';
import '../models/entry.dart';
import '../utils/formatters.dart';

/// 示例数据：三个月的真实感账目，方便首次打开就看到完整效果。
/// 生成规则：以「今天」为基准，未来日期自动跳过。
List<MoneyEntry> buildSampleEntries({DateTime? now}) {
  final DateTime today = now ?? DateTime.now();
  final List<MoneyEntry> out = <MoneyEntry>[];
  int seq = 0;

  // 日, 时, 分, 类型, 分类id, 金额, 备注
  const List<SampleRow> template = <SampleRow>[
    SampleRow(1, 9, 0, EntryType.expense, 'housing', 2800, '房租'),
    SampleRow(1, 12, 20, EntryType.expense, 'food', 26, '午餐'),
    SampleRow(2, 8, 10, EntryType.expense, 'transport', 4, '地铁'),
    SampleRow(2, 12, 40, EntryType.expense, 'food', 32.5, '外卖'),
    SampleRow(3, 8, 5, EntryType.expense, 'food', 11, '早餐'),
    SampleRow(3, 19, 30, EntryType.expense, 'shopping', 86.6, '超市'),
    SampleRow(4, 13, 0, EntryType.expense, 'food', 22, '咖啡'),
    SampleRow(4, 21, 15, EntryType.expense, 'fun', 45, '电影'),
    SampleRow(5, 9, 30, EntryType.expense, 'telecom', 59, '话费'),
    SampleRow(6, 12, 10, EntryType.expense, 'food', 28, '午餐'),
    SampleRow(6, 18, 40, EntryType.expense, 'shopping', 128, '日用品'),
    SampleRow(7, 8, 30, EntryType.expense, 'transport', 32.4, '打车'),
    SampleRow(7, 20, 0, EntryType.expense, 'food', 68, '朋友聚餐'),
    SampleRow(8, 10, 0, EntryType.expense, 'medical', 45.8, '买药'),
    SampleRow(9, 8, 20, EntryType.expense, 'food', 12, '早餐'),
    SampleRow(9, 12, 30, EntryType.expense, 'transport', 6, '公交'),
    SampleRow(10, 9, 0, EntryType.income, 'salary', 12800, '工资'),
    SampleRow(10, 14, 0, EntryType.expense, 'housing', 156.3, '水电燃气'),
    SampleRow(11, 19, 20, EntryType.expense, 'food', 42, '晚饭'),
    SampleRow(12, 11, 0, EntryType.expense, 'study', 68, '一本书'),
    SampleRow(13, 15, 30, EntryType.expense, 'fun', 299, '健身房月卡'),
    SampleRow(14, 8, 15, EntryType.expense, 'transport', 4, '地铁'),
    SampleRow(15, 12, 0, EntryType.expense, 'food', 25, '工作餐'),
    SampleRow(16, 20, 30, EntryType.expense, 'shopping', 199, '网购'),
    SampleRow(17, 8, 40, EntryType.expense, 'food', 18, '咖啡'),
    SampleRow(18, 10, 0, EntryType.income, 'parttime', 800, '周末兼职'),
    SampleRow(19, 12, 20, EntryType.expense, 'food', 30, '午餐'),
    SampleRow(20, 19, 0, EntryType.expense, 'social', 200, '随礼'),
    SampleRow(21, 9, 0, EntryType.expense, 'transport', 300, '加油'),
    SampleRow(22, 13, 30, EntryType.expense, 'food', 55, '下午茶'),
    SampleRow(23, 20, 0, EntryType.income, 'redpacket', 200, '红包'),
    SampleRow(24, 12, 0, EntryType.expense, 'food', 26, '午餐'),
    SampleRow(25, 10, 30, EntryType.income, 'invest', 86.4, '理财收益'),
    SampleRow(26, 18, 0, EntryType.expense, 'shopping', 76.8, '超市'),
    SampleRow(27, 12, 0, EntryType.expense, 'food', 24, '午餐'),
    SampleRow(28, 8, 30, EntryType.expense, 'transport', 4, '地铁'),
  ];

  for (int m = 0; m < 3; m++) {
    final DateTime month = DateTime(today.year, today.month - m);
    final int dim = daysInMonth(month);
    final double factor = m == 0 ? 1.0 : (m == 1 ? 0.88 : 1.12);
    for (final SampleRow row in template) {
      if (row.day > dim) continue;
      final DateTime time =
          DateTime(month.year, month.month, row.day, row.hour, row.minute);
      if (time.isAfter(today)) continue;
      final double amount = (row.amount * factor);
      out.add(
        MoneyEntry(
          id: 'demo_${seq++}',
          type: row.type,
          categoryId: row.categoryId,
          amount: double.parse(amount.toStringAsFixed(2)),
          time: time,
          note: row.note,
          source: EntrySource.demo,
        ),
      );
    }
  }

  out.sort((MoneyEntry a, MoneyEntry b) => b.time.compareTo(a.time));
  return out;
}

class SampleRow {
  const SampleRow(
    this.day,
    this.hour,
    this.minute,
    this.type,
    this.categoryId,
    this.amount,
    this.note,
  );

  final int day;
  final int hour;
  final int minute;
  final EntryType type;
  final String categoryId;
  final double amount;
  final String note;
}

/// 示例存款：定期、活期、国债各一笔，方便看利息效果。
List<Deposit> buildSampleDeposits({DateTime? now}) {
  final DateTime today = now ?? DateTime.now();

  DateTime startMonthsAgo(int months, int day) =>
      DateTime(today.year, today.month - months, day);

  DateTime plusYears(DateTime date, int years) =>
      DateTime(date.year + years, date.month, date.day);

  final DateTime deposit1Start = startMonthsAgo(8, 15);
  final DateTime deposit3Start = startMonthsAgo(13, 20);

  return <Deposit>[
    Deposit(
      id: 'demo_dep_1',
      name: '招商银行 · 3 年定期',
      principal: 50000,
      annualRate: 3.15,
      startDate: deposit1Start,
      maturityDate: plusYears(deposit1Start, 3),
      note: '到期自动转存',
      history: <RatePoint>[
        RatePoint(date: deposit1Start, rate: 3.15),
      ],
    ),
    Deposit(
      id: 'demo_dep_2',
      name: '余额宝',
      principal: 12000,
      annualRate: 1.85,
      startDate: startMonthsAgo(20, 8),
      note: '随时可取，利率会变',
      history: <RatePoint>[
        RatePoint(date: startMonthsAgo(20, 8), rate: 2.05),
        RatePoint(date: startMonthsAgo(6, 1), rate: 1.85),
      ],
    ),
    Deposit(
      id: 'demo_dep_3',
      name: '储蓄国债 · 5 年期',
      principal: 20000,
      annualRate: 2.65,
      startDate: deposit3Start,
      maturityDate: plusYears(deposit3Start, 5),
      note: '每年付息一次',
      history: <RatePoint>[
        RatePoint(date: deposit3Start, rate: 2.65),
      ],
    ),
  ];
}
