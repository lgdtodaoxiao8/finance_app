import 'package:finance_app/ui/screens/new_transaction.dart';
import 'package:finance_app/ui/screens/qwen_transactions_screen.dart';
import 'package:finance_app/ui/screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// ---------------- МОДЕЛИ ----------------

class Account {
  final int? id;
  final String name;
  final int currencyId;

  Account({this.id, required this.name, required this.currencyId});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'currency_id': currencyId,
  };

  factory Account.fromMap(Map<String, dynamic> map) =>
      Account(id: map['id'], name: map['name'], currencyId: map['currency_id']);
}

class Category {
  final int? id;
  final String name;
  final String type; // income / expense

  Category({this.id, required this.name, required this.type});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'type': type};

  factory Category.fromMap(Map<String, dynamic> map) =>
      Category(id: map['id'], name: map['name'], type: map['type']);
}

class Currency {
  final int? id;
  final String code;
  final String symbol;
  final double rateToBase;

  Currency({
    this.id,
    required this.code,
    required this.symbol,
    required this.rateToBase,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'code': code,
    'symbol': symbol,
    'rate_to_base': rateToBase,
  };

  factory Currency.fromMap(Map<String, dynamic> map) => Currency(
    id: map['id'],
    code: map['code'],
    symbol: map['symbol'],
    rateToBase: map['rate_to_base'],
  );
}

class FinanceTransaction {
  final int? id;
  final int accountId;
  final int categoryId;
  final int currencyId;
  final double amount;
  final String date;
  final String note;
  final String type; // income / expense

  FinanceTransaction({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.currencyId,
    required this.amount,
    required this.date,
    required this.note,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'account_id': accountId,
    'category_id': categoryId,
    'currency_id': currencyId,
    'amount': amount,
    'date': date,
    'note': note,
    'type': type,
  };

  factory FinanceTransaction.fromMap(Map<String, dynamic> map) =>
      FinanceTransaction(
        id: map['id'],
        accountId: map['account_id'],
        categoryId: map['category_id'],
        currencyId: map['currency_id'],
        amount: map['amount'],
        date: map['date'],
        note: map['note'],
        type: map['type'],
      );
}

/// ---------------- DATABASE HELPER ----------------

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
      FOREIGN KEY (currency_id) REFERENCES currencies (id)
    )
    ''');

    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      type TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER,
      category_id INTEGER,
      currency_id INTEGER,
      amount REAL,
      date TEXT,
      note TEXT,
      type TEXT,
      FOREIGN KEY (account_id) REFERENCES accounts (id),
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

  Future<List<Map<String, dynamic>>> getTransactionsWithDetails() async {
    final db = await instance.database;
    return db.rawQuery('''
      SELECT t.id, t.amount, t.date, t.note, t.type,
             a.name as account_name,
             c.name as category_name,
             cur.code as currency_code
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      JOIN categories c ON t.category_id = c.id
      JOIN currencies cur ON t.currency_id = cur.id
      ORDER BY t.date DESC
    ''');
  }
}

/// ---------------- UI ----------------

void main() {
  runApp(const MaterialApp(home: FinanceApp()));
}

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  final db = DatabaseHelper.instance;
  List<Map<String, dynamic>> transactions = [];

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seedData();
    _refreshTransactions();
  }

  Future<void> _seedData() async {
    // Добавим валюту, счёт и категорию, если пусто
    final currencies = await db.getAll("currencies");
    if (currencies.isEmpty) {
      await db.insert("currencies", {
        "code": "KZT",
        "symbol": "₸",
        "rate_to_base": 1.0,
      });
    }
    final accounts = await db.getAll("accounts");
    if (accounts.isEmpty) {
      await db.insert("accounts", {"name": "Наличные", "currency_id": 1});
    }
    final categories = await db.getAll("categories");
    if (categories.isEmpty) {
      await db.insert("categories", {"name": "Еда", "type": "expense"});
      await db.insert("categories", {"name": "Зарплата", "type": "income"});
    }
  }

  Future<void> _refreshTransactions() async {
    final data = await db.getTransactionsWithDetails();
    setState(() {
      transactions = data;
    });
  }

  Future<void> _addTransaction() async {
    if (_amountController.text.isEmpty) return;

    await db.insert("transactions", {
      "account_id": 1,
      "category_id": 1,
      "currency_id": 1,
      "amount": double.parse(_amountController.text),
      "date": DateTime.now().toIso8601String(),
      "note": _noteController.text,
      "type": "expense",
    });

    _amountController.clear();
    _noteController.clear();
    _refreshTransactions();
  }

  late Widget content;

  @override
  Widget build(BuildContext context) {
    if (indexPage == 1) {
      content = const NewTransaction();

      // content = Column(
      //   children: [
      //     // форма
      //     Padding(
      //       padding: const EdgeInsets.all(28.0),
      //       child: Column(
      //         children: [
      //           TextField(
      //             controller: _amountController,
      //             decoration: InputDecoration(labelText: "Amount"),
      //             keyboardType: TextInputType.number,
      //           ),
      //           TextField(
      //             controller: _noteController,
      //             decoration: InputDecoration(labelText: "Note"),
      //           ),
      //           ElevatedButton(
      //             onPressed: _addTransaction,
      //             child: Text("Add Transaction"),
      //           ),
      //         ],
      //       ),
      //     ),

      //     // список транзакций
      //   ],
      // );
    }
    if (indexPage == 0) {
      content = ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, i) {
          final t = transactions[i];
          return ListTile(
            title: Text(
              "${t['category_name']} - ${t['amount']} ${t['currency_code']}",
            ),
            subtitle: Text(
              "${t['date']} | ${t['account_name']} | ${t['note']}",
            ),
            trailing: Text(t['type']),
          );
        },
      );
    }

    // return Scaffold(
    //   appBar: AppBar(title: const Text("Finance MVP (Multi-Table)")),
    //   body: content,
    //   bottomNavigationBar: BottomNavigationBar(
    //     currentIndex: indexPage,
    //     onTap: (value) {
    //       setState(() {
    //         indexPage = value;
    //       });
    //     },
    //     enableFeedback: true,
    //     items: [
    //       const BottomNavigationBarItem(
    //         icon: Icon(Icons.home_rounded),
    //         label: 'Home',
    //       ),
    //       const BottomNavigationBarItem(
    //         icon: Icon(Icons.add_rounded),
    //         label: 'Add Transaction',
    //       ),
    //     ],
    //   ),
    // );
    // return TransactionsScreen(transactions);
    return QwenTransactionsScreen(
      transactions: transactions,
    );
  }

  int indexPage = 0;
}
