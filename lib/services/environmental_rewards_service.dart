import 'dart:developer' as developer;
import 'dart:math';
import '../helpers/database_helper.dart';
import '../models/notification.dart';
import '../models/leaderboard_entry.dart';
import '../utils/environmental_impact_calculator.dart';
import '../services/leaderboard_service.dart';

/// Enhanced Environmental Rewards Service
/// Provides comprehensive environmental impact-based rewards and incentives
class EnvironmentalRewardsService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final LeaderboardService _leaderboardService = LeaderboardService();

  // Enhanced reward multipliers for all environmental metrics
  static const Map<String, double> ENVIRONMENTAL_MULTIPLIERS = {
    'co2_offset_kg': 150.0,           // 150 points per kg CO2 saved
    'water_saved_liters': 2.0,        // 2 points per liter saved
    'energy_saved_kwh': 25.0,         // 25 points per kWh saved
    'tree_equivalent': 750.0,         // 750 points per tree equivalent
    'plastic_bottles_reduced': 15.0,  // 15 points per bottle reduced
    'river_meters_cleaned': 50.0,     // 50 points per meter cleaned
    'wildlife_protected': 200.0,      // 200 points per animal protected
    'air_quality_improved_m3': 5.0,   // 5 points per m³ air improved
    'soil_restored_m2': 10.0,         // 10 points per m² soil restored
    'solar_panels_equivalent': 2000.0, // 2000 points per solar panel
    'carbon_footprint_reduced': 100.0, // 100 points per kg footprint reduced
    'biodiversity_protected': 300.0,  // 300 points per species protected
    'waste_diverted_kg': 20.0,        // 20 points per kg waste diverted
  };

  // Impact tier thresholds for bonus rewards
  static const Map<String, List<double>> IMPACT_TIERS = {
    'co2_offset_kg': [0.5, 1.0, 2.5, 5.0, 10.0],
    'water_saved_liters': [10.0, 25.0, 50.0, 100.0, 200.0],
    'energy_saved_kwh': [2.0, 5.0, 10.0, 20.0, 40.0],
    'tree_equivalent': [0.1, 0.25, 0.5, 1.0, 2.0],
    'plastic_bottles_reduced': [5.0, 10.0, 25.0, 50.0, 100.0],
  };

  // Tier multipliers for bonus rewards
  static const List<double> TIER_MULTIPLIERS = [1.0, 1.2, 1.5, 2.0, 2.5, 3.0];

  // Streak bonus multipliers
  static const Map<int, double> STREAK_MULTIPLIERS = {
    3: 1.1,    // 10% bonus for 3-day streak
    7: 1.25,   // 25% bonus for 7-day streak
    14: 1.5,   // 50% bonus for 14-day streak
    30: 2.0,   // 100% bonus for 30-day streak
    90: 2.5,   // 150% bonus for 90-day streak
  };

  /// Calculate comprehensive environmental impact rewards
  Future<Map<String, dynamic>> calculateEnvironmentalRewards({
    required int userId,
    required double contributionAmount,
    String? projectName,
    bool isTransaction = false,
  }) async {
    try {
      // Get base environmental impact
      final impactData = projectName != null
          ? EnvironmentalImpactCalculator.getProjectImpact(projectName, contributionAmount)
          : EnvironmentalImpactCalculator.getEnvironmentalImpact(contributionAmount);

      // Calculate base environmental points
      int baseEnvironmentalPoints = _calculateBaseEnvironmentalPoints(impactData);

      // Apply tier bonuses
      int tierBonus = await _calculateTierBonus(userId, impactData);

      // Apply streak bonuses
      double streakMultiplier = await _calculateEnvironmentalStreak(userId);

      // Apply consistency bonuses
      int consistencyBonus = await _calculateConsistencyBonus(userId);

      // Apply milestone bonuses
      int milestoneBonus = await _calculateMilestoneBonus(userId, impactData);

      // Calculate total environmental points
      int totalEnvironmentalPoints = ((baseEnvironmentalPoints + tierBonus + consistencyBonus + milestoneBonus) * streakMultiplier).round();

      // Calculate impact achievements
      List<Map<String, dynamic>> newAchievements = await _checkEnvironmentalAchievements(userId, impactData);

      // Generate impact insights
      Map<String, dynamic> insights = _generateImpactInsights(impactData, contributionAmount);

      // Create detailed reward breakdown
      final rewardBreakdown = {
        'total_points': totalEnvironmentalPoints,
        'base_points': baseEnvironmentalPoints,
        'tier_bonus': tierBonus,
        'streak_multiplier': streakMultiplier,
        'consistency_bonus': consistencyBonus,
        'milestone_bonus': milestoneBonus,
        'environmental_impact': impactData,
        'new_achievements': newAchievements,
        'insights': insights,
        'impact_level': _determineImpactLevel(impactData),
        'next_milestone': _getNextMilestone(userId, impactData),
      };

      // Update user's environmental impact history
      await _updateEnvironmentalHistory(userId, impactData, totalEnvironmentalPoints);

      // Update environmental leaderboards
      await _updateEnvironmentalLeaderboards(userId, impactData);

      // Create environmental impact notification
      await _createEnvironmentalNotification(userId, rewardBreakdown);

      return rewardBreakdown;

    } catch (e) {
      developer.log('Error calculating environmental rewards: $e', name: 'EnvironmentalRewardsService');
      return {
        'total_points': 0,
        'base_points': 0,
        'tier_bonus': 0,
        'streak_multiplier': 1.0,
        'consistency_bonus': 0,
        'milestone_bonus': 0,
        'environmental_impact': {},
        'new_achievements': [],
        'insights': {},
        'impact_level': 'minimal',
        'next_milestone': null,
      };
    }
  }

  /// Calculate base environmental points using all 13 metrics
  int _calculateBaseEnvironmentalPoints(Map<String, dynamic> impactData) {
    double totalPoints = 0.0;

    ENVIRONMENTAL_MULTIPLIERS.forEach((metric, multiplier) {
      final value = impactData[metric] ?? 0.0;
      totalPoints += value * multiplier;
    });

    return totalPoints.round();
  }

  /// Calculate tier bonus based on impact thresholds
  Future<int> _calculateTierBonus(int userId, Map<String, dynamic> impactData) async {
    int totalTierBonus = 0;

    for (final entry in IMPACT_TIERS.entries) {
      final metric = entry.key;
      final thresholds = entry.value;
      final value = impactData[metric] ?? 0.0;

      // Find the appropriate tier
      int tier = 0;
      for (int i = 0; i < thresholds.length; i++) {
        if (value >= thresholds[i]) {
          tier = i + 1;
        }
      }

      if (tier > 0) {
        final basePoints = value * (ENVIRONMENTAL_MULTIPLIERS[metric] ?? 0.0);
        final multiplier = TIER_MULTIPLIERS[tier] - 1.0; // Subtract 1 to get only the bonus
        totalTierBonus += int.parse((basePoints * multiplier).toStringAsFixed(0));
      }
    }

    return totalTierBonus;
  }

  /// Calculate environmental streak multiplier
  Future<double> _calculateEnvironmentalStreak(int userId) async {
    try {
      final contributions = await _databaseHelper.getContributionsByUser(userId);
      if (contributions.isEmpty) return 1.0;

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

      // Find the highest applicable streak multiplier
      double multiplier = 1.0;
      for (final entry in STREAK_MULTIPLIERS.entries) {
        if (streakDays >= entry.key) {
          multiplier = max(multiplier, entry.value);
        }
      }

      return multiplier;
    } catch (e) {
      developer.log('Error calculating environmental streak: $e', name: 'EnvironmentalRewardsService');
      return 1.0;
    }
  }

  /// Calculate consistency bonus for regular environmental actions
  Future<int> _calculateConsistencyBonus(int userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final contributions = await _databaseHelper.getContributionsByUser(userId);

      // Filter contributions from last 30 days
      final recentContributions = contributions.where((c) =>
          c.timestamp.isAfter(thirtyDaysAgo)).toList();

      if (recentContributions.isEmpty) return 0;

      // Calculate consistency score based on frequency and distribution
      final daysWithContributions = recentContributions
          .map((c) => DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day))
          .toSet()
          .length;

      // Award bonus based on consistency
      if (daysWithContributions >= 20) return 500; // Very consistent
      if (daysWithContributions >= 15) return 300; // Consistent
      if (daysWithContributions >= 10) return 150; // Moderate
      if (daysWithContributions >= 5) return 50;   // Occasional

      return 0;
    } catch (e) {
      developer.log('Error calculating consistency bonus: $e', name: 'EnvironmentalRewardsService');
      return 0;
    }
  }

  /// Calculate milestone bonus for reaching impact thresholds
  Future<int> _calculateMilestoneBonus(int userId, Map<String, dynamic> impactData) async {
    try {
      int milestoneBonus = 0;

      // Check for major milestone achievements
      final co2Saved = impactData['co2_offset_kg'] ?? 0.0;
      final waterSaved = impactData['water_saved_liters'] ?? 0.0;
      final treesPlanted = impactData['tree_equivalent'] ?? 0.0;

      // CO2 milestones
      if (co2Saved >= 100) milestoneBonus += 2000;  // 100kg CO2 milestone
      else if (co2Saved >= 50) milestoneBonus += 1000; // 50kg CO2 milestone
      else if (co2Saved >= 10) milestoneBonus += 500;  // 10kg CO2 milestone

      // Water milestones
      if (waterSaved >= 1000) milestoneBonus += 1500; // 1000L water milestone
      else if (waterSaved >= 500) milestoneBonus += 750; // 500L water milestone
      else if (waterSaved >= 100) milestoneBonus += 300; // 100L water milestone

      // Tree milestones
      if (treesPlanted >= 10) milestoneBonus += 3000; // 10 trees milestone
      else if (treesPlanted >= 5) milestoneBonus += 1500; // 5 trees milestone
      else if (treesPlanted >= 1) milestoneBonus += 750; // 1 tree milestone

      return milestoneBonus;
    } catch (e) {
      developer.log('Error calculating milestone bonus: $e', name: 'EnvironmentalRewardsService');
      return 0;
    }
  }

  /// Check for environmental achievements
  Future<List<Map<String, dynamic>>> _checkEnvironmentalAchievements(int userId, Map<String, dynamic> impactData) async {
    try {
      final List<Map<String, dynamic>> newAchievements = [];

      // Get user's total environmental impact
      final contributions = await _databaseHelper.getContributionsByUser(userId);
      final totalImpact = EnvironmentalImpactCalculator.getAggregatedImpact(
        contributions.map((c) => {'amount': c.amount}).toList()
      );

      // Define environmental achievements
      final environmentalAchievements = [
        {
          'id': 'eco_warrior_co2',
          'name': 'CO2 Warrior',
          'description': 'Offset 10kg of CO2',
          'threshold': 10.0,
          'metric': 'total_co2_offset_kg',
          'points': 1000,
        },
        {
          'id': 'water_guardian',
          'name': 'Water Guardian',
          'description': 'Save 500 liters of water',
          'threshold': 500.0,
          'metric': 'total_water_saved_liters',
          'points': 800,
        },
        {
          'id': 'tree_planter',
          'name': 'Tree Planter',
          'description': 'Plant equivalent of 5 trees',
          'threshold': 5.0,
          'metric': 'total_tree_equivalent',
          'points': 1500,
        },
        {
          'id': 'energy_saver',
          'name': 'Energy Saver',
          'description': 'Save 50 kWh of energy',
          'threshold': 50.0,
          'metric': 'total_energy_saved_kwh',
          'points': 1200,
        },
        {
          'id': 'plastic_reducer',
          'name': 'Plastic Reducer',
          'description': 'Reduce 100 plastic bottles',
          'threshold': 100.0,
          'metric': 'total_plastic_bottles_reduced',
          'points': 900,
        },
        {
          'id': 'environmental_champion',
          'name': 'Environmental Champion',
          'description': 'Achieve excellence in all environmental metrics',
          'threshold': 1.0,
          'metric': 'all_metrics_threshold',
          'points': 5000,
        },
      ];

      // Check each achievement
      for (final achievement in environmentalAchievements) {
        final metric = achievement['metric'] as String;
        final threshold = achievement['threshold'] as double;
        final value = metric == 'all_metrics_threshold' 
            ? _checkAllMetricsThreshold(totalImpact)
            : (totalImpact[metric] ?? 0.0);

        if (value >= threshold) {
          // Check if user already has this achievement
          final existingAchievement = await _databaseHelper.getUserAchievementProgress(userId, achievement['id'] as int);
          if (existingAchievement == null) {
            newAchievements.add(achievement);
            
            // Award achievement
            await _databaseHelper.insertUserAchievement({
              'user_id': userId,
              'achievement_id': achievement['id'],
              'achievement_name': achievement['name'],
              'achievement_description': achievement['description'],
              'date_unlocked': DateTime.now().toIso8601String(),
              'points_earned': achievement['points'],
            });
          }
        }
      }

      return newAchievements;
    } catch (e) {
      developer.log('Error checking environmental achievements: $e', name: 'EnvironmentalRewardsService');
      return [];
    }
  }

  /// Check if all environmental metrics meet minimum thresholds
  double _checkAllMetricsThreshold(Map<String, dynamic> totalImpact) {
    final thresholds = {
      'total_co2_offset_kg': 5.0,
      'total_water_saved_liters': 100.0,
      'total_energy_saved_kwh': 20.0,
      'total_tree_equivalent': 1.0,
      'total_plastic_bottles_reduced': 25.0,
    };

    for (final entry in thresholds.entries) {
      final value = totalImpact[entry.key] ?? 0.0;
      if (value < entry.value) {
        return 0.0;
      }
    }

    return 1.0; // All thresholds met
  }

  /// Generate impact insights for the user
  Map<String, dynamic> _generateImpactInsights(Map<String, dynamic> impactData, double contributionAmount) {
    final insights = <String, dynamic>{};

    // Calculate most impactful metric
    String mostImpactfulMetric = '';
    double highestImpact = 0.0;

    ENVIRONMENTAL_MULTIPLIERS.forEach((metric, multiplier) {
      final value = impactData[metric] ?? 0.0;
      final impact = value * multiplier;
      if (impact > highestImpact) {
        highestImpact = impact;
        mostImpactfulMetric = metric;
      }
    });

    insights['most_impactful_metric'] = mostImpactfulMetric;
    insights['highest_impact_points'] = highestImpact.round();

    // Generate impact comparisons
    final co2Saved = impactData['co2_offset_kg'] ?? 0.0;
    final waterSaved = impactData['water_saved_liters'] ?? 0.0;

    insights['impact_comparisons'] = {
      'cars_off_road_days': (co2Saved / 4.6).toStringAsFixed(1), // Average car emits 4.6kg CO2/day
      'showers_worth_water': (waterSaved / 62).toStringAsFixed(1), // Average shower uses 62L
      'homes_powered_hours': ((impactData['energy_saved_kwh'] ?? 0.0) / 1.25).toStringAsFixed(1), // Average home uses 1.25kWh/hour
    };

    // Generate personalized messages
    insights['messages'] = _generatePersonalizedMessages(impactData, contributionAmount);

    return insights;
  }

  /// Generate personalized impact messages
  List<String> _generatePersonalizedMessages(Map<String, dynamic> impactData, double contributionAmount) {
    final messages = <String>[];
    final co2Saved = impactData['co2_offset_kg'] ?? 0.0;
    final waterSaved = impactData['water_saved_liters'] ?? 0.0;
    final treesPlanted = impactData['tree_equivalent'] ?? 0.0;

    if (co2Saved > 0) {
      messages.add('Your RM${contributionAmount.toStringAsFixed(2)} contribution prevents ${co2Saved.toStringAsFixed(2)}kg of CO2 from entering the atmosphere! 🌍');
    }

    if (waterSaved > 0) {
      messages.add('You\'ve helped save ${waterSaved.toStringAsFixed(0)} liters of precious water - enough for ${(waterSaved / 2).toStringAsFixed(0)} bottles! 💧');
    }

    if (treesPlanted >= 0.1) {
      messages.add('Your impact equals planting ${treesPlanted.toStringAsFixed(2)} trees, helping restore our forests! 🌱');
    }

    if (messages.isEmpty) {
      messages.add('Every contribution matters! Your action creates positive environmental impact. 🌟');
    }

    return messages;
  }

  /// Determine impact level based on contribution
  String _determineImpactLevel(Map<String, dynamic> impactData) {
    final co2Saved = impactData['co2_offset_kg'] ?? 0.0;
    final waterSaved = impactData['water_saved_liters'] ?? 0.0;
    final treesPlanted = impactData['tree_equivalent'] ?? 0.0;

    // Calculate composite impact score
    double impactScore = (co2Saved * 10) + (waterSaved * 0.1) + (treesPlanted * 50);

    if (impactScore >= 100) return 'exceptional';
    if (impactScore >= 50) return 'high';
    if (impactScore >= 25) return 'significant';
    if (impactScore >= 10) return 'moderate';
    if (impactScore >= 5) return 'noticeable';
    return 'minimal';
  }

  /// Get next milestone for the user
  Future<Map<String, dynamic>?> _getNextMilestone(int userId, Map<String, dynamic> impactData) async {
    try {
      final contributions = await _databaseHelper.getContributionsByUser(userId);
      final totalImpact = EnvironmentalImpactCalculator.getAggregatedImpact(
        contributions.map((c) => {'amount': c.amount}).toList()
      );

      // Define milestone thresholds
      final milestones = [
        {'metric': 'total_co2_offset_kg', 'threshold': 10.0, 'name': '10kg CO2 Offset', 'reward': 1000},
        {'metric': 'total_water_saved_liters', 'threshold': 500.0, 'name': '500L Water Saved', 'reward': 800},
        {'metric': 'total_tree_equivalent', 'threshold': 5.0, 'name': '5 Trees Planted', 'reward': 1500},
        {'metric': 'total_energy_saved_kwh', 'threshold': 50.0, 'name': '50kWh Energy Saved', 'reward': 1200},
      ];

      // Find the next achievable milestone
      for (final milestone in milestones) {
        final metric = milestone['metric'] as String;
        final threshold = milestone['threshold'] as double;
        final current = totalImpact[metric] ?? 0.0;

        if (current < threshold) {
          return {
            'metric': metric,
            'threshold': threshold,
            'current': current,
            'progress': (current / threshold).clamp(0.0, 1.0),
            'name': milestone['name'],
            'reward': milestone['reward'],
            'remaining': threshold - current,
          };
        }
      }

      return null; // All milestones achieved
    } catch (e) {
      developer.log('Error getting next milestone: $e', name: 'EnvironmentalRewardsService');
      return null;
    }
  }

  /// Update user's environmental impact history
  Future<void> _updateEnvironmentalHistory(int userId, Map<String, dynamic> impactData, int pointsEarned) async {
    try {
      await _databaseHelper.database.then((db) => db.insert(
        'environmental_impact_history',
        {
          'user_id': userId,
          'co2_offset_kg': impactData['co2_offset_kg'] ?? 0.0,
          'water_saved_liters': impactData['water_saved_liters'] ?? 0.0,
          'energy_saved_kwh': impactData['energy_saved_kwh'] ?? 0.0,
          'tree_equivalent': impactData['tree_equivalent'] ?? 0.0,
          'plastic_bottles_reduced': impactData['plastic_bottles_reduced'] ?? 0.0,
          'points_earned': pointsEarned,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      developer.log('Error updating environmental history: $e', name: 'EnvironmentalRewardsService');
    }
  }

  /// Update environmental leaderboards
  Future<void> _updateEnvironmentalLeaderboards(int userId, Map<String, dynamic> impactData) async {
    try {
      // Update all environmental leaderboards
      final leaderboardUpdates = [
        {'type': LeaderboardType.co2_saved, 'score': impactData['co2_offset_kg'] ?? 0.0},
        {'type': LeaderboardType.water_saved, 'score': impactData['water_saved_liters'] ?? 0.0},
        {'type': LeaderboardType.energy_saved, 'score': impactData['energy_saved_kwh'] ?? 0.0},
        {'type': LeaderboardType.trees_planted, 'score': impactData['tree_equivalent'] ?? 0.0},
      ];

      for (final update in leaderboardUpdates) {
        await _leaderboardService.updateUserEntry(
          userId: userId,
          type: update['type'] as LeaderboardType,
          score: update['score'] as double,
          period: LeaderboardPeriod.allTime,
        );
      }
    } catch (e) {
      developer.log('Error updating environmental leaderboards: $e', name: 'EnvironmentalRewardsService');
    }
  }

  /// Create environmental impact notification
  Future<void> _createEnvironmentalNotification(int userId, Map<String, dynamic> rewardData) async {
    try {
      final insights = rewardData['insights'] as Map<String, dynamic>;
      final messages = insights['messages'] as List<String>;

      if (messages.isNotEmpty) {
        await _databaseHelper.insertNotification(
          Notification.pointsEarned(
            userId: userId,
            pointsEarned: rewardData['total_points'] as int,
            source: 'environmental impact',
          ).toMap(),
        );
      }
    } catch (e) {
      developer.log('Error creating environmental notification: $e', name: 'EnvironmentalRewardsService');
    }
  }

  /// Get user's environmental impact summary
  Future<Map<String, dynamic>> getUserEnvironmentalSummary(int userId) async {
    try {
      final contributions = await _databaseHelper.getContributionsByUser(userId);
      final totalImpact = EnvironmentalImpactCalculator.getAggregatedImpact(
        contributions.map((c) => {'amount': c.amount}).toList()
      );

      // Get recent environmental actions
      final recentActions = contributions.take(5).map((c) {
        final impact = EnvironmentalImpactCalculator.getEnvironmentalImpact(c.amount);
        return {
          'date': c.timestamp.toIso8601String(),
          'amount': c.amount,
          'project_id': c.projectId,
          'co2_saved': impact['co2_offset_kg'],
          'water_saved': impact['water_saved_liters'],
          'trees_planted': impact['tree_equivalent'],
        };
      }).toList();

      // Calculate streak
      final streak = await _calculateEnvironmentalStreak(userId);

      // Get next milestone
      final nextMilestone = await _getNextMilestone(userId, totalImpact);

      return {
        'total_impact': totalImpact,
        'recent_actions': recentActions,
        'current_streak': streak,
        'next_milestone': nextMilestone,
        'impact_level': _determineImpactLevel(totalImpact),
        'achievements_count': await _getEnvironmentalAchievementsCount(userId),
        'monthly_growth': await _calculateMonthlyGrowth(userId),
      };
    } catch (e) {
      developer.log('Error getting user environmental summary: $e', name: 'EnvironmentalRewardsService');
      return {};
    }
  }

  /// Get environmental achievements count
  Future<int> _getEnvironmentalAchievementsCount(int userId) async {
    try {
      final achievements = await _databaseHelper.getUserAchievements(userId);
      return achievements.where((a) => (a['achievement_id'] as String).startsWith('eco_')).length;
    } catch (e) {
      developer.log('Error getting environmental achievements count: $e', name: 'EnvironmentalRewardsService');
      return 0;
    }
  }

  /// Calculate monthly environmental impact growth
  Future<Map<String, dynamic>> _calculateMonthlyGrowth(int userId) async {
    try {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);

      final contributions = await _databaseHelper.getContributionsByUser(userId);

      final currentMonthContributions = contributions.where((c) =>
          c.timestamp.isAfter(currentMonth)).toList();
      final lastMonthContributions = contributions.where((c) =>
          c.timestamp.isAfter(lastMonth) && c.timestamp.isBefore(currentMonth)).toList();

      final currentImpact = EnvironmentalImpactCalculator.getAggregatedImpact(
        currentMonthContributions.map((c) => {'amount': c.amount}).toList()
      );
      final lastImpact = EnvironmentalImpactCalculator.getAggregatedImpact(
        lastMonthContributions.map((c) => {'amount': c.amount}).toList()
      );

      // Calculate growth percentages
      final co2Growth = _calculateGrowthPercentage(
        lastImpact['total_co2_offset_kg'] ?? 0.0,
        currentImpact['total_co2_offset_kg'] ?? 0.0,
      );

      final waterGrowth = _calculateGrowthPercentage(
        lastImpact['total_water_saved_liters'] ?? 0.0,
        currentImpact['total_water_saved_liters'] ?? 0.0,
      );

      return {
        'co2_growth': co2Growth,
        'water_growth': waterGrowth,
        'current_month_impact': currentImpact,
        'last_month_impact': lastImpact,
      };
    } catch (e) {
      developer.log('Error calculating monthly growth: $e', name: 'EnvironmentalRewardsService');
      return {};
    }
  }

  /// Calculate growth percentage
  double _calculateGrowthPercentage(double previous, double current) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100.0;
  }

  /// Initialize the service
  void initialize() {
    _leaderboardService.initialize();
  }

  /// Dispose resources
  void dispose() {
    _leaderboardService.dispose();
  }
}