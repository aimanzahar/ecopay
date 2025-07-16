import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/balance.dart';
import '../models/transaction.dart' as AppTransaction;
import '../models/user.dart';
import '../models/contribution.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print('DEBUG: DatabaseHelper._initDatabase - Initializing database');
    // Initialize the database factory for web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'ecopay.db');
    print('DEBUG: DatabaseHelper._initDatabase - Database path: $path');
    return await openDatabase(path, version: 3, onCreate: _createDatabase, onUpgrade: _onUpgrade);
  }

  Future<void> _createDatabase(Database db, int version) async {
    print('DEBUG: DatabaseHelper._createDatabase - Creating new database version: $version');
    await db.execute('''
      CREATE TABLE balance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId TEXT NOT NULL UNIQUE,
        merchantName TEXT NOT NULL,
        amount REAL NOT NULL,
        remainingBalance REAL NOT NULL,
        transactionDate TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        ecopay_opt_in INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        cost_per_unit REAL NOT NULL,
        unit_label TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE contributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        project_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        transaction_id TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (project_id) REFERENCES projects (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        target TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        achievement_id INTEGER NOT NULL,
        date_unlocked TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (achievement_id) REFERENCES achievements (id)
      )
    ''');

    // Insert initial balance
    await db.insert('balance', {
      'amount': 96.54,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('DEBUG: DatabaseHelper._onUpgrade - Upgrading from version $oldVersion to $newVersion');
    if (oldVersion < 2) {
      print('DEBUG: DatabaseHelper._onUpgrade - Applying migration for version < 2');
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transactionId TEXT NOT NULL UNIQUE,
          merchantName TEXT NOT NULL,
          amount REAL NOT NULL,
          remainingBalance REAL NOT NULL,
          transactionDate TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'completed',
          notes TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      print('DEBUG: DatabaseHelper._onUpgrade - Applying migration for version < 3');
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          ecopay_opt_in INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          cost_per_unit REAL NOT NULL,
          unit_label TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE contributions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          project_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          transaction_id TEXT,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (project_id) REFERENCES projects (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE achievements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          target TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE user_achievements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          achievement_id INTEGER NOT NULL,
          date_unlocked TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (achievement_id) REFERENCES achievements (id)
        )
      ''');
    }
  }

  Future<Balance> getBalance() async {
    print('DEBUG: DatabaseHelper.getBalance - Called');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('balance');

    if (maps.isNotEmpty) {
      final balance = Balance.fromMap(maps.first);
      print('DEBUG: DatabaseHelper.getBalance - Retrieved balance: ${balance.amount}');
      return balance;
    } else {
      // If no balance exists, create a default one
      print('DEBUG: DatabaseHelper.getBalance - No balance found, creating default');
      final newBalance = Balance(amount: 76.54, lastUpdated: DateTime.now());
      await insertBalance(newBalance);
      return newBalance;
    }
  }

  Future<void> insertBalance(Balance balance) async {
    final db = await database;
    await db.insert('balance', balance.toMap());
  }

  Future<void> updateBalance(Balance balance) async {
    final db = await database;
    await db.update(
      'balance',
      balance.toMap(),
      where: 'id = ?',
      whereArgs: [balance.id],
    );
  }

  Future<void> reloadBalance(double amount) async {
    final db = await database;
    final currentBalance = await getBalance();

    final updatedBalance = Balance(
      id: currentBalance.id,
      amount: currentBalance.amount + amount,
      lastUpdated: DateTime.now(),
    );

    await updateBalance(updatedBalance);
  }

  // Transaction methods
  Future<void> insertTransaction(AppTransaction.Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<AppTransaction.Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'transactionDate DESC',
    );
    return List.generate(maps.length, (i) {
      return AppTransaction.Transaction.fromMap(maps[i]);
    });
  }

  Future<AppTransaction.Transaction?> getTransactionById(String transactionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
    
    if (maps.isNotEmpty) {
      return AppTransaction.Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> processPayment(String merchantName, double amount) async {
    print('DEBUG: DatabaseHelper.processPayment - Starting payment process');
    print('DEBUG: Merchant: $merchantName, Amount: $amount');
    
    final db = await database;
    
    // Check if balance is sufficient
    final currentBalance = await getBalance();
    print('DEBUG: Current balance before payment: ${currentBalance.amount}');
    
    if (currentBalance.amount < amount) {
      print('DEBUG: Insufficient balance - payment failed');
      return false; // Insufficient balance
    }
    
    // Calculate new balance
    final newBalance = currentBalance.amount - amount;
    print('DEBUG: New balance after payment: $newBalance');
    
    // Generate transaction ID
    final transactionId = AppTransaction.Transaction.generateTransactionId();
    print('DEBUG: Generated transaction ID: $transactionId');
    
    // Create transaction record
    final transaction = AppTransaction.Transaction(
      transactionId: transactionId,
      merchantName: merchantName,
      amount: amount,
      remainingBalance: newBalance,
      transactionDate: DateTime.now(),
      status: 'completed',
    );
    
    // Use database transaction to ensure atomicity
    await db.transaction((txn) async {
      // Update balance
      await txn.update(
        'balance',
        {
          'amount': newBalance,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [currentBalance.id],
      );
      
      // Insert transaction record
      await txn.insert('transactions', transaction.toMap());
    });
    
    print('DEBUG: Payment processed successfully - balance updated to: $newBalance');
    return true;
  }

  Future<bool> hasInsufficientBalance(double amount) async {
    final currentBalance = await getBalance();
    return currentBalance.amount < amount;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // User methods
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    // Create a default user if none exists
    final defaultUser = User(id: 1, name: 'Default User', ecopayOptIn: false);
    await insertUser(defaultUser);
    return defaultUser;
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Contribution methods
  Future<void> insertContribution(Contribution contribution) async {
    final db = await database;
    await db.insert('contributions', contribution.toMap());
  }

  Future<List<Contribution>> getContributionsByUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contributions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return Contribution.fromMap(maps[i]);
    });
  }
}
