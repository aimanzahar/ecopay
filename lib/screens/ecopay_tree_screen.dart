import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/user.dart';
import '../models/contribution.dart';

// Color Scheme Constants (matching main app)
const Color primaryGreen = Color(0xFF2E7D32);
const Color lightGreen = Color(0xFFA5D6A7);
const Color darkGreen = Color(0xFF1B5E20);
const Color textPrimary = Color(0xFF263238);
const Color textSecondary = Color(0xFF607D8B);

class EcoPayTreeScreen extends StatefulWidget {
  const EcoPayTreeScreen({super.key});

  @override
  State<EcoPayTreeScreen> createState() => _EcoPayTreeScreenState();
}

class _EcoPayTreeScreenState extends State<EcoPayTreeScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  User? _user;
  List<Contribution> _contributions = [];
  bool _isLoading = true;
  
  late AnimationController _treeGrowthController;
  late AnimationController _leafController;
  late Animation<double> _treeGrowthAnimation;
  late Animation<double> _leafSwayAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _treeGrowthController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _leafController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _treeGrowthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _treeGrowthController, curve: Curves.easeInOut),
    );

    _leafSwayAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _leafController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _treeGrowthController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = await _databaseHelper.getUser(1);
    if (user != null) {
      final contributions = await _databaseHelper.getContributionsByUser(user.id!);
      setState(() {
        _user = user;
        _contributions = contributions;
        _isLoading = false;
      });
      
      // Start tree growth animation after data loads
      _treeGrowthController.forward();
    } else {
      setState(() => _isLoading = false);
    }
  }

  double get _treeGrowthLevel {
    if (_contributions.isEmpty) return 0.1; // Small sapling
    
    final totalContributions = _contributions.fold<double>(
      0.0, (sum, contribution) => sum + contribution.amount
    );
    
    // Scale tree growth based on total contributions (0.1 to 1.0)
    return (totalContributions / 100.0).clamp(0.1, 1.0);
  }

  int get _leafCount {
    // More contributions = more leaves
    return (_contributions.length * 2).clamp(5, 20);
  }

  String get _treeStage {
    final level = _treeGrowthLevel;
    if (level < 0.3) return 'Sapling';
    if (level < 0.6) return 'Young Tree';
    if (level < 0.8) return 'Mature Tree';
    return 'Ancient Tree';
  }

  Color get _treeColor {
    final level = _treeGrowthLevel;
    if (level < 0.3) return Colors.green.shade300;
    if (level < 0.6) return Colors.green.shade500;
    if (level < 0.8) return Colors.green.shade700;
    return darkGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your EcoPay Tree'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildTreeStatsHeader(),
                  const SizedBox(height: 20),
                  _buildTreeVisualization(),
                  const SizedBox(height: 30),
                  _buildTreeInfo(),
                  const SizedBox(height: 20),
                  _buildContributionHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildTreeStatsHeader() {
    final totalContributions = _contributions.fold<double>(
      0.0, (sum, contribution) => sum + contribution.amount
    );
    final co2Saved = totalContributions * 0.12; // Approximate CO2 savings

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightGreen.withOpacity(0.3), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Tree Stage',
            _treeStage,
            Icons.park,
            _treeColor,
          ),
          Container(height: 50, width: 1, color: Colors.green.shade200),
          _buildStatItem(
            'CO₂ Saved',
            '${co2Saved.toStringAsFixed(1)}kg',
            Icons.eco,
            primaryGreen,
          ),
          Container(height: 50, width: 1, color: Colors.green.shade200),
          _buildStatItem(
            'Total Impact',
            'RM ${totalContributions.toStringAsFixed(2)}',
            Icons.monetization_on,
            Colors.amber.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTreeVisualization() {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.lightBlue.shade50, Colors.green.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_treeGrowthAnimation, _leafSwayAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: TreePainter(
              growthLevel: _treeGrowthAnimation.value * _treeGrowthLevel,
              leafCount: _leafCount,
              swayAngle: _leafSwayAnimation.value,
              treeColor: _treeColor,
            ),
            size: const Size(double.infinity, 300),
          );
        },
      ),
    );
  }

  Widget _buildTreeInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Environmental Impact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 15),
          _buildInfoRow(Icons.eco, 'Tree Growth Level', '${(_treeGrowthLevel * 100).toInt()}%'),
          _buildInfoRow(Icons.nature, 'Contributions Made', '${_contributions.length}'),
          _buildInfoRow(Icons.timeline, 'Days Active', _getDaysActive().toString()),
          const SizedBox(height: 15),
          Text(
            'Keep making eco-friendly transactions to help your tree grow bigger and stronger! 🌳',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionHistory() {
    if (_contributions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(Icons.eco, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 15),
            Text(
              'Start Your Journey',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make your first eco-friendly transaction to plant your tree!',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Growth',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 15),
          ...(_contributions.take(5).map((contribution) => _buildContributionItem(contribution))),
        ],
      ),
    );
  }

  Widget _buildContributionItem(Contribution contribution) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.eco, color: primaryGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eco Contribution',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatDate(contribution.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            'RM ${contribution.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  int _getDaysActive() {
    if (_contributions.isEmpty) return 0;
    
    final firstContribution = _contributions.reduce((a, b) => 
      a.timestamp.isBefore(b.timestamp) ? a : b
    );
    
    return DateTime.now().difference(firstContribution.timestamp).inDays + 1;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class TreePainter extends CustomPainter {
  final double growthLevel;
  final int leafCount;
  final double swayAngle;
  final Color treeColor;

  TreePainter({
    required this.growthLevel,
    required this.leafCount,
    required this.swayAngle,
    required this.treeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade600
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = treeColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height);
    final trunkHeight = size.height * 0.4 * growthLevel;
    final trunkTop = Offset(center.dx, center.dy - trunkHeight);

    // Draw trunk
    canvas.drawLine(center, trunkTop, paint);

    if (growthLevel > 0.2) {
      // Draw branches
      final branchLength = size.height * 0.15 * growthLevel;
      final branchPaint = Paint()
        ..color = Colors.brown.shade400
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      // Left branch
      final leftBranch = Offset(
        trunkTop.dx - branchLength + (swayAngle * 10),
        trunkTop.dy + branchLength * 0.3,
      );
      canvas.drawLine(trunkTop, leftBranch, branchPaint);

      // Right branch
      final rightBranch = Offset(
        trunkTop.dx + branchLength + (swayAngle * 10),
        trunkTop.dy + branchLength * 0.3,
      );
      canvas.drawLine(trunkTop, rightBranch, branchPaint);

      // Draw leaves
      if (growthLevel > 0.3) {
        for (int i = 0; i < leafCount; i++) {
          final angle = (i * 2 * 3.14159) / leafCount;
          final leafRadius = 8 + (growthLevel * 12);
          final leafX = trunkTop.dx + 
              (leafRadius * 2 * (0.5 + growthLevel * 0.5)) * (i.isEven ? 1 : -1) * 
              (0.7 + 0.3 * (i / leafCount)) + (swayAngle * 20);
          final leafY = trunkTop.dy - leafRadius + (i * 3) - (growthLevel * 20);

          canvas.drawCircle(
            Offset(leafX, leafY),
            leafRadius,
            leafPaint,
          );
        }
      }
    }

    // Draw ground
    final groundPaint = Paint()
      ..color = Colors.brown.shade200
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 10, size.width, 10),
      groundPaint,
    );
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.growthLevel != growthLevel ||
        oldDelegate.swayAngle != swayAngle ||
        oldDelegate.leafCount != leafCount;
  }
}