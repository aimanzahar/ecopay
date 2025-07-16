import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/contribution.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Contribution> _contributions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    setState(() {
      _isLoading = true;
    });
    // Assuming user ID 1 for this example
    final contributions = await _databaseHelper.getContributionsByUser(1);
    setState(() {
      _contributions = contributions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contributions.length,
              itemBuilder: (context, index) {
                final contribution = _contributions[index];
                return ListTile(
                  leading: const Icon(Icons.park, color: Colors.green),
                  title: Text('RM ${contribution.amount.toStringAsFixed(2)}'),
                  subtitle: Text(contribution.timestamp.toString()),
                );
              },
            ),
    );
  }
}