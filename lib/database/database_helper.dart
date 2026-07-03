import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("finance.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  void debugDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance.db');
    debugPrint('DB path: $path');
    debugPrint('DB exists: ${await File(path).exists()}');
  }

  Future deleteAll() async {
    final dbPath = await getDatabasesPath();
    const String dbName = 'finance.db';
    final path = join(dbPath + dbName);
    await deleteDatabase(path);
    debugPrint('Deleted!!!!');
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance.db');

    // Закрываем база, если открыта
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        debugPrint('Database closed and cache cleared.');
      }
    } catch (e) {
      debugPrint('Error closing DB: $e');
    }

    // Удаляем файл
    try {
      await deleteDatabase(path);
      debugPrint('deleteDatabase(path) called for: $path');
      // дополнительная проверка
      final exists = await File(path).exists();
      debugPrint('File exists after deleteDatabase? $exists');
      if (exists) {
        // принудительное удаление через File API
        await File(path).delete();
        debugPrint('File deleted via File.delete()');
      }
    } catch (e) {
      debugPrint('Error deleting DB file: $e');
    }
  }

  Future<void> deleteTable(String tableName) async {
    try {
      // Получаем соединение с базой данных
      final db =
          await database; // Убедитесь, что у вас есть доступ к базе данных

      // Проверяем, существует ли таблица перед удалением
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );

      if (tables.isNotEmpty) {
        // Выполняем удаление таблицы
        await db.execute('DROP TABLE IF EXISTS $tableName');
        debugPrint('Table $tableName successfully deleted');
      } else {
        debugPrint('Table $tableName does not exist, no action taken');
      }
    } catch (e) {
      debugPrint('Error deleting table $tableName: $e');
      rethrow; // Пробрасываем ошибку дальше для обработки в вызывающем коде
    }
  }

  Future<List<Map<String, dynamic>>> getCurrenciesWithRate() async {
    final db = await instance.database;

    return db.rawQuery('''
    SELECT * FROM currencies WHERE rate_to_base IS NOT NULL
    ''');
  }

  Future<List<Map<String, dynamic>>> getCurrenciesWithNullRate() async {
    final db = await instance.database;

    return db.rawQuery('''
    SELECT * FROM currencies WHERE rate_to_base IS NULL
    ''');
  }

  Future<List<Map<String, dynamic>>> getDefaultCurrency() async {
    final db = await instance.database;

    return db.rawQuery('''
    SELECT * FROM currencies WHERE is_base = 1 LIMIT 1
    ''');
  }

  Future<List<Map<String, dynamic>>> getCurrencyRate(int id) async {
    final db = await instance.database;

    return db.query(
      'currencies',
      columns: ['rate_to_base'],
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllCurrencies() async {
    final db = await instance.database;

    return db.rawQuery('''
    SELECT * FROM currencies
    ''');
  }

  Future<String> getCurrencySymbol(int id) async {
    final db = await instance.database;

    final rows = await db.query(
      'currencies',
      columns: ['symbol'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return '';

    return (rows.first['symbol'] as String?) ?? '';
  }

  Future makeCurrencyBase(int newId) async {
    final db = await instance.database;

    final oldBaseCurrency = await getDefaultCurrency();

    if (oldBaseCurrency.isEmpty) {
      await db.update(
        'currencies',
        {'rate_to_base': 1.0},
        where: 'id = ?',
        whereArgs: [newId],
      );
    } else {
      final double multiplier = 1.0 / oldBaseCurrency.first['rate_to_base'];

      await db.rawUpdate(
        '''
    UPDATE currencies 
    SET rate_to_base = rate_to_base * ? 
    WHERE rate_to_base IS NOT NULL
    ''',
        [multiplier],
      );
    }

    final batch = db.batch();

    batch.update(
      'currencies',
      {'is_base': 0},
    );
    batch.update(
      'currencies',
      {'is_base': 1},
      where: 'id = ?',
      whereArgs: [newId],
    );

    await batch.commit(noResult: true);
  }

  Future setNewRate(double rate, int id) async {
    final db = await instance.database;

    await db.update(
      'currencies',
      {'rate_to_base': rate},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE currencies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      code TEXT,
      symbol TEXT,
      rate_to_base REAL,
      is_base INTEGER CHECK (is_base IN (0, 1)) NOT NULL DEFAULT 0
    )
    ''');
    //name
    //rate to base null
    await db.execute('''
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      currency_id INTEGER,
      icon_code_point INTEGER,
      FOREIGN KEY (currency_id) REFERENCES currencies (id)
    )
    ''');

    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      color INTEGER,
      icon_color INTEGER,
      icon_code_point INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER,
      account_destination_id INTEGER,
      category_id INTEGER,
      currency_id INTEGER,
      amount REAL,
      date TEXT,
      note TEXT,
      type TEXT,
      is_canceled INTEGER CHECK (is_canceled IN (0, 1)),
      FOREIGN KEY (account_id) REFERENCES accounts (id),
      FOREIGN KEY (account_destination_id) REFERENCES accounts (id),
      FOREIGN KEY (category_id) REFERENCES categories (id),
      FOREIGN KEY (currency_id) REFERENCES currencies (id)
    )
    ''');
  }

  Future<int?> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    final id = await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await instance.database;
    return db.query(table);
  }

  //Future<List<Map<String, dynamic>>> getAccounts()

  Future<List<Map<String, dynamic>>> getTransactionsWithDetails() async {
    final db = await instance.database;
    return db.rawQuery('''
      SELECT t.id, t.amount, t.date, t.note, t.type, t.is_canceled,
             a.name as account_name, a.icon_code_point as account_icon_code,
             a_des.name as account_destination_name,
             a_des.icon_code_point as account_destination_icon_code,
             c.name as category_name,
             c.color as category_color,
             c.icon_color as category_icon_color,
             c.icon_code_point as category_icon_code,
             cur.name as currency_name,
             cur.code as currency_code
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      LEFT JOIN accounts a_des ON t.account_destination_id = a_des.id
      JOIN categories c ON t.category_id = c.id
      JOIN currencies cur ON t.currency_id = cur.id
      ORDER BY t.date ASC
    ''');
  }
}
