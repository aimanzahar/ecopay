import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/leaderboard_service.dart';
import '../models/user.dart';
import '../models/leaderboard_entry.dart';
import '../helpers/database_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  late TabController _tabController;
  late AnimationController _bounceController;
  late AnimationController _shimmerController;
  late AnimationController _countUpController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _countUpAnimation;

  Map<String, List<LeaderboardEntry>> _leaderboards = {};
  Map<String, dynamic> _userStats = {};
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  List<LeaderboardEntry> _monthlyLeaderboard = [];
  List<LeaderboardEntry> _allTimeLeaderboard = [];
  List<LeaderboardEntry> _friendsLeaderboard = [];
  bool _isLoading = true;
  User? _currentUser;
  String _selectedPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Animation controllers
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _countUpController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animations
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _countUpAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countUpController,
      curve: Curves.easeOut,
    ));
    
    _shimmerController.repeat();
    _bounceController.forward();
    _countUpController.forward();
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bounceController.dispose();
    _shimmerController.dispose();
    _countUpController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current user (assuming user ID 1 for now)
      _currentUser = await _databaseHelper.getUser(1);
      
      if (_currentUser != null && _currentUser!.id != null) {
        // Load leaderboard data
        final leaderboards = await _leaderboardService.getAllLeaderboards();
        final userStats = await _leaderboardService.getUserStats(_currentUser!.id!);
        final weekly = await _leaderboardService.getWeeklyLeaderboard();
        final monthly = await _leaderboardService.getMonthlyLeaderboard();
        final allTime = await _leaderboardService.getAllTimeLeaderboard();
        final friends = await _leaderboardService.getFriendsLeaderboard(_currentUser!.id!);
        
        setState(() {
          _leaderboards = leaderboards;
          _userStats = userStats;
          _weeklyLeaderboard = weekly;
          _monthlyLeaderboard = monthly;
          _allTimeLeaderboard = allTime;
          _friendsLeaderboard = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading leaderboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Leaderboard'),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Weekly', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Monthly', icon: Icon(Icons.calendar_view_month)),
            Tab(text: 'All Time', icon: Icon(Icons.timeline)),
            Tab(text: 'Friends', icon: Icon(Icons.group)),
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
          ? _buildLoadingView()
          : Column(
              children: [
                _buildStatsHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaderboardTab(_weeklyLeaderboard, 'weekly'),
                      _buildLeaderboardTab(_monthlyLeaderboard, 'monthly'),
                      _buildLeaderboardTab(_allTimeLeaderboard, 'all_time'),
                      _buildFriendsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      children: [
        _buildShimmerStatsHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (context, index) => _buildShimmerCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerStatsHeader() {
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
        children: List.generate(4, (index) => _buildShimmerStatItem()),
      ),
    );
  }

  Widget _buildShimmerStatItem() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade100,
                        Colors.grey.shade300,
                      ],
                      stops: [
                        _shimmerAnimation.value - 0.3,
                        _shimmerAnimation.value,
                        _shimmerAnimation.value + 0.3,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade100,
                              Colors.grey.shade300,
                            ],
                            stops: [
                              _shimmerAnimation.value - 0.3,
                              _shimmerAnimation.value,
                              _shimmerAnimation.value + 0.3,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade100,
                              Colors.grey.shade300,
                            ],
                            stops: [
                              _shimmerAnimation.value - 0.3,
                              _shimmerAnimation.value,
                              _shimmerAnimation.value + 0.3,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
            'Current Rank',
            '#${_userStats['current_rank'] ?? '?'}',
            Icons.emoji_events,
            Colors.amber,
          ),
          _buildStatItem(
            'Total Points',
            '${_userStats['total_points'] ?? 0}',
            Icons.star,
            Colors.purple,
          ),
          _buildStatItem(
            'This Week',
            '${_userStats['weekly_points'] ?? 0}',
            Icons.trending_up,
            Colors.green,
          ),
          _buildStatItem(
            'Friends Beat',
            '${_userStats['friends_beaten'] ?? 0}',
            Icons.group,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        ScaleTransition(
          scale: _bounceAnimation,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _countUpAnimation,
          builder: (context, child) {
            // Extract numeric value for count-up animation
            final numericValue = value.replaceAll(RegExp(r'[^\d.]'), '');
            final targetValue = double.tryParse(numericValue) ?? 0;
            final currentValue = (targetValue * _countUpAnimation.value).toInt();
            
            String displayValue = value;
            if (targetValue > 0) {
              displayValue = value.replaceAll(numericValue, currentValue.toString());
            }
            
            return Text(
              displayValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            );
          },
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

  Widget _buildLeaderboardTab(List<LeaderboardEntry> entries, String period) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(index.isEven ? -1.0 : 1.0, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _bounceController,
              curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutBack),
            )),
            child: _buildLeaderboardCard(entry, index),
          );
        },
      ),
    );
  }

  Widget _buildFriendsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          if (_friendsLeaderboard.isEmpty) ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_add, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No friends yet!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add friends to see their progress',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _friendsLeaderboard.length,
                itemBuilder: (context, index) {
                  final entry = _friendsLeaderboard[index];
                  return _buildFriendCard(entry, index);
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int index) {
    final isCurrentUser = entry.userId == _currentUser?.id;
    final rank = index + 1;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentUser ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrentUser ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showUserProfile(entry),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isCurrentUser
                ? LinearGradient(
                    colors: [Colors.green.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              _buildRankBadge(rank),
              const SizedBox(width: 16),
              _buildUserAvatar(entry.username),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? Colors.green.shade700 : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildProgressInfo(entry),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.points}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (entry.trend != null) ...[
                    const SizedBox(height: 4),
                    _buildTrendIndicator(entry.trend!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(LeaderboardEntry entry, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showUserProfile(entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildUserAvatar(entry.username),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildProgressInfo(entry),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.points}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    String rankText;
    
    switch (rank) {
      case 1:
        badgeColor = Colors.amber;
        rankText = '🥇';
        break;
      case 2:
        badgeColor = Colors.grey;
        rankText = '🥈';
        break;
      case 3:
        badgeColor = Colors.brown;
        rankText = '🥉';
        break;
      default:
        badgeColor = Colors.blue;
        rankText = '#$rank';
        break;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 2),
      ),
      child: Center(
        child: Text(
          rankText,
          style: TextStyle(
            fontSize: rank <= 3 ? 20 : 14,
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? null : badgeColor,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String username) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Text(
          username.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressInfo(LeaderboardEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${entry.co2Saved.toStringAsFixed(1)}kg CO₂ saved',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        _buildMiniProgressBar(entry.points, entry.targetPoints ?? 1000),
      ],
    );
  }

  Widget _buildMiniProgressBar(int current, int target) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(String trend) {
    IconData icon;
    Color color;
    
    switch (trend) {
      case 'up':
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case 'down':
        icon = Icons.trending_down;
        color = Colors.red;
        break;
      default:
        icon = Icons.trending_flat;
        color = Colors.grey;
        break;
    }
    
    return Icon(icon, color: color, size: 16);
  }

  void _showUserProfile(LeaderboardEntry entry) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildUserAvatar(entry.username),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.username,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Points: ${entry.points}'),
            Text('CO₂ Saved: ${entry.co2Saved.toStringAsFixed(1)}kg'),
            Text('Rank: #${entry.rank}'),
            if (entry.achievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Recent Achievements:'),
              ...entry.achievements.take(3).map((achievement) => 
                  Text('• $achievement', style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          if (entry.userId != _currentUser?.id) ...[
            TextButton(
              onPressed: () => _addFriend(entry.userId),
              child: const Text('Add Friend'),
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

  void _showAddFriendDialog() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter username or email',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Friend request sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFriend(int userId) async {
    try {
      // Add friend logic here
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add friend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}