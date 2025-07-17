enum NotificationType {
  achievement_unlocked,
  challenge_completed,
  challenge_progress,
  challenge_about_to_expire,
  leaderboard_position_changed,
  points_earned,
  level_up,
  badge_earned,
  milestone_reached,
  friend_activity,
  system_announcement,
  promotion,
  reminder,
}

class Notification {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final NotificationType notificationType;
  final bool isRead;
  final int? relatedId;
  final DateTime createdAt;

  Notification({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.isRead = false,
    this.relatedId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': notificationType.name,
      'is_read': isRead ? 1 : 0,
      'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      message: map['message'],
      notificationType: NotificationType.values.firstWhere(
        (e) => e.name == map['notification_type'],
        orElse: () => NotificationType.system_announcement,
      ),
      isRead: map['is_read'] == 1,
      relatedId: map['related_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Helper method to get notification icon
  String get icon {
    switch (notificationType) {
      case NotificationType.achievement_unlocked:
        return '🏆';
      case NotificationType.challenge_completed:
        return '🎯';
      case NotificationType.challenge_progress:
        return '📈';
      case NotificationType.challenge_about_to_expire:
        return '⏰';
      case NotificationType.leaderboard_position_changed:
        return '🏅';
      case NotificationType.points_earned:
        return '⭐';
      case NotificationType.level_up:
        return '🆙';
      case NotificationType.badge_earned:
        return '🎖️';
      case NotificationType.milestone_reached:
        return '🎉';
      case NotificationType.friend_activity:
        return '👥';
      case NotificationType.system_announcement:
        return '📢';
      case NotificationType.promotion:
        return '🎁';
      case NotificationType.reminder:
        return '🔔';
    }
  }

  // Helper method to get notification color
  String get color {
    switch (notificationType) {
      case NotificationType.achievement_unlocked:
        return '#FFD700'; // Gold
      case NotificationType.challenge_completed:
        return '#4CAF50'; // Green
      case NotificationType.challenge_progress:
        return '#2196F3'; // Blue
      case NotificationType.challenge_about_to_expire:
        return '#FF9800'; // Orange
      case NotificationType.leaderboard_position_changed:
        return '#9C27B0'; // Purple
      case NotificationType.points_earned:
        return '#00BCD4'; // Cyan
      case NotificationType.level_up:
        return '#FF5722'; // Deep Orange
      case NotificationType.badge_earned:
        return '#795548'; // Brown
      case NotificationType.milestone_reached:
        return '#E91E63'; // Pink
      case NotificationType.friend_activity:
        return '#607D8B'; // Blue Gray
      case NotificationType.system_announcement:
        return '#9E9E9E'; // Gray
      case NotificationType.promotion:
        return '#CDDC39'; // Lime
      case NotificationType.reminder:
        return '#FFC107'; // Amber
    }
  }

  // Helper method to get priority level
  int get priority {
    switch (notificationType) {
      case NotificationType.achievement_unlocked:
      case NotificationType.challenge_completed:
      case NotificationType.level_up:
        return 3; // High priority
      case NotificationType.challenge_progress:
      case NotificationType.leaderboard_position_changed:
      case NotificationType.points_earned:
      case NotificationType.badge_earned:
        return 2; // Medium priority
      case NotificationType.challenge_about_to_expire:
      case NotificationType.milestone_reached:
      case NotificationType.friend_activity:
      case NotificationType.reminder:
        return 1; // Low priority
      case NotificationType.system_announcement:
      case NotificationType.promotion:
        return 0; // Lowest priority
    }
  }

  // Helper method to get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to check if notification is recent
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  // Helper method to check if notification is urgent
  bool get isUrgent {
    return notificationType == NotificationType.challenge_about_to_expire ||
           notificationType == NotificationType.reminder;
  }

  // Helper method to get formatted created date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  // Copy method for immutable updates
  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    NotificationType? notificationType,
    bool? isRead,
    int? relatedId,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Factory methods for creating specific notification types
  factory Notification.achievementUnlocked({
    required int userId,
    required String achievementName,
    required int achievementId,
    required int pointsEarned,
  }) {
    return Notification(
      userId: userId,
      title: 'Achievement Unlocked! 🏆',
      message: 'You\'ve earned "$achievementName" and gained $pointsEarned points!',
      notificationType: NotificationType.achievement_unlocked,
      relatedId: achievementId,
      createdAt: DateTime.now(),
    );
  }

  factory Notification.challengeCompleted({
    required int userId,
    required String challengeTitle,
    required int challengeId,
    required int pointsEarned,
  }) {
    return Notification(
      userId: userId,
      title: 'Challenge Completed! 🎯',
      message: 'You\'ve completed "$challengeTitle" and earned $pointsEarned points!',
      notificationType: NotificationType.challenge_completed,
      relatedId: challengeId,
      createdAt: DateTime.now(),
    );
  }

  factory Notification.challengeProgress({
    required int userId,
    required String challengeTitle,
    required int challengeId,
    required int currentProgress,
    required int targetValue,
  }) {
    final percentage = ((currentProgress / targetValue) * 100).round();
    return Notification(
      userId: userId,
      title: 'Challenge Progress 📈',
      message: 'You\'re $percentage% complete with "$challengeTitle"!',
      notificationType: NotificationType.challenge_progress,
      relatedId: challengeId,
      createdAt: DateTime.now(),
    );
  }

  factory Notification.challengeAboutToExpire({
    required int userId,
    required String challengeTitle,
    required int challengeId,
    required String timeRemaining,
  }) {
    return Notification(
      userId: userId,
      title: 'Challenge Expiring Soon! ⏰',
      message: '"$challengeTitle" expires in $timeRemaining. Complete it now!',
      notificationType: NotificationType.challenge_about_to_expire,
      relatedId: challengeId,
      createdAt: DateTime.now(),
    );
  }

  factory Notification.levelUp({
    required int userId,
    required int newLevel,
    required int pointsEarned,
  }) {
    return Notification(
      userId: userId,
      title: 'Level Up! 🆙',
      message: 'Congratulations! You\'ve reached Level $newLevel and earned $pointsEarned bonus points!',
      notificationType: NotificationType.level_up,
      createdAt: DateTime.now(),
    );
  }

  factory Notification.leaderboardPositionChanged({
    required int userId,
    required String leaderboardType,
    required int newPosition,
    required int oldPosition,
  }) {
    final improved = newPosition < oldPosition;
    return Notification(
      userId: userId,
      title: improved ? 'Leaderboard Position Improved! 🏅' : 'Leaderboard Position Changed 🏅',
      message: improved
          ? 'You\'ve moved up to #$newPosition in $leaderboardType!'
          : 'Your position in $leaderboardType is now #$newPosition',
      notificationType: NotificationType.leaderboard_position_changed,
      createdAt: DateTime.now(),
    );
  }

  factory Notification.pointsEarned({
    required int userId,
    required int pointsEarned,
    required String source,
  }) {
    return Notification(
      userId: userId,
      title: 'Points Earned! ⭐',
      message: 'You\'ve earned $pointsEarned points from $source!',
      notificationType: NotificationType.points_earned,
      createdAt: DateTime.now(),
    );
  }
}