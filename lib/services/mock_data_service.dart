import '../models/user.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/challenge_progress.dart';
import '../data/placeholder_challenges_and_achievements.dart';

class MockDataService {
  // Get all users
  static List<User> getUsers() {
    return [
      User(
        id: 1,
        name: 'Eco Warrior',
        username: 'EcoWarrior',
        email: 'eco@example.com',
        totalPoints: 1250,
        level: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActive: DateTime.now(),
      ),
      User(
        id: 2,
        name: 'Green Thumb',
        username: 'GreenThumb',
        email: 'green@example.com',
        totalPoints: 980,
        level: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        lastActive: DateTime.now(),
      ),
      User(
        id: 3,
        name: 'Climate Champion',
        username: 'ClimateChampion',
        email: 'climate@example.com',
        totalPoints: 1450,
        level: 6,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        lastActive: DateTime.now(),
      ),
      User(
        id: 4,
        name: 'Solar Saver',
        username: 'SolarSaver',
        email: 'solar@example.com',
        totalPoints: 750,
        level: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        lastActive: DateTime.now(),
      ),
      User(
        id: 5,
        name: 'Recycle Ranger',
        username: 'RecycleRanger',
        email: 'recycle@example.com',
        totalPoints: 1150,
        level: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        lastActive: DateTime.now(),
      ),
    ];
  }

  // Get all achievements
  static List<Achievement> getAchievements() {
    return PlaceholderData.achievements;
  }

  // Get all challenges
  static List<Challenge> getChallenges() {
    return PlaceholderData.challenges;
  }

  // Get achievements for a specific user
  static List<UserAchievement> getAchievementsForUser(int userId) {
    return PlaceholderData.userAchievements.where((ua) => ua.userId == userId).toList();
  }

  // Get challenge progress for a specific user
  static List<ChallengeProgress> getChallengeProgressForUser(int userId) {
    return PlaceholderData.challengeProgress.values
        .where((cp) => cp.userId == userId)
        .toList();
  }

  // Get user by ID
  static User? getUserById(int userId) {
    try {
      return getUsers().firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Get achievement by ID
  static Achievement? getAchievementById(int achievementId) {
    try {
      return getAchievements().firstWhere((achievement) => achievement.id == achievementId);
    } catch (e) {
      return null;
    }
  }

  // Get challenge by ID
  static Challenge? getChallengeById(int challengeId) {
    try {
      return getChallenges().firstWhere((challenge) => challenge.id == challengeId);
    } catch (e) {
      return null;
    }
  }

  // Get challenge progress by challenge ID and user ID
  static ChallengeProgress? getChallengeProgress(int challengeId, int userId) {
    try {
      return getChallengeProgressForUser(userId)
          .firstWhere((cp) => cp.challengeId == challengeId);
    } catch (e) {
      return null;
    }
  }

  // Get user's total points
  static int getUserTotalPoints(int userId) {
    final user = getUserById(userId);
    return user?.totalPoints ?? 0;
  }

  // Get user's level
  static int getUserLevel(int userId) {
    final user = getUserById(userId);
    return user?.level ?? 1;
  }

  // Get completed challenges for user
  static List<Challenge> getCompletedChallengesForUser(int userId) {
    final completedProgressList = getChallengeProgressForUser(userId)
        .where((cp) => cp.status == ChallengeProgressStatus.completed)
        .toList();
    
    return completedProgressList
        .map((cp) => getChallengeById(cp.challengeId))
        .where((challenge) => challenge != null)
        .cast<Challenge>()
        .toList();
  }

  // Get active challenges for user
  static List<Challenge> getActiveChallengesForUser(int userId) {
    final activeProgressList = getChallengeProgressForUser(userId)
        .where((cp) => cp.status == ChallengeProgressStatus.inProgress)
        .toList();
    
    return activeProgressList
        .map((cp) => getChallengeById(cp.challengeId))
        .where((challenge) => challenge != null)
        .cast<Challenge>()
        .toList();
  }

  // Get completed achievements count for user
  static int getCompletedAchievementsCount(int userId) {
    return getAchievementsForUser(userId).length;
  }

  // Get total achievements count
  static int getTotalAchievementsCount() {
    return getAchievements().length;
  }

  // Get user's achievement progress percentage
  static double getUserAchievementProgress(int userId) {
    final completed = getCompletedAchievementsCount(userId);
    final total = getTotalAchievementsCount();
    return total > 0 ? (completed / total) * 100 : 0.0;
  }
}