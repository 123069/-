import '../data/app_store.dart';
import '../models/category.dart';
import '../models/entry.dart';

/// 一次「自动记账」意图：来自 URL Scheme、快捷指令、剪贴板短信/通知文本。
class AutoEntryIntent {
  const AutoEntryIntent({
    required this.type,
    this.amount,
    this.categoryName,
    this.note = '',
    this.time,
    this.autoSave = false,
    this.source = EntrySource.shortcut,
  });

  final EntryType type;
  final double? amount;
  final String? categoryName;
  final String note;
  final DateTime? time;
  final bool autoSave;
  final String source;

  bool get canSaveDirectly => amount != null && amount! > 0;

  /// 解析 qingzhang://add?amount=25&type=expense&category=餐饮&note=午餐&date=2026-03-12
  static AutoEntryIntent? fromUri(Uri uri) {
    if (uri.scheme != 'qingzhang') return null;
    final Map<String, String> q = uri.queryParameters;
    if (q.isEmpty && uri.host != 'add' && uri.path.isEmpty) return null;
    return fromQuery(q, source: EntrySource.shortcut);
  }

  static bool looksLikeAutoEntry(Map<String, String> q) =>
      q.containsKey('amount') ||
      q.containsKey('type') ||
      q.containsKey('category') ||
      q.containsKey('cat') ||
      q.containsKey('add');

  static AutoEntryIntent? fromQuery(
    Map<String, String> q, {
    String source = EntrySource.shortcut,
  }) {
    if (!looksLikeAutoEntry(q)) return null;
    final double? amount = parseAmount(q['amount']);
    final bool auto = q['auto'] == null
        ? amount != null
        : !(q['auto'] == '0' || q['auto'] == 'false' || q['auto'] == 'no');
    return AutoEntryIntent(
      type: entryTypeFromKey(q['type']),
      amount: amount,
      categoryName: q['category'] ?? q['cat'] ?? q['categoryName'],
      note: q['note'] ?? q['memo'] ?? '',
      time: parseWhen(q['date'] ?? q['time']),
      autoSave: auto && amount != null,
      source: source,
    );
  }

  /// 转成一条待保存的账目（分类名 / 备注会自动匹配）
  MoneyEntry toEntry(AppStore store) {
    final AppCategory? byName = store.findCategoryByName(categoryName, type);
    final AppCategory? guessed = byName ??
        store.findCategoryByName(ReceiptTextParser.guessCategoryName('$note ${categoryName ?? ''}', type), type);
    final AppCategory category = guessed ??
        store.findCategoryByName(
          type == EntryType.income ? '其他收入' : '其他',
          type,
        ) ??
        store.unknownCategory;
    return MoneyEntry(
      id: 'auto_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      categoryId: category.id,
      amount: amount ?? 0,
      time: time ?? DateTime.now(),
      note: note,
      source: source,
    );
  }

  static double? parseAmount(String? raw) {
    if (raw == null) return null;
    final String cleaned = raw
        .replaceAll(RegExp(r'[¥￥,，\s元人民币]'), '')
        .replaceAll('+', '')
        .trim();
    final double? value = double.tryParse(cleaned);
    if (value == null || value <= 0) return null;
    return double.parse(value.toStringAsFixed(2));
  }

  static DateTime? parseWhen(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final String s = raw.trim();
    final DateTime? parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    final RegExpMatch? m =
        RegExp(r'^(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})日?$').firstMatch(s);
    if (m != null) {
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        DateTime.now().hour,
        DateTime.now().minute,
      );
    }
    return null;
  }
}

/// 从短信 / 支付通知 / 账单文本里提取金额、方向、分类。
class ReceiptTextParser {
  ReceiptTextParser._();

  static AutoEntryIntent? parse(
    String raw, {
    String source = EntrySource.clipboard,
    EntryType fallbackType = EntryType.expense,
  }) {
    final String text = raw.trim();
    if (text.length < 2) return null;
    final double? amount = extractAmount(text);
    if (amount == null) return null;
    final EntryType type = extractType(text) ?? fallbackType;
    return AutoEntryIntent(
      type: type,
      amount: amount,
      categoryName: guessCategoryName(text, type),
      note: extractMerchant(text),
      time: extractTime(text),
      autoSave: false,
      source: source,
    );
  }

  static double? extractAmount(String text) {
    final List<RegExp> patterns = <RegExp>[
      RegExp(r'(?:¥|￥|RMB|CNY|人民币)\s*([0-9][0-9,]*\.?[0-9]{0,2})'),
      RegExp(r'([0-9][0-9,]*\.?[0-9]{1,2})\s*元'),
      RegExp(r'([0-9][0-9,]*\.[0-9]{2})'),
    ];
    for (final RegExp re in patterns) {
      final RegExpMatch? m = re.firstMatch(text);
      if (m != null) {
        final double? v = AutoEntryIntent.parseAmount(m.group(1));
        if (v != null) return v;
      }
    }
    return null;
  }

  static EntryType? extractType(String text) {
    int income = 0;
    int expense = 0;
    const List<String> incomeWords = <String>[
      '收入',
      '收款',
      '到账',
      '入账',
      '转入',
      '退款',
      '工资',
      '奖金',
      '报销',
      '红包',
      '收益',
    ];
    const List<String> expenseWords = <String>[
      '支出',
      '消费',
      '付款',
      '支付',
      '转出',
      '扣款',
      '缴费',
      '取现',
      '还款',
      '购买',
    ];
    for (final String w in incomeWords) {
      income += w.allMatches(text).length;
    }
    for (final String w in expenseWords) {
      expense += w.allMatches(text).length;
    }
    if (income == 0 && expense == 0) return null;
    return income > expense ? EntryType.income : EntryType.expense;
  }

  static String extractMerchant(String text) {
    final List<RegExp> patterns = <RegExp>[
      RegExp(r'(?:商户名称|商户|商家|收款方|付款方|对方户名|交易对方)[:：]\s*([^\n,，;；。|]{1,24})'),
      RegExp(r'在\s*([^\s,，。]{2,16})\s*(?:消费|支付|付款)'),
    ];
    for (final RegExp re in patterns) {
      final RegExpMatch? m = re.firstMatch(text);
      if (m != null) {
        final String s = m.group(1)!.trim();
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  static DateTime? extractTime(String text) {
    RegExpMatch? m = RegExp(
      r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})日?\s*(\d{1,2})[:：](\d{2})',
    ).firstMatch(text);
    if (m != null) {
      return _build(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
      );
    }
    m = RegExp(r'(\d{1,2})月(\d{1,2})日\s*(\d{1,2})[:：](\d{2})')
        .firstMatch(text);
    if (m != null) {
      final DateTime now = DateTime.now();
      return _build(
        now.year,
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
      );
    }
    m = RegExp(r'(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})日?').firstMatch(text);
    if (m != null) {
      final DateTime now = DateTime.now();
      return _build(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        now.hour,
        now.minute,
      );
    }
    return null;
  }

  static DateTime? _build(int y, int mo, int d, int h, int mi) {
    if (mo < 1 || mo > 12 || d < 1 || d > 31 || h > 23 || mi > 59) return null;
    return DateTime(y, mo, d, h, mi);
  }

  /// 从「余额宝七日年化 1.85%」「年利率 3.15%」这类文字里取出利率
  static double? extractRate(String text) {
    final RegExpMatch? match =
        RegExp(r'(\d{1,2}(?:\.\d{1,3})?)\s*[%％]').firstMatch(text);
    if (match == null) return null;
    final double? value = double.tryParse(match.group(1)!);
    if (value == null || value <= 0 || value > 30) return null;
    return value;
  }

  static String? guessCategoryName(String text, EntryType type) {
    final Map<String, List<String>> table =
        type == EntryType.income ? _incomeKeywords : _expenseKeywords;
    String? best;
    int bestScore = 0;
    table.forEach((String category, List<String> words) {
      int score = 0;
      for (final String w in words) {
        if (text.contains(w)) score += 1;
      }
      if (score > bestScore) {
        bestScore = score;
        best = category;
      }
    });
    return best;
  }

  static const Map<String, List<String>> _expenseKeywords =
      <String, List<String>>{
    '餐饮': <String>['餐饮', '外卖', '午餐', '晚餐', '早餐', '夜宵', '咖啡', '奶茶', '火锅', '烧烤', '餐厅', '面馆', '食品', '零食'],
    '交通': <String>['地铁', '公交', '打车', '滴滴', '出租车', '高铁', '火车', '机票', '加油', '停车', '高速', '骑行', '单车'],
    '购物': <String>['淘宝', '京东', '超市', '便利店', '商场', '商城', '网购', '拼多多', '日用品', '服饰'],
    '居住': <String>['房租', '物业', '水费', '电费', '燃气', '取暖', '家政', '维修', '租金'],
    '通讯': <String>['话费', '流量', '宽带', '移动', '联通', '电信', '营业厅'],
    '娱乐': <String>['电影', '游戏', '会员', '健身', '演出', '门票', 'KTV', '视频'],
    '医疗': <String>['医院', '药', '挂号', '体检', '诊所', '口腔', '医疗'],
    '学习': <String>['书', '课程', '学费', '培训', '网课', '考试', '教材'],
    '人情': <String>['红包', '礼金', '随礼', '转账', 'AA', '份子'],
  };

  static const Map<String, List<String>> _incomeKeywords =
      <String, List<String>>{
    '工资': <String>['工资', '薪资', '代发', '薪水'],
    '奖金': <String>['奖金', '绩效', '年终', '提成'],
    '兼职': <String>['兼职', '稿费', '劳务', '外快'],
    '理财': <String>['理财', '利息', '收益', '分红', '基金'],
    '红包': <String>['红包', '收款', '转入', '退款'],
  };
}
