import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/user.dart';
import '../models/contribution.dart';
import 'achievements_screen.dart';
import 'challenges_screen.dart';
import 'leaderboard_screen.dart';
import 'local_projects_screen.dart';
import 'transaction_history_screen.dart';
import 'donation_history_screen.dart';
import 'my_contribution_screen.dart';

// Color Scheme Constants
const Color primaryGreen = Color(0xFF2E7D32); // Main green
const Color lightGreen = Color(0xFFA5D6A7); // Light green
const Color darkGreen = Color(0xFF1B5E20); // Dark green
const Color textPrimary = Color(0xFF263238); // Dark gray
const Color textSecondary = Color(0xFF607D8B); // Gray-blue
const Color accentBlue = Color(0xFF1976D2); // For secondary actions
const Color accentAmber = Color(0xFFFFA000); // For highlights

class EcoPayScreen extends StatefulWidget {
  const EcoPayScreen({super.key});

  @override
  State<EcoPayScreen> createState() => _EcoPayScreenState();
}

class _EcoPayScreenState extends State<EcoPayScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  User? _user;
  List<Contribution> _contributions = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final GlobalKey _scaffoldKey = GlobalKey();
  bool _initialPositionSet = false;


  @override
  void initState() {
    super.initState();
    _loadData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final user = await _databaseHelper.getUser(1);
    if (user != null) {
      final contributions = await _databaseHelper.getContributionsByUser(
        user.id!,
      );
      setState(() {
        _user = user;
        _contributions = contributions;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOptInStatus(bool value) async {
    if (_user != null) {
      final updatedUser = User(
        id: _user!.id,
        name: _user!.name,
        username: _user!.username,
        email: _user!.email,
        ecopayOptIn: value,
      );
      await _databaseHelper.updateUser(updatedUser);
      setState(() {
        _user = updatedUser;
      });
    }
  }

  Offset _aiIconOffset = const Offset(300, 600);

  @override
  Widget build(BuildContext context) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialPositionSet) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _aiIconOffset = Offset(size.width - 80, size.height - 180);
          _initialPositionSet = true;
        });
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'EcoPay',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      // 2) Wrap in a Stack so we can overlay the AI icon:
      body: Stack(
        children: [
          // Your existing content:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOptInSwitch(),
                      if (_user?.ecopayOptIn ?? false) ...[
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildStatsVisualization(),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                        const SizedBox(height: 30),
                        _buildGamificationFeatures(),
                        const SizedBox(height: 30),
                        _buildCarbonTracker(),
                        const SizedBox(height: 30),
                        _buildGreenRewards(),
                        const SizedBox(height: 30),
                        _buildSustainabilityTips(),
                        const SizedBox(height: 20),
                        _buildESGFeatures(),
                        const SizedBox(height: 20),
                      ] else
                        _buildOptInMessage(),
                    ],
                  ),
                ),

          // 3) The draggable AI icon overlay:
          _buildDraggableAIIcon(),
        ],
      ),
    );
  }

  // 4) Builds the draggable icon in its current position:
  Widget _buildDraggableAIIcon() {
    return Positioned(
      left: _aiIconOffset.dx,
      top: _aiIconOffset.dy,
      child: Draggable(
        feedback: _aiButton(), // shown while dragging
        childWhenDragging: Opacity(opacity: 0.5, child: _aiButton()),
        child: _aiButton(), // the icon at rest
        onDragEnd: (details) {
          setState(() {
            final size = MediaQuery.of(context).size;
            // keep it within screen bounds:
            final dx = details.offset.dx.clamp(0.0, size.width - 56);
            final dy = details.offset.dy.clamp(
              kToolbarHeight, // beneath the AppBar
              size.height - 56,
            );
            _aiIconOffset = Offset(dx, dy);
          });
        },
      ),
    );
  }

  // 5) The circular AI button:
  Widget _aiButton() {
    return GestureDetector(
      onTap: _openChatBox,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 53, 40, 128),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: const Icon(Icons.android, color: Colors.white),
      ),
    );
  }

  // 6) Opens a simple chat dialog:
  void _openChatBox() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chat with AI'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  // TODO: replace with your chat messages list
                  alignment: Alignment.center,
                  child: const Text('AI Chat goes here'),
                ),
              ),
              TextField(
                decoration: const InputDecoration(hintText: 'Type a message…'),
                onSubmitted: (msg) {
                  // TODO: handle sending message
                },
              ),
            ],
          ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/EcoPayIconremovebg.png',
            height: 60,
            width: 60,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌱 Welcome to EcoPay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your sustainable payment solution',
                  style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsVisualization() {
    final double totalDonated = _contributions.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final double co2Offset = totalDonated * 0.12;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatVisual(
            'CO₂ Saved',
            '${co2Offset.toStringAsFixed(1)}kg',
            Icons.eco,
            primaryGreen,
          ),
          Container(height: 50, width: 1, color: Colors.green.shade200),
          _buildStatVisual(
            'Transactions',
            '${_contributions.length}',
            Icons.receipt,
            accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatVisual(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'My Contribution',
              Icons.eco,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyContributionScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              'History',
              Icons.history,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DonationHistoryScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen, // Changed
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: primaryGreen.withOpacity(0.3)),
        ),
      ),
      // Row is the positional child argument
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildESGFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'ESG Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            children: [
              _buildESGFeatureItem(
                'Environmental',
                Icons.eco,
                primaryGreen,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocalProjectsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 15),
              _buildESGFeatureItem('Social', Icons.people, accentBlue, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocalProjectsScreen(),
                  ),
                );
              }),
              const SizedBox(width: 15),
              _buildESGFeatureItem(
                'Governance',
                Icons.business,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocalProjectsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildESGFeatureItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: color), // Reduced icon size
              const SizedBox(height: 6), // Reduced spacing
              Text(
                title,
                style: TextStyle(
                  fontSize: 11, // Reduced font size
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamificationFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Gamification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            children: [
              _buildGamificationItem(
                'Leaderboard',
                Icons.leaderboard,
                accentAmber,
                LeaderboardScreen(),
              ),
              const SizedBox(width: 15),
              _buildGamificationItem(
                'Challenges',
                Icons.flag,
                accentBlue,
                ChallengesScreen(),
              ),
              const SizedBox(width: 15),
              _buildGamificationItem(
                'Achievements',
                Icons.workspace_premium,
                Colors.purple,
                AchievementsScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamificationItem(
    String title,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        _playAnimation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: 100,
              height: 120,
              child: Container(
                padding: const EdgeInsets.all(12), // Reduced padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), // Reduced padding
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: color,
                      ), // Reduced icon size
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarbonTracker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Carbon Footprint',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This Month',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '12.3 kg CO₂',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '↓ 23% vs last month',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.bar_chart, size: 60, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildGreenRewards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Green Rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '1,247 pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Redeem points for sustainable products & services',
                  style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Redeem'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: 1247 / 1500,
            minHeight: 8,
            color: primaryGreen, // Changed
            backgroundColor: lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '253 points to next reward',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sustainability Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 15),
          _buildTipItem(
            '💡',
            'Use digital receipts',
            'Save up to 2.5kg CO₂ per year',
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '🚶‍♀️',
            'Walk to nearby stores',
            'Reduce transport emissions by 65%',
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '♻️',
            'Choose eco-friendly businesses',
            'Support sustainable practices',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptInSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: lightGreen.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enable EcoPay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            Switch(
              value: _user?.ecopayOptIn ?? false,
              onChanged: (value) {
                _updateOptInStatus(value);
              },
              activeColor: primaryGreen, // Changed
              activeTrackColor: lightGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptInMessage() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/EcoPayIconremovebg.png',
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          const Text(
            'Activate EcoPay',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Round up your payments to support verified green projects. Track your CO₂ savings, earn rewards, and join a sustainability-driven community!',
            style: TextStyle(fontSize: 15, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
  
          // Highlights Grid
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _buildHighlightCard(Icons.eco, "Save CO₂ Automatically"),
              _buildHighlightCard(Icons.redeem, "Earn Green Rewards"),
              _buildHighlightCard(Icons.group, "Join 12k+ Eco Users"),
              _buildHighlightCard(Icons.verified, "Verified Impact"),
            ],
          ),
          const SizedBox(height: 30),
  
          // Preview of what they’re missing
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Column(
              children: [
                Text(
                  "You're missing out on:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _ImpactStatPreview(
                      label: 'CO₂ Saved',
                      value: '8.2 kg/mo',
                      icon: Icons.cloud_done,
                    ),
                    _ImpactStatPreview(
                      label: 'Green Points',
                      value: '+120 pts',
                      icon: Icons.stars,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Turn the switch ON to join the movement 🌍',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

}

Widget _buildHighlightCard(IconData icon, String title) {
  return Container(
    width: 150,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.shade100),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: primaryGreen, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ImpactStatPreview extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ImpactStatPreview({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: 28),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}

