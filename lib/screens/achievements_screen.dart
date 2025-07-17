import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mock_data_service.dart';
import '../models/user.dart';
import '../models/achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  List<Achievement> _allAchievements = [];
  List<UserAchievement> _userAchievements = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Use the first user from the mock data as the current user
    _currentUser = MockDataService.getUsers().first;
    _allAchievements = MockDataService.getAchievements();
    _userAchievements =
        MockDataService.getAchievementsForUser(_currentUser!.id!);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Eco Achievements'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Unlocked', icon: Icon(Icons.check_circle)),
            Tab(text: 'In Progress', icon: Icon(Icons.timelapse)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUnlockedTab(),
                      _buildInProgressTab(),
                      _buildCategoriesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    final completed = _userAchievements.length;
    final inProgress = _allAchievements.length - completed;
    final totalPoints = _userAchievements.fold<int>(
        0,
        (sum, ua) =>
            sum +
            _allAchievements
                .firstWhere((a) => a.id == ua.achievementId)
                .pointsReward);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Completed',
            '$completed',
            Icons.star,
            Colors.amber,
          ),
          _buildStatItem(
            'In Progress',
            '$inProgress',
            Icons.access_time,
            Colors.blue,
          ),
          _buildStatItem(
            'Total Points',
            '$totalPoints',
            Icons.diamond,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: label == 'Completed' ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedTab() {
    final unlockedAchievements = _allAchievements
        .where((a) =>
            _userAchievements.any((ua) => ua.achievementId == a.id))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unlockedAchievements.length,
      itemBuilder: (context, index) {
        final achievement = unlockedAchievements[index];
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
          )),
          child: _buildAchievementCard(achievement, isCompleted: true),
        );
      },
    );
  }

  Widget _buildInProgressTab() {
    final inProgressAchievements = _allAchievements
        .where((a) =>
            !_userAchievements.any((ua) => ua.achievementId == a.id))
        .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: inProgressAchievements.length,
        itemBuilder: (context, index) {
          final achievement = inProgressAchievements[index];
          return _buildAchievementCard(achievement, isCompleted: false);
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final achievementsByCategory = <AchievementType, List<Achievement>>{};
    for (var achievement in _allAchievements) {
      achievementsByCategory
          .putIfAbsent(achievement.type, () => [])
          .add(achievement);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: achievementsByCategory.entries.map((entry) {
        return _buildCategorySection(entry.key, entry.value);
      }).toList(),
    );
  }
  
  Widget _buildCategorySection(
      AchievementType category, List<Achievement> achievements) {
    return ExpansionTile(
      title: Text(
        _getTypeDisplayName(category),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(_getCategoryIcon(category)),
      children: achievements
          .map((achievement) => _buildAchievementCard(
                achievement,
                isCompleted: _userAchievements
                    .any((ua) => ua.achievementId == achievement.id),
              ))
          .toList(),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, {required bool isCompleted}) {
    // A stand-in for progress, since the new mock data doesn't have it.
    final percentage = isCompleted ? 100 : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCompleted ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showAchievementDetails(achievement),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isCompleted
                ? LinearGradient(
                    colors: [Colors.green.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTierColor(achievement.tier).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.star), // Placeholder icon
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          achievement.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted) ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                  ] else ...[
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (!isCompleted) ...[
                _buildProgressBar(percentage, 100),
                const SizedBox(height: 8),
                Text(
                  achievement.target,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (isCompleted) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${achievement.pointsReward} points earned',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      _getTierDisplayName(achievement.tier),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTierColor(achievement.tier),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int target,
      {bool isNearCompletion = false}) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: isNearCompletion ? Colors.orange : Colors.green,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isNearCompletion
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, size: 32), // Placeholder
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                achievement.name,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 16),
            Text('Target: ${achievement.target}'),
            const SizedBox(height: 16),
            Text('Reward: ${achievement.pointsReward} points'),
            Text('Tier: ${_getTierDisplayName(achievement.tier)}'),
            Text('Type: ${_getTypeDisplayName(achievement.type)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(AchievementType category) {
    switch (category) {
      case AchievementType.completion:
        return Icons.star;
      case AchievementType.environmental:
        return Icons.eco;
      case AchievementType.social:
        return Icons.group;
      case AchievementType.financial:
        return Icons.monetization_on;
      case AchievementType.consistency:
        return Icons.event_repeat;
      case AchievementType.exploration:
        return Icons.explore;
      case AchievementType.special:
        return Icons.diamond;
      default:
        return Icons.category;
    }
  }

  String _getTierDisplayName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown;
      case AchievementTier.silver:
        return Colors.grey;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.platinum:
        return Colors.cyan;
      case AchievementTier.diamond:
        return Colors.purple;
    }
  }

  String _getTypeDisplayName(AchievementType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }
}