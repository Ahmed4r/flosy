import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../model/transaction_model.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    return _database!;
  }

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      '${dir.path}/flosy.db',
      version: 2, // <-- bump version
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE Transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            type INTEGER,
            date INTEGER,
            category TEXT,
            iconCodePoint INTEGER,
            iconFontFamily TEXT,
            iconFontPackage TEXT
          )
          ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE Transactions ADD COLUMN iconFontPackage TEXT',
          );
        }
      },
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  // INSERT
  Future<int> addTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.insert(
      'Transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ ALL
  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query('Transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  // UPDATE
  Future<void> updateTransaction(TransactionModel tx) async {
    if (tx.id == null) return;
    final db = await database;
    await db.update(
      'Transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  // DELETE
  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('Transactions', where: 'id = ?', whereArgs: [id]);
  }
}

// simple global instance
final dbService = DatabaseService();
