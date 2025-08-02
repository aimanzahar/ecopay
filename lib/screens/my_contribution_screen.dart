import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/contribution.dart';
import '../utils/environmental_impact_calculator.dart';
import 'transparency_dashboard_screen.dart';

class MyContributionScreen extends StatefulWidget {
  const MyContributionScreen({super.key});

  @override
  State<MyContributionScreen> createState() => _MyContributionScreenState();
}

class _MyContributionScreenState extends State<MyContributionScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Contribution> _contributions = [];
  Map<String, dynamic> _aggregatedImpact = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Assuming user ID 1 for this example
      final contributions = await _databaseHelper.getContributionsByUser(1);
      
      // Convert contributions to the format expected by the calculator
      final contributionMaps = contributions.map((c) => {
        'amount': c.amount,
        'timestamp': c.timestamp.toIso8601String(),
        'project_id': c.projectId,
      }).toList();
      
      final aggregated = EnvironmentalImpactCalculator.getAggregatedImpact(contributionMaps);
      
      setState(() {
        _contributions = contributions;
        _aggregatedImpact = aggregated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Contribution',
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
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildImpactGrid(),
                  const SizedBox(height: 30),
                  _buildDetailedStats(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final totalAmount = _aggregatedImpact['total_amount'] ?? 0.0;
    final contributionCount = _aggregatedImpact['contribution_count'] ?? 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
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
            Icons.eco,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'My Environmental Impact',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Total Contributed: RM${totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$contributionCount Green Transactions',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              '🌱 Every contribution makes a difference!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactGrid() {
    final totalAmount = _aggregatedImpact['total_amount'] ?? 0.0;
    
    final impactItems = [
      {
        'icon': '🌍',
        'title': 'CO₂ Offset',
        'value': EnvironmentalImpactCalculator.formatCO2Impact(totalAmount),
        'color': Colors.green,
      },
      {
        'icon': '💧',
        'title': 'Water Saved',
        'value': EnvironmentalImpactCalculator.formatWaterImpact(totalAmount),
        'color': Colors.blue,
      },
      {
        'icon': '🌳',
        'title': 'Trees Planted',
        'value': EnvironmentalImpactCalculator.formatTreeImpact(totalAmount),
        'color': Colors.green.shade700,
      },
      {
        'icon': '⚡',
        'title': 'Energy Saved',
        'value': EnvironmentalImpactCalculator.formatEnergyImpact(totalAmount),
        'color': Colors.orange,
      },
      {
        'icon': '🍶',
        'title': 'Plastic Bottles',
        'value': EnvironmentalImpactCalculator.formatPlasticBottlesImpact(totalAmount),
        'color': Colors.red,
      },
      {
        'icon': '🌊',
        'title': 'River Cleaned',
        'value': EnvironmentalImpactCalculator.formatRiverCleanedImpact(totalAmount),
        'color': Colors.cyan,
      },
      {
        'icon': '🦋',
        'title': 'Wildlife Protected',
        'value': EnvironmentalImpactCalculator.formatWildlifeProtectedImpact(totalAmount),
        'color': Colors.purple,
      },
      {
        'icon': '🌬️',
        'title': 'Air Quality',
        'value': EnvironmentalImpactCalculator.formatAirQualityImpact(totalAmount),
        'color': Colors.lightBlue,
      },
      {
        'icon': '🌱',
        'title': 'Soil Restored',
        'value': EnvironmentalImpactCalculator.formatSoilRestoredImpact(totalAmount),
        'color': Colors.brown,
      },
      {
        'icon': '☀️',
        'title': 'Solar Panels',
        'value': EnvironmentalImpactCalculator.formatSolarPanelsImpact(totalAmount),
        'color': Colors.yellow.shade700,
      },
      {
        'icon': '👣',
        'title': 'Carbon Footprint',
        'value': EnvironmentalImpactCalculator.formatCarbonFootprintImpact(totalAmount),
        'color': Colors.grey.shade700,
      },
      {
        'icon': '🌿',
        'title': 'Biodiversity',
        'value': EnvironmentalImpactCalculator.formatBiodiversityImpact(totalAmount),
        'color': Colors.teal,
      },
      {
        'icon': '🗑️',
        'title': 'Waste Diverted',
        'value': EnvironmentalImpactCalculator.formatWasteDivertedImpact(totalAmount),
        'color': Colors.indigo,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: impactItems.length,
        itemBuilder: (context, index) {
          final item = impactItems[index];
          return _buildImpactCard(
            item['icon'] as String,
            item['title'] as String,
            item['value'] as String,
            item['color'] as Color,
          );
        },
      ),
    );
  }

  Widget _buildImpactCard(String icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    final totalAmount = _aggregatedImpact['total_amount'] ?? 0.0;
    
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
                Icons.analytics,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Impact Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow('Total Contributions', '${_contributions.length}'),
          _buildStatRow('Total Amount', 'RM${totalAmount.toStringAsFixed(2)}'),
          _buildStatRow('Average per Transaction', _contributions.isNotEmpty 
              ? 'RM${(totalAmount / _contributions.length).toStringAsFixed(2)}'
              : 'RM0.00'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade400],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                '🌍 Thank you for making a difference!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Transparency Dashboard Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransparencyDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.visibility,
                color: Colors.white,
              ),
              label: const Text(
                'Transparency Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}