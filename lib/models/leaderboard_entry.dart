enum LeaderboardType {
  points,
  contributions,
  co2_saved,
  water_saved,
  energy_saved,
  trees_planted,
  challenges_completed,
  achievements_earned,
  weekly_points,
  monthly_points,
}

class LeaderboardEntry {
  final int? id;
  final int userId;
  final String username;
  final int points;
  final String? trend;
  final double co2Saved;
  final int? targetPoints;
  final int rank;
  final List<String> achievements;
  final LeaderboardType leaderboardType;
  final double score;
  final int ranking;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaderboardEntry({
    this.id,
    required this.userId,
    required this.username,
    required this.points,
    this.trend,
    required this.co2Saved,
    this.targetPoints,
    required this.rank,
    required this.achievements,
    required this.leaderboardType,
    required this.score,
    required this.ranking,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'points': points,
      'trend': trend,
      'co2_saved': co2Saved,
      'target_points': targetPoints,
      'rank': rank,
      'achievements': achievements.join(','),
      'leaderboard_type': leaderboardType.name,
      'score': score,
      'ranking': ranking,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id'],
      userId: map['user_id'],
      username: map['username'] ?? '',
      points: map['points'] ?? 0,
      trend: map['trend'],
      co2Saved: map['co2_saved']?.toDouble() ?? 0.0,
      targetPoints: map['target_points'],
      rank: map['rank'] ?? 0,
      achievements: map['achievements']?.toString().split(',').where((a) => a.isNotEmpty).toList() ?? [],
      leaderboardType: LeaderboardType.values.firstWhere(
        (e) => e.name == map['leaderboard_type'],
        orElse: () => LeaderboardType.points,
      ),
      score: map['score']?.toDouble() ?? 0.0,
      ranking: map['ranking'],
      periodStart: DateTime.parse(map['period_start']),
      periodEnd: DateTime.parse(map['period_end']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Helper method to get formatted score
  String get formattedScore {
    switch (leaderboardType) {
      case LeaderboardType.points:
      case LeaderboardType.weekly_points:
      case LeaderboardType.monthly_points:
        return '${score.toInt()} pts';
      case LeaderboardType.contributions:
        return 'RM ${score.toStringAsFixed(2)}';
      case LeaderboardType.co2_saved:
        return '${score.toStringAsFixed(2)} kg CO₂';
      case LeaderboardType.water_saved:
        return '${score.toStringAsFixed(1)} L';
      case LeaderboardType.energy_saved:
        return '${score.toStringAsFixed(1)} kWh';
      case LeaderboardType.trees_planted:
        return '${score.toInt()} trees';
      case LeaderboardType.challenges_completed:
        return '${score.toInt()} challenges';
      case LeaderboardType.achievements_earned:
        return '${score.toInt()} achievements';
    }
  }

  // Helper method to get leaderboard display name
  String get displayName {
    switch (leaderboardType) {
      case LeaderboardType.points:
        return 'Total Points';
      case LeaderboardType.contributions:
        return 'Total Contributions';
      case LeaderboardType.co2_saved:
        return 'CO₂ Saved';
      case LeaderboardType.water_saved:
        return 'Water Saved';
      case LeaderboardType.energy_saved:
        return 'Energy Saved';
      case LeaderboardType.trees_planted:
        return 'Trees Planted';
      case LeaderboardType.challenges_completed:
        return 'Challenges Completed';
      case LeaderboardType.achievements_earned:
        return 'Achievements Earned';
      case LeaderboardType.weekly_points:
        return 'Weekly Points';
      case LeaderboardType.monthly_points:
        return 'Monthly Points';
    }
  }

  // Helper method to get leaderboard icon
  String get icon {
    switch (leaderboardType) {
      case LeaderboardType.points:
      case LeaderboardType.weekly_points:
      case LeaderboardType.monthly_points:
        return '⭐';
      case LeaderboardType.contributions:
        return '💰';
      case LeaderboardType.co2_saved:
        return '🌍';
      case LeaderboardType.water_saved:
        return '💧';
      case LeaderboardType.energy_saved:
        return '⚡';
      case LeaderboardType.trees_planted:
        return '🌳';
      case LeaderboardType.challenges_completed:
        return '🎯';
      case LeaderboardType.achievements_earned:
        return '🏆';
    }
  }

  // Helper method to get ranking medal
  String get rankingMedal {
    switch (ranking) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$ranking';
    }
  }

  // Helper method to get ranking color
  String get rankingColor {
    switch (ranking) {
      case 1:
        return '#FFD700'; // Gold
      case 2:
        return '#C0C0C0'; // Silver
      case 3:
        return '#CD7F32'; // Bronze
      default:
        return '#757575'; // Gray
    }
  }

  // Helper method to check if entry is current (within period)
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(periodStart) && now.isBefore(periodEnd);
  }

  // Helper method to get period description
  String get periodDescription {
    final diff = periodEnd.difference(periodStart);
    if (diff.inDays <= 1) {
      return 'Daily';
    } else if (diff.inDays <= 7) {
      return 'Weekly';
    } else if (diff.inDays <= 31) {
      return 'Monthly';
    } else {
      return 'All Time';
    }
  }

  // Helper method to get formatted period
  String get formattedPeriod {
    final startFormat = '${periodStart.day}/${periodStart.month}/${periodStart.year}';
    final endFormat = '${periodEnd.day}/${periodEnd.month}/${periodEnd.year}';
    return '$startFormat - $endFormat';
  }

  // Helper method to check if this is a top ranking
  bool get isTopRanking {
    return ranking <= 3;
  }

  // Helper method to check if ranking improved
  bool hasImprovedFrom(int previousRanking) {
    return ranking < previousRanking;
  }

  // Copy method for immutable updates
  LeaderboardEntry copyWith({
    int? id,
    int? userId,
    String? username,
    int? points,
    String? trend,
    double? co2Saved,
    int? targetPoints,
    int? rank,
    List<String>? achievements,
    LeaderboardType? leaderboardType,
    double? score,
    int? ranking,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      points: points ?? this.points,
      trend: trend ?? this.trend,
      co2Saved: co2Saved ?? this.co2Saved,
      targetPoints: targetPoints ?? this.targetPoints,
      rank: rank ?? this.rank,
      achievements: achievements ?? this.achievements,
      leaderboardType: leaderboardType ?? this.leaderboardType,
      score: score ?? this.score,
      ranking: ranking ?? this.ranking,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Extended class to include user details
class LeaderboardEntryWithUser extends LeaderboardEntry {
  final String name;
  final String? profileImage;

  LeaderboardEntryWithUser({
    required super.id,
    required super.userId,
    required super.username,
    required super.points,
    super.trend,
    required super.co2Saved,
    super.targetPoints,
    required super.rank,
    required super.achievements,
    required super.leaderboardType,
    required super.score,
    required super.ranking,
    required super.periodStart,
    required super.periodEnd,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    this.profileImage,
  });

  factory LeaderboardEntryWithUser.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntryWithUser(
      id: map['id'],
      userId: map['user_id'],
      username: map['username'] ?? '',
      points: map['points'] ?? 0,
      trend: map['trend'],
      co2Saved: map['co2_saved']?.toDouble() ?? 0.0,
      targetPoints: map['target_points'],
      rank: map['rank'] ?? 0,
      achievements: map['achievements']?.toString().split(',').where((a) => a.isNotEmpty).toList() ?? [],
      leaderboardType: LeaderboardType.values.firstWhere(
        (e) => e.name == map['leaderboard_type'],
        orElse: () => LeaderboardType.points,
      ),
      score: map['score']?.toDouble() ?? 0.0,
      ranking: map['ranking'],
      periodStart: DateTime.parse(map['period_start']),
      periodEnd: DateTime.parse(map['period_end']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      name: map['name'],
      profileImage: map['profile_image'],
    );
  }

  // Helper method to get display name with fallback
  String get displayUserName {
    return name.isNotEmpty ? name : 'Anonymous User';
  }

  // Helper method to get user initials for avatar
  String get userInitials {
    if (name.isEmpty) return 'AU';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}