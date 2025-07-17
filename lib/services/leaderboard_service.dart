import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/leaderboard_entry.dart';
import '../models/notification.dart';
import '../utils/environmental_impact_calculator.dart';

/// Comprehensive leaderboard service for managing rankings and social features
class LeaderboardService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Cache for frequently accessed leaderboard data
  static final Map<String, List<LeaderboardEntryWithUser>> _leaderboardCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Leaderboard update intervals
  static const Duration _realTimeUpdateInterval = Duration(seconds: 30);
  static const Duration _dailyUpdateInterval = Duration(hours: 24);
  
  Timer? _realTimeUpdateTimer;
  Timer? _dailyUpdateTimer;

  /// Initialize the leaderboard service with periodic updates
  void initialize() {
    _startRealTimeUpdates();
    _startDailyUpdates();
  }

  /// Dispose of timers and resources
  void dispose() {
    _realTimeUpdateTimer?.cancel();
    _dailyUpdateTimer?.cancel();
  }

  /// Start real-time leaderboard updates
  void _startRealTimeUpdates() {
    _realTimeUpdateTimer = Timer.periodic(_realTimeUpdateInterval, (timer) {
      _updateRealTimeLeaderboards();
    });
  }

  /// Start daily leaderboard maintenance
  void _startDailyUpdates() {
    _dailyUpdateTimer = Timer.periodic(_dailyUpdateInterval, (timer) {
      _performDailyMaintenance();
    });
  }

  /// Get leaderboard entries for a specific type and period
  Future<List<LeaderboardEntryWithUser>> getLeaderboard({
    required LeaderboardType type,
    required LeaderboardPeriod period,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final periodDates = _getPeriodDates(period);
      final cacheKey = '${type.name}_${period.name}_${limit}_$offset';
      
      // Check cache first
      if (_isCacheValid(cacheKey)) {
        return _leaderboardCache[cacheKey]!;
      }
      
      // Calculate rankings for the specified period
      final rankings = await _calculateRankings(type, periodDates.start, periodDates.end);
      
      // Get paginated results
      final paginatedResults = rankings.skip(offset).take(limit).toList();
      
      // Get user details for each entry
      final entriesWithUsers = await _enrichWithUserDetails(paginatedResults);
      
      // Cache the results
      _leaderboardCache[cacheKey] = entriesWithUsers;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      return entriesWithUsers;
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get user's position in a specific leaderboard
  Future<LeaderboardPosition> getUserPosition({
    required int userId,
    required LeaderboardType type,
    required LeaderboardPeriod period,
  }) async {
    try {
      final periodDates = _getPeriodDates(period);
      final rankings = await _calculateRankings(type, periodDates.start, periodDates.end);
      
      // Find user's position
      for (int i = 0; i < rankings.length; i++) {
        if (rankings[i]['user_id'] == userId) {
          final userScore = rankings[i]['score'] as double;
          final ranking = i + 1;
          
          // Calculate percentile
          final percentile = ((rankings.length - ranking) / rankings.length) * 100;
          
          // Get surrounding users
          final nearbyUsers = await _getNearbyUsers(rankings, i, userId);
          
          return LeaderboardPosition(
            userId: userId,
            leaderboardType: type,
            period: period,
            ranking: ranking,
            score: userScore,
            totalUsers: rankings.length,
            percentile: percentile,
            nearbyUsers: nearbyUsers,
            isTopTen: ranking <= 10,
            isTopHundred: ranking <= 100,
          );
        }
      }
      
      // User not found in rankings
      return LeaderboardPosition(
        userId: userId,
        leaderboardType: type,
        period: period,
        ranking: -1,
        score: 0.0,
        totalUsers: rankings.length,
        percentile: 0.0,
        nearbyUsers: [],
        isTopTen: false,
        isTopHundred: false,
      );
    } catch (e) {
      debugPrint('Error getting user position: $e');
      return LeaderboardPosition(
        userId: userId,
        leaderboardType: type,
        period: period,
        ranking: -1,
        score: 0.0,
        totalUsers: 0,
        percentile: 0.0,
        nearbyUsers: [],
        isTopTen: false,
        isTopHundred: false,
      );
    }
  }

  /// Get leaderboard statistics
  Future<LeaderboardStats> getLeaderboardStats({
    required LeaderboardType type,
    required LeaderboardPeriod period,
  }) async {
    try {
      final periodDates = _getPeriodDates(period);
      final rankings = await _calculateRankings(type, periodDates.start, periodDates.end);
      
      if (rankings.isEmpty) {
        return LeaderboardStats(
          leaderboardType: type,
          period: period,
          totalParticipants: 0,
          averageScore: 0.0,
          highestScore: 0.0,
          lowestScore: 0.0,
          medianScore: 0.0,
          totalScore: 0.0,
        );
      }
      
      final scores = rankings.map((r) => r['score'] as double).toList();
      scores.sort();
      
      final totalScore = scores.fold(0.0, (sum, score) => sum + score);
      final averageScore = totalScore / scores.length;
      final medianScore = scores.length % 2 == 0
          ? (scores[scores.length ~/ 2 - 1] + scores[scores.length ~/ 2]) / 2
          : scores[scores.length ~/ 2];
      
      return LeaderboardStats(
        leaderboardType: type,
        period: period,
        totalParticipants: rankings.length,
        averageScore: averageScore,
        highestScore: scores.last,
        lowestScore: scores.first,
        medianScore: medianScore,
        totalScore: totalScore,
      );
    } catch (e) {
      debugPrint('Error getting leaderboard stats: $e');
      return LeaderboardStats(
        leaderboardType: type,
        period: period,
        totalParticipants: 0,
        averageScore: 0.0,
        highestScore: 0.0,
        lowestScore: 0.0,
        medianScore: 0.0,
        totalScore: 0.0,
      );
    }
  }

  /// Update user's leaderboard entry
  Future<void> updateUserEntry({
    required int userId,
    required LeaderboardType type,
    required double score,
    required LeaderboardPeriod period,
  }) async {
    try {
      final periodDates = _getPeriodDates(period);
      final now = DateTime.now();
      
      // Get current rankings to determine new position
      final rankings = await _calculateRankings(type, periodDates.start, periodDates.end);
      
      // Find where this score would rank
      int newRanking = 1;
      for (final ranking in rankings) {
        if (score <= ranking['score']) {
          newRanking++;
        } else {
          break;
        }
      }
      
      // Get user details for the entry
      final user = await _databaseHelper.getUser(userId);
      final username = user?.name ?? 'Unknown User';
      
      // Create or update leaderboard entry
      final entry = LeaderboardEntry(
        userId: userId,
        username: username,
        points: score.toInt(),
        co2Saved: 0.0, // Will be calculated if needed
        rank: newRanking,
        achievements: [],
        leaderboardType: type,
        score: score,
        ranking: newRanking,
        periodStart: periodDates.start,
        periodEnd: periodDates.end,
        createdAt: now,
        updatedAt: now,
      );
      
      await _databaseHelper.insertLeaderboardEntry(entry.toMap());
      
      // Check for ranking achievements
      await _checkRankingAchievements(userId, type, newRanking);
      
      // Clear cache for this leaderboard type
      _clearCacheForType(type);
    } catch (e) {
      debugPrint('Error updating user entry: $e');
    }
  }

  /// Get trending leaderboards (fastest growing users)
  Future<List<TrendingUser>> getTrendingUsers({
    required LeaderboardType type,
    required LeaderboardPeriod period,
    int limit = 10,
  }) async {
    try {
      final periodDates = _getPeriodDates(period);
      final previousPeriodDates = _getPreviousPeriodDates(period);
      
      // Get current and previous rankings
      final currentRankings = await _calculateRankings(type, periodDates.start, periodDates.end);
      final previousRankings = await _calculateRankings(type, previousPeriodDates.start, previousPeriodDates.end);
      
      // Create map of previous scores for quick lookup
      final previousScores = <int, double>{};
      for (final ranking in previousRankings) {
        previousScores[ranking['user_id']] = ranking['score'];
      }
      
      // Calculate growth for each user
      final trendingUsers = <TrendingUser>[];
      for (final current in currentRankings) {
        final userId = current['user_id'] as int;
        final currentScore = current['score'] as double;
        final previousScore = previousScores[userId] ?? 0.0;
        
        if (currentScore > previousScore) {
          final growth = currentScore - previousScore;
          final growthRate = previousScore > 0 ? (growth / previousScore) * 100 : 100.0;
          
          trendingUsers.add(TrendingUser(
            userId: userId,
            currentScore: currentScore,
            previousScore: previousScore,
            growth: growth,
            growthRate: growthRate,
            leaderboardType: type,
            period: period,
          ));
        }
      }
      
      // Sort by growth rate and return top users
      trendingUsers.sort((a, b) => b.growthRate.compareTo(a.growthRate));
      return trendingUsers.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting trending users: $e');
      return [];
    }
  }

  /// Get user comparison data
  Future<UserComparison> compareUsers({
    required int userId1,
    required int userId2,
    required LeaderboardType type,
    required LeaderboardPeriod period,
  }) async {
    try {
      final position1 = await getUserPosition(userId: userId1, type: type, period: period);
      final position2 = await getUserPosition(userId: userId2, type: type, period: period);
      
      final scoreDifference = position1.score - position2.score;
      final rankingDifference = position2.ranking - position1.ranking; // Lower ranking is better
      
      return UserComparison(
        user1Id: userId1,
        user2Id: userId2,
        user1Position: position1,
        user2Position: position2,
        scoreDifference: scoreDifference,
        rankingDifference: rankingDifference,
        leaderboardType: type,
        period: period,
      );
    } catch (e) {
      debugPrint('Error comparing users: $e');
      return UserComparison(
        user1Id: userId1,
        user2Id: userId2,
        user1Position: LeaderboardPosition(
          userId: userId1,
          leaderboardType: type,
          period: period,
          ranking: -1,
          score: 0.0,
          totalUsers: 0,
          percentile: 0.0,
          nearbyUsers: [],
          isTopTen: false,
          isTopHundred: false,
        ),
        user2Position: LeaderboardPosition(
          userId: userId2,
          leaderboardType: type,
          period: period,
          ranking: -1,
          score: 0.0,
          totalUsers: 0,
          percentile: 0.0,
          nearbyUsers: [],
          isTopTen: false,
          isTopHundred: false,
        ),
        scoreDifference: 0.0,
        rankingDifference: 0,
        leaderboardType: type,
        period: period,
      );
    }
  }

  /// Calculate rankings for a specific leaderboard type and period
  Future<List<Map<String, dynamic>>> _calculateRankings(
    LeaderboardType type,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    try {
      final db = await _databaseHelper.database;
      List<Map<String, dynamic>> rankings = [];
      
      switch (type) {
        case LeaderboardType.points:
          rankings = await db.query(
            'users',
            columns: ['id as user_id', 'total_points as score'],
            where: 'total_points > 0',
            orderBy: 'total_points DESC',
          );
          break;
          
        case LeaderboardType.weekly_points:
        case LeaderboardType.monthly_points:
          rankings = await db.rawQuery('''
            SELECT user_id, SUM(points_earned) as score
            FROM user_points 
            WHERE timestamp >= ? AND timestamp <= ?
            GROUP BY user_id
            HAVING score > 0
            ORDER BY score DESC
          ''', [periodStart.toIso8601String(), periodEnd.toIso8601String()]);
          break;
          
        case LeaderboardType.contributions:
          rankings = await db.rawQuery('''
            SELECT user_id, SUM(amount) as score
            FROM contributions 
            WHERE timestamp >= ? AND timestamp <= ?
            GROUP BY user_id
            HAVING score > 0
            ORDER BY score DESC
          ''', [periodStart.toIso8601String(), periodEnd.toIso8601String()]);
          break;
          
        case LeaderboardType.co2_saved:
        case LeaderboardType.water_saved:
        case LeaderboardType.energy_saved:
        case LeaderboardType.trees_planted:
          rankings = await _calculateEnvironmentalRankings(type, periodStart, periodEnd);
          break;
          
        case LeaderboardType.challenges_completed:
          rankings = await db.rawQuery('''
            SELECT user_id, COUNT(*) as score
            FROM challenge_progress 
            WHERE is_completed = 1 AND completion_date >= ? AND completion_date <= ?
            GROUP BY user_id
            HAVING score > 0
            ORDER BY score DESC
          ''', [periodStart.toIso8601String(), periodEnd.toIso8601String()]);
          break;
          
        case LeaderboardType.achievements_earned:
          rankings = await db.rawQuery('''
            SELECT user_id, COUNT(*) as score
            FROM user_achievements 
            WHERE date_unlocked >= ? AND date_unlocked <= ?
            GROUP BY user_id
            HAVING score > 0
            ORDER BY score DESC
          ''', [periodStart.toIso8601String(), periodEnd.toIso8601String()]);
          break;
      }
      
      return rankings;
    } catch (e) {
      debugPrint('Error calculating rankings for $type: $e');
      return [];
    }
  }

  /// Calculate environmental impact rankings
  Future<List<Map<String, dynamic>>> _calculateEnvironmentalRankings(
    LeaderboardType type,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final contributions = await db.rawQuery('''
        SELECT user_id, SUM(amount) as total_contribution
        FROM contributions 
        WHERE timestamp >= ? AND timestamp <= ?
        GROUP BY user_id
        HAVING total_contribution > 0
      ''', [periodStart.toIso8601String(), periodEnd.toIso8601String()]);
      
      final rankings = <Map<String, dynamic>>[];
      
      for (final contribution in contributions) {
        final userId = contribution['user_id'] as int;
        final totalContribution = contribution['total_contribution'] as double;
        
        final impactData = EnvironmentalImpactCalculator.getEnvironmentalImpact(totalContribution);
        
        double score = 0.0;
        switch (type) {
          case LeaderboardType.co2_saved:
            score = impactData['co2_offset_kg'] ?? 0.0;
            break;
          case LeaderboardType.water_saved:
            score = impactData['water_saved_liters'] ?? 0.0;
            break;
          case LeaderboardType.energy_saved:
            score = impactData['energy_saved_kwh'] ?? 0.0;
            break;
          case LeaderboardType.trees_planted:
            score = impactData['tree_equivalent'] ?? 0.0;
            break;
          default:
            continue;
        }
        
        if (score > 0) {
          rankings.add({
            'user_id': userId,
            'score': score,
          });
        }
      }
      
      // Sort by score descending
      rankings.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      
      return rankings;
    } catch (e) {
      debugPrint('Error calculating environmental rankings: $e');
      return [];
    }
  }

  /// Enrich rankings with user details
  Future<List<LeaderboardEntryWithUser>> _enrichWithUserDetails(
    List<Map<String, dynamic>> rankings,
  ) async {
    try {
      final entries = <LeaderboardEntryWithUser>[];
      
      for (int i = 0; i < rankings.length; i++) {
        final ranking = rankings[i];
        final userId = ranking['user_id'] as int;
        final user = await _databaseHelper.getUser(userId);
        
        if (user != null) {
          entries.add(LeaderboardEntryWithUser(
            id: null,
            userId: userId,
            username: user.name,
            points: (ranking['score'] as double).toInt(),
            co2Saved: 0.0,
            rank: i + 1,
            achievements: [],
            leaderboardType: LeaderboardType.points, // This will be set by caller
            score: ranking['score'] as double,
            ranking: i + 1,
            periodStart: DateTime.now(), // This will be set by caller
            periodEnd: DateTime.now(), // This will be set by caller
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            name: user.name,
            profileImage: null, // User model doesn't have profile image yet
          ));
        }
      }
      
      return entries;
    } catch (e) {
      debugPrint('Error enriching with user details: $e');
      return [];
    }
  }

  /// Get nearby users for a specific position
  Future<List<LeaderboardEntryWithUser>> _getNearbyUsers(
    List<Map<String, dynamic>> rankings,
    int userIndex,
    int userId,
  ) async {
    try {
      final start = max(0, userIndex - 2);
      final end = min(rankings.length, userIndex + 3);
      
      final nearbyRankings = rankings.sublist(start, end);
      return await _enrichWithUserDetails(nearbyRankings);
    } catch (e) {
      debugPrint('Error getting nearby users: $e');
      return [];
    }
  }

  /// Get period dates for different leaderboard periods
  PeriodDates _getPeriodDates(LeaderboardPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case LeaderboardPeriod.daily:
        final startOfDay = DateTime(now.year, now.month, now.day);
        return PeriodDates(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 1)),
        );
        
      case LeaderboardPeriod.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return PeriodDates(
          start: startOfWeekDay,
          end: startOfWeekDay.add(const Duration(days: 7)),
        );
        
      case LeaderboardPeriod.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        return PeriodDates(
          start: startOfMonth,
          end: endOfMonth,
        );
        
      case LeaderboardPeriod.allTime:
        return PeriodDates(
          start: DateTime(2024, 1, 1),
          end: DateTime(2030, 12, 31),
        );
    }
  }

  /// Get previous period dates for trend analysis
  PeriodDates _getPreviousPeriodDates(LeaderboardPeriod period) {
    final now = DateTime.now();
    
    switch (period) {
      case LeaderboardPeriod.daily:
        final yesterday = now.subtract(const Duration(days: 1));
        final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
        return PeriodDates(
          start: startOfYesterday,
          end: startOfYesterday.add(const Duration(days: 1)),
        );
        
      case LeaderboardPeriod.weekly:
        final lastWeekStart = now.subtract(Duration(days: now.weekday - 1 + 7));
        final lastWeekStartDay = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day);
        return PeriodDates(
          start: lastWeekStartDay,
          end: lastWeekStartDay.add(const Duration(days: 7)),
        );
        
      case LeaderboardPeriod.monthly:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 1);
        return PeriodDates(
          start: lastMonth,
          end: endOfLastMonth,
        );
        
      case LeaderboardPeriod.allTime:
        return PeriodDates(
          start: DateTime(2024, 1, 1),
          end: DateTime(2030, 12, 31),
        );
    }
  }

  /// Update real-time leaderboards
  Future<void> _updateRealTimeLeaderboards() async {
    try {
      final types = [
        LeaderboardType.points,
        LeaderboardType.weekly_points,
        LeaderboardType.monthly_points,
      ];
      
      for (final type in types) {
        final period = type == LeaderboardType.points 
            ? LeaderboardPeriod.allTime 
            : type == LeaderboardType.weekly_points 
                ? LeaderboardPeriod.weekly 
                : LeaderboardPeriod.monthly;
        
        // Clear cache to force refresh
        _clearCacheForType(type);
        
        // Update rankings
        await getLeaderboard(type: type, period: period);
      }
    } catch (e) {
      debugPrint('Error updating real-time leaderboards: $e');
    }
  }

  /// Perform daily maintenance tasks
  Future<void> _performDailyMaintenance() async {
    try {
      // Clear old cache entries
      _clearExpiredCache();
      
      // Update all leaderboard types
      for (final type in LeaderboardType.values) {
        for (final period in LeaderboardPeriod.values) {
          await getLeaderboard(type: type, period: period);
        }
      }
      
      // Clean up old leaderboard entries (keep last 30 days)
      await _cleanupOldEntries();
    } catch (e) {
      debugPrint('Error performing daily maintenance: $e');
    }
  }

  /// Check for ranking achievements
  Future<void> _checkRankingAchievements(int userId, LeaderboardType type, int ranking) async {
    try {
      // Create notifications for significant ranking achievements
      if (ranking == 1) {
        await _createNotification(Notification.leaderboardPositionChanged(
          userId: userId,
          leaderboardType: type.displayName,
          newPosition: ranking,
          oldPosition: ranking + 1, // Assume they moved up from one position lower
        ));
      } else if (ranking <= 3) {
        await _createNotification(Notification.leaderboardPositionChanged(
          userId: userId,
          leaderboardType: type.displayName,
          newPosition: ranking,
          oldPosition: ranking + 1,
        ));
      } else if (ranking <= 10) {
        await _createNotification(Notification.leaderboardPositionChanged(
          userId: userId,
          leaderboardType: type.displayName,
          newPosition: ranking,
          oldPosition: ranking + 1,
        ));
      }
    } catch (e) {
      debugPrint('Error checking ranking achievements: $e');
    }
  }

  /// Create notification
  Future<void> _createNotification(Notification notification) async {
    try {
      await _databaseHelper.insertNotification(notification.toMap());
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Check if cache is valid
  bool _isCacheValid(String cacheKey) {
    if (!_leaderboardCache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }

  /// Clear cache for a specific leaderboard type
  void _clearCacheForType(LeaderboardType type) {
    final keysToRemove = _leaderboardCache.keys.where((key) => key.startsWith(type.name)).toList();
    for (final key in keysToRemove) {
      _leaderboardCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear expired cache entries
  void _clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) >= _cacheExpiry)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _leaderboardCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clean up old leaderboard entries
  Future<void> _cleanupOldEntries() async {
    try {
      final db = await _databaseHelper.database;
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      await db.delete(
        'leaderboard_entries',
        where: 'created_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
    } catch (e) {
      debugPrint('Error cleaning up old entries: $e');
    }
  }

  /// Get all leaderboards with their current data
  Future<Map<String, List<LeaderboardEntryWithUser>>> getAllLeaderboards() async {
    try {
      final allLeaderboards = <String, List<LeaderboardEntryWithUser>>{};
      
      // Get all leaderboard types
      final leaderboardTypes = [
        LeaderboardType.points,
        LeaderboardType.contributions,
        LeaderboardType.co2_saved,
        LeaderboardType.water_saved,
        LeaderboardType.energy_saved,
        LeaderboardType.trees_planted,
        LeaderboardType.challenges_completed,
        LeaderboardType.achievements_earned,
        LeaderboardType.weekly_points,
        LeaderboardType.monthly_points,
      ];
      
      // Get current data for each leaderboard type
      for (final type in leaderboardTypes) {
        final period = _getDefaultPeriodForType(type);
        final entries = await getLeaderboard(type: type, period: period, limit: 50);
        allLeaderboards[type.displayName] = entries;
      }
      
      return allLeaderboards;
    } catch (e) {
      debugPrint('Error getting all leaderboards: $e');
      return {};
    }
  }

  /// Get comprehensive user statistics
  Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final stats = <String, dynamic>{};
      
      // Get user's position in different leaderboards
      final leaderboardPositions = <String, LeaderboardPosition>{};
      final leaderboardTypes = [
        LeaderboardType.points,
        LeaderboardType.contributions,
        LeaderboardType.co2_saved,
        LeaderboardType.water_saved,
        LeaderboardType.energy_saved,
        LeaderboardType.trees_planted,
        LeaderboardType.challenges_completed,
        LeaderboardType.achievements_earned,
      ];
      
      for (final type in leaderboardTypes) {
        final position = await getUserPosition(
          userId: userId,
          type: type,
          period: LeaderboardPeriod.allTime,
        );
        leaderboardPositions[type.displayName] = position;
      }
      
      // Get user's weekly and monthly positions
      final weeklyPosition = await getUserPosition(
        userId: userId,
        type: LeaderboardType.weekly_points,
        period: LeaderboardPeriod.weekly,
      );
      
      final monthlyPosition = await getUserPosition(
        userId: userId,
        type: LeaderboardType.monthly_points,
        period: LeaderboardPeriod.monthly,
      );
      
      // Calculate overall statistics
      final totalRankings = leaderboardPositions.values.where((p) => p.ranking > 0).length;
      final averagePercentile = leaderboardPositions.values.isNotEmpty
          ? leaderboardPositions.values.map((p) => p.percentile).reduce((a, b) => a + b) / leaderboardPositions.values.length
          : 0.0;
      
      final topTenCount = leaderboardPositions.values.where((p) => p.isTopTen).length;
      final topHundredCount = leaderboardPositions.values.where((p) => p.isTopHundred).length;
      
      stats['user_id'] = userId;
      stats['leaderboard_positions'] = leaderboardPositions;
      stats['weekly_position'] = weeklyPosition;
      stats['monthly_position'] = monthlyPosition;
      stats['total_rankings'] = totalRankings;
      stats['average_percentile'] = averagePercentile;
      stats['top_ten_count'] = topTenCount;
      stats['top_hundred_count'] = topHundredCount;
      stats['last_updated'] = DateTime.now().toIso8601String();
      
      return stats;
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {'user_id': userId, 'error': 'Failed to load user stats'};
    }
  }

  /// Get weekly leaderboard (points-based)
  Future<List<LeaderboardEntryWithUser>> getWeeklyLeaderboard() async {
    try {
      return await getLeaderboard(
        type: LeaderboardType.weekly_points,
        period: LeaderboardPeriod.weekly,
        limit: 100,
      );
    } catch (e) {
      debugPrint('Error getting weekly leaderboard: $e');
      return [];
    }
  }

  /// Get monthly leaderboard (points-based)
  Future<List<LeaderboardEntryWithUser>> getMonthlyLeaderboard() async {
    try {
      return await getLeaderboard(
        type: LeaderboardType.monthly_points,
        period: LeaderboardPeriod.monthly,
        limit: 100,
      );
    } catch (e) {
      debugPrint('Error getting monthly leaderboard: $e');
      return [];
    }
  }

  /// Get all-time leaderboard (total points)
  Future<List<LeaderboardEntryWithUser>> getAllTimeLeaderboard() async {
    try {
      return await getLeaderboard(
        type: LeaderboardType.points,
        period: LeaderboardPeriod.allTime,
        limit: 100,
      );
    } catch (e) {
      debugPrint('Error getting all-time leaderboard: $e');
      return [];
    }
  }

  /// Get friends leaderboard for a specific user
  Future<List<LeaderboardEntryWithUser>> getFriendsLeaderboard(int userId) async {
    try {
      // Get user's friends list
      final friendsList = await _getUserFriends(userId);
      
      if (friendsList.isEmpty) {
        return [];
      }
      
      // Get leaderboard entries for friends
      final friendsEntries = <LeaderboardEntryWithUser>[];
      final allTimeLeaderboard = await getAllTimeLeaderboard();
      
      // Filter leaderboard to include only friends and the user
      final friendsAndUserIds = [...friendsList, userId];
      
      for (final entry in allTimeLeaderboard) {
        if (friendsAndUserIds.contains(entry.userId)) {
          friendsEntries.add(entry);
        }
      }
      
      // Re-rank the friends leaderboard
      friendsEntries.sort((a, b) => b.score.compareTo(a.score));
      
      // Update rankings for friends-only leaderboard
      final rerankedEntries = <LeaderboardEntryWithUser>[];
      for (int i = 0; i < friendsEntries.length; i++) {
        final entry = friendsEntries[i];
        rerankedEntries.add(LeaderboardEntryWithUser(
          id: entry.id,
          userId: entry.userId,
          username: entry.name,
          points: (entry.score).toInt(),
          co2Saved: 0.0,
          rank: i + 1,
          achievements: [],
          leaderboardType: entry.leaderboardType,
          score: entry.score,
          ranking: i + 1, // New ranking among friends
          periodStart: entry.periodStart,
          periodEnd: entry.periodEnd,
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
          name: entry.name,
          profileImage: entry.profileImage,
        ));
      }
      
      return rerankedEntries;
    } catch (e) {
      debugPrint('Error getting friends leaderboard: $e');
      return [];
    }
  }

  /// Get user's friends list (placeholder - would need to implement friends system)
  Future<List<int>> _getUserFriends(int userId) async {
    try {
      // This would query a friends/social table when implemented
      // For now, return an empty list as placeholder
      
      // Example query (table doesn't exist yet):
      // final db = await _databaseHelper.database;
      // final results = await db.query(
      //   'user_friends',
      //   columns: ['friend_id'],
      //   where: 'user_id = ? AND is_active = 1',
      //   whereArgs: [userId],
      // );
      // return results.map((row) => row['friend_id'] as int).toList();
      
      return []; // Return empty list for now
    } catch (e) {
      debugPrint('Error getting user friends: $e');
      return [];
    }
  }

  /// Get default period for a leaderboard type
  LeaderboardPeriod _getDefaultPeriodForType(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.weekly_points:
        return LeaderboardPeriod.weekly;
      case LeaderboardType.monthly_points:
        return LeaderboardPeriod.monthly;
      default:
        return LeaderboardPeriod.allTime;
    }
  }
}

/// Enum for leaderboard periods
enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime,
}

/// Extension for leaderboard type display names
extension LeaderboardTypeExtension on LeaderboardType {
  String get displayName {
    switch (this) {
      case LeaderboardType.points:
        return 'Total Points';
      case LeaderboardType.contributions:
        return 'Total Contributions';
      case LeaderboardType.co2_saved:
        return 'CO₂ Saved';
      case LeaderboardType.water_saved:
        return 'Water Saved';
      case LeaderboardType.energy_saved:
        return 'Energy Saved';
      case LeaderboardType.trees_planted:
        return 'Trees Planted';
      case LeaderboardType.challenges_completed:
        return 'Challenges Completed';
      case LeaderboardType.achievements_earned:
        return 'Achievements Earned';
      case LeaderboardType.weekly_points:
        return 'Weekly Points';
      case LeaderboardType.monthly_points:
        return 'Monthly Points';
    }
  }
}

/// Extension for leaderboard period display names
extension LeaderboardPeriodExtension on LeaderboardPeriod {
  String get displayName {
    switch (this) {
      case LeaderboardPeriod.daily:
        return 'Daily';
      case LeaderboardPeriod.weekly:
        return 'Weekly';
      case LeaderboardPeriod.monthly:
        return 'Monthly';
      case LeaderboardPeriod.allTime:
        return 'All Time';
    }
  }
}

/// Class representing period dates
class PeriodDates {
  final DateTime start;
  final DateTime end;

  PeriodDates({required this.start, required this.end});
}

/// Class representing user's leaderboard position
class LeaderboardPosition {
  final int userId;
  final LeaderboardType leaderboardType;
  final LeaderboardPeriod period;
  final int ranking;
  final double score;
  final int totalUsers;
  final double percentile;
  final List<LeaderboardEntryWithUser> nearbyUsers;
  final bool isTopTen;
  final bool isTopHundred;

  LeaderboardPosition({
    required this.userId,
    required this.leaderboardType,
    required this.period,
    required this.ranking,
    required this.score,
    required this.totalUsers,
    required this.percentile,
    required this.nearbyUsers,
    required this.isTopTen,
    required this.isTopHundred,
  });
}

/// Class representing leaderboard statistics
class LeaderboardStats {
  final LeaderboardType leaderboardType;
  final LeaderboardPeriod period;
  final int totalParticipants;
  final double averageScore;
  final double highestScore;
  final double lowestScore;
  final double medianScore;
  final double totalScore;

  LeaderboardStats({
    required this.leaderboardType,
    required this.period,
    required this.totalParticipants,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.medianScore,
    required this.totalScore,
  });
}

/// Class representing trending user data
class TrendingUser {
  final int userId;
  final double currentScore;
  final double previousScore;
  final double growth;
  final double growthRate;
  final LeaderboardType leaderboardType;
  final LeaderboardPeriod period;

  TrendingUser({
    required this.userId,
    required this.currentScore,
    required this.previousScore,
    required this.growth,
    required this.growthRate,
    required this.leaderboardType,
    required this.period,
  });
}

/// Class representing user comparison data
class UserComparison {
  final int user1Id;
  final int user2Id;
  final LeaderboardPosition user1Position;
  final LeaderboardPosition user2Position;
  final double scoreDifference;
  final int rankingDifference;
  final LeaderboardType leaderboardType;
  final LeaderboardPeriod period;

  UserComparison({
    required this.user1Id,
    required this.user2Id,
    required this.user1Position,
    required this.user2Position,
    required this.scoreDifference,
    required this.rankingDifference,
    required this.leaderboardType,
    required this.period,
  });
}