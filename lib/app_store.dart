import 'package:flutter/foundation.dart';
import 'data/finance_repository.dart';
import 'domain/models.dart';

class AppStore extends ChangeNotifier {
  AppStore(this.repository);
  final FinanceRepository repository;
  List<MoneyEntry> entries = [];
  List<MoneyCategory> categories = [];
  int openingBalance = 0;
  bool loading = true;
  String? error;
  Future<void> refresh() async {
    try {
      final nextCategories = await repository.categories();
      final nextEntries = await repository.entries();
      final nextBalance = await repository.openingBalance();
      categories = nextCategories;
      entries = nextEntries;
      openingBalance = nextBalance;
      error = null;
    } catch (_) {
      error = 'Data lokal belum dapat dibuka. Coba lagi.';
    }
    loading = false;
    notifyListeners();
  }

  MoneyCategory category(int id) => categories.firstWhere((c) => c.id == id);
  List<MoneyEntry> inMonth(DateTime month) => entries
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .toList();
  int total(Iterable<MoneyEntry> list, EntryKind kind) =>
      list.where((e) => e.kind == kind).fold(0, (sum, e) => sum + e.amount);
  int get balance =>
      openingBalance +
      total(entries, EntryKind.income) -
      total(entries, EntryKind.expense);
}
