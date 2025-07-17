import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../helpers/database_helper.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';
import '../services/achievement_service.dart';
import '../services/challenge_service.dart';
import '../services/leaderboard_service.dart';

/// Notification scheduling configuration
enum NotificationSchedule {
  immediate,
  delayed_5min,
  delayed_15min,
  delayed_1hour,
  daily_summary,
  weekly_summary,
}

/// Notification delivery status
enum NotificationDeliveryStatus {
  pending,
  delivered,
  failed,
  cancelled,
}

/// Notification preferences for users
class NotificationPreferences {
  final bool achievementNotifications;
  final bool challengeNotifications;
  final bool leaderboardNotifications;
  final bool pointsNotifications;
  final bool environmentalNotifications;
  final bool socialNotifications;
  final bool systemNotifications;
  final bool promotionNotifications;
  final bool reminderNotifications;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool inAppNotifications;
  final NotificationSchedule defaultSchedule;
  final List<int> quietHours; // Hours when notifications are muted (0-23)
  final bool batchSimilarNotifications;
  final int maxDailyNotifications;

  NotificationPreferences({
    this.achievementNotifications = true,
    this.challengeNotifications = true,
    this.leaderboardNotifications = true,
    this.pointsNotifications = true,
    this.environmentalNotifications = true,
    this.socialNotifications = true,
    this.systemNotifications = true,
    this.promotionNotifications = false,
    this.reminderNotifications = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.inAppNotifications = true,
    this.defaultSchedule = NotificationSchedule.immediate,
    this.quietHours = const [22, 23, 0, 1, 2, 3, 4, 5, 6], // 10 PM - 6 AM
    this.batchSimilarNotifications = true,
    this.maxDailyNotifications = 20,
  });

  Map<String, dynamic> toMap() {
    return {
      'achievement_notifications': achievementNotifications ? 1 : 0,
      'challenge_notifications': challengeNotifications ? 1 : 0,
      'leaderboard_notifications': leaderboardNotifications ? 1 : 0,
      'points_notifications': pointsNotifications ? 1 : 0,
      'environmental_notifications': environmentalNotifications ? 1 : 0,
      'social_notifications': socialNotifications ? 1 : 0,
      'system_notifications': systemNotifications ? 1 : 0,
      'promotion_notifications': promotionNotifications ? 1 : 0,
      'reminder_notifications': reminderNotifications ? 1 : 0,
      'push_notifications': pushNotifications ? 1 : 0,
      'email_notifications': emailNotifications ? 1 : 0,
      'in_app_notifications': inAppNotifications ? 1 : 0,
      'default_schedule': defaultSchedule.name,
      'quiet_hours': quietHours.join(','),
      'batch_similar_notifications': batchSimilarNotifications ? 1 : 0,
      'max_daily_notifications': maxDailyNotifications,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      achievementNotifications: map['achievement_notifications'] == 1,
      challengeNotifications: map['challenge_notifications'] == 1,
      leaderboardNotifications: map['leaderboard_notifications'] == 1,
      pointsNotifications: map['points_notifications'] == 1,
      environmentalNotifications: map['environmental_notifications'] == 1,
      socialNotifications: map['social_notifications'] == 1,
      systemNotifications: map['system_notifications'] == 1,
      promotionNotifications: map['promotion_notifications'] == 1,
      reminderNotifications: map['reminder_notifications'] == 1,
      pushNotifications: map['push_notifications'] == 1,
      emailNotifications: map['email_notifications'] == 1,
      inAppNotifications: map['in_app_notifications'] == 1,
      defaultSchedule: NotificationSchedule.values.byName(map['default_schedule'] ?? 'immediate'),
      quietHours: (map['quiet_hours'] as String?)?.split(',').map(int.parse).toList() ?? [],
      batchSimilarNotifications: map['batch_similar_notifications'] == 1,
      maxDailyNotifications: map['max_daily_notifications'] ?? 20,
    );
  }
}

/// Notification batch for grouping similar notifications
class NotificationBatch {
  final String batchId;
  final NotificationType type;
  final List<Notification> notifications;
  final DateTime createdAt;
  final DateTime scheduledFor;
  final bool isProcessed;

  NotificationBatch({
    required this.batchId,
    required this.type,
    required this.notifications,
    required this.createdAt,
    required this.scheduledFor,
    this.isProcessed = false,
  });

  Notification createBatchNotification(int userId) {
    if (notifications.isEmpty) {
      throw Exception('Cannot create batch notification from empty list');
    }

    switch (type) {
      case NotificationType.points_earned:
        final totalPoints = notifications.fold(0, (sum, n) => sum + _extractPointsFromMessage(n.message));
        return Notification.pointsEarned(
          userId: userId,
          pointsEarned: totalPoints,
          source: '${notifications.length} activities',
        );

      case NotificationType.achievement_unlocked:
        return Notification(
          userId: userId,
          title: 'Multiple Achievements Unlocked! 🏆',
          message: 'You\'ve unlocked ${notifications.length} achievements! Check your profile for details.',
          notificationType: NotificationType.achievement_unlocked,
          createdAt: DateTime.now(),
        );

      case NotificationType.challenge_completed:
        return Notification(
          userId: userId,
          title: 'Challenges Completed! 🎯',
          message: 'You\'ve completed ${notifications.length} challenges! Great job!',
          notificationType: NotificationType.challenge_completed,
          createdAt: DateTime.now(),
        );

      default:
        // For other types, return the first notification with updated message
        return notifications.first.copyWith(
          message: '${notifications.first.message} (+${notifications.length - 1} more)',
        );
    }
  }

  int _extractPointsFromMessage(String message) {
    // Extract points from messages like "You've earned 150 points from transaction..."
    final match = RegExp(r'(\d+) points?').firstMatch(message);
    return match != null ? int.parse(match.group(1)!) : 0;
  }
}

/// Comprehensive notification service for managing all notifications
class NotificationService {
    static final NotificationService _instance = NotificationService._internal();
  
    factory NotificationService() {
      return _instance;
    }
  
    NotificationService._internal();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final AchievementService _achievementService = AchievementService();
  final ChallengeService _challengeService = ChallengeService();
  final LeaderboardService _leaderboardService = LeaderboardService();

  // In-memory notification queue for real-time delivery
  final List<Notification> _notificationQueue = [];
  final Map<int, NotificationPreferences> _userPreferences = {};
  final Map<String, NotificationBatch> _notificationBatches = {};
  final Map<String, Timer> _scheduledNotifications = {};

  // Real-time notification stream
  final StreamController<Notification> _notificationStreamController = StreamController<Notification>.broadcast();
  Stream<Notification> get notificationStream => _notificationStreamController.stream;

  // Notification delivery timers
  Timer? _batchProcessingTimer;
  Timer? _reminderTimer;
  Timer? _dailySummaryTimer;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      developer.log('NotificationService: Initializing notification service');
      
      // Start periodic batch processing
      _batchProcessingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _processBatchedNotifications();
      });

      // Start reminder checking
      _reminderTimer = Timer.periodic(const Duration(minutes: 30), (_) {
        _checkForReminders();
      });

      // Start daily summary processing
      _dailySummaryTimer = Timer.periodic(const Duration(hours: 24), (_) {
        _sendDailySummaries();
      });

      // Load user preferences
      await _loadUserPreferences();

      developer.log('NotificationService: Initialization complete');
    } catch (e) {
      developer.log('NotificationService: Error during initialization: $e', level: 1000);
    }
  }

  /// Dispose of timers and resources
  void dispose() {
    _batchProcessingTimer?.cancel();
    _reminderTimer?.cancel();
    _dailySummaryTimer?.cancel();
    _notificationStreamController.close();
    
    // Cancel all scheduled notifications
    for (final timer in _scheduledNotifications.values) {
      timer.cancel();
    }
    _scheduledNotifications.clear();
  }

  /// Send a notification with smart delivery logic
  Future<void> sendNotification(Notification notification, {NotificationSchedule? schedule}) async {
    try {
      final preferences = await _getUserPreferences(notification.userId);
      
      // Check if notification type is enabled
      if (!_isNotificationTypeEnabled(notification.notificationType, preferences)) {
        developer.log('NotificationService: Notification type ${notification.notificationType.name} is disabled for user ${notification.userId}');
        return;
      }

      // Check daily notification limit
      if (await _exceedsDailyLimit(notification.userId, preferences)) {
        developer.log('NotificationService: Daily notification limit exceeded for user ${notification.userId}');
        return;
      }

      // Check quiet hours
      if (_isQuietHour(preferences)) {
        developer.log('NotificationService: Delaying notification due to quiet hours');
        await _scheduleNotification(notification, _getNextActiveHour(preferences));
        return;
      }

      // Determine delivery method
      final deliverySchedule = schedule ?? preferences.defaultSchedule;
      
      switch (deliverySchedule) {
        case NotificationSchedule.immediate:
          await _deliverImmediately(notification, preferences);
          break;
          
        case NotificationSchedule.delayed_5min:
          await _scheduleNotification(notification, DateTime.now().add(const Duration(minutes: 5)));
          break;
          
        case NotificationSchedule.delayed_15min:
          await _scheduleNotification(notification, DateTime.now().add(const Duration(minutes: 15)));
          break;
          
        case NotificationSchedule.delayed_1hour:
          await _scheduleNotification(notification, DateTime.now().add(const Duration(hours: 1)));
          break;
          
        case NotificationSchedule.daily_summary:
          await _addToDailySummary(notification);
          break;
          
        case NotificationSchedule.weekly_summary:
          await _addToWeeklySummary(notification);
          break;
      }
    } catch (e) {
      developer.log('NotificationService: Error sending notification: $e', level: 1000);
    }
  }

  /// Deliver notification immediately
  Future<void> _deliverImmediately(Notification notification, NotificationPreferences preferences) async {
    try {
      // Check if batching is enabled and should be batched
      if (preferences.batchSimilarNotifications && _shouldBatchNotification(notification)) {
        await _addToBatch(notification);
        return;
      }

      // Store in database
      await _databaseHelper.insertNotification(notification.toMap());

      // Add to real-time stream
      _notificationStreamController.add(notification);

      // Send push notification if enabled
      if (preferences.pushNotifications) {
        await _sendPushNotification(notification);
      }

      developer.log('NotificationService: Notification delivered immediately to user ${notification.userId}');
    } catch (e) {
      developer.log('NotificationService: Error delivering notification: $e', level: 1000);
    }
  }

  /// Get user notifications with filtering and pagination
  Future<List<Notification>> getUserNotifications(
    int userId, {
    bool? isRead,
    List<NotificationType>? types,
    int limit = 50,
    int offset = 0,
    DateTime? since,
    DateTime? until,
  }) async {
    try {
      final db = await _databaseHelper.database;
      
      // Build query conditions
      final conditions = <String>['user_id = ?'];
      final arguments = <dynamic>[userId];

      if (isRead != null) {
        conditions.add('is_read = ?');
        arguments.add(isRead ? 1 : 0);
      }

      if (types != null && types.isNotEmpty) {
        final typeNames = types.map((t) => t.name).join("', '");
        conditions.add("notification_type IN ('$typeNames')");
      }

      if (since != null) {
        conditions.add('created_at >= ?');
        arguments.add(since.toIso8601String());
      }

      if (until != null) {
        conditions.add('created_at <= ?');
        arguments.add(until.toIso8601String());
      }

      final whereClause = conditions.join(' AND ');
      
      final results = await db.query(
        'notifications',
        where: whereClause,
        whereArgs: arguments,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => Notification.fromMap(map)).toList();
    } catch (e) {
      developer.log('NotificationService: Error getting user notifications: $e', level: 1000);
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _databaseHelper.markNotificationAsRead(notificationId);
      developer.log('NotificationService: Notification $notificationId marked as read');
    } catch (e) {
      developer.log('NotificationService: Error marking notification as read: $e', level: 1000);
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(int userId) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'user_id = ? AND is_read = 0',
        whereArgs: [userId],
      );
      developer.log('NotificationService: All notifications marked as read for user $userId');
    } catch (e) {
      developer.log('NotificationService: Error marking all notifications as read: $e', level: 1000);
    }
  }

  /// Get notification statistics for a user
  Future<Map<String, dynamic>> getNotificationStats(int userId) async {
    try {
      final db = await _databaseHelper.database;
      
      final totalResult = await db.query(
        'notifications',
        columns: ['COUNT(*) as total'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      final unreadResult = await db.query(
        'notifications',
        columns: ['COUNT(*) as unread'],
        where: 'user_id = ? AND is_read = 0',
        whereArgs: [userId],
      );

      final typeBreakdown = await db.rawQuery('''
        SELECT notification_type, COUNT(*) as count
        FROM notifications
        WHERE user_id = ?
        GROUP BY notification_type
        ORDER BY count DESC
      ''', [userId]);

      final recentActivity = await db.query(
        'notifications',
        where: 'user_id = ? AND created_at >= ?',
        whereArgs: [userId, DateTime.now().subtract(const Duration(days: 7)).toIso8601String()],
        orderBy: 'created_at DESC',
        limit: 5,
      );

      final totalCount = totalResult.first['total'] as int? ?? 0;
      final unreadCount = unreadResult.first['unread'] as int? ?? 0;
      
      return {
        'total_notifications': totalCount,
        'unread_notifications': unreadCount,
        'read_notifications': totalCount - unreadCount,
        'type_breakdown': typeBreakdown,
        'recent_activity': recentActivity.map((map) => Notification.fromMap(map)).toList(),
      };
    } catch (e) {
      developer.log('NotificationService: Error getting notification stats: $e', level: 1000);
      return {};
    }
  }

  /// Update user notification preferences
  Future<void> updateUserPreferences(int userId, NotificationPreferences preferences) async {
    try {
      final db = await _databaseHelper.database;
      
      // Check if preferences exist
      final existing = await db.query(
        'user_notification_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final preferencesMap = preferences.toMap();
      preferencesMap['user_id'] = userId;
      preferencesMap['updated_at'] = DateTime.now().toIso8601String();

      if (existing.isNotEmpty) {
        await db.update(
          'user_notification_preferences',
          preferencesMap,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      } else {
        preferencesMap['created_at'] = DateTime.now().toIso8601String();
        await db.insert('user_notification_preferences', preferencesMap);
      }

      // Update cache
      _userPreferences[userId] = preferences;
      developer.log('NotificationService: Updated notification preferences for user $userId');
    } catch (e) {
      developer.log('NotificationService: Error updating user preferences: $e', level: 1000);
    }
  }

  /// Get user notification preferences
  Future<NotificationPreferences> _getUserPreferences(int userId) async {
    try {
      // Check cache first
      if (_userPreferences.containsKey(userId)) {
        return _userPreferences[userId]!;
      }

      final db = await _databaseHelper.database;
      final result = await db.query(
        'user_notification_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      NotificationPreferences preferences;
      if (result.isNotEmpty) {
        preferences = NotificationPreferences.fromMap(result.first);
      } else {
        preferences = NotificationPreferences(); // Default preferences
      }

      _userPreferences[userId] = preferences;
      return preferences;
    } catch (e) {
      developer.log('NotificationService: Error getting user preferences: $e', level: 1000);
      return NotificationPreferences();
    }
  }

  /// Check if notification type is enabled for user
  bool _isNotificationTypeEnabled(NotificationType type, NotificationPreferences preferences) {
    switch (type) {
      case NotificationType.achievement_unlocked:
        return preferences.achievementNotifications;
      case NotificationType.challenge_completed:
      case NotificationType.challenge_progress:
      case NotificationType.challenge_about_to_expire:
        return preferences.challengeNotifications;
      case NotificationType.leaderboard_position_changed:
        return preferences.leaderboardNotifications;
      case NotificationType.points_earned:
      case NotificationType.level_up:
      case NotificationType.badge_earned:
      case NotificationType.milestone_reached:
        return preferences.pointsNotifications;
      case NotificationType.friend_activity:
        return preferences.socialNotifications;
      case NotificationType.system_announcement:
        return preferences.systemNotifications;
      case NotificationType.promotion:
        return preferences.promotionNotifications;
      case NotificationType.reminder:
        return preferences.reminderNotifications;
    }
  }

  /// Check if current time is within quiet hours
  bool _isQuietHour(NotificationPreferences preferences) {
    final currentHour = DateTime.now().hour;
    return preferences.quietHours.contains(currentHour);
  }

  /// Get next active hour (outside quiet hours)
  DateTime _getNextActiveHour(NotificationPreferences preferences) {
    final now = DateTime.now();
    DateTime nextActiveTime = now.add(const Duration(hours: 1));
    
    while (preferences.quietHours.contains(nextActiveTime.hour)) {
      nextActiveTime = nextActiveTime.add(const Duration(hours: 1));
    }
    
    return nextActiveTime;
  }

  /// Check if user has exceeded daily notification limit
  Future<bool> _exceedsDailyLimit(int userId, NotificationPreferences preferences) async {
    try {
      final db = await _databaseHelper.database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final result = await db.query(
        'notifications',
        columns: ['COUNT(*) as count'],
        where: 'user_id = ? AND created_at >= ?',
        whereArgs: [userId, startOfDay.toIso8601String()],
      );

      final todayCount = result.first['count'] as int;
      return todayCount >= preferences.maxDailyNotifications;
    } catch (e) {
      developer.log('NotificationService: Error checking daily limit: $e', level: 1000);
      return false;
    }
  }

  /// Schedule a notification for later delivery
  Future<void> _scheduleNotification(Notification notification, DateTime scheduledTime) async {
    try {
      final scheduleId = '${notification.userId}_${DateTime.now().millisecondsSinceEpoch}';
      final delay = scheduledTime.difference(DateTime.now());
      
      if (delay.isNegative) {
        // If scheduled time is in the past, deliver immediately
        await _deliverImmediately(notification, await _getUserPreferences(notification.userId));
        return;
      }

      final timer = Timer(delay, () async {
        await _deliverImmediately(notification, await _getUserPreferences(notification.userId));
        _scheduledNotifications.remove(scheduleId);
      });

      _scheduledNotifications[scheduleId] = timer;
      developer.log('NotificationService: Scheduled notification for user ${notification.userId} at $scheduledTime');
    } catch (e) {
      developer.log('NotificationService: Error scheduling notification: $e', level: 1000);
    }
  }

  /// Check if notification should be batched
  bool _shouldBatchNotification(Notification notification) {
    // Batch notifications that are frequent and similar
    return notification.notificationType == NotificationType.points_earned ||
           notification.notificationType == NotificationType.challenge_progress ||
           notification.notificationType == NotificationType.achievement_unlocked;
  }

  /// Add notification to batch
  Future<void> _addToBatch(Notification notification) async {
    try {
      final batchId = '${notification.userId}_${notification.notificationType.name}';
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(minutes: 15)); // Batch every 15 minutes

      if (_notificationBatches.containsKey(batchId)) {
        _notificationBatches[batchId]!.notifications.add(notification);
      } else {
        _notificationBatches[batchId] = NotificationBatch(
          batchId: batchId,
          type: notification.notificationType,
          notifications: [notification],
          createdAt: now,
          scheduledFor: scheduledTime,
        );
      }

      developer.log('NotificationService: Added notification to batch $batchId');
    } catch (e) {
      developer.log('NotificationService: Error adding to batch: $e', level: 1000);
    }
  }

  /// Process batched notifications
  Future<void> _processBatchedNotifications() async {
    try {
      final now = DateTime.now();
      final batchesToProcess = _notificationBatches.values
          .where((batch) => !batch.isProcessed && batch.scheduledFor.isBefore(now))
          .toList();

      for (final batch in batchesToProcess) {
        if (batch.notifications.isNotEmpty) {
          final userId = batch.notifications.first.userId;
          final batchNotification = batch.createBatchNotification(userId);
          
          await _deliverImmediately(batchNotification, await _getUserPreferences(userId));
          
          // Mark batch as processed
          _notificationBatches[batch.batchId] = NotificationBatch(
            batchId: batch.batchId,
            type: batch.type,
            notifications: batch.notifications,
            createdAt: batch.createdAt,
            scheduledFor: batch.scheduledFor,
            isProcessed: true,
          );
        }
      }

      // Clean up old processed batches
      _notificationBatches.removeWhere((key, batch) => 
        batch.isProcessed && batch.scheduledFor.isBefore(now.subtract(const Duration(hours: 1)))
      );
    } catch (e) {
      developer.log('NotificationService: Error processing batched notifications: $e', level: 1000);
    }
  }

  /// Send push notification (placeholder for future implementation)
  Future<void> _sendPushNotification(Notification notification) async {
    // TODO: Implement push notification service integration
    // This could integrate with Firebase Cloud Messaging, OneSignal, etc.
    developer.log('NotificationService: Push notification would be sent: ${notification.title}');
  }

  /// Add notification to daily summary
  Future<void> _addToDailySummary(Notification notification) async {
    // TODO: Implement daily summary functionality
    developer.log('NotificationService: Added notification to daily summary for user ${notification.userId}');
  }

  /// Add notification to weekly summary
  Future<void> _addToWeeklySummary(Notification notification) async {
    // TODO: Implement weekly summary functionality
    developer.log('NotificationService: Added notification to weekly summary for user ${notification.userId}');
  }

  /// Check for reminder notifications
  Future<void> _checkForReminders() async {
    try {
      // Check for challenge expiration reminders
      final expiringChallenges = await _challengeService.getExpiringChallenges();
      for (final challenge in expiringChallenges) {
        // Get users with progress on this challenge
        final db = await _databaseHelper.database;
        final usersWithProgress = await db.query(
          'challenge_progress',
          where: 'challenge_id = ? AND is_completed = 0',
          whereArgs: [challenge.id],
        );

        for (final userProgress in usersWithProgress) {
          final userId = userProgress['user_id'] as int;
          final timeRemaining = challenge.endDate.difference(DateTime.now());
          
          if (timeRemaining.inHours <= 24) {
            final reminder = Notification.challengeAboutToExpire(
              userId: userId,
              challengeTitle: challenge.title,
              challengeId: challenge.id!,
              timeRemaining: timeRemaining.inHours > 0 
                ? '${timeRemaining.inHours} hours' 
                : '${timeRemaining.inMinutes} minutes',
            );

            await sendNotification(reminder, schedule: NotificationSchedule.immediate);
          }
        }
      }

      developer.log('NotificationService: Reminder check completed');
    } catch (e) {
      developer.log('NotificationService: Error checking reminders: $e', level: 1000);
    }
  }

  /// Send daily summary notifications
  Future<void> _sendDailySummaries() async {
    try {
      // TODO: Implement daily summary notifications
      developer.log('NotificationService: Daily summary notifications would be sent');
    } catch (e) {
      developer.log('NotificationService: Error sending daily summaries: $e', level: 1000);
    }
  }

  /// Load user preferences from database
  Future<void> _loadUserPreferences() async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query('user_notification_preferences');
      
      for (final result in results) {
        final userId = result['user_id'] as int;
        final preferences = NotificationPreferences.fromMap(result);
        _userPreferences[userId] = preferences;
      }

      developer.log('NotificationService: Loaded ${_userPreferences.length} user preferences');
    } catch (e) {
      developer.log('NotificationService: Error loading user preferences: $e', level: 1000);
    }
  }

  /// Delete old notifications beyond retention period
  Future<void> cleanupOldNotifications({int retentionDays = 30}) async {
    try {
      final db = await _databaseHelper.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      
      final deletedCount = await db.delete(
        'notifications',
        where: 'created_at < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );

      developer.log('NotificationService: Cleaned up $deletedCount old notifications');
    } catch (e) {
      developer.log('NotificationService: Error cleaning up old notifications: $e', level: 1000);
    }
  }
}