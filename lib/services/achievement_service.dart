import 'dart:async';
import '../helpers/database_helper.dart';
import '../models/achievement.dart';
import '../models/user.dart';
import '../models/notification.dart';

enum AchievementType {
  points,
  transactions,
  contributions,
  streak,
  environmental_impact,
  social,
  milestone,
  special
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond
}

class AchievementDefinition {
  final int id;
  final String name;
  final String description;
  final String icon;
  final AchievementType type;
  final AchievementTier tier;
  final int targetValue;
  final String targetUnit;
  final int pointsReward;
  final List<String> prerequisites;
  final bool isHidden;
  final DateTime? validFrom;
  final DateTime? validUntil;

  AchievementDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.tier,
    required this.targetValue,
    required this.targetUnit,
    required this.pointsReward,
    this.prerequisites = const [],
    this.isHidden = false,
    this.validFrom,
    this.validUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type.name,
      'tier': tier.name,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'points_reward': pointsReward,
      'prerequisites': prerequisites.join(','),
      'is_hidden': isHidden ? 1 : 0,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
    };
  }

  factory AchievementDefinition.fromMap(Map<String, dynamic> map) {
    return AchievementDefinition(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
      type: AchievementType.values.byName(map['type']),
      tier: AchievementTier.values.byName(map['tier']),
      targetValue: map['target_value'],
      targetUnit: map['target_unit'],
      pointsReward: map['points_reward'],
      prerequisites: map['prerequisites']?.split(',') ?? [],
      isHidden: map['is_hidden'] == 1,
      validFrom: map['valid_from'] != null ? DateTime.parse(map['valid_from']) : null,
      validUntil: map['valid_until'] != null ? DateTime.parse(map['valid_until']) : null,
    );
  }
}

class UserAchievementProgress {
  final int? id;
  final int userId;
  final int achievementId;
  final int currentProgress;
  final int targetValue;
  final int remainingValue;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAchievementProgress({
    this.id,
    required this.userId,
    required this.achievementId,
    required this.currentProgress,
    required this.targetValue,
    int? remainingValue,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : remainingValue = remainingValue ?? (targetValue - currentProgress).clamp(0, targetValue);

  double get progressPercentage => (currentProgress / targetValue).clamp(0.0, 1.0);
  bool get isNearCompletion => progressPercentage >= 0.8;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'current_progress': currentProgress,
      'target_value': targetValue,
      'remaining_value': remainingValue,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserAchievementProgress.fromMap(Map<String, dynamic> map) {
    return UserAchievementProgress(
      id: map['id'],
      userId: map['user_id'],
      achievementId: map['achievement_id'],
      currentProgress: map['current_progress'],
      targetValue: map['target_value'],
      remainingValue: map['remaining_value'],
      isCompleted: map['is_completed'] == 1,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class AchievementService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Achievement definitions
  static final List<AchievementDefinition> _achievements = [
    // Points-based achievements
    AchievementDefinition(
      id: 1,
      name: 'First Steps',
      description: 'Earn your first 100 points',
      icon: '🌱',
      type: AchievementType.points,
      tier: AchievementTier.bronze,
      targetValue: 100,
      targetUnit: 'points',
      pointsReward: 50,
    ),
    AchievementDefinition(
      id: 2,
      name: 'Eco Enthusiast',
      description: 'Earn 500 points',
      icon: '🌿',
      type: AchievementType.points,
      tier: AchievementTier.silver,
      targetValue: 500,
      targetUnit: 'points',
      pointsReward: 100,
    ),
    AchievementDefinition(
      id: 3,
      name: 'Green Guardian',
      description: 'Earn 1,000 points',
      icon: '🌳',
      type: AchievementType.points,
      tier: AchievementTier.gold,
      targetValue: 1000,
      targetUnit: 'points',
      pointsReward: 200,
    ),
    AchievementDefinition(
      id: 4,
      name: 'Eco Warrior',
      description: 'Earn 2,500 points',
      icon: '🏆',
      type: AchievementType.points,
      tier: AchievementTier.platinum,
      targetValue: 2500,
      targetUnit: 'points',
      pointsReward: 500,
    ),
    AchievementDefinition(
      id: 5,
      name: 'Planet Protector',
      description: 'Earn 5,000 points',
      icon: '🌍',
      type: AchievementType.points,
      tier: AchievementTier.diamond,
      targetValue: 5000,
      targetUnit: 'points',
      pointsReward: 1000,
    ),
    
    // Transaction-based achievements
    AchievementDefinition(
      id: 6,
      name: 'First Purchase',
      description: 'Make your first eco-friendly transaction',
      icon: '💳',
      type: AchievementType.transactions,
      tier: AchievementTier.bronze,
      targetValue: 1,
      targetUnit: 'transactions',
      pointsReward: 25,
    ),
    AchievementDefinition(
      id: 7,
      name: 'Frequent Shopper',
      description: 'Make 10 eco-friendly transactions',
      icon: '🛒',
      type: AchievementType.transactions,
      tier: AchievementTier.silver,
      targetValue: 10,
      targetUnit: 'transactions',
      pointsReward: 100,
    ),
    AchievementDefinition(
      id: 8,
      name: 'Eco Shopping Master',
      description: 'Make 50 eco-friendly transactions',
      icon: '🛍️',
      type: AchievementType.transactions,
      tier: AchievementTier.gold,
      targetValue: 50,
      targetUnit: 'transactions',
      pointsReward: 250,
    ),
    
    // Contribution-based achievements
    AchievementDefinition(
      id: 9,
      name: 'First Contribution',
      description: 'Make your first environmental contribution',
      icon: '💚',
      type: AchievementType.contributions,
      tier: AchievementTier.bronze,
      targetValue: 1,
      targetUnit: 'contributions',
      pointsReward: 50,
    ),
    AchievementDefinition(
      id: 10,
      name: 'Generous Giver',
      description: 'Make 5 environmental contributions',
      icon: '🎁',
      type: AchievementType.contributions,
      tier: AchievementTier.silver,
      targetValue: 5,
      targetUnit: 'contributions',
      pointsReward: 150,
    ),
    AchievementDefinition(
      id: 11,
      name: 'Environmental Philanthropist',
      description: 'Make 20 environmental contributions',
      icon: '🌟',
      type: AchievementType.contributions,
      tier: AchievementTier.gold,
      targetValue: 20,
      targetUnit: 'contributions',
      pointsReward: 500,
    ),
    
    // Streak-based achievements
    AchievementDefinition(
      id: 12,
      name: 'Consistent Contributor',
      description: 'Make contributions for 3 consecutive days',
      icon: '🔥',
      type: AchievementType.streak,
      tier: AchievementTier.bronze,
      targetValue: 3,
      targetUnit: 'days',
      pointsReward: 100,
    ),
    AchievementDefinition(
      id: 13,
      name: 'Streak Master',
      description: 'Make contributions for 7 consecutive days',
      icon: '⚡',
      type: AchievementType.streak,
      tier: AchievementTier.silver,
      targetValue: 7,
      targetUnit: 'days',
      pointsReward: 300,
    ),
    AchievementDefinition(
      id: 14,
      name: 'Dedication Champion',
      description: 'Make contributions for 30 consecutive days',
      icon: '🏅',
      type: AchievementType.streak,
      tier: AchievementTier.gold,
      targetValue: 30,
      targetUnit: 'days',
      pointsReward: 1000,
    ),
    
    // Environmental impact achievements
    AchievementDefinition(
      id: 15,
      name: 'Carbon Saver',
      description: 'Offset 1kg of CO2 emissions',
      icon: '🌬️',
      type: AchievementType.environmental_impact,
      tier: AchievementTier.bronze,
      targetValue: 1,
      targetUnit: 'kg CO2',
      pointsReward: 100,
    ),
    AchievementDefinition(
      id: 16,
      name: 'Tree Planter',
      description: 'Plant equivalent of 5 trees',
      icon: '🌲',
      type: AchievementType.environmental_impact,
      tier: AchievementTier.silver,
      targetValue: 5,
      targetUnit: 'trees',
      pointsReward: 250,
    ),
    AchievementDefinition(
      id: 17,
      name: 'Water Guardian',
      description: 'Save 1000 liters of water',
      icon: '💧',
      type: AchievementType.environmental_impact,
      tier: AchievementTier.gold,
      targetValue: 1000,
      targetUnit: 'liters',
      pointsReward: 400,
    ),
    
    // Milestone achievements
    AchievementDefinition(
      id: 18,
      name: 'Level Up!',
      description: 'Reach level 5',
      icon: '🎖️',
      type: AchievementType.milestone,
      tier: AchievementTier.silver,
      targetValue: 5,
      targetUnit: 'level',
      pointsReward: 200,
    ),
    AchievementDefinition(
      id: 19,
      name: 'Elite Status',
      description: 'Reach level 10',
      icon: '👑',
      type: AchievementType.milestone,
      tier: AchievementTier.gold,
      targetValue: 10,
      targetUnit: 'level',
      pointsReward: 500,
    ),
    
    // Special achievements
    AchievementDefinition(
      id: 20,
      name: 'Early Adopter',
      description: 'Join EcoPay in the first month',
      icon: '🚀',
      type: AchievementType.special,
      tier: AchievementTier.platinum,
      targetValue: 1,
      targetUnit: 'qualification',
      pointsReward: 1000,
      validUntil: DateTime(2024, 12, 31),
    ),
  ];

  /// Get all achievement definitions
  List<AchievementDefinition> get allAchievements => _achievements;

  /// Get achievement definition by ID
  AchievementDefinition? getAchievementById(int id) {
    try {
      return _achievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get user's achievement progress
  Future<List<UserAchievementProgress>> getUserAchievementProgress(int userId) async {
    try {
      final results = await _databaseHelper.getAllUserAchievementProgress(userId);
      return results.map((map) => UserAchievementProgress.fromMap(map)).toList();
    } catch (e) {
      print('Error getting user achievement progress: $e');
      return [];
    }
  }

  /// Update achievement progress
  Future<bool> updateAchievementProgress(int userId, AchievementType type, int value) async {
    try {
      final relevantAchievements = _achievements.where((a) => a.type == type).toList();
      bool anyUnlocked = false;
      
      for (final achievement in relevantAchievements) {
        final progress = await _getOrCreateProgress(userId, achievement.id);
        
        if (progress.isCompleted) continue;
        
        final newProgress = switch (type) {
          AchievementType.points => value,
          AchievementType.transactions => progress.currentProgress + 1,
          AchievementType.contributions => progress.currentProgress + 1,
          AchievementType.streak => value,
          AchievementType.environmental_impact => progress.currentProgress + value,
          AchievementType.milestone => value,
          _ => progress.currentProgress + value,
        };
        
        final updated = UserAchievementProgress(
          id: progress.id,
          userId: userId,
          achievementId: achievement.id,
          currentProgress: newProgress,
          targetValue: achievement.targetValue,
          isCompleted: newProgress >= achievement.targetValue,
          completedAt: newProgress >= achievement.targetValue ? DateTime.now() : null,
          createdAt: progress.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _updateProgress(updated);
        
        // Check if achievement was just completed
        if (!progress.isCompleted && updated.isCompleted) {
          await _unlockAchievement(userId, achievement);
          anyUnlocked = true;
        }
      }
      
      return anyUnlocked;
    } catch (e) {
      print('Error updating achievement progress: $e');
      return false;
    }
  }

  /// Get or create progress for an achievement
  Future<UserAchievementProgress> _getOrCreateProgress(int userId, int achievementId) async {
    try {
      final result = await _databaseHelper.getUserAchievementProgress(userId, achievementId);
      
      if (result != null) {
        return UserAchievementProgress.fromMap(result);
      }
      
      // Create new progress
      final achievement = getAchievementById(achievementId)!;
      final progress = UserAchievementProgress(
        userId: userId,
        achievementId: achievementId,
        currentProgress: 0,
        targetValue: achievement.targetValue,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _createProgress(progress);
      return progress;
    } catch (e) {
      print('Error getting/creating progress: $e');
      rethrow;
    }
  }

  /// Create new achievement progress
  Future<void> _createProgress(UserAchievementProgress progress) async {
    await _databaseHelper.insertUserAchievementProgress(progress.toMap());
  }

  /// Update achievement progress
  Future<void> _updateProgress(UserAchievementProgress progress) async {
    await _databaseHelper.updateUserAchievementProgress(
      progress.userId,
      progress.achievementId,
      progress.currentProgress,
    );
    
    // If completed, mark as completed
    if (progress.isCompleted) {
      await _databaseHelper.completeUserAchievement(
        progress.userId,
        progress.achievementId,
      );
    }
  }

  /// Unlock achievement and award points
  Future<void> _unlockAchievement(int userId, AchievementDefinition achievement) async {
    try {
      // Record achievement unlock
      await _databaseHelper.insertUserAchievement({
        'user_id': userId,
        'achievement_id': achievement.id,
        'date_unlocked': DateTime.now().toIso8601String(),
      });
      
      // Award points
      await _databaseHelper.addUserPoints(
        userId, 
        achievement.pointsReward, 
        'achievement',
        achievementId: achievement.id,
      );
      
      // Add badge to user
      await _databaseHelper.addBadgeToUser(userId, 'achievement_${achievement.id}');
      
      // Create notification
      await _databaseHelper.insertNotification(
        Notification.achievementUnlocked(
          userId: userId,
          achievementName: achievement.name,
          achievementId: achievement.id,
          pointsEarned: achievement.pointsReward,
        ).toMap(),
      );
      
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  /// Get achievement statistics for user
  Future<Map<String, dynamic>> getAchievementStats(int userId) async {
    try {
      final dbStats = await _databaseHelper.getAchievementStatistics(userId);
      final unlocked = await _databaseHelper.getUserAchievements(userId);
      
      final totalPoints = unlocked.fold(0, (sum, ua) {
        final achievement = getAchievementById(ua['achievement_id']);
        return sum + (achievement?.pointsReward ?? 0);
      });
      
      return {
        'total_achievements': _achievements.length,
        'completed': dbStats['completed_achievements'] ?? 0,
        'in_progress': dbStats['in_progress_achievements'] ?? 0,
        'completion_rate': (dbStats['completed_achievements'] ?? 0) / _achievements.length,
        'total_points_earned': totalPoints,
        'average_progress': dbStats['average_progress'] ?? 0.0,
        'recent_unlocks': unlocked.take(5).toList(),
      };
    } catch (e) {
      print('Error getting achievement stats: $e');
      return {};
    }
  }

  /// Get achievements by tier
  List<AchievementDefinition> getAchievementsByTier(AchievementTier tier) {
    return _achievements.where((a) => a.tier == tier).toList();
  }

  /// Get achievements by type
  List<AchievementDefinition> getAchievementsByType(AchievementType type) {
    return _achievements.where((a) => a.type == type).toList();
  }

  /// Initialize achievement system for user
  Future<void> initializeUserAchievements(int userId) async {
    try {
      for (final achievement in _achievements) {
        await _getOrCreateProgress(userId, achievement.id);
      }
    } catch (e) {
      print('Error initializing user achievements: $e');
    }
  }

  /// Get completed achievements for user
  Future<List<UserAchievementProgress>> getCompletedAchievements(int userId) async {
    try {
      final results = await _databaseHelper.getCompletedAchievements(userId);
      return results.map((map) => UserAchievementProgress.fromMap(map)).toList();
    } catch (e) {
      print('Error getting completed achievements: $e');
      return [];
    }
  }

  /// Get in-progress achievements for user
  Future<List<UserAchievementProgress>> getInProgressAchievements(int userId) async {
    try {
      final results = await _databaseHelper.getInProgressAchievements(userId);
      return results.map((map) => UserAchievementProgress.fromMap(map)).toList();
    } catch (e) {
      print('Error getting in-progress achievements: $e');
      return [];
    }
  }

  /// Get achievement progress for specific achievement
  Future<UserAchievementProgress?> getSpecificAchievementProgress(int userId, int achievementId) async {
    try {
      final result = await _databaseHelper.getUserAchievementProgress(userId, achievementId);
      return result != null ? UserAchievementProgress.fromMap(result) : null;
    } catch (e) {
      print('Error getting specific achievement progress: $e');
      return null;
    }
  }

  /// Check if user has completed specific achievement
  Future<bool> hasCompletedAchievement(int userId, int achievementId) async {
    try {
      final progress = await getSpecificAchievementProgress(userId, achievementId);
      return progress?.isCompleted ?? false;
    } catch (e) {
      print('Error checking achievement completion: $e');
      return false;
    }
  }

  /// Update multiple achievement types at once (for transactions)
  Future<List<String>> updateMultipleAchievements(int userId, Map<AchievementType, int> updates) async {
    final unlockedAchievements = <String>[];
    
    for (final entry in updates.entries) {
      try {
        final unlocked = await updateAchievementProgress(userId, entry.key, entry.value);
        if (unlocked) {
          final relevantAchievements = _achievements.where((a) => a.type == entry.key);
          for (final achievement in relevantAchievements) {
            final progress = await getSpecificAchievementProgress(userId, achievement.id);
            if (progress?.isCompleted == true) {
              unlockedAchievements.add(achievement.name);
            }
          }
        }
      } catch (e) {
        print('Error updating achievement type ${entry.key}: $e');
      }
    }
    
    return unlockedAchievements;
  }

  /// Get achievements that are close to completion (>80% progress)
  Future<List<Map<String, dynamic>>> getNearCompletionAchievements(int userId) async {
    try {
      final progress = await getInProgressAchievements(userId);
      final nearCompletion = progress.where((p) => p.isNearCompletion).toList();
      
      return nearCompletion.map((p) {
        final achievement = getAchievementById(p.achievementId);
        return {
          'progress': p,
          'achievement': achievement,
          'percentage': (p.progressPercentage * 100).round(),
        };
      }).toList();
    } catch (e) {
      print('Error getting near completion achievements: $e');
      return [];
    }
  }

  /// Get achievements by category for display
  Future<Map<String, List<Map<String, dynamic>>>> getAchievementsByCategory(int userId) async {
    try {
      final userProgress = await getUserAchievementProgress(userId);
      final progressMap = {for (var p in userProgress) p.achievementId: p};
      
      final categorized = <String, List<Map<String, dynamic>>>{};
      
      for (final type in AchievementType.values) {
        final achievements = getAchievementsByType(type);
        categorized[type.name] = achievements.map((achievement) {
          final progress = progressMap[achievement.id];
          return {
            'achievement': achievement,
            'progress': progress,
            'percentage': progress != null ? (progress.progressPercentage * 100).round() : 0,
          };
        }).toList();
      }
      
      return categorized;
    } catch (e) {
      print('Error getting achievements by category: $e');
      return {};
    }
  }
}