class Achievement {
  final int? id;
  final String name;
  final String description;
  final String target;

  Achievement({
    this.id,
    required this.name,
    required this.description,
    required this.target,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target': target,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      target: map['target'],
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