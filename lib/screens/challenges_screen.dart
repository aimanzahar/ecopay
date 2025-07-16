import 'package:flutter/material.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sustainable Living Challenges'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildChallengeCard(
              context: context,
              title: 'Ramadan Green Challenge',
              status: 'Active',
              description: '"Reduce food waste during iftar"',
              progress: '15/30 days completed',
              reward: 'Reward: RM 20 voucher for organic food at Village Grocer',
              color: Colors.green.shade100,
            ),
            _buildChallengeCard(
              context: context,
              title: 'CNY Eco-Celebration',
              status: 'Starts: Jan 25th',
              description: '"Digital ang pow instead of paper"',
              progress: '',
              reward: 'Reward: Exclusive TnG e-ang pow design + tree planting',
              color: Colors.red.shade100,
            ),
            _buildChallengeCard(
              context: context,
              title: 'Merdeka Green Malaysia',
              status: 'Current participants: 12,847',
              description: '"31 days of sustainable choices"',
              progress: '',
              reward: 'Reward: Meet PM at tree planting ceremony (top 100 winners)',
              color: Colors.blue.shade100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard({
    required BuildContext context,
    required String title,
    required String status,
    required String description,
    required String progress,
    required String reward,
    required Color color,
  }) {
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(status, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            if (progress.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(progress),
            ],
            const SizedBox(height: 12),
            Text(reward, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}