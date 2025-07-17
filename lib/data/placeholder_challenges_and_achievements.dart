import '../models/challenge.dart';
import '../models/achievement.dart';
import '../models/challenge_progress.dart';

class PlaceholderData {
  // Placeholder challenges with points
  static final List<Challenge> challenges = [
    Challenge(
      id: 1,
      title: "Eco Warrior Beginner",
      description: "Complete your first 5 transactions using EcoPay",
      category: ChallengeCategory.environmental,
      type: ChallengeType.transactions,
      challengeType: ChallengeType.transactions,
      targetValue: 5,
      targetUnit: "transactions",
      pointsReward: 100,
      startDate: DateTime.now().subtract(Duration(days: 7)),
      endDate: DateTime.now().add(Duration(days: 7)),
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: 14)),
    ),
    
    Challenge(
      id: 2,
      title: "Green Contributor",
      description: "Make a total of RM50 in donations to environmental projects",
      category: ChallengeCategory.environmental,
      type: ChallengeType.contributions,
      challengeType: ChallengeType.contributions,
      targetValue: 50,
      targetUnit: "RM",
      pointsReward: 150,
      startDate: DateTime.now().subtract(Duration(days: 3)),
      endDate: DateTime.now().add(Duration(days: 10)),
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: 10)),
    ),
    
    Challenge(
      id: 3,
      title: "Daily Eco Habit",
      description: "Use EcoPay for 7 consecutive days",
      category: ChallengeCategory.personal,
      type: ChallengeType.daily,
      challengeType: ChallengeType.daily,
      targetValue: 7,
      targetUnit: "days",
      pointsReward: 75,
      startDate: DateTime.now().subtract(Duration(days: 5)),
      endDate: DateTime.now().add(Duration(days: 7)),
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: 12)),
    ),
    
    Challenge(
      id: 4,
      title: "Carbon Footprint Champion",
      description: "Save 100kg of CO2 through your transactions",
      category: ChallengeCategory.environmental,
      type: ChallengeType.environmental_impact,
      challengeType: ChallengeType.environmental_impact,
      targetValue: 100,
      targetUnit: "kg CO2",
      pointsReward: 200,
      startDate: DateTime.now().subtract(Duration(days: 2)),
      endDate: DateTime.now().add(Duration(days: 14)),
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: 16)),
    ),
    
    Challenge(
      id: 5,
      title: "Community Builder",
      description: "Refer 3 friends to use EcoPay",
      category: ChallengeCategory.community,
      type: ChallengeType.social_sharing,
      challengeType: ChallengeType.social_sharing,
      targetValue: 3,
      targetUnit: "friends",
      pointsReward: 125,
      startDate: DateTime.now().subtract(Duration(days: 1)),
      endDate: DateTime.now().add(Duration(days: 30)),
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    
    Challenge(
      id: 6,
      title: "Weekly Streak Master",
      description: "Complete any 3 challenges in one week",
      category: ChallengeCategory.personal,
      type: ChallengeType.weekly,
      challengeType: ChallengeType.weekly,
      targetValue: 3,
      targetUnit: "challenges",
      pointsReward: 250,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: 7)),
      isActive: true,
      createdAt: DateTime.now(),
    ),
  ];

  // Placeholder achievements with points
  static final List<Achievement> achievements = [
    Achievement(
      id: 1,
      name: "First Transaction",
      description: "Complete your first EcoPay transaction",
      target: "1 transaction",
      tier: AchievementTier.bronze,
      type: AchievementType.completion,
      pointsReward: 50,
    ),
    
    Achievement(
      id: 2,
      name: "Eco Contributor",
      description: "Make your first environmental donation",
      target: "1 donation",
      tier: AchievementTier.bronze,
      type: AchievementType.environmental,
      pointsReward: 75,
    ),
    
    Achievement(
      id: 3,
      name: "Green Guardian",
      description: "Save 50kg of CO2 through your transactions",
      target: "50kg CO2 saved",
      tier: AchievementTier.silver,
      type: AchievementType.environmental,
      pointsReward: 100,
    ),
    
    Achievement(
      id: 4,
      name: "Daily User",
      description: "Use EcoPay for 5 consecutive days",
      target: "5 days streak",
      tier: AchievementTier.bronze,
      type: AchievementType.consistency,
      pointsReward: 75,
    ),
    
    Achievement(
      id: 5,
      name: "Payment Pro",
      description: "Complete 50 transactions with EcoPay",
      target: "50 transactions",
      tier: AchievementTier.gold,
      type: AchievementType.completion,
      pointsReward: 200,
    ),
    
    Achievement(
      id: 6,
      name: "Community Champion",
      description: "Refer 5 friends to use EcoPay",
      target: "5 referrals",
      tier: AchievementTier.silver,
      type: AchievementType.social,
      pointsReward: 150,
    ),
    
    Achievement(
      id: 7,
      name: "Milestone Master",
      description: "Complete 10 challenges",
      target: "10 challenges",
      tier: AchievementTier.gold,
      type: AchievementType.completion,
      pointsReward: 250,
    ),
    
    Achievement(
      id: 8,
      name: "Eco Hero",
      description: "Save 500kg of CO2 in total",
      target: "500kg CO2 saved",
      tier: AchievementTier.platinum,
      type: AchievementType.environmental,
      pointsReward: 500,
    ),
  ];

  // Placeholder challenge progress for current user
  static final Map<int, ChallengeProgress> challengeProgress = {
    1: ChallengeProgress(
      id: 1,
      userId: 1,
      challengeId: 1,
      currentProgress: 3,
      targetValue: 5,
      status: ChallengeProgressStatus.inProgress,
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      updatedAt: DateTime.now().subtract(Duration(hours: 2)),
      lastUpdated: DateTime.now().subtract(Duration(hours: 2)),
      completionDate: null,
    ),
    
    2: ChallengeProgress(
      id: 2,
      userId: 1,
      challengeId: 2,
      currentProgress: 25,
      targetValue: 50,
      status: ChallengeProgressStatus.inProgress,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
      lastUpdated: DateTime.now().subtract(Duration(days: 1)),
      completionDate: null,
    ),
    
    3: ChallengeProgress(
      id: 3,
      userId: 1,
      challengeId: 3,
      currentProgress: 4,
      targetValue: 7,
      status: ChallengeProgressStatus.inProgress,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      completionDate: null,
    ),
    
    4: ChallengeProgress(
      id: 4,
      userId: 1,
      challengeId: 4,
      currentProgress: 45,
      targetValue: 100,
      status: ChallengeProgressStatus.inProgress,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: 3)),
      lastUpdated: DateTime.now().subtract(Duration(days: 3)),
      completionDate: null,
    ),
    
    5: ChallengeProgress(
      id: 5,
      userId: 1,
      challengeId: 5,
      currentProgress: 1,
      targetValue: 3,
      status: ChallengeProgressStatus.inProgress,
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      updatedAt: DateTime.now().subtract(Duration(days: 2)),
      lastUpdated: DateTime.now().subtract(Duration(days: 2)),
      completionDate: null,
    ),
  };

  // Placeholder user achievements for current user
  static final List<UserAchievement> userAchievements = [
    UserAchievement(
      id: 1,
      userId: 1,
      achievementId: 1,
      dateUnlocked: DateTime.now().subtract(Duration(days: 14)),
    ),
    
    UserAchievement(
      id: 2,
      userId: 1,
      achievementId: 2,
      dateUnlocked: DateTime.now().subtract(Duration(days: 10)),
    ),
    
    UserAchievement(
      id: 3,
      userId: 1,
      achievementId: 3,
      dateUnlocked: DateTime.now().subtract(Duration(days: 7)),
    ),
    
    UserAchievement(
      id: 4,
      userId: 1,
      achievementId: 4,
      dateUnlocked: DateTime.now().subtract(Duration(days: 5)),
    ),
  ];

  // Helper method to get challenge progress for a specific challenge
  static ChallengeProgress? getChallengeProgress(int challengeId) {
    return challengeProgress[challengeId];
  }

  // Helper method to get total points from completed achievements
  static int getTotalPointsFromAchievements() {
    return userAchievements.length * 50; // 50 points per achievement
  }

  // Helper method to get total points from completed challenges
  static int getTotalPointsFromChallenges() {
    // Count completed challenges
    int completedChallenges = 0;
    for (var progress in challengeProgress.values) {
      if (progress.status == ChallengeProgressStatus.completed) {
        completedChallenges++;
      }
    }
    return completedChallenges * 100; // 100 points per challenge
  }

  // Helper method to get current user points
  static int getCurrentUserPoints() {
    return getTotalPointsFromAchievements() + getTotalPointsFromChallenges();
  }

  // Helper method to get current user level
  static String getCurrentUserLevel() {
    int totalPoints = getCurrentUserPoints();
    if (totalPoints < 100) return "Eco Newbie";
    if (totalPoints < 300) return "Eco Enthusiast";
    if (totalPoints < 600) return "Eco Warrior";
    if (totalPoints < 1000) return "Eco Champion";
    return "Eco Hero";
  }
}