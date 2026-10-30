import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';

import '../models/category.dart';
import 'auto_entry.dart';

class ImportRow {
  ImportRow({
    required this.time,
    required this.type,
    required this.amount,
    required this.note,
    this.categoryName,
    this.rawCategory = '',
    this.selected = true,
  });

  final DateTime time;
  final EntryType type;
  final double amount;
  final String note;
  final String? categoryName;
  final String rawCategory;
  bool selected;
}

class ImportResult {
  ImportResult({
    required this.rows,
    this.warnings = const <String>[],
    this.error,
  });

  final List<ImportRow> rows;
  final List<String> warnings;
  final String? error;

  bool get ok => error == null && rows.isNotEmpty;
}

/// 解析支付宝 / 微信 / 银行导出的账单（CSV 文本）
class BillImporter {
  BillImporter._();

  static const List<String> _timeKeys = <String>[
    '交易时间',
    '交易日期',
    '记账时间',
    '记账日期',
    '时间',
    '日期',
  ];
  static const List<String> _amountKeys = <String>[
    '金额(元)',
    '金额（元）',
    '交易金额',
    '发生额',
    '金额',
  ];
  static const List<String> _dirKeys = <String>[
    '收/支',
    '收支',
    '收/付款',
    '方向',
  ];
  static const List<String> _noteKeys = <String>[
    '商品说明',
    '商品',
    '交易对方',
    '对方户名',
    '商户名称',
    '摘要',
    '备注',
    '说明',
  ];
  static const List<String> _statusKeys = <String>[
    '交易状态',
    '当前状态',
    '状态',
  ];
  static const List<String> _categoryKeys = <String>['交易分类', '交易类型', '分类'];

  /// 支付宝导出的 CSV 多为 GBK，微信为 UTF-8，这里都尽量兜住
  static String decodeBytes(List<int> bytes) {
    final Uint8List data =
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    try {
      return utf8.decode(data);
    } on FormatException {
      // 落到 GBK
    }
    try {
      return gbk.decode(data);
    } catch (_) {
      return utf8.decode(data, allowMalformed: true);
    }
  }

  static ImportResult parse(String content) {
    final List<List<String>> rows = _parseCsv(content);
    if (rows.isEmpty) {
      return ImportResult(rows: const <ImportRow>[], error: '内容为空，没有可解析的账单');
    }

    int headerIndex = -1;
    for (int i = 0; i < rows.length && i < 15; i++) {
      final List<String> cells = rows[i];
      final bool hasTime = cells.any((String c) => _timeKeys.any(c.contains));
      final bool hasAmount = cells.any((String c) => _amountKeys.any(c.contains));
      if (hasTime && hasAmount) {
        headerIndex = i;
        break;
      }
    }
    if (headerIndex < 0) {
      return ImportResult(
        rows: const <ImportRow>[],
        error: '没找到表头（需要同时有「时间」和「金额」列）。支付宝/微信的 CSV 账单可以直接粘贴。',
      );
    }

    final List<String> header = rows[headerIndex];
    final int timeIdx = _findColumn(header, _timeKeys);
    final int amountIdx = _findColumn(header, _amountKeys);
    final int dirIdx = _findColumn(header, _dirKeys);
    final int noteIdx = _findColumn(header, _noteKeys);
    final int statusIdx = _findColumn(header, _statusKeys);
    final int categoryIdx = _findColumn(header, _categoryKeys);

    final List<ImportRow> out = <ImportRow>[];
    final List<String> warnings = <String>[];
    int skipped = 0;

    for (int i = headerIndex + 1; i < rows.length; i++) {
      final List<String> cells = rows[i];
      if (cells.every((String c) => c.trim().isEmpty)) continue;
      String cell(int idx) =>
          idx >= 0 && idx < cells.length ? cells[idx].trim() : '';

      if (cells.length < 3) {
        skipped++;
        continue;
      }
      if (cell(0).startsWith('---') ||
          cell(0).contains('导出时间') ||
          cell(0).contains('说明')) {
        continue;
      }

      final DateTime? time = _parseTime(cell(timeIdx));
      final double? amount = _parseMoney(cell(amountIdx));
      if (time == null || amount == null || amount <= 0) {
        skipped++;
        continue;
      }

      final String status = cell(statusIdx);
      if (status.contains('关闭') ||
          status.contains('失败') ||
          status.contains('撤销') ||
          status.contains('取消')) {
        skipped++;
        continue;
      }

      final String dir = cell(dirIdx);
      if (dir.contains('不计收支')) {
        skipped++;
        continue;
      }

      EntryType type;
      if (dir.contains('收入') || dir.contains('收')) {
        type = EntryType.income;
      } else if (dir.contains('支') || dir.contains('付')) {
        type = EntryType.expense;
      } else {
        type = EntryType.expense;
      }

      final String rawCategory = cell(categoryIdx);
      final String notePart = cell(noteIdx);
      final String note = notePart.isEmpty ? status : notePart;
      final String guessSource = '$rawCategory $note';
      final String? category =
          ReceiptTextParser.guessCategoryName(guessSource, type);

      out.add(
        ImportRow(
          time: time,
          type: type,
          amount: amount,
          note: note,
          categoryName: category,
          rawCategory: rawCategory,
        ),
      );
    }

    if (out.isEmpty) {
      return ImportResult(
        rows: const <ImportRow>[],
        warnings: warnings,
        error: '表头识别到了，但没能解析出有效记录（可能都是不计收支或已关闭的订单）。',
      );
    }
    if (skipped > 0) {
      warnings.add('已跳过 $skipped 条无法识别或无关的记录');
    }
    return ImportResult(rows: out, warnings: warnings);
  }

  static int _findColumn(List<String> header, List<String> keys) {
    for (final String key in keys) {
      for (int i = 0; i < header.length; i++) {
        if (header[i].replaceAll(' ', '').contains(key)) return i;
      }
    }
    return -1;
  }

  static List<List<String>> _parseCsv(String text) {
    final List<List<String>> rows = <List<String>>[];
    List<String> row = <String>[];
    final StringBuffer cell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n') {
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else if (ch != '\r') {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows
        .where((List<String> r) => r.any((String c) => c.trim().isNotEmpty))
        .toList();
  }

  static DateTime? _parseTime(String raw) {
    final String s = raw.trim();
    if (s.isEmpty) return null;
    final String normalized = s
        .replaceAll('年', '-')
        .replaceAll('月', '-')
        .replaceAll('日', '')
        .replaceAll('/', '-');
    final RegExpMatch? m = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(normalized);
    if (m != null) {
      final int y = int.parse(m.group(1)!);
      final int mo = int.parse(m.group(2)!);
      final int d = int.parse(m.group(3)!);
      final int h = int.tryParse(m.group(4) ?? '') ?? 0;
      final int mi = int.tryParse(m.group(5) ?? '') ?? 0;
      if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
        return DateTime(y, mo, d, h.clamp(0, 23), mi.clamp(0, 59));
      }
    }
    if (RegExp(r'^\d{8}$').hasMatch(s)) {
      return DateTime(
        int.parse(s.substring(0, 4)),
        int.parse(s.substring(4, 6)),
        int.parse(s.substring(6, 8)),
      );
    }
    return DateTime.tryParse(s);
  }

  static double? _parseMoney(String raw) {
    final String cleaned = raw
        .replaceAll(RegExp(r'[¥￥,，\s元]'), '')
        .replaceAll('+', '')
        .trim();
    if (cleaned.isEmpty) return null;
    final double? v = double.tryParse(cleaned);
    if (v == null) return null;
    return double.parse(v.abs().toStringAsFixed(2));
  }
}
