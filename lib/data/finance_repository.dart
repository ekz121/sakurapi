import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/models.dart';

class FinanceRepository {
  FinanceRepository({DatabaseFactory? factory, this.databasePath})
    : _factory = factory ?? databaseFactory;
  final DatabaseFactory _factory;
  final String? databasePath;
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final path =
        databasePath ??
        p.join(await _factory.getDatabasesPath(), 'sakurapi.db');
    _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'name TEXT NOT NULL COLLATE NOCASE, kind TEXT NOT NULL CHECK(kind IN (\'expense\',\'income\')), '
            'color INTEGER NOT NULL, symbol TEXT NOT NULL, UNIQUE(name,kind))',
          );
          await db.execute(
            'CREATE TABLE entries (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'kind TEXT NOT NULL CHECK(kind IN (\'expense\',\'income\')), '
            'amount INTEGER NOT NULL CHECK(amount > 0 AND amount <= 999999999999), '
            'category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT, '
            'date TEXT NOT NULL, merchant TEXT NOT NULL DEFAULT \'\', '
            'note TEXT NOT NULL DEFAULT \'\', receipt_path TEXT)',
          );
          await db.execute('CREATE INDEX entries_date ON entries(date)');
          await db.execute(
            'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.insert('settings', {'key': 'opening_balance', 'value': '0'});
          for (final row in [
            ['Makan & minum', 'expense', 0xFFF09B55, 'food'],
            ['Transportasi', 'expense', 0xFF7691D5, 'transport'],
            ['Belanja', 'expense', 0xFFB28AD0, 'shopping'],
            ['Kuliah', 'expense', 0xFF75A89B, 'study'],
            ['Lainnya', 'expense', 0xFF8C929D, 'other'],
            ['Uang saku', 'income', 0xFF317E70, 'wallet'],
            ['Gaji', 'income', 0xFF6887AB, 'work'],
            ['Lainnya', 'income', 0xFF8C929D, 'other'],
          ]) {
            await db.insert('categories', {
              'name': row[0],
              'kind': row[1],
              'color': row[2],
              'symbol': row[3],
            });
          }
        },
      ),
    );
    return _db!;
  }

  Future<List<MoneyCategory>> categories() async =>
      (await (await database).query(
        'categories',
        orderBy: 'kind, name',
      )).map(MoneyCategory.fromMap).toList();
  Future<List<MoneyEntry>> entries() async => (await (await database).query(
    'entries',
    orderBy: 'date DESC, id DESC',
  )).map(MoneyEntry.fromMap).toList();
  Future<int> openingBalance() async {
    final rows = await (await database).query(
      'settings',
      where: 'key = ?',
      whereArgs: ['opening_balance'],
    );
    return int.parse(rows.first['value'] as String);
  }

  Future<void> setOpeningBalance(int amount) async {
    if (amount.abs() > 999999999999) throw ArgumentError('Saldo terlalu besar');
    await (await database).update(
      'settings',
      {'value': '$amount'},
      where: 'key = ?',
      whereArgs: ['opening_balance'],
    );
  }

  Future<void> saveEntry(MoneyEntry entry) async {
    if (entry.amount <= 0 || entry.amount > 999999999999) {
      throw ArgumentError('Nominal tidak valid');
    }
    await (await database).transaction((txn) async {
      final category = await txn.query(
        'categories',
        where: 'id = ?',
        whereArgs: [entry.categoryId],
      );
      if (category.isEmpty || category.first['kind'] != entry.kind.name) {
        throw ArgumentError('Kategori tidak sesuai jenis transaksi');
      }
      if (entry.id == null) {
        await txn.insert('entries', entry.toMap());
      } else {
        final count = await txn.update(
          'entries',
          entry.toMap(),
          where: 'id = ?',
          whereArgs: [entry.id],
        );
        if (count != 1) throw StateError('Transaksi sudah tidak tersedia');
      }
    });
  }

  Future<void> deleteEntry(int id) async =>
      (await database).delete('entries', where: 'id = ?', whereArgs: [id]);

  Future<void> saveCategory({
    int? id,
    required String name,
    required EntryKind kind,
    required int color,
    required String symbol,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Nama kategori wajib diisi');
    final db = await database;
    await db.transaction((txn) async {
      final duplicate = await txn.query(
        'categories',
        where: 'name = ? COLLATE NOCASE AND kind = ? AND id != ?',
        whereArgs: [name.trim(), kind.name, id ?? -1],
      );
      if (duplicate.isNotEmpty) throw ArgumentError('Nama kategori sudah ada');
      if (id != null) {
        final used = await txn.query(
          'entries',
          where: 'category_id = ? AND kind != ?',
          whereArgs: [id, kind.name],
          limit: 1,
        );
        if (used.isNotEmpty) {
          throw ArgumentError('Jenis kategori yang dipakai tidak dapat diubah');
        }
      }
      final row = {
        'name': name.trim(),
        'kind': kind.name,
        'color': color,
        'symbol': symbol,
      };
      if (id == null) {
        await txn.insert('categories', row);
      } else {
        await txn.update('categories', row, where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  Future<void> deleteCategory(int id) async {
    await (await database).transaction((txn) async {
      final used = await txn.query(
        'entries',
        where: 'category_id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (used.isNotEmpty) {
        throw ArgumentError(
          'Kategori masih digunakan oleh transaksi. Ubah kategori transaksi tersebut terlebih dahulu.',
        );
      }
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
