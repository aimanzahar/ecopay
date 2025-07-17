enum ChallengeCategory {
  environmental,
  social,
  financial,
  health,
  education,
  community,
  personal,
  seasonal
}

enum ChallengeType {
  // From models (category-based)
  transactions,
  contributions,
  environmental_impact,
  daily_login,
  social_sharing,
  milestone,
  seasonal,
  // From services (time-based)
  daily,
  weekly,
  monthly,
  special,
  community
}

enum ChallengeStatus {
  active,
  completed,
  expired,
  inactive,
  // From services
  failed,
  upcoming
}

class Challenge {
  final int? id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final ChallengeType type;
  final ChallengeType challengeType;
  final int targetValue;
  final String targetUnit;
  final int pointsReward;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  Challenge({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.challengeType,
    required this.targetValue,
    required this.targetUnit,
    required this.pointsReward,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'type': type.name,
      'challenge_type': challengeType.name,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'points_reward': pointsReward,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: ChallengeCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ChallengeCategory.environmental,
      ),
      type: ChallengeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ChallengeType.transactions,
      ),
      challengeType: ChallengeType.values.firstWhere(
        (e) => e.name == map['challenge_type'],
        orElse: () => ChallengeType.transactions,
      ),
      targetValue: map['target_value'],
      targetUnit: map['target_unit'],
      pointsReward: map['points_reward'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Helper method to get challenge status
  ChallengeStatus get status {
    final now = DateTime.now();
    if (!isActive) return ChallengeStatus.inactive;
    if (now.isAfter(endDate)) return ChallengeStatus.expired;
    if (now.isBefore(startDate)) return ChallengeStatus.inactive;
    return ChallengeStatus.active;
  }

  // Helper method to get time remaining
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  // Helper method to get formatted time remaining
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays} days left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hours left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minutes left';
    } else {
      return 'Expired';
    }
  }

  // Helper method to get challenge icon
  String get icon {
    switch (challengeType) {
      case ChallengeType.transactions:
        return '💳';
      case ChallengeType.contributions:
        return '🌱';
      case ChallengeType.environmental_impact:
        return '🌍';
      case ChallengeType.daily_login:
        return '📅';
      case ChallengeType.social_sharing:
        return '📱';
      case ChallengeType.milestone:
        return '🎯';
      case ChallengeType.seasonal:
        return '🎉';
      case ChallengeType.daily:
        return '📅';
      case ChallengeType.weekly:
        return '📊';
      case ChallengeType.monthly:
        return '📈';
      case ChallengeType.special:
        return '⭐';
      case ChallengeType.community:
        return '👥';
    }
  }

  // Helper method to get challenge color
  String get colorHex {
    switch (challengeType) {
      case ChallengeType.transactions:
        return '#2196F3';
      case ChallengeType.contributions:
        return '#4CAF50';
      case ChallengeType.environmental_impact:
        return '#00BCD4';
      case ChallengeType.daily_login:
        return '#FF9800';
      case ChallengeType.social_sharing:
        return '#E91E63';
      case ChallengeType.milestone:
        return '#9C27B0';
      case ChallengeType.seasonal:
        return '#FF5722';
      case ChallengeType.daily:
        return '#FF9800';
      case ChallengeType.weekly:
        return '#3F51B5';
      case ChallengeType.monthly:
        return '#673AB7';
      case ChallengeType.special:
        return '#FFC107';
      case ChallengeType.community:
        return '#795548';
    }
  }

  // Helper method to get formatted target
  String get formattedTarget {
    return '$targetValue $targetUnit';
  }

  // Helper method to check if challenge is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Helper method to get difficulty level
  String get difficulty {
    if (targetValue <= 5) return 'Easy';
    if (targetValue <= 15) return 'Medium';
    if (targetValue <= 30) return 'Hard';
    return 'Expert';
  }

  // Copy method for immutable updates
  Challenge copyWith({
    int? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    ChallengeType? type,
    ChallengeType? challengeType,
    int? targetValue,
    String? targetUnit,
    int? pointsReward,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      challengeType: challengeType ?? this.challengeType,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      pointsReward: pointsReward ?? this.pointsReward,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}