import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sakurapi/app_store.dart';
import 'package:sakurapi/data/finance_repository.dart';
import 'package:sakurapi/domain/models.dart';

void main() {
  test('data survives closing and reopening the SQLite file', () async {
    sqfliteFfiInit();
    final filePath =
        '${Directory.systemTemp.path}/sakurapi-persistence-${DateTime.now().microsecondsSinceEpoch}.db';
    final first = FinanceRepository(
      factory: databaseFactoryFfi,
      databasePath: filePath,
    );
    final second = FinanceRepository(
      factory: databaseFactoryFfi,
      databasePath: filePath,
    );
    try {
      final category = (await first.categories()).first;
      await first.setOpeningBalance(75000);
      await first.saveEntry(
        MoneyEntry(
          kind: category.kind,
          amount: 12500,
          categoryId: category.id,
          date: DateTime(2026, 11, 17),
          merchant: 'Toko contoh',
        ),
      );
      await first.close();
      expect(await second.openingBalance(), 75000);
      expect((await second.entries()).single.merchant, 'Toko contoh');
    } finally {
      await first.close();
      await second.close();
      await databaseFactoryFfi.deleteDatabase(filePath);
    }
  });
  late FinanceRepository repo;
  setUpAll(sqfliteFfiInit);
  setUp(() {
    repo = FinanceRepository(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });
  tearDown(() => repo.close());
  test(
    'create, update, delete, balances and month boundaries use SQLite',
    () async {
      final store = AppStore(repo);
      await store.refresh();
      final expense = store.categories.firstWhere(
        (c) => c.kind == EntryKind.expense,
      );
      final income = store.categories.firstWhere(
        (c) => c.kind == EntryKind.income,
      );
      await repo.setOpeningBalance(50000);
      await repo.saveEntry(
        MoneyEntry(
          kind: EntryKind.income,
          amount: 100000,
          categoryId: income.id,
          date: DateTime(2026, 10, 31),
        ),
      );
      await repo.saveEntry(
        MoneyEntry(
          kind: EntryKind.expense,
          amount: 20000,
          categoryId: expense.id,
          date: DateTime(2026, 11, 1),
        ),
      );
      await store.refresh();
      expect(store.balance, 130000);
      expect(store.inMonth(DateTime(2026, 11)).length, 1);
      final entry = store.entries.first;
      await repo.saveEntry(
        MoneyEntry(
          id: entry.id,
          kind: EntryKind.expense,
          amount: 35000,
          categoryId: expense.id,
          date: entry.date,
          merchant: 'Kantin',
        ),
      );
      await store.refresh();
      expect(store.balance, 115000);
      expect(store.entries.first.merchant, 'Kantin');
      await repo.deleteEntry(entry.id!);
      await store.refresh();
      expect(store.balance, 150000);
      expect(store.inMonth(DateTime(2026, 11)), isEmpty);
      store.dispose();
    },
  );
  test(
    'category updates persist, in-use deletion and duplicate names are blocked',
    () async {
      final first = (await repo.categories()).first;
      await repo.saveCategory(
        id: first.id,
        name: 'Kebutuhan',
        kind: first.kind,
        color: first.color,
        symbol: first.symbol,
      );
      expect(
        (await repo.categories()).firstWhere((c) => c.id == first.id).name,
        'Kebutuhan',
      );
      await expectLater(
        repo.saveCategory(
          name: 'kebutuhan',
          kind: first.kind,
          color: first.color,
          symbol: first.symbol,
        ),
        throwsArgumentError,
      );
      await repo.saveEntry(
        MoneyEntry(
          kind: first.kind,
          amount: 1000,
          categoryId: first.id,
          date: DateTime(2026, 11, 17),
        ),
      );
      await expectLater(repo.deleteCategory(first.id), throwsArgumentError);
      await expectLater(
        repo.saveEntry(
          MoneyEntry(
            kind: first.kind == EntryKind.income
                ? EntryKind.expense
                : EntryKind.income,
            amount: 1000,
            categoryId: first.id,
            date: DateTime(2026, 11, 17),
          ),
        ),
        throwsArgumentError,
      );
      await repo.deleteEntry((await repo.entries()).first.id!);
      await repo.deleteCategory(first.id);
      expect((await repo.categories()).any((c) => c.id == first.id), isFalse);
    },
  );
}
