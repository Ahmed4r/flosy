import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/model/transaction_model.dart';
import '../../../budget/data/model/budget_model.dart';

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
      version: 6, // Increment version
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
        await db.execute('''
          CREATE TABLE Budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            limitAmount REAL,
            period TEXT,
            startDate INTEGER,
            endDate INTEGER,
            iconCodePoint INTEGER,
            iconFontFamily TEXT,
            iconFontPackage TEXT,
            notifyAtThreshold INTEGER DEFAULT 1,
            notifyPercent REAL DEFAULT 80,
            isRecurring INTEGER DEFAULT 1,
            createdAt INTEGER
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE Transactions ADD COLUMN iconFontPackage TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Budgets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT UNIQUE,
              limitAmount REAL,
              iconCodePoint INTEGER,
              iconFontFamily TEXT,
              iconFontPackage TEXT,
              notifyAtThreshold INTEGER DEFAULT 1,
              notifyPercent REAL DEFAULT 80,
              isRecurring INTEGER DEFAULT 1,
              createdAt INTEGER
            )
          ''');
        }
        if (oldVersion < 5) {
          // Add missing columns to Budgets table
          final result = await db.rawQuery('PRAGMA table_info(Budgets)');
          final columnNames = result
              .map((col) => col['name'] as String)
              .toList();

          if (!columnNames.contains('iconCodePoint')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN iconCodePoint INTEGER',
            );
          }
          if (!columnNames.contains('iconFontFamily')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN iconFontFamily TEXT',
            );
          }
          if (!columnNames.contains('iconFontPackage')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN iconFontPackage TEXT',
            );
          }
          if (!columnNames.contains('notifyAtThreshold')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN notifyAtThreshold INTEGER DEFAULT 1',
            );
          }
          if (!columnNames.contains('notifyPercent')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN notifyPercent REAL DEFAULT 80',
            );
          }
          if (!columnNames.contains('isRecurring')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN isRecurring INTEGER DEFAULT 1',
            );
          }
        }
        if (oldVersion < 6) {
          // Check if column exists and rename it or add it
          final result = await db.rawQuery('PRAGMA table_info(Budgets)');
          final columnNames = result
              .map((col) => col['name'] as String)
              .toList();

          // Check if we have the old column name
          if (columnNames.contains('limit_amount') &&
              !columnNames.contains('limitAmount')) {
            // Rename the column by recreating the table
            await db.execute('ALTER TABLE Budgets RENAME TO Budgets_old');

            await db.execute('''
              CREATE TABLE Budgets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT,
                limitAmount REAL,
                period TEXT,
                startDate INTEGER,
                endDate INTEGER,
                iconCodePoint INTEGER,
                iconFontFamily TEXT,
                iconFontPackage TEXT,
                notifyAtThreshold INTEGER DEFAULT 1,
                notifyPercent REAL DEFAULT 80,
                isRecurring INTEGER DEFAULT 1,
                createdAt INTEGER
              )
            ''');

            // Copy data from old table
            await db.execute('''
              INSERT INTO Budgets (id, category, limitAmount, period, startDate, endDate)
              SELECT id, category, limit_amount, period, startDate, endDate FROM Budgets_old
            ''');

            await db.execute('DROP TABLE Budgets_old');
          } else if (!columnNames.contains('limitAmount')) {
            // Just add the column if it doesn't exist
            await db.execute('ALTER TABLE Budgets ADD COLUMN limitAmount REAL');
          }

          // Add other missing columns
          if (!columnNames.contains('iconCodePoint')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN iconCodePoint INTEGER',
            );
          }
          if (!columnNames.contains('iconFontFamily')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN iconFontFamily TEXT',
            );
          }
          if (!columnNames.contains('iconFontPackage')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN iconFontPackage TEXT',
            );
          }
          if (!columnNames.contains('notifyAtThreshold')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN notifyAtThreshold INTEGER DEFAULT 1',
            );
          }
          if (!columnNames.contains('notifyPercent')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN notifyPercent REAL DEFAULT 80',
            );
          }
          if (!columnNames.contains('isRecurring')) {
            await db.execute(
              'ALTER TABLE Budgets ADD COLUMN isRecurring INTEGER DEFAULT 1',
            );
          }
        }
      },
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  // ─── TRANSACTIONS ────────────────────────────────────

  Future<int> addTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.insert(
      'Transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query('Transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

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

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('Transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('Transactions');
  }

  /// Get total spent per category for a given month
  Future<Map<String, double>> getSpentByCategory(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final maps = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM Transactions
      WHERE type = 1 AND date >= ? AND date <= ?
      GROUP BY category
    ''',
      [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch],
    );

    final result = <String, double>{};
    for (final row in maps) {
      result[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return result;
  }

  // ─── BUDGETS ─────────────────────────────────────────

  Future<int> addBudget(BudgetModel budget) async {
    final db = await database;
    return await db.insert(
      'Budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BudgetModel>> getBudgets() async {
    final db = await database;
    final maps = await db.query('Budgets', orderBy: 'createdAt DESC');
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    if (budget.id == null) return;
    final db = await database;
    await db.update(
      'Budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    await db.delete('Budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalBalance() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(CASE WHEN type = 0 THEN amount ELSE -amount END) as totalBalance FROM Transactions',
    );
    return (result.first['totalBalance'] as num?)?.toDouble() ?? 0.0;
  }
}

// simple global instance
final dbService = DatabaseService();
