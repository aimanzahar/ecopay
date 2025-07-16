import 'package:flutter/material.dart';

class EcoPayScreen extends StatefulWidget {
  const EcoPayScreen({super.key});

  @override
  State<EcoPayScreen> createState() => _EcoPayScreenState();
}

class _EcoPayScreenState extends State<EcoPayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'EcoPay',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildESGFeatures(),
            const SizedBox(height: 30),
            _buildCarbonTracker(),
            const SizedBox(height: 30),
            _buildGreenRewards(),
            const SizedBox(height: 30),
            _buildSustainabilityTips(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
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
          // Logo
          Image.asset(
            'assets/images/EcoPayIconremovebg.png',
            height: 120,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 20),

          Text(
            '🌱 Welcome to EcoPay',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Your sustainable payment solution',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '"Every ringgit you spend, the Earth thanks you 🌍"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: Colors.green.shade600,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatCard('127kg', 'CO₂ Saved', Colors.green.shade600, Icons.eco),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard('45', 'Green Transactions', Colors.green.shade600, Icons.nature_people),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildESGFeatures() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ESG Features', style: _sectionTitleStyle()),

          const SizedBox(height: 15),

          _buildFeatureCard('🌍 Environmental Impact', 'Track your carbon footprint and offset emissions', Colors.green.shade50, Icons.public),
          const SizedBox(height: 12),
          _buildFeatureCard('👥 Social Responsibility', 'Support local communities and social causes', Colors.blue.shade50, Icons.group),
          const SizedBox(height: 12),
          _buildFeatureCard('🏢 Corporate Governance', 'Transparent and ethical business practices', Colors.purple.shade50, Icons.business),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green.shade600, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _cardTitleStyle()),
                const SizedBox(height: 4),
                Text(description, style: _cardDescStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonTracker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.eco, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Carbon Footprint Tracker',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('This Month', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    SizedBox(height: 4),
                    Text('12.3 kg CO₂', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 8),
                    Text('↓ 23% vs last month', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              const Icon(Icons.local_florist, size: 80, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreenRewards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Green Rewards', style: _sectionTitleStyle()),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eco Points Available', style: _cardTitleStyle()),
                          const SizedBox(height: 4),
                          Text('1,247 points', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                          const SizedBox(height: 8),
                          const Text('Redeem for green products & services', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Redeem'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 1247 / 1500,
                  color: Colors.green,
                  backgroundColor: Colors.green.shade100,
                ),
                const SizedBox(height: 6),
                Text(
                  '253 points left to next reward!',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sustainability Tips', style: _sectionTitleStyle()),
          const SizedBox(height: 15),
          _buildTipCard('💡', 'Use digital receipts to save paper', 'Save up to 2.5kg CO₂ per year'),
          const SizedBox(height: 12),
          _buildTipCard('🚶‍♀️', 'Walk to nearby stores instead of driving', 'Reduce transport emissions by 65%'),
          const SizedBox(height: 12),
          _buildTipCard('♻️', 'Choose eco-friendly businesses', 'Support sustainable practices'),
        ],
      ),
    );
  }

  Widget _buildTipCard(String emoji, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _cardTitleStyle()),
                const SizedBox(height: 4),
                Text(description, style: _cardDescStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Typography styles
  TextStyle _sectionTitleStyle() => TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700);
  TextStyle _cardTitleStyle() => TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade700);
  TextStyle _cardDescStyle() => TextStyle(fontSize: 14, color: Colors.green.shade600);
}
