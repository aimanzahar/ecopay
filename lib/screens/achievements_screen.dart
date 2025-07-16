import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Eco Achievements'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionTitle('UNLOCKED BADGES'),
            _buildAchievementBadge(
              emoji: '🌱',
              title: 'Eco Warrior',
              description: '(100 green purchases)',
            ),
            _buildAchievementBadge(
              emoji: '🌊',
              title: 'Mangrove Guardian',
              description: '(RM 50 donated)',
            ),
            _buildAchievementBadge(
              emoji: '🚗',
              title: 'Car-Free Champion',
              description: '(10 e-hailing)',
            ),
            _buildAchievementBadge(
              emoji: '☕',
              title: 'Conscious Coffee',
              description: '(20 sustainable cafés)',
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('NEXT TARGETS'),
            _buildTargetCard(
              title: '🌳 Forest Protector (Plant 50 trees)',
              progress: 'Progress: 12/50 trees',
              reward: 'Reward: Virtual forest tour + RM 50',
            ),
            _buildTargetCard(
              title: '🏙️ Urban Green Hero (KL impact focus)',
              progress: 'Progress: 67% completed',
              reward: 'Reward: Mayor appreciation letter',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  Widget _buildAchievementBadge({
    required String emoji,
    required String title,
    required String description,
  }) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 28)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description),
    );
  }

  Widget _buildTargetCard({
    required String title,
    required String progress,
    required String reward,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(progress),
            const SizedBox(height: 12),
            Text(reward, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}