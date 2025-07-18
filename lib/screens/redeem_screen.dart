import 'package:flutter/material.dart';

class RedeemScreen extends StatelessWidget {
  const RedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RewardItem> rewards = [
      RewardItem('Eco Tote Bag', 'assets/images/tote.png', 200),
      RewardItem('Metal Straw Set', 'assets/images/straw.png', 120),
      RewardItem('Plantable Pencil', 'assets/images/pencil.png', 90),
      RewardItem('Tree Planted In Your Name', 'assets/images/tree.png', 500),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Rewards", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 1,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildPointsCard(),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
              ),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Hero(
                  tag: reward.title,
                  child: _buildRewardCard(context, reward),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.greenAccent,
              blurRadius: 20,
              spreadRadius: 1,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Icon(Icons.stars, size: 40, color: Colors.white),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Green Points',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  '1,247 pts',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, RewardItem reward) {
    return GestureDetector(
      onTap: () => _showRewardDetail(context, reward),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(reward.image, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            Text(
              reward.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text('${reward.points} pts',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showRewardDetail(BuildContext context, RewardItem reward) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Hero(
                  tag: reward.title,
                  child: Image.asset(
                    reward.image,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  reward.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${reward.points} pts required',
                  style: TextStyle(color: Colors.green.shade600),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.redeem),
                  label: const Text("Redeem Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRedeemSuccessDialog(context, reward.title);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRedeemSuccessDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text("Redeemed Successfully"),
          ],
        ),
        content: Text("You've redeemed \"$title\". 🎉"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay"),
          ),
        ],
      ),
    );
  }
}

class RewardItem {
  final String title;
  final String image;
  final int points;

  RewardItem(this.title, this.image, this.points);
}
