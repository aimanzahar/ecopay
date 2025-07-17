import '../data/placeholder_challenges_and_achievements.dart';
import '../models/challenge.dart';
import '../models/achievement.dart';
import '../models/challenge_progress.dart';

class PlaceholderDataService {
  // Get all active challenges for the current user
  static List<Challenge> getActiveChallenges() {
    return PlaceholderData.challenges.where((challenge) => challenge.isCurrentlyActive).toList();
  }

  // Get current user's challenge progress
  static List<ChallengeProgress> getUserChallengeProgress() {
    return PlaceholderData.challengeProgress.values.toList();
  }

  // Get current user's achievements
  static List<UserAchievement> getUserAchievements() {
    return PlaceholderData.userAchievements;
  }

  // Get all achievements
  static List<Achievement> getAllAchievements() {
    return PlaceholderData.achievements;
  }

  // Get current user points
  static int getUserPoints() {
    return PlaceholderData.getCurrentUserPoints();
  }

  // Get current user level
  static String getUserLevel() {
    return PlaceholderData.getCurrentUserLevel();
  }

  // Get challenge progress for a specific challenge
  static ChallengeProgress? getChallengeProgress(int challengeId) {
    return PlaceholderData.getChallengeProgress(challengeId);
  }

  // Get total points from achievements
  static int getPointsFromAchievements() {
    return PlaceholderData.getTotalPointsFromAchievements();
  }

  // Get total points from challenges
  static int getPointsFromChallenges() {
    return PlaceholderData.getTotalPointsFromChallenges();
  }

  // Get completion percentage for a challenge
  static double getChallengeCompletionPercentage(int challengeId) {
    final progress = getChallengeProgress(challengeId);
    if (progress == null) return 0.0;
    
    final challenge = PlaceholderData.challenges.firstWhere((c) => c.id == challengeId);
    return (progress.currentProgress / challenge.targetValue).clamp(0.0, 1.0);
  }

  // Get user's next milestone
  static String getNextMilestone() {
    final totalPoints = getUserPoints();
    final nextMilestone = ((totalPoints ~/ 100) + 1) * 100;
    return "Reach $nextMilestone points";
  }

  // Get user's recent activity summary
  static Map<String, dynamic> getUserActivitySummary() {
    return {
      'totalPoints': getUserPoints(),
      'currentLevel': getUserLevel(),
      'completedAchievements': PlaceholderData.userAchievements.length,
      'activeChallenges': getActiveChallenges().length,
      'nextMilestone': getNextMilestone(),
      'recentActivity': [
        {
          'type': 'achievement',
          'title': 'Eco Warrior Beginner',
          'points': 100,
          'date': DateTime.now().subtract(Duration(days: 2)),
        },
        {
          'type': 'challenge_progress',
          'title': 'Green Contributor',
          'progress': '50%',
          'points': 75,
          'date': DateTime.now().subtract(Duration(days: 1)),
        },
      ],
    };
  }
}