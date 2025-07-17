# 🌱 EcoPay Placeholder Data Usage Guide

This file provides a quick guide on how to use the placeholder challenges and achievements data that has been created for your Eco leaderboard.

## 📊 What's Included

### ✅ Challenges (6 Active Challenges)
- **Eco Warrior Beginner** - Complete 5 transactions (100 points)
- **Green Contributor** - Make RM50 in donations (150 points)
- **Daily Eco Habit** - Use EcoPay for 7 consecutive days (75 points)
- **Carbon Footprint Champion** - Save 100kg CO2 (200 points)
- **Community Builder** - Refer 3 friends (125 points)
- **Weekly Streak Master** - Complete 3 challenges in a week (250 points)

### 🏆 Achievements (8 Achievements)
- First Transaction, Eco Contributor, Green Guardian, Daily User
- Payment Pro, Community Champion, Milestone Master, Eco Hero
- Each achievement gives 50 points when unlocked

### 📈 Current User Progress
- **Total Points**: 200 points (from 4 achievements + 2 partial challenges)
- **Current Level**: "Eco Enthusiast"
- **Active Progress**: 
  - 3/5 transactions completed (60%)
  - 25/50 RM donated (50%)
  - 4/7 days streak (57%)

## 🚀 Quick Integration

### 1. Get Current User Data
```dart
import 'package:ecopay/services/placeholder_data_service.dart';

// Get current user points
final points = PlaceholderDataService.getUserPoints(); // Returns 200

// Get current user level
final level = PlaceholderDataService.getUserLevel(); // Returns "Eco Enthusiast"

// Get all active challenges
final challenges = PlaceholderDataService.getActiveChallenges();

// Get user achievements
final achievements = PlaceholderDataService.getUserAchievements();
```

### 2. Display Challenge Progress
```dart
// Get challenge progress
final progress = PlaceholderDataService.getChallengeProgress(1); // Challenge 1

// Get completion percentage
final percentage = PlaceholderDataService.getChallengeCompletionPercentage(1); // Returns 0.6 for 60%
```

### 3. Use in Leaderboard
```dart
// Get activity summary
final summary = PlaceholderDataService.getUserActivitySummary();
```

## 📱 Sample UI Usage

### Displaying Challenges
```dart
// In your challenge screen
ListView.builder(
  itemCount: challenges.length,
  itemBuilder: (context, index) {
    final challenge = challenges[index];
    final progress = PlaceholderDataService.getChallengeProgress(challenge.id);
    final percentage = PlaceholderDataService.getChallengeCompletionPercentage(challenge.id);
    
    return ChallengeCard(
      title: challenge.title,
      description: challenge.description,
      progress: percentage,
      points: challenge.pointsReward,
      icon: challenge.icon,
    );
  },
);
```

### Displaying Achievements
```dart
// In your achievements screen
GridView.builder(
  itemCount: achievements.length,
  itemBuilder: (context, index) {
    final achievement = achievements[index];
    final isUnlocked = PlaceholderDataService.getUserAchievements()
        .any((ua) => ua.achievementId == achievement.id);
    
    return AchievementBadge(
      name: achievement.name,
      description: achievement.description,
      isUnlocked: isUnlocked,
      points: 50,
    );
  },
);
```

## 🎯 Next Steps

1. **Replace Mock Data**: Replace the placeholder data with actual user data from your database
2. **Real-time Updates**: Implement real-time updates when users complete transactions or donations
3. **New Challenges**: Add seasonal or special event challenges
4. **Social Features**: Add friend referral tracking and community challenges

## 📊 Sample Data Summary

| Metric | Value |
|--------|--------|
| **Total Challenges** | 6 active |
| **Total Achievements** | 8 available |
| **User Points** | 200 |
| **User Level** | "Eco Enthusiast" |
| **Completed Achievements** | 4 |
| **Active Challenges** | 6 |
| **Next Milestone** | 300 points |

## 🔄 Auto-initialization

The placeholder data is automatically available and can be used immediately without any setup required. When you're ready to replace it with real data, simply modify the `PlaceholderDataService` to fetch from your actual database.