enum EntryKind { expense, income }

class MoneyCategory {
  const MoneyCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.color,
    required this.symbol,
  });
  final int id;
  final String name;
  final EntryKind kind;
  final int color;
  final String symbol;
  factory MoneyCategory.fromMap(Map<String, Object?> row) => MoneyCategory(
    id: row['id'] as int,
    name: row['name'] as String,
    kind: EntryKind.values.byName(row['kind'] as String),
    color: row['color'] as int,
    symbol: row['symbol'] as String,
  );
}

class MoneyEntry {
  const MoneyEntry({
    this.id,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.merchant = '',
    this.note = '',
    this.receiptPath,
  });
  final int? id;
  final EntryKind kind;

  /// Whole Indonesian Rupiah, never floating point.
  final int amount;
  final int categoryId;
  final DateTime date;
  final String merchant;
  final String note;
  final String? receiptPath;
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'kind': kind.name,
    'amount': amount,
    'category_id': categoryId,
    'date': dateKey(date),
    'merchant': merchant.trim(),
    'note': note.trim(),
    'receipt_path': receiptPath,
  };
  factory MoneyEntry.fromMap(Map<String, Object?> row) => MoneyEntry(
    id: row['id'] as int,
    kind: EntryKind.values.byName(row['kind'] as String),
    amount: row['amount'] as int,
    categoryId: row['category_id'] as int,
    date: DateTime.parse(row['date'] as String),
    merchant: row['merchant'] as String,
    note: row['note'] as String,
    receiptPath: row['receipt_path'] as String?,
  );
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class ReceiptDraft {
  const ReceiptDraft({
    required this.rawText,
    this.total,
    this.date,
    this.merchant,
    this.imagePath,
  });
  final String rawText;
  final int? total;
  final DateTime? date;
  final String? merchant;
  final String? imagePath;
}
