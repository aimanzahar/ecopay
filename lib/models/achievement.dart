enum AchievementTier { bronze, silver, gold, platinum, diamond }

enum AchievementType {
  completion,
  environmental,
  social,
  financial,
  consistency,
  exploration,
  special
}

class Achievement {
  final int? id;
  final String name;
  final String description;
  final String target;
  final AchievementTier tier;
  final AchievementType type;
  final int pointsReward;

  Achievement({
    this.id,
    required this.name,
    required this.description,
    required this.target,
    required this.tier,
    required this.type,
    required this.pointsReward,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target': target,
      'tier': tier.name,
      'type': type.name,
      'points_reward': pointsReward,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      target: map['target'],
      tier: AchievementTier.values.firstWhere(
        (e) => e.name == map['tier'],
        orElse: () => AchievementTier.bronze,
      ),
      type: AchievementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AchievementType.completion,
      ),
      pointsReward: map['points_reward'] ?? 50,
    );
  }
}

class UserAchievement {
  final int? id;
  final int userId;
  final int achievementId;
  final DateTime dateUnlocked;

  UserAchievement({
    this.id,
    required this.userId,
    required this.achievementId,
    required this.dateUnlocked,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'date_unlocked': dateUnlocked.toIso8601String(),
    };
  }

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: map['id'],
      userId: map['user_id'],
      achievementId: map['achievement_id'],
      dateUnlocked: DateTime.parse(map['date_unlocked']),
    );
  }
}