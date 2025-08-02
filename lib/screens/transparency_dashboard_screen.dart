import 'package:flutter/material.dart';
import 'dart:math';
import '../helpers/database_helper.dart';
import '../models/contribution.dart';
import '../models/project.dart';
import 'project_detail_screen.dart';

class TransparencyDashboardScreen extends StatefulWidget {
  const TransparencyDashboardScreen({super.key});

  @override
  State<TransparencyDashboardScreen> createState() => _TransparencyDashboardScreenState();
}

class _TransparencyDashboardScreenState extends State<TransparencyDashboardScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Contribution> _contributions = [];
  List<Map<String, dynamic>> _fundAllocation = [];
  bool _isLoading = true;
  double _totalContributed = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransparencyData();
  }

  Future<void> _loadTransparencyData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load user contributions (assuming user ID 1)
      final contributions = await _databaseHelper.getContributionsByUser(1);
      
      // DEBUG: Log contributions data
      print('DEBUG: Found ${contributions.length} contributions');
      for (var contrib in contributions) {
        print('DEBUG: Contribution - Amount: ${contrib.amount}, Timestamp: ${contrib.timestamp}');
      }
      
      // Calculate total contributed FIRST
      final totalContributed = contributions.fold<double>(
        0.0,
        (sum, contribution) => sum + contribution.amount
      );
      
      // DEBUG: Log total before setting instance variable
      print('DEBUG: Total contributed calculated: $totalContributed');
      print('DEBUG: Instance variable _totalContributed before update: $_totalContributed');
      
      // Set instance variable so _generateFundAllocation can use it
      _totalContributed = totalContributed;
      
      print('DEBUG: Instance variable _totalContributed after update: $_totalContributed');
      
      // Generate mock fund allocation data based on contributions
      final fundAllocation = _generateFundAllocation(contributions);
      
      // DEBUG: Log allocation results
      print('DEBUG: Generated ${fundAllocation.length} fund allocations');
      for (var allocation in fundAllocation) {
        print('DEBUG: ${allocation['name']}: ${allocation['totalAllocated']} (${(allocation['allocation'] * 100).toInt()}%)');
      }
      
      setState(() {
        _contributions = contributions;
        _fundAllocation = fundAllocation;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error in _loadTransparencyData: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateFundAllocation(List<Contribution> contributions) {
    final random = Random();
    
    // Generate random but realistic allocation percentages that sum to 100%
    List<double> baseAllocations = [0.28, 0.22, 0.25, 0.15, 0.10]; // Base percentages
    
    // Add some randomization to make it more realistic
    for (int i = 0; i < baseAllocations.length; i++) {
      double variation = (random.nextDouble() - 0.5) * 0.1; // ±5% variation
      baseAllocations[i] = (baseAllocations[i] + variation).clamp(0.05, 0.4);
    }
    
    // Normalize to ensure they sum to 1.0
    double sum = baseAllocations.reduce((a, b) => a + b);
    baseAllocations = baseAllocations.map((a) => a / sum).toList();

    // Mock projects with randomized allocation percentages and impact data
    final projectData = [
      {
        'id': 1,
        'name': 'Mangrove Restoration',
        'description': 'Planting mangrove trees in coastal areas to prevent erosion and support marine life',
        'icon': '🌲',
        'color': Colors.green,
        'allocation': baseAllocations[0],
        'impact': 'Trees Planted',
        'unitLabel': 'trees',
        'totalAllocated': 0.0,
        'targetAmount': 5000.0 + (random.nextDouble() * 2000), // Randomize target
        'currentProgress': 0.0,
        'impactPerRM': 0.15 + (random.nextDouble() * 0.1), // Random impact rate
        'fundingGoal': 'RM8,000',
        'fundingProgress': 0.0,
        'lastUpdate': 'Updated 2 days ago',
        'beneficiaries': '${150 + random.nextInt(100)} coastal communities',
      },
      {
        'id': 2,
        'name': 'Solar Panel Installation',
        'description': 'Install solar panels in rural schools to provide clean energy and reduce electricity costs',
        'icon': '☀️',
        'color': Colors.orange,
        'allocation': baseAllocations[1],
        'impact': 'Energy Generated',
        'unitLabel': 'kWh',
        'totalAllocated': 0.0,
        'targetAmount': 8000.0 + (random.nextDouble() * 3000),
        'currentProgress': 0.0,
        'impactPerRM': 3.5 + (random.nextDouble() * 1.0),
        'fundingGoal': 'RM12,000',
        'fundingProgress': 0.0,
        'lastUpdate': 'Updated 5 hours ago',
        'beneficiaries': '${25 + random.nextInt(15)} rural schools',
      },
      {
        'id': 3,
        'name': 'Clean Water Wells',
        'description': 'Build water filtration systems and wells for rural communities without access to clean water',
        'icon': '💧',
        'color': Colors.blue,
        'allocation': baseAllocations[2],
        'impact': 'Water Provided',
        'unitLabel': 'liters/day',
        'totalAllocated': 0.0,
        'targetAmount': 10000.0 + (random.nextDouble() * 4000),
        'currentProgress': 0.0,
        'impactPerRM': 45.0 + (random.nextDouble() * 15.0),
        'fundingGoal': 'RM15,000',
        'fundingProgress': 0.0,
        'lastUpdate': 'Updated 1 day ago',
        'beneficiaries': '${500 + random.nextInt(300)} people',
      },
      {
        'id': 4,
        'name': 'Ocean Cleanup',
        'description': 'Remove plastic waste from oceans and coastal areas to protect marine ecosystems',
        'icon': '🌊',
        'color': Colors.cyan,
        'allocation': baseAllocations[3],
        'impact': 'Plastic Removed',
        'unitLabel': 'kg',
        'totalAllocated': 0.0,
        'targetAmount': 3000.0 + (random.nextDouble() * 1500),
        'currentProgress': 0.0,
        'impactPerRM': 0.7 + (random.nextDouble() * 0.3),
        'fundingGoal': 'RM6,000',
        'fundingProgress': 0.0,
        'lastUpdate': 'Updated 3 hours ago',
        'beneficiaries': '${10 + random.nextInt(8)} marine protected areas',
      },
      {
        'id': 5,
        'name': 'Wildlife Protection',
        'description': 'Protect endangered species through habitat conservation and anti-poaching efforts',
        'icon': '🦋',
        'color': Colors.purple,
        'allocation': baseAllocations[4],
        'impact': 'Animals Protected',
        'unitLabel': 'animals',
        'totalAllocated': 0.0,
        'targetAmount': 2000.0 + (random.nextDouble() * 1000),
        'currentProgress': 0.0,
        'impactPerRM': 0.08 + (random.nextDouble() * 0.05),
        'fundingGoal': 'RM4,500',
        'fundingProgress': 0.0,
        'lastUpdate': 'Updated 6 hours ago',
        'beneficiaries': '${3 + random.nextInt(4)} protected species',
      },
    ];

    // Calculate allocations based on total contributions with some realistic progress
    for (var project in projectData) {
      final allocation = project['allocation'] as double;
      final targetAmount = project['targetAmount'] as double;
      final impactPerRM = project['impactPerRM'] as double;
      
      final allocated = _totalContributed * allocation;
      project['totalAllocated'] = allocated;
      
      // Simulate realistic progress (70-95% of allocated funds have been used)
      final usageRate = 0.7 + (random.nextDouble() * 0.25);
      final actuallyUsed = allocated * usageRate;
      
      project['currentProgress'] = actuallyUsed / targetAmount;
      project['impactAchieved'] = actuallyUsed * impactPerRM;
      project['fundingProgress'] = actuallyUsed;
      
      // Add some recent activity for realism
      project['recentActivity'] = _generateRecentActivity(project, random);
    }

    return projectData;
  }

  List<Map<String, dynamic>> _generateRecentActivity(Map<String, dynamic> project, Random random) {
    final activities = [
      'Funds disbursed to field team',
      'Equipment purchased and shipped',
      'Local partnerships established',
      'Project milestone achieved',
      'Community training completed',
      'Environmental impact assessment done',
      'New beneficiaries enrolled',
      'Progress report submitted',
    ];
    
    final recentActivity = <Map<String, dynamic>>[];
    final activityCount = 2 + random.nextInt(3); // 2-4 activities
    
    for (int i = 0; i < activityCount; i++) {
      recentActivity.add({
        'action': activities[random.nextInt(activities.length)],
        'date': '${random.nextInt(7) + 1} days ago',
        'amount': 'RM${(random.nextDouble() * 200 + 50).toStringAsFixed(2)}',
      });
    }
    
    return recentActivity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transparency Dashboard',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildFundAllocationSection(),
                  const SizedBox(height: 20),
                  _buildProjectDetails(),
                  const SizedBox(height: 20),
                  _buildImpactSummary(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.visibility,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Fund Transparency',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Total Contributed: RM${_totalContributed.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '100% Transparent • Real Impact',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundAllocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Fund Allocation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._fundAllocation.map((project) => _buildAllocationBar(project)),
        ],
      ),
    );
  }

  Widget _buildAllocationBar(Map<String, dynamic> project) {
    final percentage = (project['allocation'] * 100).toInt();
    final allocated = project['totalAllocated'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    project['icon'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$percentage% • RM${allocated.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: project['color'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: project['allocation'],
              child: Container(
                decoration: BoxDecoration(
                  color: project['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Impact Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ..._fundAllocation.map((project) => _buildProjectCard(project)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final progress = project['currentProgress'].clamp(0.0, 1.0);
    final impactAchieved = project['impactAchieved'];
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(project: project),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: project['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project['icon'],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        project['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress: ${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'RM${project['totalAllocated'].toStringAsFixed(2)} allocated',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(project['color']),
              minHeight: 6,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: project['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Impact Achieved:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: project['color'],
                    ),
                  ),
                  Text(
                    '${impactAchieved.toStringAsFixed(1)} ${project['unitLabel']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: project['color'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  project['lastUpdate'],
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                Text(
                  '👥 ${project['beneficiaries']}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.eco,
            size: 40,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Impact Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '${_contributions.length}',
                'Transactions',
                Icons.payment,
                Colors.blue,
              ),
              _buildSummaryItem(
                '${_fundAllocation.length}',
                'Projects',
                Icons.eco,
                Colors.green,
              ),
              _buildSummaryItem(
                '100%',
                'Transparent',
                Icons.visibility,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🌍 Every ringgit you contribute goes directly to verified environmental projects. Track your impact in real-time!',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}