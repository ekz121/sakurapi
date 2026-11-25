import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sakurapi/app_store.dart';
import 'package:sakurapi/data/finance_repository.dart';
import 'package:sakurapi/domain/models.dart';
import 'package:sakurapi/main.dart';
import 'package:sakurapi/ui/receipt_review_screen.dart';

// Optional artifact capture, never uses a user's actual financial data.
void main() {
  testWidgets('capture original UI with synthetic local data', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '../.tools/flutter';
    final font = File(
      '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
    await initializeDateFormatting('id_ID');
    sqfliteFfiInit();
    final repo = FinanceRepository(
      factory: databaseFactoryFfiNoIsolate,
      databasePath: inMemoryDatabasePath,
    );
    final store = AppStore(repo);
    final today = DateTime.now();
    await tester.runAsync(() async {
      await store.refresh();
      final income = store.categories.firstWhere(
        (c) => c.kind == EntryKind.income,
      );
      final food = store.categories.firstWhere(
        (c) => c.name == 'Makan & minum',
      );
      final transport = store.categories.firstWhere(
        (c) => c.name == 'Transportasi',
      );
      await repo.setOpeningBalance(150000);
      await repo.saveEntry(
        MoneyEntry(
          kind: EntryKind.income,
          amount: 1500000,
          categoryId: income.id,
          date: today,
          merchant: 'Uang saku bulanan',
        ),
      );
      await repo.saveEntry(
        MoneyEntry(
          kind: EntryKind.expense,
          amount: 28000,
          categoryId: food.id,
          date: today,
          merchant: 'Kantin kampus',
        ),
      );
      await repo.saveEntry(
        MoneyEntry(
          kind: EntryKind.expense,
          amount: 12000,
          categoryId: transport.id,
          date: today,
          merchant: 'Perjalanan ke kampus',
        ),
      );
      await store.refresh();
    });
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: SakuRapiApp(store: store),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('docs/pratinjau').create(recursive: true);
        await File(
          'docs/pratinjau/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('ringkasan');
    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
    await capture('transaksi');
    await tester.tap(find.text('Laporan').last);
    await tester.pumpAndSettle();
    await capture('laporan');
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptReviewScreen(
          store: store,
          draft: ReceiptDraft(
            rawText: 'KEDAI KAMPUS\nTOTAL Rp29.500',
            total: 29500,
            date: today,
            merchant: 'Kedai Kampus',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('review-struk');
    expect(
      store.entries.length,
      3,
      reason: 'Review must not save a transaction',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
    await repo.close();
  }, skip: !const bool.fromEnvironment('CAPTURE_PREVIEW'));
}
