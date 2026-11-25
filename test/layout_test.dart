import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sakurapi/app_store.dart';
import 'package:sakurapi/data/finance_repository.dart';
import 'package:sakurapi/main.dart';
import 'package:sakurapi/domain/models.dart';

void main() {
  for (final config in [(320.0, 1.0), (390.0, 2.0), (768.0, 1.0)]) {
    testWidgets(
      'navigation and forms fit width ${config.$1}, text ${config.$2}',
      (tester) async {
        tester.view.physicalSize = Size(config.$1, 932);
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
        await tester.runAsync(() async {
          await repo.saveEntry(
            MoneyEntry(
              kind: EntryKind.expense,
              amount: 999999999999,
              categoryId: store.categories
                  .firstWhere((c) => c.kind == EntryKind.expense)
                  .id,
              date: DateTime.now(),
              merchant: 'Nama toko panjang untuk pengujian tampilan',
            ),
          );
          await store.refresh();
        });
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(config.$2)),
            child: SakuRapiApp(store: store),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'dashboard');
        for (final label in ['Transaksi', 'Laporan', 'Kategori']) {
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
        }
        await tester.tap(find.byTooltip('Catat'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'editor');
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
        await repo.close();
      },
    );
  }
}
