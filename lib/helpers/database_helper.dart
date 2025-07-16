import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/balance.dart';

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
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE balance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Insert initial balance
    await db.insert('balance', {
      'amount': 76.54,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<Balance> getBalance() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('balance');

    if (maps.isNotEmpty) {
      return Balance.fromMap(maps.first);
    } else {
      // If no balance exists, create a default one
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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
