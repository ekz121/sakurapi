import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sakurapi/services/receipt_scanner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real ML Kit reads the supplied receipt on Android', (
    tester,
  ) async {
    const path = String.fromEnvironment('OCR_FIXTURE');
    expect(
      path,
      isNotEmpty,
      reason: 'Provide the app-private OCR_FIXTURE path',
    );
    expect(await File(path).exists(), isTrue);
    final bytes = await File(path).readAsBytes();
    // ignore: avoid_print
    print(
      'OCR_FIXTURE_BYTES=${bytes.length}; HEADER=${bytes.take(8).toList()}',
    );
    final draft = await ReceiptScanner().scan(path);
    // Only this explicitly supplied test receipt is logged, never user records.
    // ignore: avoid_print
    print(
      'OCR_FIXTURE_RESULT=${jsonEncode({'total': draft.total, 'date': draft.date?.toIso8601String(), 'merchant': draft.merchant, 'text': draft.rawText})}',
    );
    expect(draft.total, 27000);
    expect(draft.date, DateTime(2024, 10, 4));
    expect(draft.merchant, 'Indomaret');
  });
}
