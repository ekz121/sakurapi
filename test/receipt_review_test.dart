import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sakurapi/app_store.dart';
import 'package:sakurapi/data/finance_repository.dart';
import 'package:sakurapi/domain/models.dart';
import 'package:sakurapi/ui/receipt_review_screen.dart';

void main() {
  testWidgets(
    'OCR prefills review, correction is saved once only after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await initializeDateFormatting('id_ID');
      sqfliteFfiInit();
      final repo = FinanceRepository(
        factory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
      );
      final store = AppStore(repo);
      await tester.runAsync(store.refresh);
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptReviewScreen(
            store: store,
            draft: ReceiptDraft(
              rawText: 'TOTAL 27,000',
              total: 27000,
              date: DateTime(2024, 10, 4),
              merchant: 'Indomaret',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Indomaret'), findsOneWidget);
      expect(find.text('27000'), findsOneWidget);
      expect(await repo.entries(), isEmpty);
      await tester.tap(find.text('Simpan transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih kategori pengeluaran'), findsOneWidget);
      expect(await repo.entries(), isEmpty);
      await tester.enterText(find.byType(TextFormField).at(1), '28000');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makan & minum').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan transaksi'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final saved = (await repo.entries()).single;
      expect(saved.amount, 28000);
      expect(saved.merchant, 'Indomaret');
      expect(saved.date, DateTime(2024, 10, 4));
      expect(saved.kind, EntryKind.expense);
      expect(store.balance, -28000);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      await repo.close();
    },
  );
}
