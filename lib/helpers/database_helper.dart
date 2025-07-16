import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/balance.dart';
import '../models/transaction.dart' as AppTransaction;

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
    // Initialize the database factory for web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'ecopay.db');
    return await openDatabase(path, version: 2, onCreate: _createDatabase, onUpgrade: _onUpgrade);
  }

  Future<void> _createDatabase(Database db, int version) async {
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

    // Insert initial balance
    await db.insert('balance', {
      'amount': 96.54,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
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
}
