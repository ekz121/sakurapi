import 'package:flutter_test/flutter_test.dart';
import 'package:sakurapi/domain/receipt_parser.dart';
import 'package:sakurapi/domain/receipt_layout.dart';

void main() {
  test(
    'supplied Indomaret receipt uses comma thousands and date beside time',
    () {
      final draft = ReceiptParser().parse(
        'PT INDOMARCO PRISMATAMA\nFRESH UTAN KAYU\n04.10.24-13:21/3.0.19/T004-14315/RIDWA/06\nP/C BISCOFF MLKCHESE 1 27000 27,000\nHARGA JUAL : 27,000\nTOTAL : 27,000\nTUNAI : 27,000\nPJK RST.: DPP=24,545 PJK=2,455\nKONTAK@INDOMARET.CO.ID',
      );
      expect(draft.total, 27000);
      expect(draft.date, DateTime(2024, 10, 4));
      expect(draft.merchant, 'Indomaret');
    },
  );
  test('OCR columns are reconstructed by coordinates before parsing', () {
    final text = receiptReadingOrderFixture();
    final draft = ReceiptParser().parse(text);
    expect(draft.total, 27000);
    expect(text, contains('TOTAL  :  27,000'));
  });
  test(
    'formatted zero cents and leading receipt metadata do not change the total',
    () {
      expect(
        ReceiptParser()
            .parse('TOKO KAMPUS\nTOTAL Rp 1.250.000,00\nTUNAI 2.000.000')
            .total,
        1250000,
      );
      expect(
        ReceiptParser().parse('TOKO KAMPUS\nTOTAL Rp 27,000.00').total,
        27000,
      );
      expect(
        ReceiptParser().parse('TOKO KAMPUS\nTOTAL 1.23.456').total,
        isNull,
      );
    },
  );
}

String receiptReadingOrderFixture() => receiptReadingOrder([
  const ReceiptTextLine('27,000', 210, 100, 60, 15),
  const ReceiptTextLine('TOTAL', 30, 101, 60, 14),
  const ReceiptTextLine(':', 170, 100, 5, 15),
  const ReceiptTextLine('50,000', 210, 126, 60, 15),
  const ReceiptTextLine('TUNAI', 30, 126, 60, 15),
]);
