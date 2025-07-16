import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/user.dart';
import '../models/contribution.dart';
import 'achievements_screen.dart';
import 'challenges_screen.dart';
import 'leaderboard_screen.dart';
import 'local_projects_screen.dart';
import 'transaction_history_screen.dart';

class EcoPayScreen extends StatefulWidget {
  const EcoPayScreen({super.key});

  @override
  State<EcoPayScreen> createState() => _EcoPayScreenState();
}

class _EcoPayScreenState extends State<EcoPayScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  User? _user;
  List<Contribution> _contributions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    // Assuming user ID 1 for this example
    final user = await _databaseHelper.getUser(1);
    if (user != null) {
      final contributions = await _databaseHelper.getContributionsByUser(user.id!);
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
        ecopayOptIn: value,
      );
      await _databaseHelper.updateUser(updatedUser);
      setState(() {
        _user = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildOptInSwitch(),
                  if (_user?.ecopayOptIn ?? false)
                    _buildDashboard()
                  else
                    _buildOptInMessage(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade100,
            Colors.green.shade50,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Plant icon
          Container(
            height: 150,
            child: Icon(
              Icons.park,
              size: 120,
              color: Colors.green.shade600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            '🌱 Welcome to EcoPay',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          
          const SizedBox(height: 10),
          
          Text(
            'Your sustainable payment solution',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade600,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '127kg',
                  'CO₂ Saved',
                  Colors.green.shade600,
                  Icons.eco,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  '45',
                  'Green Transactions',
                  Colors.green.shade600,
                  Icons.nature_people,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildESGFeatures() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESG Features',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          
          const SizedBox(height: 15),
          
          _buildFeatureCard(
            '🌍 Environmental Impact',
            'Track your carbon footprint and offset emissions',
            Colors.green.shade50,
            Icons.public,
          ),
          
          const SizedBox(height: 12),
          
          _buildFeatureCard(
            '👥 Social Responsibility',
            'Support local communities and social causes',
            Colors.blue.shade50,
            Icons.group,
          ),
          
          const SizedBox(height: 12),
          
          _buildFeatureCard(
            '🏢 Corporate Governance',
            'Transparent and ethical business practices',
            Colors.purple.shade50,
            Icons.business,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green.shade600, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonTracker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Carbon Footprint Tracker',
                style: TextStyle(
                  fontSize: 20,
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
                    const Text(
                      'This Month',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '12.3 kg CO₂',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        '↓ 23% vs last month',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Plant growing icon
              Container(
                width: 100,
                height: 100,
                child: Icon(
                  Icons.local_florist,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreenRewards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Green Rewards',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          
          const SizedBox(height: 15),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🏆',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eco Points Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1,247 points',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Redeem for green products & services',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Redeem'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sustainability Tips',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          
          const SizedBox(height: 15),
          
          _buildTipCard(
            '💡',
            'Use digital receipts to save paper',
            'Save up to 2.5kg CO₂ per year',
          ),
          
          const SizedBox(height: 12),
          
          _buildTipCard(
            '🚶‍♀️',
            'Walk to nearby stores instead of driving',
            'Reduce transport emissions by 65%',
          ),
          
          const SizedBox(height: 12),
          
          _buildTipCard(
            '♻️',
            'Choose eco-friendly businesses',
            'Support sustainable practices',
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String emoji, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade600,
                  ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Enable EcoPay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Switch(
            value: _user?.ecopayOptIn ?? false,
            onChanged: (value) {
              _updateOptInStatus(value);
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildOptInMessage() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco,
            size: 100,
            color: Colors.green.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          const Text(
            'Join EcoPay!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Enable EcoPay to round up your transactions and contribute to environmental projects.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 20),
          _buildImpactStats(),
          const SizedBox(height: 20),
          _buildDashboardCards(),
          const SizedBox(height: 20),
          _buildDashboardButtons(),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${_user?.name ?? 'User'}! 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "This month's impact:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const Icon(Icons.notifications_none, size: 28),
      ],
    );
  }

  Widget _buildImpactStats() {
    final double totalDonated = _contributions.fold(0.0, (sum, item) => sum + item.amount);
    final int treesPlanted = (totalDonated / 2.5).floor(); // Assuming RM 2.5 per tree
    final double co2Offset = totalDonated * 0.12; // Simple calculation

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.park, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text('$treesPlanted trees planted', style: const TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.eco, color: Colors.blue, size: 28),
            const SizedBox(width: 10),
            Text('${co2Offset.toStringAsFixed(2)}kg CO₂ offset', style: const TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Rank: #847 in Selangor', style: TextStyle(fontSize: 18)),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCards() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryScreen(),
                ),
              );
            },
            child: _buildInfoCard('Recent Activity', '📍 Mamak Ali\n+0.5 trees 🌳\n2 hours ago'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChallengesScreen(),
                ),
              );
            },
            child: _buildInfoCard('Challenges', '🎯 Eco Weekend\n3/5 green meals\n2 days left'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildDashboardButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LocalProjectsScreen(),
              ),
            );
          },
          child: const Text('View Full Impact'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LeaderboardScreen(),
              ),
            );
          },
          child: const Text('Leaderboard'),
        ),
      ],
    );
  }
}