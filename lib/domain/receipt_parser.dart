import 'models.dart';

/// Extracts editable suggestions; never writes transactions or guesses a total
/// from cash/change/phone numbers when a total label is missing.
class ReceiptParser {
  ReceiptDraft parse(String text, {String? imagePath}) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    int? total;
    var bestScore = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      if (RegExp(
        r'sub\s*total|kembali|change|tunai|cash|debit|credit|\bdpp\b|total\s*(item|qty|barang|pajak)|jumlah\s*(item|barang)',
      ).hasMatch(line)) {
        continue;
      }
      final score =
          RegExp(
            r'grand\s*total|total\s*(bayar|belanja|pembayaran|tagihan)|amount\s*due',
          ).hasMatch(line)
          ? 5
          : RegExp(r'\btotal\b|jumlah\s*bayar').hasMatch(line)
          ? 4
          : RegExp(r'harga\s*jual').hasMatch(line)
          ? 2
          : 0;
      if (score == 0) continue;
      var amount = _amount(lines[i]);
      if (amount == null) {
        for (var next = i + 1; next < lines.length && next <= i + 2; next++) {
          if (RegExp(r'^[-_=\s]+$').hasMatch(lines[next])) continue;
          if (RegExp(
            r'^(?:Rp\.?\s*)?[\d.,\s]+(?:,-)?$',
            caseSensitive: false,
          ).hasMatch(lines[next])) {
            amount = _amount(lines[next]);
          }
          break;
        }
      }
      if (amount != null && score > bestScore) {
        total = amount;
        bestScore = score;
      }
    }
    return ReceiptDraft(
      rawText: text,
      total: total,
      date: _date(text),
      merchant: _merchant(lines, text),
      imagePath: imagePath,
    );
  }

  int? _amount(String line) {
    if (RegExp(r'-\s*\d').hasMatch(line)) return null;
    final numbers = RegExp(r'\d[\d.,]*').allMatches(line).toList();
    if (numbers.isEmpty) return null;
    var token = numbers.last.group(0)!.replaceAll(RegExp(r'[.,]+$'), '');
    final decimal = RegExp(r'[.,](\d{2})$').firstMatch(token);
    if (decimal != null) {
      if (decimal[1] != '00') return null;
      token = token.substring(0, decimal.start);
    }
    if (!RegExp(r'^\d+$').hasMatch(token) &&
        !RegExp(r'^\d{1,3}([.,])\d{3}(?:\1\d{3})*$').hasMatch(token)) {
      return null;
    }
    final amount = int.tryParse(token.replaceAll(RegExp(r'[.,]'), ''));
    return amount != null && amount > 0 && amount <= 999999999999
        ? amount
        : null;
  }

  String? _merchant(List<String> lines, String text) {
    // A printed email/website can identify a brand even if the logo is unreadable.
    final brands = <String, String>{
      'indomaret': 'Indomaret',
      'alfamart': 'Alfamart',
      'alfamidi': 'Alfamidi',
      'superindo': 'Super Indo',
      'super indo': 'Super Indo',
      'starbucks': 'Starbucks',
      'point coffee': 'Point Coffee',
      'kopi kenangan': 'Kopi Kenangan',
    };
    final normalized = text.toLowerCase();
    for (final brand in brands.entries) {
      if (normalized.contains(brand.key)) return brand.value;
    }
    for (final line in lines.take(10)) {
      if (line.length >= 3 &&
          RegExp(r'[a-zA-Z]{3}').hasMatch(line) &&
          !RegExp(
            r'^(pt\.?\s|cv\.?\s)|struk|receipt|invoice|tanggal|telp|phone|kasir|jl\.|jalan|npwp|www\.|https|no\s*:|layanan|konsumen',
            caseSensitive: false,
          ).hasMatch(line)) {
        return line;
      }
    }
    return null;
  }

  DateTime? _date(String text) {
    for (final match in RegExp(
      r'\b(\d{1,4})\s*[./-]\s*(\d{1,2})\s*[./-]\s*(\d{2,4})(?!\d)',
    ).allMatches(text)) {
      final a = int.parse(match[1]!),
          b = int.parse(match[2]!),
          c = int.parse(match[3]!);
      final year = match[1]!.length == 4
          ? a
          : c < 100
          ? 2000 + c
          : c;
      final day = match[1]!.length == 4 ? c : a;
      final date = _validDate(year, b, day);
      if (date != null) return date;
    }
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'mei': 5,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'agu': 8,
      'aug': 8,
      'sep': 9,
      'okt': 10,
      'oct': 10,
      'nov': 11,
      'des': 12,
      'dec': 12,
    };
    for (final match in RegExp(
      r'\b(\d{1,2})\s+([a-zA-Z]+)\s+(\d{4})\b',
    ).allMatches(text)) {
      final word = match[2]!.toLowerCase();
      final key = months.keys.where((m) => word.startsWith(m)).firstOrNull;
      if (key != null) {
        final date = _validDate(
          int.parse(match[3]!),
          months[key]!,
          int.parse(match[1]!),
        );
        if (date != null) return date;
      }
    }
    return null;
  }

  DateTime? _validDate(int year, int month, int day) {
    if (year < 2000 || year > 2100 || month < 1 || month > 12 || day < 1) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}
