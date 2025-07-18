import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../utils/environmental_impact_calculator.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _contributions = [];
  List<Map<String, dynamic>> _filteredContributions = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _selectedSortBy = 'date';
  String _selectedProjectFilter = 'all';
  DateTimeRange? _selectedDateRange;
  double _minAmount = 0;
  double _maxAmount = 1000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialize sample data
      await _databaseHelper.insertSampleProjects();
      await _databaseHelper.insertSampleContributions(1);
      
      // Load contributions with project details
      final contributions = await _databaseHelper.getContributionsWithProjectDetails(1);
      final statistics = await _databaseHelper.getContributionStatistics(1);
      
      setState(() {
        _contributions = contributions;
        _filteredContributions = contributions;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredContributions = List<Map<String, dynamic>>.from(_contributions.where((contribution) {
        // Project filter
        if (_selectedProjectFilter != 'all' &&
            contribution['project_name'] != _selectedProjectFilter) {
          return false;
        }
        
        // Amount filter
        final amount = contribution['amount'] as double;
        if (amount < _minAmount || amount > _maxAmount) {
          return false;
        }
        
        // Date range filter
        if (_selectedDateRange != null) {
          final timestamp = DateTime.parse(contribution['timestamp']);
          if (timestamp.isBefore(_selectedDateRange!.start) ||
              timestamp.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }
        
        return true;
      }).toList());
      
      _sortContributions();
    });
  }

  void _sortContributions() {
    setState(() {
      _filteredContributions.sort((a, b) {
        switch (_selectedSortBy) {
          case 'date':
            return DateTime.parse(b['timestamp'])
                .compareTo(DateTime.parse(a['timestamp']));
          case 'amount':
            return (b['amount'] as double).compareTo(a['amount'] as double);
          case 'impact':
            final impactA = EnvironmentalImpactCalculator.calculateCO2Offset(a['amount']);
            final impactB = EnvironmentalImpactCalculator.calculateCO2Offset(b['amount']);
            return impactB.compareTo(impactA);
          case 'project':
            return (a['project_name'] as String).compareTo(b['project_name'] as String);
          default:
            return 0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Contribution History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildStatisticsCard(),
                  _buildFilterChips(),
                  Expanded(
                    child: _filteredContributions.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredContributions.length,
                            itemBuilder: (context, index) {
                              final contribution = _filteredContributions[index];
                              return _buildContributionCard(contribution);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

Widget _buildStatisticsCard() {
  if (_statistics.isEmpty) return const SizedBox.shrink();

  final totalDonated = _statistics['total_donated'] as double? ?? 0.0;
  final totalContributions = _statistics['total_contributions'] as int? ?? 0;
  final projectsSupported = _statistics['projects_supported'] as int? ?? 0;
  final aggregatedImpact = EnvironmentalImpactCalculator.getAggregatedImpact(
    _contributions.map((c) => {'amount': c['amount']}).toList(),
  );

  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.emoji_nature, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'Your Environmental Impact',
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
              child: _enhancedStatItem(
                icon: Icons.account_balance_wallet,
                value: 'RM${totalDonated.toStringAsFixed(2)}',
                label: 'Total Donated',
              ),
            ),
            Expanded(
              child: _enhancedStatItem(
                icon: Icons.eco,
                value: '${aggregatedImpact['total_co2_offset_kg'].toStringAsFixed(1)}kg',
                label: 'CO₂ Offset',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _enhancedStatItem(
                icon: Icons.volunteer_activism,
                value: '$totalContributions',
                label: 'Contributions',
              ),
            ),
            Expanded(
              child: _enhancedStatItem(
                icon: Icons.park,
                value: '$projectsSupported',
                label: 'Projects Supported',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _enhancedStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Date', 'date'),
                  _buildSortChip('Amount', 'amount'),
                  _buildSortChip('Impact', 'impact'),
                  _buildSortChip('Project', 'project'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedSortBy == value,
        onSelected: (selected) {
          setState(() {
            _selectedSortBy = value;
            _sortContributions();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.green[100],
        checkmarkColor: Colors.green[700],
      ),
    );
  }

  Widget _buildContributionCard(Map<String, dynamic> contribution) {
    final amount = contribution['amount'] as double;
    final projectName = contribution['project_name'] as String? ?? 'Unknown Project';
    final projectDescription = contribution['project_description'] as String? ?? '';
    final timestamp = DateTime.parse(contribution['timestamp']);
    final impact = EnvironmentalImpactCalculator.getProjectImpact(projectName, amount);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showContributionDetails(contribution),
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getProjectIcon(projectName),
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          projectDescription,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        _formatDate(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildImpactItem(
                        '${impact['co2_offset_kg'].toStringAsFixed(1)}kg',
                        'CO₂ Offset',
                        Icons.eco,
                      ),
                    ),
                    Expanded(
                      child: _buildImpactItem(
                        '${impact['water_saved_liters'].toStringAsFixed(0)}L',
                        'Water Saved',
                        Icons.water_drop,
                      ),
                    ),
                    Expanded(
                      child: _buildImpactItem(
                        '${(impact['tree_equivalent'] * 100).toStringAsFixed(0)}%',
                        'Tree Equiv.',
                        Icons.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700], size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No contributions yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start making a difference today!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProjectIcon(String projectName) {
    switch (projectName.toLowerCase()) {
      case 'mangrove restoration':
        return Icons.water;
      case 'solar panel installation':
        return Icons.solar_power;
      case 'clean water wells':
        return Icons.water_drop;
      case 'rainforest conservation':
        return Icons.forest;
      case 'ocean cleanup':
        return Icons.waves;
      default:
        return Icons.eco;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Contributions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Project Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedProjectFilter,
                    isExpanded: true,
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedProjectFilter = value ?? 'all';
                      });
                    },
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All Projects')),
                      ..._contributions
                          .map((c) => c['project_name'] as String?)
                          .where((name) => name != null)
                          .toSet()
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name!),
                              )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Amount Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _minAmount.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Min Amount',
                            prefixText: 'RM',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _minAmount = double.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _maxAmount.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Max Amount',
                            prefixText: 'RM',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _maxAmount = double.tryParse(value) ?? 1000;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final dateRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _selectedDateRange,
                            );
                            if (dateRange != null) {
                              setDialogState(() {
                                _selectedDateRange = dateRange;
                              });
                            }
                          },
                          child: Text(_selectedDateRange == null
                              ? 'Select Date Range'
                              : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'),
                        ),
                      ),
                      if (_selectedDateRange != null)
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedDateRange = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedProjectFilter = 'all';
                    _minAmount = 0;
                    _maxAmount = 1000;
                    _selectedDateRange = null;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _applyFilters();
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContributionDetails(Map<String, dynamic> contribution) {
    final amount = contribution['amount'] as double;
    final projectName = contribution['project_name'] as String? ?? 'Unknown Project';
    final projectDescription = contribution['project_description'] as String? ?? 'No description available';
    final costPerUnit = contribution['cost_per_unit'] as double? ?? 0.0;
    final unitLabel = contribution['unit_label'] as String? ?? 'unit';
    final timestamp = DateTime.parse(contribution['timestamp']);
    final transactionId = contribution['transaction_id'] as String? ?? 'N/A';
    final impact = EnvironmentalImpactCalculator.getProjectImpact(projectName, amount);
    
    final unitsContributed = costPerUnit > 0 ? amount / costPerUnit : 0.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getProjectIcon(projectName),
                      color: Colors.green[700],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RM${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Project Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                projectDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environmental Impact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailImpactItem(
                            '${impact['co2_offset_kg'].toStringAsFixed(2)}kg',
                            'CO₂ Offset',
                            Icons.eco,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailImpactItem(
                            '${impact['water_saved_liters'].toStringAsFixed(0)}L',
                            'Water Saved',
                            Icons.water_drop,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailImpactItem(
                            '${impact['energy_saved_kwh'].toStringAsFixed(1)}kWh',
                            'Energy Saved',
                            Icons.bolt,
                          ),
                        ),
                        Expanded(
                          child: _buildDetailImpactItem(
                            '${unitsContributed.toStringAsFixed(1)}',
                            unitLabel,
                            Icons.straighten,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailInfoItem('Date', _formatDate(timestamp)),
                  ),
                  Expanded(
                    child: _buildDetailInfoItem('Transaction ID', transactionId),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement share functionality
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share functionality coming soon!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                      child: const Text('Share Impact', style: TextStyle(color: Colors.white)),
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

  Widget _buildDetailImpactItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}