import 'models.dart';

class FinancialReport {
  FinancialReport(Iterable<MoneyEntry> allEntries, DateTime selectedMonth)
    : month = DateTime(selectedMonth.year, selectedMonth.month) {
    final all = allEntries.toList();
    entries = all.where((e) => sameMonth(e.date, month)).toList();
    income = sum(entries, EntryKind.income);
    expense = sum(entries, EntryKind.expense);
    months = List.generate(6, (i) => DateTime(month.year, month.month - 5 + i));
    monthlyIncome = months
        .map(
          (m) => sum(all.where((e) => sameMonth(e.date, m)), EntryKind.income),
        )
        .toList();
    monthlyExpense = months
        .map(
          (m) => sum(all.where((e) => sameMonth(e.date, m)), EntryKind.expense),
        )
        .toList();
  }
  final DateTime month;
  late final List<MoneyEntry> entries;
  late final int income, expense;
  late final List<DateTime> months;
  late final List<int> monthlyIncome, monthlyExpense;
  int get net => income - expense;
  int get averageExpense =>
      (monthlyExpense.fold<int>(0, (a, b) => a + b) / 6).round();
  Map<int, int> categories(EntryKind kind) {
    final totals = <int, int>{};
    for (final entry in entries.where((e) => e.kind == kind)) {
      totals.update(
        entry.categoryId,
        (v) => v + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }
    return totals;
  }

  static bool sameMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;
  static int sum(Iterable<MoneyEntry> entries, EntryKind kind) => entries
      .where((e) => e.kind == kind)
      .fold(0, (value, entry) => value + entry.amount);
}
