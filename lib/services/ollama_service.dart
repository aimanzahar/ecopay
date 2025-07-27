import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../helpers/database_helper.dart';
import '../models/user.dart';
import '../models/contribution.dart';
import '../models/balance.dart';
import '../models/transaction.dart' as AppTransaction;

class OllamaService {
  final String baseUrl;
  final String model;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  OllamaService({
    this.baseUrl = 'http://zahar.my:11434',
    this.model = 'Gemma3:latest',
  });

  /// Generate selective context based on user question
  Future<String> _generateSelectiveContext(int userId, String userMessage) async {
    try {
      final message = userMessage.toLowerCase();
      
      // Only fetch relevant data based on user's question
      if (message.contains('balance') || message.contains('money') || message.contains('wallet')) {
        final balance = await _databaseHelper.getBalance();
        return 'Current Balance: RM ${balance.amount.toStringAsFixed(2)}';
      }
      
      if (message.contains('carbon') || message.contains('co2') || message.contains('environment')) {
        final contributions = await _databaseHelper.getContributionsByUser(userId);
        final totalDonated = contributions.fold(0.0, (sum, contrib) => sum + contrib.amount);
        final co2Saved = totalDonated * 0.12;
        return 'Environmental Impact: RM ${totalDonated.toStringAsFixed(2)} donated, ${co2Saved.toStringAsFixed(1)} kg CO₂ saved';
      }
      
      if (message.contains('point') || message.contains('reward')) {
        final totalPoints = await _databaseHelper.getUserTotalPoints(userId);
        return 'Green Points: $totalPoints points available for rewards';
      }
      
      if (message.contains('transaction') || message.contains('history')) {
        final transactions = await _databaseHelper.getTransactions();
        return 'Recent Transactions: ${transactions.length} total transactions';
      }
      
      // Default minimal context for general questions
      return 'EcoPay: Sustainable e-wallet with CO₂ tracking and green rewards';
    } catch (e) {
      return 'EcoPay: Sustainable e-wallet application';
    }
  }

  /// Generate comprehensive context about the user's EcoPay data (legacy method)
  Future<String> _generateEcoPayContext(int userId) async {
    try {
      // Get user information
      final user = await _databaseHelper.getUser(userId);
      final balance = await _databaseHelper.getBalance();
      final contributions = await _databaseHelper.getContributionsByUser(userId);
      final transactions = await _databaseHelper.getTransactions();
      final contributionStats = await _databaseHelper.getContributionStatistics(userId);
      final monthlyContributions = await _databaseHelper.getMonthlyContributions(userId);
      final totalPoints = await _databaseHelper.getUserTotalPoints(userId);
      final pointsHistory = await _databaseHelper.getUserPointsHistory(userId);
      final challengeProgress = await _databaseHelper.getUserChallengeProgress(userId);
      final notifications = await _databaseHelper.getUserNotifications(userId);

      // Calculate environmental impact
      final totalDonated = contributions.fold(0.0, (sum, contrib) => sum + contrib.amount);
      final co2Saved = totalDonated * 0.12; // 0.12kg CO2 per RM donated
      final treesEquivalent = (totalDonated / 5.0).floor(); // 1 tree per RM 5 donated

      final context = '''
=== ECOPAY USER PROFILE & ESG DATA ===

USER INFORMATION:
- Name: ${user?.name ?? 'Default User'}
- Username: ${user?.username ?? 'N/A'}
- Email: ${user?.email ?? 'N/A'}
- User Level: ${user?.level ?? 1}
- Total Points Earned: $totalPoints
- EcoPay Opt-in Status: ${user?.ecopayOptIn == true ? 'ACTIVE' : 'INACTIVE'}
- Account Created: ${user?.createdAt?.toString() ?? 'N/A'}
- Last Active: ${user?.lastActive?.toString() ?? 'N/A'}
- Badges Earned: ${user?.badgesList.join(', ') ?? 'None'}

WALLET & FINANCIAL DATA:
- Current Balance: RM ${balance.amount.toStringAsFixed(2)}
- Balance Last Updated: ${balance.lastUpdated}
- Total Transactions: ${transactions.length}
- Recent Transactions: ${transactions.take(5).map((t) => '${t.merchantName}: ${t.getFormattedAmount()} on ${t.getFormattedDate()}').join('; ')}

ESG CONTRIBUTIONS & ENVIRONMENTAL IMPACT:
- Total Environmental Contributions: ${contributions.length} transactions
- Total Amount Donated: RM ${totalDonated.toStringAsFixed(2)}
- CO₂ Emissions Saved: ${co2Saved.toStringAsFixed(2)} kg
- Trees Equivalent Impact: $treesEquivalent trees planted/saved
- Projects Supported: ${contributionStats['projects_supported'] ?? 0}
- First Contribution Date: ${contributionStats['first_contribution'] ?? 'N/A'}
- Latest Contribution Date: ${contributionStats['latest_contribution'] ?? 'N/A'}

MONTHLY CONTRIBUTION TRENDS:
${monthlyContributions.take(6).map((month) => '${month['month']}: RM ${(month['total_amount'] ?? 0).toStringAsFixed(2)} (${month['contribution_count']} contributions)').join('\n')}

GAMIFICATION & ACHIEVEMENTS:
- Current Points: $totalPoints
- User Level: ${user?.level ?? 1}
- Active Challenges: ${challengeProgress.length}
- Challenge Progress: ${challengeProgress.map((c) => '${c['title']}: ${c['current_progress']}/${c['target_value']} ${c['target_unit']}').join('; ')}

RECENT POINTS ACTIVITY:
${pointsHistory.take(5).map((p) => '${p['points_earned']} points from ${p['points_source']} on ${DateTime.parse(p['timestamp']).toString().split(' ')[0]}').join('\n')}

SUSTAINABILITY METRICS:
- Carbon Footprint Reduction: ${co2Saved.toStringAsFixed(1)} kg CO₂ saved
- Environmental Projects Impact: Supporting ${contributionStats['projects_supported']} different green projects
- Consistency Score: ${contributions.length > 10 ? 'High' : contributions.length > 5 ? 'Medium' : 'Low'} (based on ${contributions.length} contributions)
- Green Rewards Available: ${(totalPoints / 100).floor()} reward tiers unlocked

RECENT NOTIFICATIONS:
${notifications.take(3).map((n) => '${n['title']}: ${n['message']}').join('\n')}

ECOPAY FEATURES CONTEXT:
- Round-up donations to environmental projects
- Carbon footprint tracking and CO₂ savings calculation
- Gamified sustainability with points, levels, and challenges
- ESG (Environmental, Social, Governance) focus
- Real-time impact visualization
- Green rewards redemption system
- Community leaderboards for sustainable practices
- Achievement system for environmental milestones

=== END CONTEXT ===
''';

      return context;
    } catch (e) {
      print('Error generating EcoPay context: $e');
      return '''
=== ECOPAY BASIC CONTEXT ===
EcoPay is a sustainability-focused e-wallet application that helps users:
- Make environmentally conscious payments
- Track their carbon footprint reduction
- Earn points for sustainable choices
- Support verified green projects through round-up donations
- Participate in environmental challenges and achievements

The user is currently using the EcoPay chat assistant for help with their sustainable journey.
=== END CONTEXT ===
''';
    }
  }

  /// Send a chat message to Ollama with conversation history
  Future<String> sendChatMessage(String userMessage, int userId, [List<Map<String, String>>? conversationHistory]) async {
    try {
      // Generate selective context based on user question
      final relevantContext = await _generateSelectiveContext(userId, userMessage);
      
      // Build conversation history for context
      String conversationContext = '';
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        conversationContext = '\n\nPREVIOUS CONVERSATION:\n';
        // Only include last 4 messages to keep context manageable
        final recentHistory = conversationHistory.take(8).toList();
        for (var msg in recentHistory) {
          conversationContext += '${msg['role']}: ${msg['content']}\n';
        }
        conversationContext += '\n';
      }

      // Create a concise, focused system prompt
      final systemPrompt = '''
You are EcoPay Assistant 🌱 - a friendly, concise AI helper for sustainable e-wallet users.

TONE: Warm, encouraging, brief. Use emojis sparingly. Keep responses short and focused.

$relevantContext$conversationContext

USER: "$userMessage"

Respond helpfully and concisely. Only mention specific data if directly relevant to their question.
''';

      final requestBody = {
        'model': model,
        'prompt': systemPrompt,
        'stream': false,
        'options': {
          'temperature': 0.7,
          'num_predict': 300, // Reduced for shorter responses
          'top_p': 0.9,
          'repeat_penalty': 1.1,
          'stop': ['\n\nUSER:', 'Human:', 'User:'], // Stop tokens to prevent repetition
        }
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final botResponse = responseData['response'] as String;
        
        if (botResponse.trim().isEmpty) {
          return _getFallbackResponse(userMessage);
        }
        
        return botResponse.trim();
      } else {
        print('Ollama API error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(userMessage);
      }
    } on SocketException catch (e) {
      print('Network error connecting to Ollama: $e');
      return "🌐 I'm having trouble connecting to my AI brain right now. Please check if the Ollama server is running and try again. In the meantime, let me help you with some basic EcoPay information!";
    } on http.ClientException catch (e) {
      print('HTTP client error: $e');
      return _getFallbackResponse(userMessage);
    } catch (e) {
      print('Unexpected error in Ollama service: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  /// Fallback responses when Ollama is unavailable
  String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('carbon') || message.contains('co2') || message.contains('environment')) {
      return "🌍 Great question about environmental impact! Based on your EcoPay contributions, you're making a real difference. Every transaction through EcoPay helps fund verified green projects. Keep using sustainable payment methods to maximize your positive environmental impact!";
    } else if (message.contains('reward') || message.contains('point')) {
      return "⭐ Your green points are earned through sustainable transactions and environmental contributions! You can redeem them for eco-friendly products and services in the Rewards section. Keep making green choices to earn more points!";
    } else if (message.contains('tip') || message.contains('help') || message.contains('advice')) {
      return "💡 Here are some eco-friendly tips for your EcoPay journey:\n• Use digital receipts to reduce paper waste\n• Walk or cycle for nearby purchases\n• Choose businesses with green certifications\n• Enable round-up donations for automatic contributions\n• Track your monthly CO₂ savings progress!";
    } else if (message.contains('balance') || message.contains('money')) {
      return "💰 I can help you understand your EcoPay wallet! Your sustainable spending choices are making a positive environmental impact. Check your balance and recent green transactions in the main dashboard.";
    } else if (message.contains('challenge') || message.contains('achievement')) {
      return "🏆 EcoPay challenges help you build sustainable habits! Complete environmental challenges to earn points, unlock achievements, and climb the green leaderboard. Every small action contributes to a bigger impact!";
    } else {
      return "🌱 I'm here to help you with your EcoPay sustainable journey! I can assist with questions about your environmental impact, green rewards, sustainability tips, and eco-friendly features. What would you like to know more about?";
    }
  }

  /// Check if Ollama server is available
  Future<bool> isServerAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Ollama server availability check failed: $e');
      return false;
    }
  }

  /// Get available models from Ollama server
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        return models.map((model) => model['name'] as String).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching available models: $e');
      return [];
    }
  }
}