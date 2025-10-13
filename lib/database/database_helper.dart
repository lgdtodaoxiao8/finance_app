import 'dart:io';

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
    print('DB path: $path');
    print('DB exists: ${await File(path).exists()}');
  }

  Future deleteAll() async {
    final dbPath = await getDatabasesPath();
    const String dbName = 'finance.db';
    final path = join(dbPath + dbName);
    await deleteDatabase(path);
    print('Deleted!!!!');
  }

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance.db');

    // Закрываем база, если открыта
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        print('Database closed and cache cleared.');
      }
    } catch (e) {
      print('Error closing DB: $e');
    }

    // Удаляем файл
    try {
      await deleteDatabase(path);
      print('deleteDatabase(path) called for: $path');
      // дополнительная проверка
      final exists = await File(path).exists();
      print('File exists after deleteDatabase? $exists');
      if (exists) {
        // принудительное удаление через File API
        await File(path).delete();
        print('File deleted via File.delete()');
      }
    } catch (e) {
      print('Error deleting DB file: $e');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE currencies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT,
      symbol TEXT,
      rate_to_base REAL
    )
    ''');

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

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
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
             c.icon_code_point as category_icon_code,
             cur.code as currency_code
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      LEFT JOIN accounts a_des ON t.account_destination_id = a_des.id
      JOIN categories c ON t.category_id = c.id
      JOIN currencies cur ON t.currency_id = cur.id
      ORDER BY t.date ASC
    ''');
  }

  Future<void> deleteTable() async {
    final db = await instance.database;
    await db.execute('DROP TABLE IF EXISTS accounts');
  }
}
