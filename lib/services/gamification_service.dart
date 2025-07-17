import 'dart:math';
import '../helpers/database_helper.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';
import '../models/notification.dart';
import '../models/contribution.dart';
import '../models/transaction.dart' as app_transaction;
import '../utils/environmental_impact_calculator.dart';
import '../services/leaderboard_service.dart';
import '../services/notification_service.dart';

class GamificationService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final LeaderboardService _leaderboardService = LeaderboardService();
  NotificationService get _notificationService => NotificationService();

  // Points calculation constants
  static const int POINTS_PER_RINGGIT_TRANSACTION = 10;
  static const int POINTS_PER_RINGGIT_CONTRIBUTION = 50;
  static const int DAILY_LOGIN_BONUS = 5;
  static const int CHALLENGE_COMPLETION_BONUS = 100;
  static const int ACHIEVEMENT_UNLOCK_BONUS = 200;
  static const int LEVEL_UP_BONUS = 500;

  // Environmental impact points multipliers
  static const double CO2_POINTS_MULTIPLIER = 100.0; // 100 points per kg CO2 saved
  static const double WATER_POINTS_MULTIPLIER = 1.0; // 1 point per liter saved
  static const double ENERGY_POINTS_MULTIPLIER = 10.0; // 10 points per kWh saved
  static const double TREE_POINTS_MULTIPLIER = 500.0; // 500 points per tree equivalent

  // Level thresholds
  static const List<int> LEVEL_THRESHOLDS = [
    0, 100, 300, 600, 1000, 1500, 2100, 2800, 3600, 4500, 5500, 6600, 7800, 9100, 10500, 12000
  ];

  /// Initialize the gamification service
  void initialize() {
    _leaderboardService.initialize();
    _notificationService.initialize();
  }

  /// Dispose of resources
  void dispose() {
    _leaderboardService.dispose();
    _notificationService.dispose();
  }

  /// Calculate and award points for a transaction
  Future<int> awardTransactionPoints(int userId, app_transaction.Transaction transaction) async {
    try {
      // Base points for transaction amount
      int basePoints = (transaction.amount * POINTS_PER_RINGGIT_TRANSACTION).round();
      
      // Environmental impact bonus points
      final impactData = EnvironmentalImpactCalculator.getEnvironmentalImpact(transaction.amount);
      int environmentalPoints = _calculateEnvironmentalPoints(impactData);
      
      // Merchant-specific bonus
      int merchantBonus = _calculateMerchantBonus(transaction.merchantName);
      
      // Time-based bonus (evening/weekend transactions get bonus)
      int timeBonus = _calculateTimeBonus(transaction.transactionDate);
      
      int totalPoints = basePoints + environmentalPoints + merchantBonus + timeBonus;
      
      // Award points to user
      await _databaseHelper.addUserPoints(
        userId, 
        totalPoints, 
        'transaction',
        transactionId: transaction.transactionId,
      );
      
      // Check for achievements and level ups
      await _checkAchievements(userId);
      await _checkLevelUp(userId);
      
      // Update challenge progress
      await _updateChallengeProgress(userId, ChallengeType.transactions, 1);
      
      // Update leaderboard entries
      await _leaderboardService.updateUserEntry(
        userId: userId,
        type: LeaderboardType.points,
        score: totalPoints.toDouble(),
        period: LeaderboardPeriod.allTime,
      );
      
      // Create notification
      await _createNotification(Notification.pointsEarned(
        userId: userId,
        pointsEarned: totalPoints,
        source: 'transaction with ${transaction.merchantName}',
      ));
      
      return totalPoints;
    } catch (e) {
      print('Error awarding transaction points: $e');
      return 0;
    }
  }

  /// Calculate and award points for a contribution
  Future<int> awardContributionPoints(int userId, Contribution contribution) async {
    try {
      // Base points for contribution amount
      int basePoints = (contribution.amount * POINTS_PER_RINGGIT_CONTRIBUTION).round();
      
      // Environmental impact bonus points
      final impactData = EnvironmentalImpactCalculator.getEnvironmentalImpact(contribution.amount);
      int environmentalPoints = _calculateEnvironmentalPoints(impactData);
      
      // Project-specific bonus
      int projectBonus = _calculateProjectBonus(contribution.projectId);
      
      // Streak bonus (consecutive days of contributions)
      int streakBonus = await _calculateContributionStreak(userId);
      
      int totalPoints = basePoints + environmentalPoints + projectBonus + streakBonus;
      
      // Award points to user
      await _databaseHelper.addUserPoints(
        userId, 
        totalPoints, 
        'contribution',
        contributionId: contribution.id,
      );
      
      // Check for achievements and level ups
      await _checkAchievements(userId);
      await _checkLevelUp(userId);
      
      // Update challenge progress
      await _updateChallengeProgress(userId, ChallengeType.contributions, 1);
      await _updateChallengeProgress(userId, ChallengeType.environmental_impact, contribution.amount.round());
      
      // Update leaderboard entries
      await _leaderboardService.updateUserEntry(
        userId: userId,
        type: LeaderboardType.points,
        score: totalPoints.toDouble(),
        period: LeaderboardPeriod.allTime,
      );
      await _leaderboardService.updateUserEntry(
        userId: userId,
        type: LeaderboardType.contributions,
        score: contribution.amount,
        period: LeaderboardPeriod.allTime,
      );
      
      // Create notification
      await _createNotification(Notification.pointsEarned(
        userId: userId,
        pointsEarned: totalPoints,
        source: 'environmental contribution',
      ));
      
      return totalPoints;
    } catch (e) {
      print('Error awarding contribution points: $e');
      return 0;
    }
  }

  /// Calculate environmental impact points
  int _calculateEnvironmentalPoints(Map<String, dynamic> impactData) {
    double co2Points = (impactData['co2_offset_kg'] ?? 0.0) * CO2_POINTS_MULTIPLIER;
    double waterPoints = (impactData['water_saved_liters'] ?? 0.0) * WATER_POINTS_MULTIPLIER;
    double energyPoints = (impactData['energy_saved_kwh'] ?? 0.0) * ENERGY_POINTS_MULTIPLIER;
    double treePoints = (impactData['tree_equivalent'] ?? 0.0) * TREE_POINTS_MULTIPLIER;
    
    return (co2Points + waterPoints + energyPoints + treePoints).round();
  }

  /// Calculate merchant-specific bonus
  int _calculateMerchantBonus(String merchantName) {
    // Eco-friendly merchants get bonus points
    final ecoMerchants = [
      'EcoMart', 'Green Grocers', 'Sustainable Store', 'Organic Market',
      'Solar Solutions', 'Wind Power Co', 'Recycling Center', 'Bike Shop'
    ];
    
    return ecoMerchants.any((merchant) => merchantName.toLowerCase().contains(merchant.toLowerCase())) ? 20 : 0;
  }

  /// Calculate time-based bonus
  int _calculateTimeBonus(DateTime transactionDate) {
    // Evening transactions (6-10 PM) get bonus
    if (transactionDate.hour >= 18 && transactionDate.hour <= 22) {
      return 5;
    }
    // Weekend transactions get bonus
    if (transactionDate.weekday == DateTime.saturday || transactionDate.weekday == DateTime.sunday) {
      return 10;
    }
    return 0;
  }

  /// Calculate project-specific bonus
  int _calculateProjectBonus(int projectId) {
    // Different project types have different bonus multipliers
    final projectBonuses = {
      1: 50,  // Mangrove Restoration - high impact
      2: 30,  // Solar Panel Installation - medium impact
      3: 40,  // Clean Water Wells - medium-high impact
      4: 60,  // Rainforest Conservation - highest impact
      5: 35,  // Ocean Cleanup - medium impact
    };
    
    return projectBonuses[projectId] ?? 25;
  }

  /// Calculate contribution streak bonus
  Future<int> _calculateContributionStreak(int userId) async {
    try {
      final contributions = await _databaseHelper.getContributionsByUser(userId);
      if (contributions.isEmpty) return 0;
      
      // Sort by timestamp descending
      contributions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      int streakDays = 1;
      DateTime lastDate = contributions[0].timestamp;
      
      for (int i = 1; i < contributions.length; i++) {
        final currentDate = contributions[i].timestamp;
        final daysDiff = lastDate.difference(currentDate).inDays;
        
        if (daysDiff == 1) {
          streakDays++;
          lastDate = currentDate;
        } else {
          break;
        }
      }
      
      // Award bonus points based on streak length
      return min(streakDays * 10, 100); // Max 100 bonus points
    } catch (e) {
      print('Error calculating contribution streak: $e');
      return 0;
    }
  }

  /// Award daily login bonus
  Future<int> awardDailyLoginBonus(int userId) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      // Check if user already got daily login bonus today
      final existingBonus = await _databaseHelper.getUserPointsHistory(userId);
      final todayBonus = existingBonus.where((point) {
        final pointDate = DateTime.parse(point['timestamp']);
        return point['points_source'] == 'daily_login' &&
               pointDate.isAfter(todayStart) &&
               pointDate.isBefore(todayEnd);
      }).toList();
      
      if (todayBonus.isNotEmpty) {
        return 0; // Already got bonus today
      }
      
      // Award daily login bonus
      await _databaseHelper.addUserPoints(userId, DAILY_LOGIN_BONUS, 'daily_login');
      
      // Update challenge progress
      await _updateChallengeProgress(userId, ChallengeType.daily_login, 1);
      
      return DAILY_LOGIN_BONUS;
    } catch (e) {
      print('Error awarding daily login bonus: $e');
      return 0;
    }
  }

  /// Check and unlock achievements
  Future<void> _checkAchievements(int userId) async {
    try {
      final user = await _databaseHelper.getUser(userId);
      if (user == null) return;
      
      final userAchievements = await _databaseHelper.getUserAchievements(userId);
      final unlockedAchievementIds = userAchievements.map((ua) => ua['achievement_id'] as int).toList();
      
      // Define achievements to check
      final achievementsToCheck = [
        {'id': 1, 'points_required': 100, 'name': 'First Steps', 'description': 'Earn your first 100 points'},
        {'id': 2, 'points_required': 500, 'name': 'Getting Started', 'description': 'Earn 500 points'},
        {'id': 3, 'points_required': 1000, 'name': 'Eco Warrior', 'description': 'Earn 1000 points'},
        {'id': 4, 'points_required': 2500, 'name': 'Environmental Champion', 'description': 'Earn 2500 points'},
        {'id': 5, 'points_required': 5000, 'name': 'Planet Protector', 'description': 'Earn 5000 points'},
      ];
      
      for (final achievement in achievementsToCheck) {
        final achievementId = achievement['id'] as int;
        final pointsRequired = achievement['points_required'] as int;
        final name = achievement['name'] as String;
        
        if (!unlockedAchievementIds.contains(achievementId) && user.totalPoints >= pointsRequired) {
          // Unlock achievement
          await _databaseHelper.insertUserAchievement({
            'user_id': userId,
            'achievement_id': achievementId,
            'date_unlocked': DateTime.now().toIso8601String(),
          });
          
          // Award bonus points
          await _databaseHelper.addUserPoints(userId, ACHIEVEMENT_UNLOCK_BONUS, 'achievement', achievementId: achievementId);
          
          // Add badge to user
          await _databaseHelper.addBadgeToUser(userId, 'achievement_$achievementId');
          
          // Create notification
          await _createNotification(Notification.achievementUnlocked(
            userId: userId,
            achievementName: name,
            achievementId: achievementId,
            pointsEarned: ACHIEVEMENT_UNLOCK_BONUS,
          ));
        }
      }
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  /// Check and handle level up
  Future<void> _checkLevelUp(int userId) async {
    try {
      final user = await _databaseHelper.getUser(userId);
      if (user == null) return;
      
      final currentLevel = user.level;
      final newLevel = _calculateLevel(user.totalPoints);
      
      if (newLevel > currentLevel) {
        // Update user level
        await _databaseHelper.updateUserLevel(userId, newLevel);
        
        // Award level up bonus
        await _databaseHelper.addUserPoints(userId, LEVEL_UP_BONUS, 'milestone');
        
        // Create notification
        await _createNotification(Notification.levelUp(
          userId: userId,
          newLevel: newLevel,
          pointsEarned: LEVEL_UP_BONUS,
        ));
      }
    } catch (e) {
      print('Error checking level up: $e');
    }
  }

  /// Calculate user level based on total points
  int _calculateLevel(int totalPoints) {
    for (int i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
      if (totalPoints >= LEVEL_THRESHOLDS[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Update challenge progress
  Future<void> _updateChallengeProgress(int userId, ChallengeType challengeType, int progressAmount) async {
    try {
      final activeChallenges = await _databaseHelper.getActiveChallenges();
      final relevantChallenges = activeChallenges.where((c) => c['challenge_type'] == challengeType.name).toList();
      
      for (final challengeData in relevantChallenges) {
        final challengeId = challengeData['id'] as int;
        final targetValue = challengeData['target_value'] as int;
        
        // Get or create challenge progress
        var progress = await _databaseHelper.getChallengeProgress(userId, challengeId);
        
        if (progress == null) {
          // Create new progress
          await _databaseHelper.insertChallengeProgress({
            'user_id': userId,
            'challenge_id': challengeId,
            'current_progress': progressAmount,
            'is_completed': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } else {
          // Update existing progress
          final newProgress = (progress['current_progress'] as int) + progressAmount;
          await _databaseHelper.updateChallengeProgress(userId, challengeId, newProgress);
          
          // Check if challenge is completed
          if (newProgress >= targetValue && progress['is_completed'] == 0) {
            await _databaseHelper.completeChallenge(userId, challengeId);
            
            // Award challenge completion bonus
            final pointsReward = challengeData['points_reward'] as int;
            await _databaseHelper.addUserPoints(userId, pointsReward, 'challenge', challengeId: challengeId);
            
            // Create notification
            await _createNotification(Notification.challengeCompleted(
              userId: userId,
              challengeTitle: challengeData['title'] as String,
              challengeId: challengeId,
              pointsEarned: pointsReward,
            ));
          } else {
            // Check for progress milestones
            final progressPercentage = (newProgress / targetValue);
            if (progressPercentage >= 0.5 && (progress['current_progress'] as int) / targetValue < 0.5) {
              // 50% milestone
              await _createNotification(Notification.challengeProgress(
                userId: userId,
                challengeTitle: challengeData['title'] as String,
                challengeId: challengeId,
                currentProgress: newProgress,
                targetValue: targetValue,
              ));
            }
          }
        }
      }
    } catch (e) {
      print('Error updating challenge progress: $e');
    }
  }

  /// Create notification
  Future<void> _createNotification(Notification notification) async {
    try {
      await _notificationService.sendNotification(notification);
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  /// Get user's current gamification status
  Future<Map<String, dynamic>> getUserGamificationStatus(int userId) async {
    try {
      final user = await _databaseHelper.getUser(userId);
      if (user == null) return {};
      
      final pointsHistory = await _databaseHelper.getUserPointsHistory(userId);
      final challengeProgress = await _databaseHelper.getUserChallengeProgress(userId);
      final achievements = await _databaseHelper.getUserAchievements(userId);
      final notifications = await _databaseHelper.getUserNotifications(userId);
      
      return {
        'user': user.toMap(),
        'total_points': user.totalPoints,
        'level': user.level,
        'next_level_threshold': _getNextLevelThreshold(user.level),
        'points_to_next_level': _getPointsToNextLevel(user.totalPoints, user.level),
        'badges': user.badgesList,
        'recent_points': pointsHistory.take(10).toList(),
        'active_challenges': challengeProgress,
        'achievements_count': achievements.length,
        'unread_notifications': notifications.where((n) => n['is_read'] == 0).length,
      };
    } catch (e) {
      print('Error getting user gamification status: $e');
      return {};
    }
  }

  /// Get next level threshold
  int _getNextLevelThreshold(int currentLevel) {
    if (currentLevel >= LEVEL_THRESHOLDS.length) {
      return LEVEL_THRESHOLDS.last;
    }
    return LEVEL_THRESHOLDS[currentLevel];
  }

  /// Get points needed for next level
  int _getPointsToNextLevel(int currentPoints, int currentLevel) {
    final nextThreshold = _getNextLevelThreshold(currentLevel);
    return max(0, nextThreshold - currentPoints);
  }

  /// Update leaderboards using the advanced LeaderboardService
  Future<void> updateLeaderboards() async {
    try {
      // The LeaderboardService handles real-time updates automatically
      // This method now focuses on manual refresh and environmental impact calculations
      
      final users = await _databaseHelper.database.then((db) => db.query('users'));
      
      for (final user in users) {
        final userId = user['id'] as int;
        
        // Update environmental impact leaderboards
        final contributions = await _databaseHelper.getContributionsByUser(userId);
        double totalCO2 = 0.0;
        double totalWater = 0.0;
        double totalEnergy = 0.0;
        double totalTrees = 0.0;
        
        for (final contribution in contributions) {
          final impactData = EnvironmentalImpactCalculator.getEnvironmentalImpact(contribution.amount);
          totalCO2 += impactData['co2_offset_kg'] ?? 0.0;
          totalWater += impactData['water_saved_liters'] ?? 0.0;
          totalEnergy += impactData['energy_saved_kwh'] ?? 0.0;
          totalTrees += impactData['tree_equivalent'] ?? 0.0;
        }
        
        // Update environmental impact leaderboards
        await _leaderboardService.updateUserEntry(
          userId: userId,
          type: LeaderboardType.co2_saved,
          score: totalCO2,
          period: LeaderboardPeriod.allTime,
        );
        
        await _leaderboardService.updateUserEntry(
          userId: userId,
          type: LeaderboardType.water_saved,
          score: totalWater,
          period: LeaderboardPeriod.allTime,
        );
        
        await _leaderboardService.updateUserEntry(
          userId: userId,
          type: LeaderboardType.energy_saved,
          score: totalEnergy,
          period: LeaderboardPeriod.allTime,
        );
        
        await _leaderboardService.updateUserEntry(
          userId: userId,
          type: LeaderboardType.trees_planted,
          score: totalTrees,
          period: LeaderboardPeriod.allTime,
        );
        
        // Update challenge and achievement counts
        final challengeProgress = await _databaseHelper.getUserChallengeProgress(userId);
        final completedChallenges = challengeProgress.where((cp) => cp['is_completed'] == 1).length;
        
        await _leaderboardService.updateUserEntry(
          userId: userId,
          type: LeaderboardType.challenges_completed,
          score: completedChallenges.toDouble(),
          period: LeaderboardPeriod.allTime,
        );
        
        final achievements = await _databaseHelper.getUserAchievements(userId);
        await _leaderboardService.updateUserEntry(
          userId: userId,
          type: LeaderboardType.achievements_earned,
          score: achievements.length.toDouble(),
          period: LeaderboardPeriod.allTime,
        );
      }
      
    } catch (e) {
      print('Error updating leaderboards: $e');
    }
  }
}