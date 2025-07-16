import 'package:flutter/material.dart';

class LocalProjectsScreen extends StatelessWidget {
  const LocalProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Malaysia\'s Environment'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildProjectCard(
              context: context,
              title: 'Langkawi Mangrove Recovery',
              donation: 'RM 2.50 = 1m² mangrove protected',
              status: '847m² protected this week',
              color: Colors.blue.shade100,
            ),
            _buildProjectCard(
              context: context,
              title: 'Sepilok Orangutan Sanctuary',
              donation: 'RM 5.00 = 1 day food for orangutan',
              status: '23 orangutans helped',
              color: Colors.orange.shade100,
            ),
            _buildProjectCard(
              context: context,
              title: 'KL City Centre Tree Planting',
              donation: 'RM 3.80 = 1 tree planted & maintained',
              status: '156 trees planted in TRX',
              color: Colors.green.shade100,
            ),
            _buildProjectCard(
              context: context,
              title: 'Orang Asli Solar Power Program',
              donation: 'RM 10.00 = 1 week clean energy',
              status: '12 villages powered',
              color: Colors.yellow.shade100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard({
    required BuildContext context,
    required String title,
    required String donation,
    required String status,
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(donation, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.show_chart, size: 20),
                const SizedBox(width: 8),
                Text(status, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}