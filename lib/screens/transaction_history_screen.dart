import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/transaction.dart' as AppTransaction;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<AppTransaction.Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });
    final transactions = await _databaseHelper.getTransactions();
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Green Journey'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week: RM ${_calculateWeeklyContribution().toStringAsFixed(2)} contributed',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '🌍 Real impact in Malaysia:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return _buildTransactionStory(
                          date: transaction.getFormattedDateTime(),
                          details: '${transaction.merchantName} - ${transaction.getFormattedAmount()}',
                          story: _getStoryForTransaction(transaction),
                          actionText: 'View Details',
                          onAction: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double _calculateWeeklyContribution() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _transactions
        .where((t) => t.transactionDate.isAfter(startOfWeek))
        .fold(0.0, (sum, item) => sum + (double.tryParse(item.notes ?? '0.0') ?? 0.0));
  }

  String _getStoryForTransaction(AppTransaction.Transaction transaction) {
    // This is a placeholder for a more sophisticated storytelling logic
    final ecoPayAmount = double.tryParse(transaction.notes ?? '0.0') ?? 0.0;
    if (ecoPayAmount > 0) {
      return '🌿 "Your contribution is making a difference!"';
    }
    return 'A regular transaction.';
  }

  Widget _buildTransactionStory({
    required String date,
    required String details,
    required String story,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(details),
            const SizedBox(height: 12),
            Text(story, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}