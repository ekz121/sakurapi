import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);
String rupiah(int value) => _rupiah.format(value);
String dayLabel(DateTime date) =>
    DateFormat('d MMM yyyy', 'id_ID').format(date);
String monthLabel(DateTime date) =>
    DateFormat('MMMM yyyy', 'id_ID').format(date);

int? parseRupiahInput(String input) {
  final amount = parseBalanceInput(input);
  return amount != null && amount > 0 && amount <= 999999999999 ? amount : null;
}

int? parseBalanceInput(String input) {
  var text = input.trim().replaceAll(' ', '');
  final negative = text.startsWith('-');
  if (negative) text = text.substring(1);
  if (!RegExp(r'^(?:\d+|\d{1,3}(?:\.\d{3})+)$').hasMatch(text)) return null;
  final value = int.tryParse(text.replaceAll('.', ''));
  if (value == null || value > 999999999999) return null;
  return negative ? -value : value;
}
