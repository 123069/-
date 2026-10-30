/// 金额、日期等格式化工具（自己实现，避免额外依赖，也保证中文格式一致）。
library;

String _pad2(int v) => v.toString().padLeft(2, '0');

String _group(String digits) {
  if (digits.length <= 3) return digits;
  final StringBuffer sb = StringBuffer();
  final int first = digits.length % 3;
  if (first > 0) sb.write(digits.substring(0, first));
  for (int i = first; i < digits.length; i += 3) {
    if (sb.isNotEmpty) sb.write(',');
    sb.write(digits.substring(i, i + 3));
  }
  return sb.toString();
}

/// 1,234.56
String fmtMoney(double value) {
  final bool negative = value < 0;
  final List<String> parts = value.abs().toStringAsFixed(2).split('.');
  final String body = '${_group(parts[0])}.${parts[1]}';
  return negative ? '-$body' : body;
}

/// 1,235（四舍五入到元）
String fmtMoneyInt(double value) => _group(value.abs().round().toString());

/// 1.2万 / 3,400
String fmtCompact(double value) {
  final double abs = value.abs();
  if (abs >= 100000000) {
    return '${(value / 100000000).toStringAsFixed(2)}亿';
  }
  if (abs >= 10000) {
    final String s = (value / 10000).toStringAsFixed(abs >= 100000 ? 1 : 2);
    return '${s.replaceFirst(RegExp(r'\.?0+$'), '')}万';
  }
  return fmtMoneyInt(value);
}

/// +/- 前缀
String fmtSigned(double value, {required bool income}) =>
    '${income ? '+' : '-'}${fmtMoney(value)}';

String monthKey(DateTime d) => '${d.year}-${_pad2(d.month)}';

DateTime monthStart(DateTime d) => DateTime(d.year, d.month);

DateTime nowMonth() => monthStart(DateTime.now());

int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

/// 2026年3月
String fmtMonth(DateTime d) => '${d.year}年${d.month}月';

/// 3月
String fmtMonthShort(DateTime d) => '${d.month}月';

/// 今天 / 昨天 / 3月10日
String fmtDayLabel(DateTime d) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime target = DateTime(d.year, d.month, d.day);
  final int diff = today.difference(target).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  if (d.year != now.year) return '${d.year}年${d.month}月${d.day}日';
  return '${d.month}月${d.day}日';
}

String fmtHM(DateTime d) => '${_pad2(d.hour)}:${_pad2(d.minute)}';

/// 3月12日 14:05
String fmtDateTime(DateTime d) =>
    '${d.month}月${d.day}日 ${fmtHM(d)}';

String fmtDate(DateTime d) => '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';

String weekdayName(DateTime d) {
  const List<String> names = <String>[
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];
  return names[(d.weekday - 1).clamp(0, 6)];
}

String greeting([DateTime? now]) {
  final int h = (now ?? DateTime.now()).hour;
  if (h < 6) return '夜深了';
  if (h < 11) return '早上好';
  if (h < 14) return '中午好';
  if (h < 18) return '下午好';
  return '晚上好';
}

/// 百分比文案，最多 1 位小数
String fmtPercent(double value) {
  final String s = (value * 100).toStringAsFixed(1);
  return '${s.replaceFirst(RegExp(r'\.0$'), '')}%';
}

/// 金额输入合法性：最多 2 位小数
bool isValidAmountText(String text) =>
    RegExp(r'^\d{0,8}(\.\d{0,2})?$').hasMatch(text);
