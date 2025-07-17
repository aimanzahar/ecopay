class UserPoints {
  final int? id;
  final int userId;
  final int pointsEarned;
  final String pointsSource;
  final String? transactionId;
  final int? contributionId;
  final int? achievementId;
  final int? challengeId;
  final DateTime timestamp;

  UserPoints({
    this.id,
    required this.userId,
    required this.pointsEarned,
    required this.pointsSource,
    this.transactionId,
    this.contributionId,
    this.achievementId,
    this.challengeId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'points_earned': pointsEarned,
      'points_source': pointsSource,
      'transaction_id': transactionId,
      'contribution_id': contributionId,
      'achievement_id': achievementId,
      'challenge_id': challengeId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserPoints.fromMap(Map<String, dynamic> map) {
    return UserPoints(
      id: map['id'],
      userId: map['user_id'],
      pointsEarned: map['points_earned'],
      pointsSource: map['points_source'],
      transactionId: map['transaction_id'],
      contributionId: map['contribution_id'],
      achievementId: map['achievement_id'],
      challengeId: map['challenge_id'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  // Helper method to get formatted points display
  String get formattedPoints {
    return pointsEarned > 0 ? '+$pointsEarned' : '$pointsEarned';
  }

  // Helper method to get source display name
  String get sourceDisplayName {
    switch (pointsSource) {
      case 'transaction':
        return 'Transaction Reward';
      case 'contribution':
        return 'Donation Reward';
      case 'achievement':
        return 'Achievement Unlocked';
      case 'challenge':
        return 'Challenge Completed';
      case 'daily_login':
        return 'Daily Login Bonus';
      case 'referral':
        return 'Referral Bonus';
      case 'milestone':
        return 'Milestone Reached';
      default:
        return 'Points Earned';
    }
  }

  // Helper method to get icon for points source
  String get sourceIcon {
    switch (pointsSource) {
      case 'transaction':
        return '💳';
      case 'contribution':
        return '🌱';
      case 'achievement':
        return '🏆';
      case 'challenge':
        return '🎯';
      case 'daily_login':
        return '📅';
      case 'referral':
        return '👥';
      case 'milestone':
        return '🎖️';
      default:
        return '⭐';
    }
  }

  // Copy method for immutable updates
  UserPoints copyWith({
    int? id,
    int? userId,
    int? pointsEarned,
    String? pointsSource,
    String? transactionId,
    int? contributionId,
    int? achievementId,
    int? challengeId,
    DateTime? timestamp,
  }) {
    return UserPoints(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsSource: pointsSource ?? this.pointsSource,
      transactionId: transactionId ?? this.transactionId,
      contributionId: contributionId ?? this.contributionId,
      achievementId: achievementId ?? this.achievementId,
      challengeId: challengeId ?? this.challengeId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}