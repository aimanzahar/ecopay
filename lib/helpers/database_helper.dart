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

  Future<Set<String>> getColumns(Database db, String tableName) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    return result.map((row) => row['name'] as String).toSet();
  }

  Future<void> ensureUserSchema(Database db) async {
    await addColumnIfNotExists(db, 'users', 'username', 'TEXT');
    await addColumnIfNotExists(db, 'users', 'email', 'TEXT');
    await addColumnIfNotExists(db, 'users', 'total_points', 'INTEGER', defaultValue: '0');
    await addColumnIfNotExists(db, 'users', 'level', 'INTEGER', defaultValue: '1');
    await addColumnIfNotExists(db, 'users', 'badges_earned', 'TEXT', defaultValue: "''");
    await addColumnIfNotExists(db, 'users', 'created_at', 'TEXT');
    await addColumnIfNotExists(db, 'users', 'last_active', 'TEXT');
  }


  Future<void> addColumnIfNotExists(Database db, String table, String column, String type, {String? defaultValue}) async {
    final columns = await getColumns(db, table);
    if (!columns.contains(column)) {
      final def = (defaultValue != null) ? "DEFAULT $defaultValue" : "";
      await db.execute("ALTER TABLE $table ADD COLUMN $column $type $def");
      print('DEBUG: Column $column added to $table');
    } else {
      print('DEBUG: Column $column already exists in $table');
    }
  }


  Future<Database> _initDatabase() async {
    print('DEBUG: DatabaseHelper._initDatabase - Initializing database');
    // Initialize the database factory for web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'ecopay.db');
    print('DEBUG: DatabaseHelper._initDatabase - Database path: $path');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    print(
      'DEBUG: DatabaseHelper._createDatabase - Creating new database version: $version',
    );
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

    // New gamification tables
    await db.execute('''
      CREATE TABLE user_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        points_earned INTEGER NOT NULL,
        points_source TEXT NOT NULL,
        transaction_id TEXT,
        contribution_id INTEGER,
        achievement_id INTEGER,
        challenge_id INTEGER,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (contribution_id) REFERENCES contributions (id),
        FOREIGN KEY (achievement_id) REFERENCES achievements (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        challenge_type TEXT NOT NULL,
        target_value INTEGER NOT NULL,
        target_unit TEXT NOT NULL,
        points_reward INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE challenge_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        challenge_id INTEGER NOT NULL,
        current_progress INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completion_date TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (challenge_id) REFERENCES challenges (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE leaderboard_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        leaderboard_type TEXT NOT NULL,
        score REAL NOT NULL,
        ranking INTEGER NOT NULL,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        notification_type TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        related_id INTEGER,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Insert initial balance
    await db.insert('balance', {
      'amount': 96.54,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print(
      'DEBUG: DatabaseHelper._onUpgrade - Upgrading from version $oldVersion to $newVersion',
    );
    if (oldVersion < 2) {
      print(
        'DEBUG: DatabaseHelper._onUpgrade - Applying migration for version < 2',
      );
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
      print(
        'DEBUG: DatabaseHelper._onUpgrade - Applying migration for version < 3',
      );
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          ecopay_opt_in INTEGER NOT NULL DEFAULT 0,
          total_points INTEGER NOT NULL DEFAULT 0,
          level INTEGER NOT NULL DEFAULT 1,
          badges_earned TEXT DEFAULT '',
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          last_active TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
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

    if (oldVersion < 4) {
      print(
        'DEBUG: DatabaseHelper._onUpgrade - Applying migration for version < 4',
      );

      // Check current table structure before migration
      final tableInfo = await db.rawQuery("PRAGMA table_info(users)");
      print('DEBUG: Current users table structure: $tableInfo');

      try {
        // Add new columns to users table
        print('DEBUG: Adding total_points column');
        await db.execute(
          'ALTER TABLE users ADD COLUMN total_points INTEGER NOT NULL DEFAULT 0',
        );

        print('DEBUG: Adding level column');
        await db.execute(
          'ALTER TABLE users ADD COLUMN level INTEGER NOT NULL DEFAULT 1',
        );

        print('DEBUG: Adding badges_earned column');
        await db.execute(
          'ALTER TABLE users ADD COLUMN badges_earned TEXT DEFAULT ""',
        );

        // FIXED: Multi-step approach for adding timestamp columns
        print('DEBUG: Adding created_at column using multi-step approach');
        try {
          // Step 1: Add column as nullable first
          await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT');

          // Step 2: Update existing rows with current timestamp
          await db.execute(
            "UPDATE users SET created_at = datetime('now') WHERE created_at IS NULL",
          );

          print('DEBUG: Successfully added created_at column');
        } catch (e) {
          print('ERROR: Failed to add created_at column: $e');
          rethrow;
        }

        print('DEBUG: Adding last_active column using multi-step approach');
        try {
          // Step 1: Add column as nullable first
          await db.execute('ALTER TABLE users ADD COLUMN last_active TEXT');

          // Step 2: Update existing rows with current timestamp
          await db.execute(
            "UPDATE users SET last_active = datetime('now') WHERE last_active IS NULL",
          );

          print('DEBUG: Successfully added last_active column');
        } catch (e) {
          print('ERROR: Failed to add last_active column: $e');
          rethrow;
        }
      } catch (e) {
        print('ERROR: Migration failed at line ${e.toString()}');
        print('ERROR: This is the SQLite constraint error we\'re debugging');
        print(
          'ERROR: SQLite doesn\'t support non-constant defaults in ALTER TABLE ADD COLUMN with NOT NULL',
        );
        rethrow;
      }

      // Create new gamification tables
      await db.execute('''
        CREATE TABLE user_points (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          points_earned INTEGER NOT NULL,
          points_source TEXT NOT NULL,
          transaction_id TEXT,
          contribution_id INTEGER,
          achievement_id INTEGER,
          challenge_id INTEGER,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (contribution_id) REFERENCES contributions (id),
          FOREIGN KEY (achievement_id) REFERENCES achievements (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE challenges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          challenge_type TEXT NOT NULL,
          target_value INTEGER NOT NULL,
          target_unit TEXT NOT NULL,
          points_reward INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE challenge_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          challenge_id INTEGER NOT NULL,
          current_progress INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completion_date TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (challenge_id) REFERENCES challenges (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE leaderboard_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          leaderboard_type TEXT NOT NULL,
          score REAL NOT NULL,
          ranking INTEGER NOT NULL,
          period_start TEXT NOT NULL,
          period_end TEXT NOT NULL,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          notification_type TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          related_id INTEGER,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE user_achievement_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          achievement_id INTEGER NOT NULL,
          current_progress INTEGER NOT NULL DEFAULT 0,
          target_value INTEGER NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id),
          UNIQUE(user_id, achievement_id)
        )
      ''');
    }

    if (oldVersion < 5) {
      print(
        'DEBUG: DatabaseHelper._onUpgrade - Applying migration for version < 5',
      );

      // Create notification preferences table
      await db.execute('''
        CREATE TABLE notification_preferences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          achievements_enabled INTEGER NOT NULL DEFAULT 1,
          challenges_enabled INTEGER NOT NULL DEFAULT 1,
          leaderboard_enabled INTEGER NOT NULL DEFAULT 1,
          level_up_enabled INTEGER NOT NULL DEFAULT 1,
          badge_enabled INTEGER NOT NULL DEFAULT 1,
          reminder_enabled INTEGER NOT NULL DEFAULT 1,
          daily_limit INTEGER NOT NULL DEFAULT 10,
          quiet_hours_start TEXT DEFAULT '22:00',
          quiet_hours_end TEXT DEFAULT '07:00',
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id),
          UNIQUE(user_id)
        )
      ''');
    }
    if (oldVersion < 6) {
      print('DEBUG: DatabaseHelper._onUpgrade - Applying migration for version < 6');
    
      Future<void> addColumnIfNotExists(String column, String type, {String? defaultValue}) async {
        final cols = await db.rawQuery("PRAGMA table_info(users)");
        final existing = cols.map((c) => c['name']?.toString()).toSet();
        if (!existing.contains(column)) {
          final def = (defaultValue != null) ? "DEFAULT $defaultValue" : "";
          final query = "ALTER TABLE users ADD COLUMN $column $type $def";
          print('DEBUG: Adding column: $query');
          await db.execute(query);
        } else {
          print('DEBUG: Column $column already exists');
        }
      }
    
      await addColumnIfNotExists('username', 'TEXT');
      await addColumnIfNotExists('email', 'TEXT');
      await addColumnIfNotExists('total_points', 'INTEGER', defaultValue: '0');
      await addColumnIfNotExists('level', 'INTEGER', defaultValue: '1');
      await addColumnIfNotExists('badges_earned', 'TEXT', defaultValue: "''");
      await addColumnIfNotExists('created_at', 'TEXT');
      await addColumnIfNotExists('last_active', 'TEXT');
    }

  }

  Future<Balance> getBalance() async {
    print('DEBUG: DatabaseHelper.getBalance - Called');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('balance');

    if (maps.isNotEmpty) {
      final balance = Balance.fromMap(maps.first);
      print(
        'DEBUG: DatabaseHelper.getBalance - Retrieved balance: ${balance.amount}',
      );
      return balance;
    } else {
      // If no balance exists, create a default one
      print(
        'DEBUG: DatabaseHelper.getBalance - No balance found, creating default',
      );
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

  Future<AppTransaction.Transaction?> getTransactionById(
    String transactionId,
  ) async {
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

  Future<String?> processPayment(String merchantName, double amount) async {
    print('DEBUG: DatabaseHelper.processPayment - Starting payment process');
    print('DEBUG: Merchant: $merchantName, Amount: $amount');

    final db = await database;

    // Check if balance is sufficient
    final currentBalance = await getBalance();
    print('DEBUG: Current balance before payment: ${currentBalance.amount}');

    if (currentBalance.amount < amount) {
      print('DEBUG: Insufficient balance - payment failed');
      return null; // Insufficient balance
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
        {'amount': newBalance, 'lastUpdated': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [currentBalance.id],
      );

      // Insert transaction record
      await txn.insert('transactions', transaction.toMap());
    });

    print(
      'DEBUG: Payment processed successfully - balance updated to: $newBalance',
    );
    return transactionId; // Return the transaction ID for linking to contributions
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
    await ensureUserSchema(db);
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    final defaultUser = User(
      id: 1,
      name: 'Default User',
      username: 'default_user',
      email: 'default@example.com',
      ecopayOptIn: false,
    );
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

  // Enhanced method to get contributions with project details
  Future<List<Map<String, dynamic>>> getContributionsWithProjectDetails(
    int userId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        c.id as contribution_id,
        c.user_id,
        c.project_id,
        c.amount,
        c.transaction_id,
        c.timestamp,
        p.name as project_name,
        p.description as project_description,
        p.cost_per_unit,
        p.unit_label
      FROM contributions c
      LEFT JOIN projects p ON c.project_id = p.id
      WHERE c.user_id = ?
      ORDER BY c.timestamp DESC
    ''',
      [userId],
    );
    return maps;
  }

  // Get contribution statistics for a user
  Future<Map<String, dynamic>> getContributionStatistics(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_contributions,
        SUM(amount) as total_donated,
        COUNT(DISTINCT project_id) as projects_supported,
        MIN(timestamp) as first_contribution,
        MAX(timestamp) as latest_contribution
      FROM contributions
      WHERE user_id = ?
    ''',
      [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return {
      'total_contributions': 0,
      'total_donated': 0.0,
      'projects_supported': 0,
      'first_contribution': null,
      'latest_contribution': null,
    };
  }

  // Get monthly contribution data for charts
  Future<List<Map<String, dynamic>>> getMonthlyContributions(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        strftime('%Y-%m', timestamp) as month,
        COUNT(*) as contribution_count,
        SUM(amount) as total_amount
      FROM contributions
      WHERE user_id = ?
      GROUP BY strftime('%Y-%m', timestamp)
      ORDER BY month DESC
      LIMIT 12
    ''',
      [userId],
    );
    return maps;
  }

  // Insert sample project data for testing
  Future<void> insertSampleProjects() async {
    final db = await database;

    // Check if projects already exist
    final existing = await db.query('projects', limit: 1);
    if (existing.isNotEmpty) return;

    final sampleProjects = [
      {
        'name': 'Mangrove Restoration',
        'description':
            'Plant mangrove trees in coastal areas to prevent erosion and support marine life',
        'cost_per_unit': 5.0,
        'unit_label': 'tree',
      },
      {
        'name': 'Solar Panel Installation',
        'description':
            'Install solar panels in rural schools to provide clean energy',
        'cost_per_unit': 25.0,
        'unit_label': 'watt',
      },
      {
        'name': 'Clean Water Wells',
        'description': 'Build water filtration systems for rural communities',
        'cost_per_unit': 100.0,
        'unit_label': 'system',
      },
      {
        'name': 'Rainforest Conservation',
        'description':
            'Protect endangered rainforest areas and wildlife habitats',
        'cost_per_unit': 10.0,
        'unit_label': 'sq meter',
      },
      {
        'name': 'Ocean Cleanup',
        'description': 'Remove plastic waste from oceans and coastal areas',
        'cost_per_unit': 15.0,
        'unit_label': 'kg waste',
      },
    ];

    for (final project in sampleProjects) {
      await db.insert('projects', project);
    }
  }

  // Insert sample contribution data for testing
  Future<void> insertSampleContributions(int userId) async {
    final db = await database;

    // Check if contributions already exist
    final existing = await db.query(
      'contributions',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final sampleContributions = [
      {
        'user_id': userId,
        'project_id': 1,
        'amount': 15.50,
        'transaction_id': 'TXN001',
        'timestamp': now.subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'user_id': userId,
        'project_id': 2,
        'amount': 8.75,
        'transaction_id': 'TXN002',
        'timestamp': now.subtract(const Duration(days: 12)).toIso8601String(),
      },
      {
        'user_id': userId,
        'project_id': 3,
        'amount': 22.30,
        'transaction_id': 'TXN003',
        'timestamp': now.subtract(const Duration(days: 18)).toIso8601String(),
      },
      {
        'user_id': userId,
        'project_id': 1,
        'amount': 12.00,
        'transaction_id': 'TXN004',
        'timestamp': now.subtract(const Duration(days: 25)).toIso8601String(),
      },
      {
        'user_id': userId,
        'project_id': 4,
        'amount': 18.90,
        'transaction_id': 'TXN005',
        'timestamp': now.subtract(const Duration(days: 30)).toIso8601String(),
      },
    ];

    for (final contribution in sampleContributions) {
      await db.insert('contributions', contribution);
    }
  }

  // Achievement methods
  Future<List<Map<String, dynamic>>> getUserAchievements(int userId) async {
    final db = await database;
    return await db.query(
      'user_achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> insertUserAchievement(Map<String, dynamic> achievement) async {
    final db = await database;
    return await db.insert('user_achievements', achievement);
  }

  // Gamification-related methods
  Future<int> addUserPoints(
    int userId,
    int points,
    String source, {
    String? transactionId,
    int? contributionId,
    int? achievementId,
    int? challengeId,
  }) async {
    final db = await database;

    // Insert points record
    await db.insert('user_points', {
      'user_id': userId,
      'points_earned': points,
      'points_source': source,
      'transaction_id': transactionId,
      'contribution_id': contributionId,
      'achievement_id': achievementId,
      'challenge_id': challengeId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update user's total points
    await db.rawUpdate(
      'UPDATE users SET total_points = total_points + ? WHERE id = ?',
      [points, userId],
    );

    return points;
  }

  Future<int> getUserTotalPoints(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['total_points'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first['total_points'] as int : 0;
  }

  Future<List<Map<String, dynamic>>> getUserPointsHistory(int userId) async {
    final db = await database;
    return await db.query(
      'user_points',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> insertChallenge(Map<String, dynamic> challenge) async {
    final db = await database;
    return await db.insert('challenges', challenge);
  }

  Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    final db = await database;
    return await db.query(
      'challenges',
      where: 'is_active = ? AND end_date > ?',
      whereArgs: [1, DateTime.now().toIso8601String()],
      orderBy: 'start_date ASC',
    );
  }

  Future<int> updateChallengeProgress(
    int userId,
    int challengeId,
    int progress,
  ) async {
    final db = await database;
    return await db.update(
      'challenge_progress',
      {
        'current_progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ? AND challenge_id = ?',
      whereArgs: [userId, challengeId],
    );
  }

  Future<int> insertChallengeProgress(Map<String, dynamic> progress) async {
    final db = await database;
    return await db.insert('challenge_progress', progress);
  }

  Future<List<Map<String, dynamic>>> getUserChallengeProgress(
    int userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT cp.*, c.title, c.description, c.target_value, c.target_unit, c.points_reward, c.end_date
      FROM challenge_progress cp
      JOIN challenges c ON cp.challenge_id = c.id
      WHERE cp.user_id = ? AND c.is_active = 1
      ORDER BY c.end_date ASC
    ''',
      [userId],
    );
  }

  Future<int> insertLeaderboardEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('leaderboard_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(
    String type,
    String periodStart,
    String periodEnd,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT le.*, u.name, u.profile_image
      FROM leaderboard_entries le
      JOIN users u ON le.user_id = u.id
      WHERE le.leaderboard_type = ? AND le.period_start = ? AND le.period_end = ?
      ORDER BY le.ranking ASC
    ''',
      [type, periodStart, periodEnd],
    );
  }

  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('notifications', notification);
  }

  Future<List<Map<String, dynamic>>> getUserNotifications(int userId) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // Method to get or create challenge progress
  Future<Map<String, dynamic>?> getChallengeProgress(
    int userId,
    int challengeId,
  ) async {
    final db = await database;
    final result = await db.query(
      'challenge_progress',
      where: 'user_id = ? AND challenge_id = ?',
      whereArgs: [userId, challengeId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Method to complete a challenge
  Future<int> completeChallenge(int userId, int challengeId) async {
    final db = await database;
    return await db.update(
      'challenge_progress',
      {
        'is_completed': 1,
        'completion_date': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ? AND challenge_id = ?',
      whereArgs: [userId, challengeId],
    );
  }

  // Method to update user level
  Future<int> updateUserLevel(int userId, int level) async {
    final db = await database;
    return await db.update(
      'users',
      {'level': level},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Method to add badge to user
  Future<int> addBadgeToUser(int userId, String badgeId) async {
    final db = await database;
    final user = await getUser(userId);
    if (user != null) {
      List<String> badges = user.badgesEarned?.split(',') ?? [];
      if (!badges.contains(badgeId)) {
        badges.add(badgeId);
        return await db.update(
          'users',
          {'badges_earned': badges.join(',')},
          where: 'id = ?',
          whereArgs: [userId],
        );
      }
    }
    return 0;
  }

  // Achievement progress methods
  Future<int> insertUserAchievementProgress(
    Map<String, dynamic> progress,
  ) async {
    final db = await database;
    return await db.insert(
      'user_achievement_progress',
      progress,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserAchievementProgress(
    int userId,
    int achievementId,
  ) async {
    final db = await database;
    final result = await db.query(
      'user_achievement_progress',
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUserAchievementProgress(
    int userId,
  ) async {
    final db = await database;
    return await db.query(
      'user_achievement_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateUserAchievementProgress(
    int userId,
    int achievementId,
    int currentProgress,
  ) async {
    final db = await database;
    return await db.update(
      'user_achievement_progress',
      {
        'current_progress': currentProgress,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
    );
  }

  Future<int> completeUserAchievement(int userId, int achievementId) async {
    final db = await database;
    return await db.update(
      'user_achievement_progress',
      {
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
    );
  }

  Future<List<Map<String, dynamic>>> getCompletedAchievements(
    int userId,
  ) async {
    final db = await database;
    return await db.query(
      'user_achievement_progress',
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getInProgressAchievements(
    int userId,
  ) async {
    final db = await database;
    return await db.query(
      'user_achievement_progress',
      where: 'user_id = ? AND is_completed = 0',
      whereArgs: [userId],
      orderBy: 'current_progress DESC',
    );
  }

  Future<Map<String, dynamic>> getAchievementStatistics(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_achievements,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed_achievements,
        SUM(CASE WHEN is_completed = 0 THEN 1 ELSE 0 END) as in_progress_achievements,
        AVG(CASE WHEN is_completed = 0 THEN (current_progress * 100.0 / target_value) ELSE NULL END) as average_progress
      FROM user_achievement_progress
      WHERE user_id = ?
    ''',
      [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return {
      'total_achievements': 0,
      'completed_achievements': 0,
      'in_progress_achievements': 0,
      'average_progress': 0.0,
    };
  }

  // Notification Preferences methods
  Future<int> insertNotificationPreferences(
    Map<String, dynamic> preferences,
  ) async {
    final db = await database;
    return await db.insert(
      'notification_preferences',
      preferences,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getNotificationPreferences(int userId) async {
    final db = await database;
    final result = await db.query(
      'notification_preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateNotificationPreferences(
    int userId,
    Map<String, dynamic> preferences,
  ) async {
    final db = await database;
    return await db.update(
      'notification_preferences',
      preferences,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteNotificationPreferences(int userId) async {
    final db = await database;
    return await db.delete(
      'notification_preferences',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Enhanced notification methods
  Future<List<Map<String, dynamic>>> getUnreadNotifications(int userId) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> getUnreadNotificationCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM notifications
      WHERE user_id = ? AND is_read = 0
    ''',
      [userId],
    );
    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<List<Map<String, dynamic>>> getNotificationsByType(
    int userId,
    String type,
  ) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'user_id = ? AND notification_type = ?',
      whereArgs: [userId, type],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> markAllNotificationsAsRead(int userId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteNotification(int notificationId) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<int> deleteOldNotifications(int userId, DateTime cutoffDate) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'user_id = ? AND created_at < ?',
      whereArgs: [userId, cutoffDate.toIso8601String()],
    );
  }

  Future<Map<String, dynamic>> getNotificationStatistics(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) as total_notifications,
        SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_notifications,
        SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_notifications,
        COUNT(DISTINCT notification_type) as notification_types
      FROM notifications
      WHERE user_id = ?
    ''',
      [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return {
      'total_notifications': 0,
      'read_notifications': 0,
      'unread_notifications': 0,
      'notification_types': 0,
    };
  }

  Future<List<Map<String, dynamic>>> getNotificationsByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'user_id = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getNotificationTypeStats(
    int userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT
        notification_type,
        COUNT(*) as count,
        SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as read_count,
        SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread_count
      FROM notifications
      WHERE user_id = ?
      GROUP BY notification_type
      ORDER BY count DESC
    ''',
      [userId],
    );
  }
}
