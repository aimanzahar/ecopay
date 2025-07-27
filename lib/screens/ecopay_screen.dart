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
import 'redeem_screen.dart';
import 'ecopay_tree_screen.dart';

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
    print("EcoPayScreen build() - Screen size: ${MediaQuery.of(context).size}");
    print("EcoPayScreen build() - User opt-in: ${_user?.ecopayOptIn}");
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialPositionSet) {
        final size = MediaQuery.of(context).size;
        print("EcoPayScreen - Setting AI icon position: ${Offset(size.width - 80, size.height - 180)}");
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

  // 5) The circular AI button with EcoPay styling:
  Widget _aiButton() {
    return GestureDetector(
      onTap: _openChatBox,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryGreen, darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Icon(Icons.eco, color: Colors.white, size: 28),
      ),
    );
  }

  // 6) Opens a modern EcoPay-themed chat interface:
  void _openChatBox() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return const EcoPayChatWidget();
      },
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
              Colors.white,
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
              Colors.white,
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
              const SizedBox(width: 15),
              _buildGamificationItem(
                'EcoPayTree',
                Icons.park,
                primaryGreen,
                EcoPayTreeScreen(),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RedeemScreen(),
                    ),
                  );
                },
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
        Text(label, style: const TextStyle(fontSize: 12, color: textSecondary)),
      ],
    );
  }
}

// Modern EcoPay-themed Chat Widget
class EcoPayChatWidget extends StatefulWidget {
  const EcoPayChatWidget({super.key});

  @override
  State<EcoPayChatWidget> createState() => _EcoPayChatWidgetState();
}

class _EcoPayChatWidgetState extends State<EcoPayChatWidget>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Add welcome message
    _messages.add(ChatMessage(
      text: "🌱 Hi! I'm your EcoPay assistant. How can I help you with your sustainable journey today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: _messageController.text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _generateResponse(userMessage.text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  String _generateResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    if (message.contains('carbon') || message.contains('co2')) {
      return "🌍 Great question about carbon footprint! Based on your transactions, you've saved approximately 12.3kg of CO₂ this month. Keep using EcoPay to maximize your environmental impact!";
    } else if (message.contains('reward') || message.contains('point')) {
      return "⭐ You currently have 1,247 green points! You can redeem them for sustainable products in the Redeem section. You're 253 points away from your next reward!";
    } else if (message.contains('tip') || message.contains('help')) {
      return "💡 Here are some eco-friendly tips:\n• Use digital receipts to save paper\n• Walk to nearby stores when possible\n• Choose businesses with green certifications\n• Round up your payments to support environmental projects!";
    } else {
      return "🌱 Thanks for your message! I'm here to help you with your EcoPay journey, environmental tips, and tracking your green impact. What would you like to know more about?";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Add safety bounds for chat height to prevent overflow
    final maxChatHeight = screenSize.height - 100; // Leave space for system UI
    final chatHeight = (screenSize.height * 0.7).clamp(300.0, maxChatHeight);
    
    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: chatHeight,
              maxWidth: screenSize.width - 32, // Account for margins
            ),
            child: Container(
              height: chatHeight,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildChatHeader(),
                    Expanded(
                      child: _buildMessagesList(),
                    ),
                    if (_isTyping) _buildTypingIndicator(),
                    _buildMessageInput(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EcoPay Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your sustainable companion 🌱',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) _buildBotAvatar(),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? primaryGreen
                    : lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.eco, color: Colors.white, size: 18),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: Colors.grey.shade600, size: 18),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(200),
                const SizedBox(width: 4),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    print("EcoPayChatWidget _buildMessageInput() - Building message input");
    print("EcoPayChatWidget _buildMessageInput() - Material context: ${Material.maybeOf(context) != null}");
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ask about your green impact...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
