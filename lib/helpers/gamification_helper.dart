import '../helpers/database_helper.dart';
import '../models/user.dart';
import '../models/transaction.dart';

class GamificationHelper {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> checkAllChallengesAndAchievements(User user) async {
    final transactions = await _databaseHelper.getTransactions();
    await _checkEcoWarriorAchievement(user, transactions);
    await _checkMangroveGuardianAchievement(user);
    // Add more checks for other achievements and challenges
  }

  Future<void> _checkEcoWarriorAchievement(User user, List<Transaction> transactions) async {
    // Logic to check for 100 green purchases
    final greenPurchaseCount = transactions.where((t) => t.notes?.contains('EcoPay') ?? false).length;
    if (greenPurchaseCount >= 100) {
      // Award achievement
    }
  }

  Future<void> _checkMangroveGuardianAchievement(User user) async {
    // Logic to check for RM 50 donated to mangrove projects
    // This will require more detailed contribution tracking
  }
}