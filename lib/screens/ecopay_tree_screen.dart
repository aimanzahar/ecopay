import 'package:flutter/material.dart';
import 'dart:math' as math;
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
    if (level < 1.0) return 'Ancient Tree';
    return 'Legendary Giant';
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
    final center = Offset(size.width / 2, size.height);
    
    // Draw ground first
    _drawGround(canvas, size);
    
    // Draw roots if mature enough
    if (growthLevel > 0.4) {
      _drawRoots(canvas, size, center);
    }
    
    // Draw main trunk
    _drawTrunk(canvas, size, center);
    
    // Draw branch system
    if (growthLevel > 0.2) {
      _drawBranchSystem(canvas, size, center);
    }
    
    // Add special effects for fully grown tree
    if (growthLevel >= 1.0) {
      _drawSpecialEffects(canvas, size, center);
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundPaint = Paint()
      ..color = Colors.brown.shade300
      ..style = PaintingStyle.fill;

    // Enhanced ground with gradient effect
    final gradient = LinearGradient(
      colors: [Colors.brown.shade400, Colors.brown.shade200],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    
    final groundRect = Rect.fromLTWH(0, size.height - 15, size.width, 15);
    groundPaint.shader = gradient.createShader(groundRect);
    canvas.drawRect(groundRect, groundPaint);
    
    // Add grass effect
    final grassPaint = Paint()
      ..color = Colors.green.shade300
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < size.width.toInt(); i += 8) {
      canvas.drawLine(
        Offset(i.toDouble(), size.height - 15),
        Offset(i.toDouble(), size.height - 12),
        grassPaint,
      );
    }
  }

  void _drawRoots(Canvas canvas, Size size, Offset center) {
    final rootPaint = Paint()
      ..color = Colors.brown.shade600
      ..strokeWidth = 3 + (growthLevel * 2)
      ..strokeCap = StrokeCap.round;

    final rootLength = size.width * 0.15 * growthLevel;
    
    // Draw multiple root branches
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i - 2) * 0.4;
      final rootEnd = Offset(
        center.dx + rootLength * (0.5 + growthLevel * 0.5) * math.cos(angle),
        center.dy - 5 + (growthLevel * 10) * math.sin(angle).abs(),
      );
      
      canvas.drawLine(
        Offset(center.dx, center.dy - 10),
        rootEnd,
        rootPaint,
      );
    }
  }

  void _drawTrunk(Canvas canvas, Size size, Offset center) {
    final trunkHeight = size.height * (0.35 + growthLevel * 0.25);
    final trunkTop = Offset(center.dx, center.dy - trunkHeight);
    
    // Progressive trunk thickness
    final baseWidth = 12 + (growthLevel * 8);
    final topWidth = 6 + (growthLevel * 4);
    
    // Draw trunk with taper
    final trunkPaint = Paint()
      ..color = Colors.brown.shade700
      ..style = PaintingStyle.fill;

    final trunkPath = Path();
    trunkPath.moveTo(center.dx - baseWidth / 2, center.dy);
    trunkPath.lineTo(center.dx + baseWidth / 2, center.dy);
    trunkPath.lineTo(trunkTop.dx + topWidth / 2, trunkTop.dy);
    trunkPath.lineTo(trunkTop.dx - topWidth / 2, trunkTop.dy);
    trunkPath.close();
    
    canvas.drawPath(trunkPath, trunkPaint);
    
    // Add trunk texture
    final texturePaint = Paint()
      ..color = Colors.brown.shade600
      ..strokeWidth = 1;
    
    for (double y = center.dy - 20; y > trunkTop.dy; y -= 15) {
      canvas.drawLine(
        Offset(center.dx - (baseWidth * (center.dy - y) / trunkHeight) / 3, y),
        Offset(center.dx + (baseWidth * (center.dy - y) / trunkHeight) / 3, y),
        texturePaint,
      );
    }
  }

  void _drawBranchSystem(Canvas canvas, Size size, Offset center) {
    final trunkHeight = size.height * (0.35 + growthLevel * 0.25);
    final trunkTop = Offset(center.dx, center.dy - trunkHeight);
    
    // Primary branches
    _drawPrimaryBranches(canvas, size, trunkTop);
    
    // Secondary branches for mature trees
    if (growthLevel > 0.5) {
      _drawSecondaryBranches(canvas, size, trunkTop);
    }
    
    // Intermediate canopy for mature trees (60-80%)
    if (growthLevel > 0.6 && growthLevel <= 0.8) {
      _drawIntermediateCanopy(canvas, size, trunkTop);
    }
    
    // Full canopy for ancient trees (80%+)
    if (growthLevel > 0.8) {
      _drawFullCanopy(canvas, size, trunkTop);
    }
  }

  void _drawPrimaryBranches(Canvas canvas, Size size, Offset trunkTop) {
    final branchPaint = Paint()
      ..color = Colors.brown.shade500
      ..strokeWidth = 4 + (growthLevel * 3)
      ..strokeCap = StrokeCap.round;

    final branchLength = size.height * 0.2 * growthLevel;
    
    // Main left and right branches
    final branches = [
      {'angle': -0.7, 'length': branchLength},
      {'angle': 0.7, 'length': branchLength},
      {'angle': -0.3, 'length': branchLength * 0.8},
      {'angle': 0.3, 'length': branchLength * 0.8},
    ];
    
    for (final branch in branches) {
      final angle = branch['angle'] as double;
      final length = branch['length'] as double;
      
      final branchEnd = Offset(
        trunkTop.dx + length * math.cos(angle + swayAngle),
        trunkTop.dy + length * math.sin(angle) - length * 0.3,
      );
      
      canvas.drawLine(trunkTop, branchEnd, branchPaint);
      
      // Draw leaves on primary branches
      if (growthLevel > 0.3) {
        _drawLeavesOnBranch(canvas, trunkTop, branchEnd, 8 + (growthLevel * 4).toInt());
      }
    }
  }

  void _drawSecondaryBranches(Canvas canvas, Size size, Offset trunkTop) {
    final branchPaint = Paint()
      ..color = Colors.brown.shade400
      ..strokeWidth = 2 + growthLevel
      ..strokeCap = StrokeCap.round;

    final branchLength = size.height * 0.12 * growthLevel;
    
    // More numerous secondary branches
    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (i * math.pi / 4);
      final length = branchLength * (0.7 + (i % 2) * 0.3);
      
      final branchStart = Offset(
        trunkTop.dx + (size.height * 0.15 * math.cos(angle)) * growthLevel,
        trunkTop.dy - (size.height * 0.1) + (i * 5),
      );
      
      final branchEnd = Offset(
        branchStart.dx + length * math.cos(angle + swayAngle * 0.5),
        branchStart.dy + length * math.sin(angle),
      );
      
      canvas.drawLine(branchStart, branchEnd, branchPaint);
      
      // Leaves on secondary branches
      _drawLeavesOnBranch(canvas, branchStart, branchEnd, 4 + (growthLevel * 2).toInt());
    }
  }

  void _drawIntermediateCanopy(Canvas canvas, Size size, Offset trunkTop) {
    // Create leaves attached to branch endpoints for 60-80% growth
    final leafPaint = Paint()
      ..color = treeColor
      ..style = PaintingStyle.fill;
    
    final branchLength = size.height * 0.2 * growthLevel;
    
    // Draw leaves at the end of each main branch direction
    final branchAngles = [-0.7, 0.7, -0.3, 0.3, -1.0, 1.0];
    
    for (final angle in branchAngles) {
      final length = branchLength * (angle.abs() > 0.5 ? 1.0 : 0.8);
      
      // Calculate branch endpoint
      final branchEnd = Offset(
        trunkTop.dx + length * math.cos(angle + swayAngle),
        trunkTop.dy + length * math.sin(angle) - length * 0.3,
      );
      
      // Draw multiple leaves around each branch endpoint
      final leavesPerBranch = (3 + (growthLevel * 2)).toInt();
      for (int i = 0; i < leavesPerBranch; i++) {
        final leafAngle = (i * 2 * math.pi) / leavesPerBranch;
        final leafDistance = 15 + (growthLevel * 10); // Distance from branch end
        
        final leafPos = Offset(
          branchEnd.dx + leafDistance * math.cos(leafAngle + swayAngle),
          branchEnd.dy + leafDistance * 0.6 * math.sin(leafAngle),
        );
        
        final leafSize = 7 + (growthLevel * 3);
        canvas.drawCircle(leafPos, leafSize, leafPaint);
      }
      
      // Add some leaves along the branch path for more fullness
      for (int j = 1; j <= 3; j++) {
        final t = j / 4.0; // Along branch from trunk to end
        final branchPoint = Offset(
          trunkTop.dx + (branchEnd.dx - trunkTop.dx) * t,
          trunkTop.dy + (branchEnd.dy - trunkTop.dy) * t,
        );
        
        // Small cluster of leaves at this branch point
        for (int k = 0; k < 2; k++) {
          final clusterAngle = k * math.pi;
          final clusterPos = Offset(
            branchPoint.dx + 8 * math.cos(clusterAngle + swayAngle),
            branchPoint.dy + 8 * 0.5 * math.sin(clusterAngle),
          );
          
          final clusterLeafSize = 5 + (growthLevel * 2);
          canvas.drawCircle(clusterPos, clusterLeafSize, leafPaint);
        }
      }
    }
  }

  void _drawFullCanopy(Canvas canvas, Size size, Offset trunkTop) {
    // Create a grand, natural canopy for 100% grown trees
    final canopyCenter = Offset(trunkTop.dx, trunkTop.dy - size.height * 0.12);
    final canopyRadius = size.width * 0.25 * growthLevel;
    
    // For 100% growth, create a magnificent but natural canopy
    if (growthLevel >= 1.0) {
      // Draw main canopy shape with organic variations
      final mainCanopyPaint = Paint()
        ..color = Colors.green.shade700.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      
      // Create organic canopy shape with overlapping circles
      final canopyPoints = [
        Offset(canopyCenter.dx, canopyCenter.dy - canopyRadius * 0.3), // top
        Offset(canopyCenter.dx - canopyRadius * 0.8, canopyCenter.dy), // left
        Offset(canopyCenter.dx + canopyRadius * 0.8, canopyCenter.dy), // right
        Offset(canopyCenter.dx - canopyRadius * 0.5, canopyCenter.dy + canopyRadius * 0.3), // bottom left
        Offset(canopyCenter.dx + canopyRadius * 0.5, canopyCenter.dy + canopyRadius * 0.3), // bottom right
      ];
      
      // Draw organic canopy shape
      for (final point in canopyPoints) {
        final leafCluster = Offset(
          point.dx + (swayAngle * 8),
          point.dy,
        );
        canvas.drawCircle(leafCluster, canopyRadius * 0.6, mainCanopyPaint);
      }
      
      // Add highlight layer for depth
      final highlightPaint = Paint()
        ..color = treeColor.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < canopyPoints.length; i++) {
        final point = canopyPoints[i];
        final highlightPos = Offset(
          point.dx + (swayAngle * 5) - canopyRadius * 0.1,
          point.dy - canopyRadius * 0.1,
        );
        canvas.drawCircle(highlightPos, canopyRadius * 0.4, highlightPaint);
      }
      
      // Add bright accent leaves for legendary status
      final accentPaint = Paint()
        ..color = Colors.lightGreen.shade200.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi * 2) / 8;
        final accentPos = Offset(
          canopyCenter.dx + canopyRadius * 0.6 * math.cos(angle + swayAngle),
          canopyCenter.dy + canopyRadius * 0.4 * math.sin(angle),
        );
        canvas.drawCircle(accentPos, canopyRadius * 0.15, accentPaint);
      }
    } else {
      // Regular canopy for other growth levels
      final leafPaint = Paint()
        ..color = treeColor
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < leafCount; i++) {
        final angle = (i * 2 * math.pi) / leafCount;
        final leafRadius = 8 + (growthLevel * 8);
        final distance = canopyRadius * (0.6 + (i % 3) * 0.3);
        
        final leafX = canopyCenter.dx + distance * math.cos(angle + swayAngle);
        final leafY = canopyCenter.dy + distance * 0.6 * math.sin(angle);

        canvas.drawCircle(Offset(leafX, leafY), leafRadius, leafPaint);
      }
    }
  }

  void _drawLeavesOnBranch(Canvas canvas, Offset start, Offset end, int count) {
    final leafPaint = Paint()
      ..color = treeColor
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < count; i++) {
      final t = i / count;
      final leafPos = Offset(
        start.dx + (end.dx - start.dx) * t + (swayAngle * 15),
        start.dy + (end.dy - start.dy) * t - (growthLevel * 5),
      );
      
      // Simple, properly sized leaves
      final leafSize = 5 + (growthLevel * 2); // Reasonable size that's not too big or too small
      canvas.drawCircle(leafPos, leafSize, leafPaint);
    }
  }

  void _drawSpecialEffects(Canvas canvas, Size size, Offset center) {
    // Add magical sparkles around a fully grown tree
    final sparkleCount = 15;
    final sparkleRadius = size.width * 0.4;
    
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i * 2 * math.pi) / sparkleCount;
      final distance = sparkleRadius * (0.7 + (i % 3) * 0.15);
      
      final sparklePos = Offset(
        center.dx + distance * math.cos(angle + swayAngle * 2),
        center.dy - size.height * 0.5 + distance * math.sin(angle) * 0.3,
      );
      
      // Golden sparkles
      final sparklePaint = Paint()
        ..color = Colors.amber.shade300.withOpacity(0.7 + (swayAngle.abs() * 0.3))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(sparklePos, 2, sparklePaint);
      
      // Add a subtle glow effect
      final glowPaint = Paint()
        ..color = Colors.yellow.shade200.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(sparklePos, 4, glowPaint);
    }
    
    // Add fruits/flowers for the legendary tree
    _drawFruits(canvas, size, center);
  }

  void _drawFruits(Canvas canvas, Size size, Offset center) {
    final fruitCount = 8;
    final trunkHeight = size.height * (0.35 + growthLevel * 0.25);
    final trunkTop = Offset(center.dx, center.dy - trunkHeight);
    final canopyCenter = Offset(trunkTop.dx, trunkTop.dy - size.height * 0.12);
    final canopyRadius = size.width * 0.2; // Match the actual canopy size
    
    for (int i = 0; i < fruitCount; i++) {
      final angle = (i * 2 * math.pi) / fruitCount;
      // Position fruits closer to the canopy edge, within the actual canopy area
      final distance = canopyRadius * (0.7 + (i % 2) * 0.2);
      
      final fruitPos = Offset(
        canopyCenter.dx + distance * math.cos(angle) + (swayAngle * 8),
        canopyCenter.dy + distance * 0.6 * math.sin(angle),
      );
      
      // Draw colorful fruits
      final fruitColors = [Colors.red.shade400, Colors.orange.shade400, Colors.yellow.shade600];
      final fruitPaint = Paint()
        ..color = fruitColors[i % fruitColors.length]
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(fruitPos, 4, fruitPaint);
      
      // Add highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(fruitPos.dx - 1, fruitPos.dy - 1),
        1.5,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.growthLevel != growthLevel ||
        oldDelegate.swayAngle != swayAngle ||
        oldDelegate.leafCount != leafCount;
  }
  
}