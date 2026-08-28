import 'package:flosy/features/home/presentation/widgets/transaction_category.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/model/transaction_model.dart';
import '../../../budget/data/model/budget_model.dart';
import 'db_factory_stub.dart' if (dart.library.html) 'db_factory_web.dart';

class DatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    return _database!;
  }

  Future<void> init() async {
    final dir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    final dbPath = kIsWeb ? 'flosy.db' : '${dir!.path}/flosy.db';
    _database = await openDatabaseWebCompatible(
      dbPath,
      // v7: TransactionModel stopped writing iconCodePoint/iconFontFamily/
      // iconFontPackage (icon is now resolved from `category` in the
      // presentation layer). Those Transactions columns were always
      // nullable, so old rows are untouched and new rows simply leave
      // them NULL — no destructive migration needed, nothing is
      // dropped or recreated (requirement: never blindly wipe user data).
      // v8: Added createdBy column to Transactions for family tracking.
      version: 8,
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
            iconFontPackage TEXT,
            createdBy TEXT
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
          final result = await db.rawQuery('PRAGMA table_info(Budgets)');
          final columnNames = result
              .map((col) => col['name'] as String)
              .toList();

          if (columnNames.contains('limit_amount') &&
              !columnNames.contains('limitAmount')) {
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

            await db.execute('''
              INSERT INTO Budgets (id, category, limitAmount, period, startDate, endDate)
              SELECT id, category, limit_amount, period, startDate, endDate FROM Budgets_old
            ''');

            await db.execute('DROP TABLE Budgets_old');
          } else if (!columnNames.contains('limitAmount')) {
            await db.execute('ALTER TABLE Budgets ADD COLUMN limitAmount REAL');
          }

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
        // v7 is intentionally a no-op migration for Transactions:
        // iconCodePoint/iconFontFamily/iconFontPackage are left in place
        // (still nullable, still harmless) rather than dropped, since
        // SQLite column drops are version-fragile and unnecessary here —
        // the app just stops writing/reading them from this version on.
        
        if (oldVersion < 8) {
          final result = await db.rawQuery('PRAGMA table_info(Transactions)');
          final columnNames = result
              .map((col) => col['name'] as String)
              .toList();

          if (!columnNames.contains('createdBy')) {
            await db.execute(
              'ALTER TABLE Transactions ADD COLUMN createdBy TEXT',
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

  /// Handles AI-parsed voice/text transactions. Category may arrive as an
  /// English id ("food"), an Arabic word ("اكل", "سوبر ماركت"), or something
  /// unrecognized — it is normalized to a canonical TransactionCategory id
  /// before saving so it renders and groups (getSpentByCategory, budgets)
  /// consistently with manually-added transactions. No IconData is ever
  /// created or stored here anymore; icons are resolved purely from the
  /// category id in the presentation layer.
  Future<void> processAndSaveAiResponse(Map<String, dynamic> aiJson) async {
    try {
      final txType = TransactionType.values[aiJson['type'] ?? 1];
      final categoryId = TransactionCategory.normalizeForStorage(
        aiJson['category'] as String?,
      );

      final newTransaction = TransactionModel(
        title: aiJson['title'] ?? 'معاملة صوتية',
        amount: (aiJson['amount'] as num).toDouble(),
        type: txType,
        date: DateTime.now(),
        category: categoryId,
      );
      final id = await addTransaction(newTransaction);

      debugPrint('✅ تم التخزين بنجاح! رقم المعاملة: $id');
    } catch (e) {
      debugPrint('❌ خطأ أثناء معالجة أو تخزين البيانات: $e');
    }
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
  // Out of scope for this refactor (BudgetModel wasn't provided and still
  // owns its own icon columns) — left untouched.

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
    return (result.first['totalBalance'] as num?)?.toDouble() ?? 0;
  }
}

// simple global instance
final dbService = DatabaseService();
