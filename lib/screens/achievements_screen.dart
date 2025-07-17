import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/achievement_service.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../helpers/database_helper.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  final AchievementService _achievementService = AchievementService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, List<Map<String, dynamic>>> _achievementsByCategory = {};
  Map<String, dynamic> _achievementStats = {};
  List<Map<String, dynamic>> _nearCompletionAchievements = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animations
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseController.repeat(reverse: true);
    _slideController.forward();
    
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
    try {
      setState(() => _isLoading = true);
      
      // Get current user (assuming user ID 1 for now)
      _currentUser = await _databaseHelper.getUser(1);
      
      if (_currentUser != null && _currentUser!.id != null) {
        // Load achievements data
        final achievements = await _achievementService.getAchievementsByCategory(_currentUser!.id!);
        final stats = await _achievementService.getAchievementStats(_currentUser!.id!);
        final nearCompletion = await _achievementService.getNearCompletionAchievements(_currentUser!.id!);
        
        setState(() {
          _achievementsByCategory = achievements;
          _achievementStats = stats;
          _nearCompletionAchievements = nearCompletion;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading achievements data: $e');
      setState(() => _isLoading = false);
    }
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
            '${_achievementStats['completed'] ?? 0}',
            Icons.star,
            Colors.amber,
          ),
          _buildStatItem(
            'In Progress',
            '${_achievementStats['in_progress'] ?? 0}',
            Icons.access_time,
            Colors.blue,
          ),
          _buildStatItem(
            'Total Points',
            '${_achievementStats['total_points_earned'] ?? 0}',
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
    final completedAchievements = <Map<String, dynamic>>[];
    
    for (final category in _achievementsByCategory.entries) {
      for (final achievement in category.value) {
        if (achievement['progress']?.isCompleted == true) {
          completedAchievements.add(achievement);
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedAchievements.length,
      itemBuilder: (context, index) {
        final achievement = completedAchievements[index];
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
          )),
          child: _buildAchievementCard(achievement, true),
        );
      },
    );
  }

  Widget _buildInProgressTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_nearCompletionAchievements.isNotEmpty) ...[
            const Text(
              'Almost There! 🎯',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            ..._nearCompletionAchievements.map((achievement) =>
                _buildNearCompletionCard(achievement)),
            const SizedBox(height: 24),
          ],
          const Text(
            'All Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._getAllInProgressAchievements().map((achievement) =>
              _buildAchievementCard(achievement, false)),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _achievementsByCategory.entries.map((category) {
        return _buildCategorySection(category.key, category.value);
      }).toList(),
    );
  }

  Widget _buildCategorySection(String categoryName, List<Map<String, dynamic>> achievements) {
    return ExpansionTile(
      title: Text(
        _getCategoryDisplayName(categoryName),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(_getCategoryIcon(categoryName)),
      children: achievements.map((achievement) => 
          _buildAchievementCard(achievement, achievement['progress']?.isCompleted == true)
      ).toList(),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievementData, bool isCompleted) {
    final achievement = achievementData['achievement'] as AchievementDefinition;
    final progress = achievementData['progress'] as UserAchievementProgress?;
    final percentage = achievementData['percentage'] as int? ?? 0;

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
        onTap: () => _showAchievementDetails(achievement, progress),
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
                    child: Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
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
              if (!isCompleted && progress != null) ...[
                _buildProgressBar(progress.currentProgress, progress.targetValue),
                const SizedBox(height: 8),
                Text(
                  '${progress.currentProgress}/${progress.targetValue} ${achievement.targetUnit}',
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

  Widget _buildNearCompletionCard(Map<String, dynamic> achievementData) {
    final achievement = achievementData['achievement'] as AchievementDefinition;
    final progress = achievementData['progress'] as UserAchievementProgress;
    final percentage = achievementData['percentage'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.orange, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  },
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
                        'Only ${progress.remainingValue} ${achievement.targetUnit} to go!',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressBar(progress.currentProgress, progress.targetValue, isNearCompletion: true),
            const SizedBox(height: 8),
            Text(
              '${progress.currentProgress}/${progress.targetValue} ${achievement.targetUnit}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int current, int target, {bool isNearCompletion = false}) {
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

  List<Map<String, dynamic>> _getAllInProgressAchievements() {
    final inProgressAchievements = <Map<String, dynamic>>[];
    
    for (final category in _achievementsByCategory.entries) {
      for (final achievement in category.value) {
        if (achievement['progress']?.isCompleted != true) {
          inProgressAchievements.add(achievement);
        }
      }
    }
    
    return inProgressAchievements;
  }

  void _showAchievementDetails(AchievementDefinition achievement, UserAchievementProgress? progress) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 32)),
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
            if (progress != null) ...[
              Text('Progress: ${progress.currentProgress}/${progress.targetValue} ${achievement.targetUnit}'),
              const SizedBox(height: 8),
              _buildProgressBar(progress.currentProgress, progress.targetValue),
              const SizedBox(height: 16),
            ],
            Text('Reward: ${achievement.pointsReward} points'),
            Text('Tier: ${_getTierDisplayName(achievement.tier)}'),
            Text('Type: ${_getTypeDisplayName(achievement.type)}'),
            if (progress?.completedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed: ${_formatDate(progress!.completedAt!)}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
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

  String _getCategoryDisplayName(String categoryName) {
    switch (categoryName) {
      case 'points':
        return 'Points';
      case 'transactions':
        return 'Transactions';
      case 'contributions':
        return 'Contributions';
      case 'streak':
        return 'Streaks';
      case 'environmental_impact':
        return 'Environmental Impact';
      case 'social':
        return 'Social';
      case 'milestone':
        return 'Milestones';
      case 'special':
        return 'Special';
      default:
        return categoryName;
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'points':
        return Icons.star;
      case 'transactions':
        return Icons.shopping_cart;
      case 'contributions':
        return Icons.favorite;
      case 'streak':
        return Icons.local_fire_department;
      case 'environmental_impact':
        return Icons.eco;
      case 'social':
        return Icons.group;
      case 'milestone':
        return Icons.flag;
      case 'special':
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
    switch (type) {
      case AchievementType.points:
        return 'Points';
      case AchievementType.transactions:
        return 'Transactions';
      case AchievementType.contributions:
        return 'Contributions';
      case AchievementType.streak:
        return 'Streak';
      case AchievementType.environmental_impact:
        return 'Environmental Impact';
      case AchievementType.social:
        return 'Social';
      case AchievementType.milestone:
        return 'Milestone';
      case AchievementType.special:
        return 'Special';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}