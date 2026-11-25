import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/finance_repository.dart';
import '../domain/models.dart';

/// Copies a receipt only on explicit Save, and cleans up if SQLite rejects it.
Future<void> persistEntry(
  FinanceRepository repository,
  MoneyEntry entry, {
  String? newReceiptPath,
}) async {
  String? copiedPath;
  try {
    var receiptPath = entry.receiptPath;
    if (newReceiptPath != null) {
      final directory = Directory(
        p.join((await getApplicationDocumentsDirectory()).path, 'receipts'),
      );
      await directory.create(recursive: true);
      final extension = p.extension(newReceiptPath).isEmpty
          ? '.jpg'
          : p.extension(newReceiptPath);
      copiedPath = p.join(
        directory.path,
        '${DateTime.now().microsecondsSinceEpoch}$extension',
      );
      await File(newReceiptPath).copy(copiedPath);
      receiptPath = copiedPath;
    }
    await repository.saveEntry(
      MoneyEntry(
        id: entry.id,
        kind: entry.kind,
        amount: entry.amount,
        categoryId: entry.categoryId,
        date: entry.date,
        merchant: entry.merchant,
        note: entry.note,
        receiptPath: receiptPath,
      ),
    );
  } catch (_) {
    if (copiedPath != null) {
      try {
        await File(copiedPath).delete();
      } catch (_) {}
    }
    rethrow;
  }
}
