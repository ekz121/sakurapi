import 'package:flutter_test/flutter_test.dart';
import 'package:sakurapi/domain/financial_report.dart';
import 'package:sakurapi/domain/models.dart';
import 'package:sakurapi/app_store.dart';
import 'package:sakurapi/data/finance_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

MoneyEntry entry(EntryKind kind, int amount, int category, DateTime date) =>
    MoneyEntry(kind: kind, amount: amount, categoryId: category, date: date);

void main() {
  test('reference report 100000 minus 51000, shares and six-month average', () {
    final report = FinancialReport([
      entry(EntryKind.income, 100000, 1, DateTime(2026, 11, 1)),
      entry(EntryKind.expense, 27000, 2, DateTime(2026, 11, 4)),
      entry(EntryKind.expense, 24000, 2, DateTime(2026, 11, 5)),
    ], DateTime(2026, 11));
    expect(report.income, 100000);
    expect(report.expense, 51000);
    expect(report.net, 49000);
    expect(report.averageExpense, 8500);
    expect(report.categories(EntryKind.expense), {2: 51000});
    expect(report.monthlyExpense, [0, 0, 0, 0, 0, 51000]);
  });
  test('year boundary, empty month, large integers and category totals', () {
    final report = FinancialReport([
      entry(EntryKind.expense, 20000, 2, DateTime(2025, 12, 31)),
      entry(EntryKind.expense, 10000, 3, DateTime(2026, 1, 1)),
      entry(EntryKind.expense, 999999999999, 3, DateTime(2026, 1, 31)),
      entry(EntryKind.income, 15, 1, DateTime(2026, 2, 1)),
    ], DateTime(2026, 1));
    expect(report.months.first, DateTime(2025, 8));
    expect(report.expense, 1000000009999);
    expect(report.monthlyExpense[4], 20000);
    expect(
      report.categories(EntryKind.expense).values.reduce((a, b) => a + b),
      report.expense,
    );
    expect(report.categories(EntryKind.income), isEmpty);
    final empty = FinancialReport([], DateTime(2026, 1));
    expect(empty.net, 0);
    expect(empty.averageExpense, 0);
  });
  test(
    'balance and reports recalculate after income becomes expense, date change and delete',
    () async {
      sqfliteFfiInit();
      final repo = FinanceRepository(
        factory: databaseFactoryFfi,
        databasePath: inMemoryDatabasePath,
      );
      final store = AppStore(repo);
      try {
        await store.refresh();
        final income = store.categories.firstWhere(
          (c) => c.kind == EntryKind.income,
        );
        final expense = store.categories.firstWhere(
          (c) => c.kind == EntryKind.expense,
        );
        await repo.setOpeningBalance(10000);
        await repo.saveEntry(
          entry(EntryKind.income, 100000, income.id, DateTime(2026, 11, 1)),
        );
        await repo.saveEntry(
          entry(EntryKind.expense, 51000, expense.id, DateTime(2026, 11, 2)),
        );
        await store.refresh();
        expect(store.balance, 59000);
        expect(FinancialReport(store.entries, DateTime(2026, 11)).net, 49000);
        final id = store.entries
            .firstWhere((e) => e.kind == EntryKind.income)
            .id;
        await repo.saveEntry(
          MoneyEntry(
            id: id,
            kind: EntryKind.expense,
            amount: 200000,
            categoryId: expense.id,
            date: DateTime(2026, 12, 1),
          ),
        );
        await store.refresh();
        expect(store.balance, -241000);
        expect(
          FinancialReport(store.entries, DateTime(2026, 11)).expense,
          51000,
        );
        expect(
          FinancialReport(store.entries, DateTime(2026, 12)).expense,
          200000,
        );
        await repo.deleteEntry(id!);
        await store.refresh();
        expect(store.balance, -41000);
      } finally {
        store.dispose();
        await repo.close();
      }
    },
  );
}
