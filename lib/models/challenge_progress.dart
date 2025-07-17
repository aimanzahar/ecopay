// Challenge Progress Status Enum
enum ChallengeProgressStatus {
  notStarted,
  inProgress,
  completed,
  failed,
  expired,
}

class ChallengeProgress {
  final int? id;
  final int userId;
  final int challengeId;
  final int currentProgress;
  final int targetValue;
  final bool isCompleted;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChallengeProgressStatus status;
  final DateTime lastUpdated;

  ChallengeProgress({
    this.id,
    required this.userId,
    required this.challengeId,
    this.currentProgress = 0,
    required this.targetValue,
    this.isCompleted = false,
    this.completionDate,
    required this.createdAt,
    required this.updatedAt,
    this.status = ChallengeProgressStatus.notStarted,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'current_progress': currentProgress,
      'target_value': targetValue,
      'is_completed': isCompleted ? 1 : 0,
      'completion_date': completionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status.index,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory ChallengeProgress.fromMap(Map<String, dynamic> map) {
    return ChallengeProgress(
      id: map['id'],
      userId: map['user_id'],
      challengeId: map['challenge_id'],
      currentProgress: map['current_progress'] ?? 0,
      targetValue: map['target_value'] ?? 0,
      isCompleted: map['is_completed'] == 1,
      completionDate: map['completion_date'] != null
          ? DateTime.parse(map['completion_date'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      status: ChallengeProgressStatus.values[map['status'] ?? 0],
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  // Helper method to calculate progress percentage
  double progressPercentage([int? targetValueOverride]) {
    final target = targetValueOverride ?? targetValue;
    if (target == 0) return 0.0;
    return (currentProgress / target).clamp(0.0, 1.0);
  }

  // Helper method to get formatted progress
  String formattedProgress([int? targetValueOverride, String? unit]) {
    final target = targetValueOverride ?? targetValue;
    return '$currentProgress / $target ${unit ?? 'units'}';
  }

  // Helper method to check if challenge is close to completion
  bool isCloseToCompletion([int? targetValueOverride]) {
    return progressPercentage(targetValueOverride) >= 0.8;
  }

  // Helper method to get remaining progress
  int remainingProgress([int? targetValueOverride]) {
    final target = targetValueOverride ?? targetValue;
    return (target - currentProgress).clamp(0, target);
  }

  // Helper method to get progress status
  String getProgressStatus([int? targetValueOverride]) {
    if (isCompleted) return 'Completed';
    
    final percentage = progressPercentage(targetValueOverride);
    if (percentage >= 0.8) return 'Almost there!';
    if (percentage >= 0.5) return 'Halfway there';
    if (percentage >= 0.25) return 'Good progress';
    return 'Just started';
  }

  // Helper method to get progress color
  String getProgressColor([int? targetValueOverride]) {
    if (isCompleted) return '#4CAF50'; // Green
    
    final percentage = progressPercentage(targetValueOverride);
    if (percentage >= 0.8) return '#FF9800'; // Orange
    if (percentage >= 0.5) return '#2196F3'; // Blue
    if (percentage >= 0.25) return '#9C27B0'; // Purple
    return '#757575'; // Gray
  }

  // Helper method to check if progress should trigger a milestone notification
  bool shouldNotifyMilestone([int? targetValueOverride, List<double>? milestones]) {
    final target = targetValueOverride ?? targetValue;
    final milestoneList = milestones ?? [0.25, 0.5, 0.75, 1.0];
    final percentage = progressPercentage(target);
    return milestoneList.any((milestone) =>
        percentage >= milestone &&
        (currentProgress - 1) < (target * milestone)
    );
  }

  // Copy method for immutable updates
  ChallengeProgress copyWith({
    int? id,
    int? userId,
    int? challengeId,
    int? currentProgress,
    int? targetValue,
    bool? isCompleted,
    DateTime? completionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChallengeProgressStatus? status,
    DateTime? lastUpdated,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetValue: targetValue ?? this.targetValue,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Extended class to include challenge details
class ChallengeProgressWithDetails extends ChallengeProgress {
  final String title;
  final String description;
  final String targetUnit;
  final int pointsReward;
  final DateTime endDate;

  ChallengeProgressWithDetails({
    super.id,
    required super.userId,
    required super.challengeId,
    super.currentProgress = 0,
    required super.targetValue,
    super.isCompleted = false,
    super.completionDate,
    required super.createdAt,
    required super.updatedAt,
    super.status = ChallengeProgressStatus.notStarted,
    required super.lastUpdated,
    required this.title,
    required this.description,
    required this.targetUnit,
    required this.pointsReward,
    required this.endDate,
  });

  factory ChallengeProgressWithDetails.fromMap(Map<String, dynamic> map) {
    return ChallengeProgressWithDetails(
      id: map['id'],
      userId: map['user_id'],
      challengeId: map['challenge_id'],
      currentProgress: map['current_progress'] ?? 0,
      isCompleted: map['is_completed'] == 1,
      completionDate: map['completion_date'] != null
          ? DateTime.parse(map['completion_date'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastUpdated: DateTime.parse(map['last_updated']),
      title: map['title'],
      description: map['description'],
      targetValue: map['target_value'],
      targetUnit: map['target_unit'],
      pointsReward: map['points_reward'],
      endDate: DateTime.parse(map['end_date']),
    );
  }

  // Helper method to check if challenge is about to expire
  bool isAboutToExpire() {
    final now = DateTime.now();
    final timeUntilExpiry = endDate.difference(now);
    return timeUntilExpiry.inDays <= 1 && timeUntilExpiry.inSeconds > 0;
  }

  // Helper method to get time until expiry
  Duration get timeUntilExpiry {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }

  // Helper method to get formatted time until expiry
  String get formattedTimeUntilExpiry {
    final remaining = timeUntilExpiry;
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
}