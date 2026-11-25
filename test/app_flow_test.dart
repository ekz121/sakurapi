import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sakurapi/app_store.dart';
import 'package:sakurapi/data/finance_repository.dart';
import 'package:sakurapi/main.dart';

void main() {
  testWidgets(
    'dashboard, editor validation, save, report, and delete use local data',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      await initializeDateFormatting('id_ID');
      sqfliteFfiInit();
      final repo = FinanceRepository(
        factory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
      );
      final store = AppStore(repo);
      await tester.runAsync(store.refresh);
      await tester.pumpWidget(SakuRapiApp(store: store));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('SakuRapi'), findsOneWidget);
      expect(
        find.text('Milik Anda. Tersimpan di perangkat ini.'),
        findsNothing,
      );
      final addCenter = tester.getCenter(find.byTooltip('Catat'));
      expect(addCenter.dx, closeTo(215, 1));
      await tester.tap(find.byTooltip('Tentang aplikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Lihat lisensi'), findsNothing);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Catat'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simpan transaksi'));
      await tester.tap(find.text('Simpan transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih kategori terlebih dahulu'), findsOneWidget);
      expect((await repo.entries()), isEmpty);
      await tester.enterText(find.byType(TextFormField).first, '25000');
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makan & minum').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simpan transaksi'));
      await tester.tap(find.text('Simpan transaksi'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(store.balance, -25000);
      expect(store.entries.length, 1);
      await tester.tap(find.text('Laporan').last);
      await tester.pumpAndSettle();
      expect(find.text('Selisih bulan ini'), findsOneWidget);
      await tester.tap(find.text('Transaksi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makan & minum').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hapus transaksi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(store.entries, isEmpty);
      expect(store.balance, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      await repo.close();
    },
  );
}
