import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selangor Sustainability Leaderboard'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildLeaderboardHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildLeaderboardList(),
            ),
            const SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader() {
    return const Text(
      "This Week's Green Champions:",
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLeaderboardList() {
    return ListView(
      children: [
        _buildLeaderboardEntry('🥇', 'Ahmad_KL', '24.5kg CO₂ saved', isYou: false),
        _buildLeaderboardEntry('🥈', 'LilyPJ', '19.8kg CO₂ saved', isYou: false),
        _buildLeaderboardEntry('🥉', 'RahmanUSJ', '17.2kg CO₂ saved', isYou: false),
        _buildLeaderboardEntry('4️⃣', 'Sarah_SSTwo', '15.2kg CO₂ saved', isYou: true),
        _buildLeaderboardEntry('5️⃣', 'Danny_Subang', '14.1kg CO₂ saved', isYou: false),
      ],
    );
  }

  Widget _buildLeaderboardEntry(String rank, String name, String score, {required bool isYou}) {
    return Card(
      color: isYou ? Colors.green.shade100 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(rank, style: const TextStyle(fontSize: 24)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(score, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          '🎯 Beat RahmanUSJ to win bronze! Only 2.0kg CO₂ to go!',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.share),
          label: const Text('Share EcoPay'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}