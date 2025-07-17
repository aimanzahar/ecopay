import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/challenge_service.dart';
import '../models/user.dart';
import '../models/challenge.dart' as ChallengeModel;
import '../models/challenge_progress.dart';
import '../helpers/database_helper.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with TickerProviderStateMixin {
  final ChallengeService _challengeService = ChallengeService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  late TabController _tabController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;

  Map<String, dynamic> _challengesByCategory = {};
  Map<String, dynamic> _challengeStats = {};
  List<dynamic> _activeChallenges = [];
  List<dynamic> _completedChallenges = [];
  List<dynamic> _upcomingChallenges = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Animation controllers
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animations
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationController.repeat();
    _scaleController.repeat(reverse: true);
    _slideController.forward();
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current user (assuming user ID 1 for now)
      _currentUser = await _databaseHelper.getUser(1);
      
      if (_currentUser != null && _currentUser!.id != null) {
        // Load challenges data
        final challengesByCategory = await _challengeService.getChallengesByCategory(_currentUser!.id!);
        final stats = await _challengeService.getChallengeStats(_currentUser!.id!);
        final active = await _challengeService.getActiveChallenges(_currentUser!.id!);
        final completed = await _challengeService.getCompletedChallenges(_currentUser!.id!);
        final upcoming = await _challengeService.getUpcomingChallenges(_currentUser!.id!);
        
        setState(() {
          _challengesByCategory = challengesByCategory;
          _challengeStats = stats;
          _activeChallenges = active;
          _completedChallenges = completed;
          _upcomingChallenges = upcoming;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading challenges data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Challenges'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.play_arrow)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
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
                      _buildActiveTab(),
                      _buildCompletedTab(),
                      _buildUpcomingTab(),
                      _buildCategoriesTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showJoinChallengeDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
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
            'Active',
            '${_challengeStats['active'] ?? 0}',
            Icons.play_arrow,
            Colors.green,
          ),
          _buildStatItem(
            'Completed',
            '${_challengeStats['completed'] ?? 0}',
            Icons.check_circle,
            Colors.blue,
          ),
          _buildStatItem(
            'Points Earned',
            '${_challengeStats['total_points'] ?? 0}',
            Icons.star,
            Colors.amber,
          ),
          _buildStatItem(
            'Streak',
            '${_challengeStats['current_streak'] ?? 0}',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: label == 'Active' ? _scaleAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeChallenges.length,
        itemBuilder: (context, index) {
          final challengeData = _activeChallenges[index];
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
            )),
            child: _buildChallengeCard(challengeData, ChallengeModel.ChallengeStatus.active),
          );
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedChallenges.length,
      itemBuilder: (context, index) {
        final challengeData = _completedChallenges[index];
        return _buildChallengeCard(challengeData, ChallengeModel.ChallengeStatus.completed);
      },
    );
  }

  Widget _buildUpcomingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingChallenges.length,
      itemBuilder: (context, index) {
        final challengeData = _upcomingChallenges[index];
        return _buildChallengeCard(challengeData, ChallengeModel.ChallengeStatus.upcoming);
      },
    );
  }

  Widget _buildCategoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _challengesByCategory.entries.map((category) {
        return _buildCategorySection(category.key, category.value as List<dynamic>);
      }).toList(),
    );
  }

  Widget _buildCategorySection(String categoryName, List<dynamic> challenges) {
    return ExpansionTile(
      title: Text(
        _getCategoryDisplayName(categoryName),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: Icon(_getCategoryIcon(categoryName)),
      children: challenges.map((challengeData) {
        final challenge = challengeData['challenge'] as ChallengeModel.Challenge;
        return _buildChallengeCard(challengeData, challenge.status);
      }).toList(),
    );
  }

  Widget _buildChallengeCard(dynamic challengeData, ChallengeModel.ChallengeStatus status) {
    final challenge = challengeData['challenge'] as ChallengeModel.Challenge;
    final progress = challengeData['progress'] as ChallengeProgress?;
    final progressPercentage = challengeData['progress_percentage'] as double? ?? 0.0;

    Color cardColor;
    Color borderColor;
    IconData statusIcon;
    
    switch (status) {
      case ChallengeModel.ChallengeStatus.active:
        cardColor = Colors.green.shade50;
        borderColor = Colors.green;
        statusIcon = Icons.play_arrow;
        break;
      case ChallengeModel.ChallengeStatus.completed:
        cardColor = Colors.blue.shade50;
        borderColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case ChallengeModel.ChallengeStatus.upcoming:
        cardColor = Colors.orange.shade50;
        borderColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case ChallengeModel.ChallengeStatus.expired:
        cardColor = Colors.grey.shade50;
        borderColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      case ChallengeModel.ChallengeStatus.inactive:
        cardColor = Colors.grey.shade50;
        borderColor = Colors.grey;
        statusIcon = Icons.pause;
        break;
      case ChallengeModel.ChallengeStatus.failed:
        cardColor = Colors.red.shade50;
        borderColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: status == ChallengeModel.ChallengeStatus.active ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      child: InkWell(
        onTap: () => _showChallengeDetails(challenge, progress),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [cardColor, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        challenge.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            challenge.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Icon(statusIcon, color: borderColor, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusDisplayName(status),
                          style: TextStyle(
                            fontSize: 10,
                            color: borderColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (progress != null && status == ChallengeModel.ChallengeStatus.active) ...[
                  _buildProgressSection(challenge, progress, progressPercentage),
                  const SizedBox(height: 12),
                ],
                _buildChallengeInfo(challenge, status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(ChallengeModel.Challenge challenge, ChallengeProgress progress, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildAnimatedProgressBar(percentage / 100),
        const SizedBox(height: 4),
        Text(
          '${progress.currentProgress}/${progress.targetValue} ${challenge.targetUnit}',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedProgressBar(double progress) {
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
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.shade300],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeInfo(ChallengeModel.Challenge challenge, ChallengeModel.ChallengeStatus status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reward: ${challenge.pointsReward} points',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status == ChallengeModel.ChallengeStatus.upcoming
                    ? 'Starts: ${_formatDate(challenge.startDate)}'
                    : 'Ends: ${_formatDate(challenge.endDate)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(challenge.category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getCategoryDisplayName(challenge.category.toString().split('.').last),
            style: TextStyle(
              fontSize: 10,
              color: _getCategoryColor(challenge.category),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showChallengeDetails(ChallengeModel.Challenge challenge, ChallengeProgress? progress) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(challenge.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                challenge.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(challenge.description),
            const SizedBox(height: 16),
            if (progress != null) ...[
              Text('Progress: ${progress.currentProgress}/${progress.targetValue} ${challenge.targetUnit}'),
              const SizedBox(height: 8),
              _buildAnimatedProgressBar(progress.currentProgress / progress.targetValue),
              const SizedBox(height: 16),
            ],
            Text('Reward: ${challenge.pointsReward} points'),
            Text('Category: ${_getCategoryDisplayName(challenge.category.toString().split('.').last)}'),
            Text('Type: ${_getTypeDisplayName(challenge.type)}'),
            const SizedBox(height: 8),
            Text('End Date: ${_formatDate(challenge.endDate)}'),
          ],
        ),
        actions: [
          if (challenge.status == ChallengeModel.ChallengeStatus.upcoming) ...[
            TextButton(
              onPressed: () => _joinChallenge(challenge),
              child: const Text('Join Challenge'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showJoinChallengeDialog() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join New Challenge'),
        content: const Text('Browse available challenges and join one that interests you!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinChallenge(ChallengeModel.Challenge challenge) async {
    try {
      if (_currentUser != null && _currentUser!.id != null && challenge.id != null) {
        await _challengeService.joinChallenge(challenge.id!, _currentUser!.id!);
        Navigator.pop(context);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "${challenge.title}"!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCategoryDisplayName(String categoryName) {
    switch (categoryName) {
      case 'environmental':
        return 'Environmental';
      case 'social':
        return 'Social Impact';
      case 'financial':
        return 'Financial';
      case 'health':
        return 'Health';
      case 'education':
        return 'Education';
      case 'community':
        return 'Community';
      case 'personal':
        return 'Personal';
      case 'seasonal':
        return 'Seasonal';
      default:
        return categoryName;
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'environmental':
        return Icons.eco;
      case 'social':
        return Icons.group;
      case 'financial':
        return Icons.attach_money;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'community':
        return Icons.location_city;
      case 'personal':
        return Icons.person;
      case 'seasonal':
        return Icons.calendar_today;
      default:
        return Icons.eco;
    }
  }

  Color _getCategoryColor(ChallengeModel.ChallengeCategory category) {
    switch (category) {
      case ChallengeModel.ChallengeCategory.environmental:
        return Colors.green;
      case ChallengeModel.ChallengeCategory.social:
        return Colors.orange;
      case ChallengeModel.ChallengeCategory.financial:
        return Colors.blue;
      case ChallengeModel.ChallengeCategory.health:
        return Colors.red;
      case ChallengeModel.ChallengeCategory.education:
        return Colors.indigo;
      case ChallengeModel.ChallengeCategory.community:
        return Colors.purple;
      case ChallengeModel.ChallengeCategory.personal:
        return Colors.teal;
      case ChallengeModel.ChallengeCategory.seasonal:
        return Colors.amber;
    }
  }

  String _getStatusDisplayName(ChallengeModel.ChallengeStatus status) {
    switch (status) {
      case ChallengeModel.ChallengeStatus.active:
        return 'Active';
      case ChallengeModel.ChallengeStatus.completed:
        return 'Done';
      case ChallengeModel.ChallengeStatus.upcoming:
        return 'Soon';
      case ChallengeModel.ChallengeStatus.expired:
        return 'Expired';
      case ChallengeModel.ChallengeStatus.inactive:
        return 'Inactive';
      case ChallengeModel.ChallengeStatus.failed:
        return 'Failed';
    }
  }

  String _getTypeDisplayName(ChallengeModel.ChallengeType type) {
    switch (type) {
      case ChallengeModel.ChallengeType.daily:
        return 'Daily';
      case ChallengeModel.ChallengeType.weekly:
        return 'Weekly';
      case ChallengeModel.ChallengeType.monthly:
        return 'Monthly';
      case ChallengeModel.ChallengeType.seasonal:
        return 'Seasonal';
      case ChallengeModel.ChallengeType.special:
        return 'Special';
      case ChallengeModel.ChallengeType.transactions:
        return 'Transactions';
      case ChallengeModel.ChallengeType.contributions:
        return 'Contributions';
      case ChallengeModel.ChallengeType.environmental_impact:
        return 'Environmental Impact';
      case ChallengeModel.ChallengeType.daily_login:
        return 'Daily Login';
      case ChallengeModel.ChallengeType.social_sharing:
        return 'Social Sharing';
      case ChallengeModel.ChallengeType.milestone:
        return 'Milestone';
      case ChallengeModel.ChallengeType.community:
        return 'Community';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}