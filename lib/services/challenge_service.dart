import 'dart:async';
import '../helpers/database_helper.dart';
import '../models/challenge.dart';
import '../models/challenge_progress.dart';
import '../models/notification.dart';
import '../services/gamification_service.dart';
import '../utils/environmental_impact_calculator.dart';

enum ChallengeCategory {
  transactions,
  contributions,
  environmental_impact,
  social,
  streak,
  spending,
  savings
}

class ChallengeDefinition {
  final int? id;
  final String title;
  final String description;
  final String icon;
  final ChallengeType type;
  final ChallengeCategory category;
  final int targetValue;
  final String targetUnit;
  final int pointsReward;
  final int difficultyLevel;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final Map<String, dynamic> conditions;
  final List<String> tags;

  ChallengeDefinition({
    this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.category,
    required this.targetValue,
    required this.targetUnit,
    required this.pointsReward,
    required this.difficultyLevel,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.conditions = const {},
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'challenge_type': type.name,
      'category': category.name,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'points_reward': pointsReward,
      'difficulty_level': difficultyLevel,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'conditions': conditions.toString(),
      'tags': tags.join(','),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory ChallengeDefinition.fromMap(Map<String, dynamic> map) {
    return ChallengeDefinition(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      type: ChallengeType.values.byName(map['challenge_type']),
      category: ChallengeCategory.values.byName(map['category']),
      targetValue: map['target_value'],
      targetUnit: map['target_unit'],
      pointsReward: map['points_reward'],
      difficultyLevel: map['difficulty_level'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isActive: map['is_active'] == 1,
      conditions: {}, // Parse conditions if needed
      tags: map['tags']?.split(',') ?? [],
    );
  }
}

class UserChallengeProgress {
  final int? id;
  final int userId;
  final int challengeId;
  final int currentProgress;
  final int targetValue;
  final bool isCompleted;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChallengeDefinition? challenge;

  UserChallengeProgress({
    this.id,
    required this.userId,
    required this.challengeId,
    required this.currentProgress,
    required this.targetValue,
    required this.isCompleted,
    this.completionDate,
    required this.createdAt,
    required this.updatedAt,
    this.challenge,
  });

  double get progressPercentage => (currentProgress / targetValue).clamp(0.0, 1.0);
  bool get isNearCompletion => progressPercentage >= 0.8;
  int get remainingValue => (targetValue - currentProgress).clamp(0, targetValue);
  
  ChallengeStatus get status {
    if (isCompleted) return ChallengeStatus.completed;
    if (challenge != null) {
      final now = DateTime.now();
      if (now.isBefore(challenge!.startDate)) return ChallengeStatus.upcoming;
      if (now.isAfter(challenge!.endDate)) return ChallengeStatus.expired;
      return ChallengeStatus.active;
    }
    return ChallengeStatus.active;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'current_progress': currentProgress,
      'target_value': targetValue,
      'is_completed': isCompleted ? 1 : 0,
      'completion_date': completionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserChallengeProgress.fromMap(Map<String, dynamic> map) {
    return UserChallengeProgress(
      id: map['id'],
      userId: map['user_id'],
      challengeId: map['challenge_id'],
      currentProgress: map['current_progress'],
      targetValue: map['target_value'],
      isCompleted: map['is_completed'] == 1,
      completionDate: map['completion_date'] != null ? DateTime.parse(map['completion_date']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class ChallengeService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final GamificationService _gamificationService = GamificationService();
  
  // Predefined challenge templates
  static final List<ChallengeDefinition> _challengeTemplates = [
    // Daily challenges
    ChallengeDefinition(
      title: 'Daily Eco Shopper',
      description: 'Make 3 eco-friendly purchases today',
      icon: '🛒',
      type: ChallengeType.daily,
      category: ChallengeCategory.transactions,
      targetValue: 3,
      targetUnit: 'transactions',
      pointsReward: 100,
      difficultyLevel: 1,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 1)),
      tags: ['shopping', 'daily', 'eco'],
    ),
    
    ChallengeDefinition(
      title: 'Green Contributor',
      description: 'Make 1 environmental contribution today',
      icon: '🌱',
      type: ChallengeType.daily,
      category: ChallengeCategory.contributions,
      targetValue: 1,
      targetUnit: 'contributions',
      pointsReward: 75,
      difficultyLevel: 1,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 1)),
      tags: ['contribution', 'daily', 'green'],
    ),
    
    // Weekly challenges
    ChallengeDefinition(
      title: 'Weekly Eco Warrior',
      description: 'Complete 10 eco-friendly transactions this week',
      icon: '⚡',
      type: ChallengeType.weekly,
      category: ChallengeCategory.transactions,
      targetValue: 10,
      targetUnit: 'transactions',
      pointsReward: 500,
      difficultyLevel: 2,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 7)),
      tags: ['shopping', 'weekly', 'warrior'],
    ),
    
    ChallengeDefinition(
      title: 'Carbon Offset Champion',
      description: 'Offset 5kg of CO2 emissions this week',
      icon: '🌬️',
      type: ChallengeType.weekly,
      category: ChallengeCategory.environmental_impact,
      targetValue: 5,
      targetUnit: 'kg CO2',
      pointsReward: 400,
      difficultyLevel: 2,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 7)),
      tags: ['carbon', 'weekly', 'offset'],
    ),
    
    // Monthly challenges
    ChallengeDefinition(
      title: 'Monthly Philanthropist',
      description: 'Make 20 environmental contributions this month',
      icon: '🎁',
      type: ChallengeType.monthly,
      category: ChallengeCategory.contributions,
      targetValue: 20,
      targetUnit: 'contributions',
      pointsReward: 1000,
      difficultyLevel: 3,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 30)),
      tags: ['contribution', 'monthly', 'philanthropist'],
    ),
    
    ChallengeDefinition(
      title: 'Streak Master',
      description: 'Maintain a 15-day contribution streak',
      icon: '🔥',
      type: ChallengeType.monthly,
      category: ChallengeCategory.streak,
      targetValue: 15,
      targetUnit: 'days',
      pointsReward: 800,
      difficultyLevel: 3,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 30)),
      tags: ['streak', 'monthly', 'consistency'],
    ),
    
    // Special challenges
    ChallengeDefinition(
      title: 'Earth Day Special',
      description: 'Plant equivalent of 10 trees on Earth Day',
      icon: '🌍',
      type: ChallengeType.special,
      category: ChallengeCategory.environmental_impact,
      targetValue: 10,
      targetUnit: 'trees',
      pointsReward: 2000,
      difficultyLevel: 4,
      startDate: DateTime(2024, 4, 22),
      endDate: DateTime(2024, 4, 23),
      tags: ['earth-day', 'special', 'trees'],
    ),
  ];

  /// Get all active challenges for a user
  Future<List<ChallengeDefinition>> getActiveChallenges(int userId) async {
    try {
      final results = await _databaseHelper.getActiveChallenges();
      final allChallenges = results.map((map) => ChallengeDefinition.fromMap(map)).toList();
      
      // Filter challenges that are currently active and not completed by user
      final activeChallenges = <ChallengeDefinition>[];
      for (final challenge in allChallenges) {
        if (challenge.id != null) {
          final progress = await _databaseHelper.getChallengeProgress(userId, challenge.id!);
          final isCompleted = progress?['is_completed'] == 1;
          final now = DateTime.now();
          
          // Include challenge if it's active, not completed, and within time bounds
          if (!isCompleted &&
              challenge.isActive &&
              now.isAfter(challenge.startDate) &&
              now.isBefore(challenge.endDate)) {
            activeChallenges.add(challenge);
          }
        }
      }
      
      return activeChallenges;
    } catch (e) {
      print('Error getting active challenges: $e');
      return [];
    }
  }

  /// Get all active challenges (legacy method for backward compatibility)
  Future<List<ChallengeDefinition>> getAllActiveChallenges() async {
    try {
      final results = await _databaseHelper.getActiveChallenges();
      return results.map((map) => ChallengeDefinition.fromMap(map)).toList();
    } catch (e) {
      print('Error getting active challenges: $e');
      return [];
    }
  }

  /// Get user's challenge progress
  Future<List<UserChallengeProgress>> getUserChallengeProgress(int userId) async {
    try {
      final results = await _databaseHelper.getUserChallengeProgress(userId);
      return results.map((map) => UserChallengeProgress.fromMap(map)).toList();
    } catch (e) {
      print('Error getting user challenge progress: $e');
      return [];
    }
  }

  /// Create a new challenge
  Future<int?> createChallenge(ChallengeDefinition challenge) async {
    try {
      return await _databaseHelper.insertChallenge(challenge.toMap());
    } catch (e) {
      print('Error creating challenge: $e');
      return null;
    }
  }

  /// Update challenge progress
  Future<bool> updateChallengeProgress(int userId, int challengeId, int progressValue) async {
    try {
      // Get or create progress record
      final existingProgress = await _databaseHelper.getChallengeProgress(userId, challengeId);
      
      if (existingProgress != null) {
        // Update existing progress
        await _databaseHelper.updateChallengeProgress(userId, challengeId, progressValue);
      } else {
        // Create new progress record
        await _databaseHelper.insertChallengeProgress({
          'user_id': userId,
          'challenge_id': challengeId,
          'current_progress': progressValue,
          'is_completed': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Check if challenge is completed
      final activeChallenges = await getAllActiveChallenges();
      final challenge = activeChallenges.where((c) => c.id == challengeId).firstOrNull;
      
      if (challenge != null && progressValue >= challenge.targetValue) {
        await _completeChallenge(userId, challengeId, challenge);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating challenge progress: $e');
      return false;
    }
  }

  /// Complete a challenge
  Future<void> _completeChallenge(int userId, int challengeId, ChallengeDefinition challenge) async {
    try {
      // Mark challenge as completed
      await _databaseHelper.completeChallenge(userId, challengeId);
      
      // Award points
      await _databaseHelper.addUserPoints(
        userId, 
        challenge.pointsReward, 
        'challenge_completion',
        challengeId: challengeId,
      );
      
      // Create notification
      await _databaseHelper.insertNotification(
        Notification.challengeCompleted(
          userId: userId,
          challengeTitle: challenge.title,
          challengeId: challengeId,
          pointsEarned: challenge.pointsReward,
        ).toMap(),
      );
      
      // Challenge completion triggers other gamification updates automatically
      print('Challenge completed: ${challenge.title} for user $userId');
      
    } catch (e) {
      print('Error completing challenge: $e');
    }
  }

  /// Get challenge statistics for user
  Future<Map<String, dynamic>> getChallengeStats(int userId) async {
    try {
      final userProgress = await getUserChallengeProgress(userId);
      final completed = userProgress.where((p) => p.isCompleted).length;
      final active = userProgress.where((p) => !p.isCompleted && p.status == ChallengeStatus.active).length;
      final totalPoints = userProgress.where((p) => p.isCompleted).fold(0, (sum, p) => sum + (p.challenge?.pointsReward ?? 0));
      
      return {
        'total_challenges': userProgress.length,
        'completed': completed,
        'active': active,
        'completion_rate': userProgress.isNotEmpty ? completed / userProgress.length : 0.0,
        'total_points_earned': totalPoints,
        'average_progress': userProgress.isNotEmpty 
          ? userProgress.map((p) => p.progressPercentage).reduce((a, b) => a + b) / userProgress.length
          : 0.0,
      };
    } catch (e) {
      print('Error getting challenge stats: $e');
      return {};
    }
  }

  /// Get challenges by type
  Future<List<ChallengeDefinition>> getChallengesByType(ChallengeType type) async {
    try {
      final allChallenges = await getAllActiveChallenges();
      return allChallenges.where((c) => c.type == type).toList();
    } catch (e) {
      print('Error getting challenges by type: $e');
      return [];
    }
  }

  /// Get challenges by category for a user
  Future<Map<String, List<ChallengeDefinition>>> getChallengesByCategory(int userId) async {
    try {
      final allChallenges = await getActiveChallenges(userId);
      
      // Group challenges by category
      final Map<String, List<ChallengeDefinition>> challengesByCategory = {};
      
      for (final challenge in allChallenges) {
        final categoryName = challenge.category.name;
        if (!challengesByCategory.containsKey(categoryName)) {
          challengesByCategory[categoryName] = [];
        }
        challengesByCategory[categoryName]!.add(challenge);
      }
      
      return challengesByCategory;
    } catch (e) {
      print('Error getting challenges by category: $e');
      return {};
    }
  }

  /// Get challenges by specific category (legacy method)
  Future<List<ChallengeDefinition>> getChallengesByCategoryType(ChallengeCategory category) async {
    try {
      final allChallenges = await getAllActiveChallenges();
      return allChallenges.where((c) => c.category == category).toList();
    } catch (e) {
      print('Error getting challenges by category: $e');
      return [];
    }
  }

  /// Get challenges near expiration (within 24 hours)
  Future<List<ChallengeDefinition>> getExpiringChallenges() async {
    try {
      final allChallenges = await getAllActiveChallenges();
      final tomorrow = DateTime.now().add(Duration(hours: 24));
      return allChallenges.where((c) => c.endDate.isBefore(tomorrow)).toList();
    } catch (e) {
      print('Error getting expiring challenges: $e');
      return [];
    }
  }

  /// Initialize daily challenges for user
  Future<void> initializeDailyChallenges(int userId) async {
    try {
      final dailyTemplates = _challengeTemplates.where((t) => t.type == ChallengeType.daily);
      
      for (final template in dailyTemplates) {
        // Create daily challenge with today's date
        final dailyChallenge = ChallengeDefinition(
          title: template.title,
          description: template.description,
          icon: template.icon,
          type: template.type,
          category: template.category,
          targetValue: template.targetValue,
          targetUnit: template.targetUnit,
          pointsReward: template.pointsReward,
          difficultyLevel: template.difficultyLevel,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 1)),
          tags: template.tags,
        );
        
        await createChallenge(dailyChallenge);
      }
    } catch (e) {
      print('Error initializing daily challenges: $e');
    }
  }

  /// Process transaction-based challenge progress
  Future<void> processTransactionChallenges(int userId, double amount) async {
    try {
      final transactionChallenges = await getChallengesByCategoryType(ChallengeCategory.transactions);
      
      for (final challenge in transactionChallenges) {
        if (challenge.id != null) {
          final progress = await _databaseHelper.getChallengeProgress(userId, challenge.id!);
          final currentProgress = progress?['current_progress'] ?? 0;
          await updateChallengeProgress(userId, challenge.id!, currentProgress + 1);
        }
      }
    } catch (e) {
      print('Error processing transaction challenges: $e');
    }
  }

  /// Process contribution-based challenge progress
  Future<void> processContributionChallenges(int userId, double amount) async {
    try {
      final contributionChallenges = await getChallengesByCategoryType(ChallengeCategory.contributions);
      
      for (final challenge in contributionChallenges) {
        if (challenge.id != null) {
          final progress = await _databaseHelper.getChallengeProgress(userId, challenge.id!);
          final currentProgress = progress?['current_progress'] ?? 0;
          await updateChallengeProgress(userId, challenge.id!, currentProgress + 1);
        }
      }
    } catch (e) {
      print('Error processing contribution challenges: $e');
    }
  }

  /// Process environmental impact challenges
  Future<void> processEnvironmentalImpactChallenges(int userId, Map<String, dynamic> impact) async {
    try {
      final impactChallenges = await getChallengesByCategoryType(ChallengeCategory.environmental_impact);
      
      for (final challenge in impactChallenges) {
        if (challenge.id != null) {
          int progressValue = 0;
          
          // Map impact data to challenge progress based on target unit
          switch (challenge.targetUnit) {
            case 'kg CO2':
              progressValue = (impact['co2_offset_kg'] ?? 0).round();
              break;
            case 'trees':
              progressValue = (impact['trees_planted'] ?? 0).round();
              break;
            case 'liters':
              progressValue = (impact['water_saved_liters'] ?? 0).round();
              break;
            default:
              progressValue = 1; // Default increment
          }
          
          if (progressValue > 0) {
            final progress = await _databaseHelper.getChallengeProgress(userId, challenge.id!);
            final currentProgress = progress?['current_progress'] ?? 0;
            await updateChallengeProgress(userId, challenge.id!, currentProgress + progressValue);
          }
        }
      }
    } catch (e) {
      print('Error processing environmental impact challenges: $e');
    }
  }

  /// Clean up expired challenges
  Future<void> cleanupExpiredChallenges() async {
    try {
      final allChallenges = await getAllActiveChallenges();
      final now = DateTime.now();
      
      for (final challenge in allChallenges) {
        if (challenge.endDate.isBefore(now)) {
          // Mark challenge as inactive
          // Note: This would require an update method in DatabaseHelper
          print('Challenge expired: ${challenge.title}');
        }
      }
    } catch (e) {
      print('Error cleaning up expired challenges: $e');
    }
  }

  /// Get user's challenge completion history
  Future<List<UserChallengeProgress>> getCompletedChallenges(int userId) async {
    try {
      final allProgress = await getUserChallengeProgress(userId);
      return allProgress.where((p) => p.isCompleted).toList();
    } catch (e) {
      print('Error getting completed challenges: $e');
      return [];
    }
  }

  /// Get recommended challenges for user
  Future<List<ChallengeDefinition>> getRecommendedChallenges(int userId) async {
    try {
      final userProgress = await getUserChallengeProgress(userId);
      final completedChallengeIds = userProgress.where((p) => p.isCompleted).map((p) => p.challengeId).toSet();
      
      final allChallenges = await getAllActiveChallenges();
      final availableChallenges = allChallenges.where((c) => !completedChallengeIds.contains(c.id)).toList();
      
      // Sort by difficulty and reward
      availableChallenges.sort((a, b) {
        final scoreDiff = (b.pointsReward / b.difficultyLevel) - (a.pointsReward / a.difficultyLevel);
        return scoreDiff.round();
      });
      
      return availableChallenges.take(5).toList();
    } catch (e) {
      print('Error getting recommended challenges: $e');
      return [];
    }
  }

  /// Join a challenge (user enrolls in a challenge)
  Future<bool> joinChallenge(int userId, int challengeId) async {
    try {
      // Check if user is already enrolled in this challenge
      final existingProgress = await _databaseHelper.getChallengeProgress(userId, challengeId);
      if (existingProgress != null) {
        print('User $userId is already enrolled in challenge $challengeId');
        return false;
      }

      // Get challenge details to ensure it exists and is active
      final allChallenges = await getAllActiveChallenges();
      final challenge = allChallenges.where((c) => c.id == challengeId).firstOrNull;
      
      if (challenge == null) {
        print('Challenge $challengeId not found or not active');
        return false;
      }

      // Check if challenge is still available to join
      final now = DateTime.now();
      if (now.isAfter(challenge.endDate)) {
        print('Challenge $challengeId has expired');
        return false;
      }

      // Create initial progress record
      await _databaseHelper.insertChallengeProgress({
        'user_id': userId,
        'challenge_id': challengeId,
        'current_progress': 0,
        'target_value': challenge.targetValue,
        'is_completed': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create notification for joining challenge
      await _databaseHelper.insertNotification(
        Notification(
          userId: userId,
          title: 'Challenge Joined! 🎯',
          message: 'You\'ve successfully joined "${challenge.title}". Good luck!',
          notificationType: NotificationType.challenge_progress,
          relatedId: challengeId,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      return true;
    } catch (e) {
      print('Error joining challenge: $e');
      return false;
    }
  }

  /// Get upcoming challenges for a user (challenges that haven't started yet)
  Future<List<ChallengeDefinition>> getUpcomingChallenges(int userId) async {
    try {
      final allChallenges = await getAllActiveChallenges();
      final now = DateTime.now();
      
      // Filter challenges that haven't started yet
      final upcomingChallenges = allChallenges.where((challenge) {
        return challenge.startDate.isAfter(now);
      }).toList();

      // Sort by start date (earliest first)
      upcomingChallenges.sort((a, b) => a.startDate.compareTo(b.startDate));

      return upcomingChallenges;
    } catch (e) {
      print('Error getting upcoming challenges: $e');
      return [];
    }
  }
}