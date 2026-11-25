import 'package:flutter_test/flutter_test.dart';
import 'package:sakurapi/domain/receipt_parser.dart';
import 'package:sakurapi/domain/formatters.dart';

void main() {
  test('negative receipt totals are left for review', () {
    expect(ReceiptParser().parse('TOTAL -10.000').total, isNull);
  });
  final parser = ReceiptParser();
  test('grand total wins over subtotal, payment and change', () {
    final result = parser.parse(
      'KEDAI SENJA\n17/11/2026\nSubtotal 25.000\nGRAND TOTAL Rp27.500\nTunai 50.000\nKembalian 22.500',
    );
    expect(result.total, 27500);
    expect(result.merchant, 'KEDAI SENJA');
    expect(result.date, DateTime(2026, 11, 17));
  });
  test('split label and value; decimal rupiah zero', () {
    final result = parser.parse(
      'TOKO CONTOH\n2026-11-17\nTOTAL BAYAR\nRp 125.000,00',
    );
    expect(result.total, 125000);
    expect(result.date, DateTime(2026, 11, 17));
  });
  test(
    'no confident total is left empty rather than using cash or a phone number',
    () {
      final result = parser.parse(
        'TOKO CONTOH\nTelp 081234567890\nSubtotal 10000\nTunai 20000\nKembali 10000',
      );
      expect(result.total, isNull);
    },
  );
  test('invalid date is not normalized into next month', () {
    expect(parser.parse('TOKO\n31/02/2026\nTotal 10.000').date, isNull);
    expect(parser.parse('TOKO\n17 November 2026').date, DateTime(2026, 11, 17));
  });
  test('item quantity is not a total and fractional amounts need review', () {
    expect(parser.parse('TOTAL QTY 3\nTOTAL 20.000,50').total, isNull);
  });
  test(
    'amount validation rejects negative, fractions, zero, and excessive values',
    () {
      expect(parseRupiahInput('25.000'), 25000);
      for (final value in [
        '0',
        '-5000',
        '20,50',
        'abc',
        '1000000000000',
        '1.5',
        '1..000',
        '12.34',
      ]) {
        expect(parseRupiahInput(value), isNull, reason: value);
      }
    },
  );
}
