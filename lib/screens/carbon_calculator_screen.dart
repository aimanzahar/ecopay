import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ollama_service.dart';
import '../helpers/database_helper.dart';
import '../models/user.dart';

// Color Scheme Constants
const Color primaryGreen = Color(0xFF2E7D32);
const Color lightGreen = Color(0xFFA5D6A7);
const Color darkGreen = Color(0xFF1B5E20);
const Color textPrimary = Color(0xFF263238);
const Color textSecondary = Color(0xFF607D8B);
const Color accentBlue = Color(0xFF1976D2);

class CarbonCalculatorScreen extends StatefulWidget {
  const CarbonCalculatorScreen({super.key});

  @override
  State<CarbonCalculatorScreen> createState() => _CarbonCalculatorScreenState();
}

class _CarbonCalculatorScreenState extends State<CarbonCalculatorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final OllamaService _ollamaService = OllamaService();
  
  double _calculatedCarbon = 0.0;
  double _carbonPerRM = 0.084; // Base carbon footprint per RM1 (kg CO2)
  bool _isCalculating = false;
  bool _showResults = false;
  String _selectedCategory = 'General';
  
  User? _user;
  List<ChatMessage> _chatMessages = [];
  bool _isChatting = false;
  bool _serverAvailable = false;
  
  late AnimationController _resultAnimationController;
  late Animation<double> _resultScaleAnimation;
  
  // Carbon footprint factors by category (kg CO2 per RM)
  final Map<String, double> _carbonFactors = {
    'General': 0.084,
    'Transportation': 0.156,
    'Food & Dining': 0.067,
    'Utilities': 0.198,
    'Shopping': 0.045,
    'Entertainment': 0.032,
    'Healthcare': 0.089,
    'Education': 0.023,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkServerAvailability();
    
    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _resultScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await _databaseHelper.getUser(1);
    setState(() {
      _user = user;
    });
  }

  Future<void> _checkServerAvailability() async {
    final isAvailable = await _ollamaService.isServerAvailable();
    setState(() {
      _serverAvailable = isAvailable;
    });
  }

  void _calculateCarbon() {
    if (_amountController.text.isEmpty) return;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount greater than 0');
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    // Simulate calculation delay for better UX
    Future.delayed(const Duration(milliseconds: 800), () {
      final carbonFactor = _carbonFactors[_selectedCategory] ?? _carbonPerRM;
      setState(() {
        _calculatedCarbon = amount * carbonFactor;
        _isCalculating = false;
        _showResults = true;
      });
      
      _resultAnimationController.forward();
      _addSystemMessage(
        'I calculated your carbon footprint for RM$amount in $_selectedCategory category. '
        'Would you like me to suggest ways to reduce your environmental impact?'
      );
    });
  }

  void _addSystemMessage(String message) {
    setState(() {
      _chatMessages.add(ChatMessage(
        text: message,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text.trim();
    setState(() {
      _chatMessages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isChatting = true;
    });

    _chatController.clear();
    _scrollToBottom();

    try {
      // Create context about the current calculation
      final calculationContext = _showResults 
          ? 'User just calculated carbon footprint: RM${_amountController.text} in $_selectedCategory category results in ${_calculatedCarbon.toStringAsFixed(3)} kg CO₂'
          : 'User is on the carbon calculator screen but hasn\'t calculated anything yet';

      final prompt = '''
Context: $calculationContext
Carbon factors by category: ${_carbonFactors.toString()}
User question: $userMessage

Please provide helpful advice about carbon footprint, environmental impact, or sustainable spending habits.
''';

      final response = await _ollamaService.sendChatMessage(prompt, _user?.id ?? 1);
      
      setState(() {
        _chatMessages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isChatting = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          text: _getFallbackResponse(userMessage),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isChatting = false;
      });
    }
    
    _scrollToBottom();
  }

  String _getFallbackResponse(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('reduce') || msg.contains('lower') || msg.contains('decrease')) {
      return '🌱 To reduce your carbon footprint: Choose local products, use public transport, opt for digital receipts, and support eco-friendly businesses. Every RM you spend mindfully can save up to 0.084 kg CO₂!';
    } else if (msg.contains('category') || msg.contains('type')) {
      return '📊 Different spending categories have different carbon impacts. Transportation has the highest impact (0.156 kg CO₂/RM), while entertainment has the lowest (0.032 kg CO₂/RM).';
    } else {
      return '💡 I can help you understand carbon footprints and suggest ways to reduce environmental impact. Try asking about specific categories or reduction strategies!';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Carbon Calculator',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildCalculatorCard(),
            const SizedBox(height: 20),
            if (_showResults) _buildResultsCard(),
            const SizedBox(height: 30),
            _buildAIChatSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen.withOpacity(0.1), lightGreen.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calculate, color: primaryGreen, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carbon Footprint Calculator',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculate environmental impact per RM spent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Track your spending\'s environmental impact and get AI-powered suggestions to reduce your carbon footprint.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculate Carbon Impact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Amount Input
          Text(
            'Amount (RM)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter amount',
              prefixText: 'RM ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: primaryGreen, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Category Selection
          Text(
            'Spending Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _carbonFactors.keys.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        _getCategoryIcon(category),
                        const SizedBox(width: 12),
                        Text(category),
                        const Spacer(),
                        Text(
                          '${_carbonFactors[category]!.toStringAsFixed(3)} kg/RM',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 25),
          
          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCalculating ? null : _calculateCarbon,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
              child: _isCalculating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Calculate Carbon Footprint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return AnimatedBuilder(
      animation: _resultScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _resultScaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkGreen, primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Carbon Footprint Result',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'For RM${_amountController.text} in $_selectedCategory',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultStat(
                      'CO₂ Impact',
                      '${_calculatedCarbon.toStringAsFixed(3)} kg',
                      Icons.cloud,
                    ),
                    Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                    _buildResultStat(
                      'Per RM',
                      '${_carbonFactors[_selectedCategory]!.toStringAsFixed(3)} kg',
                      Icons.attach_money,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getImpactMessage(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getImpactMessage() {
    if (_calculatedCarbon < 0.05) {
      return 'Low impact! This spending has minimal environmental impact.';
    } else if (_calculatedCarbon < 0.15) {
      return 'Moderate impact. Consider eco-friendly alternatives where possible.';
    } else {
      return 'High impact. Look for sustainable alternatives to reduce your footprint.';
    }
  }

  Widget _buildAIChatSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen.withOpacity(0.1), lightGreen.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, color: primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Sustainability Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _serverAvailable ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _serverAvailable ? 'AI Online' : 'Offline Mode',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: _chatMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, 
                             color: Colors.grey.shade400, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me about carbon footprints,\nsustainable spending, or eco tips!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      return _buildChatBubble(_chatMessages[index]);
                    },
                  ),
          ),
          
          if (_isChatting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy, color: primaryGreen, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          
          // Chat Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask about sustainability tips...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: primaryGreen),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryGreen, darkGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendChatMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: primaryGreen, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isUser ? primaryGreen : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.grey.shade600, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation':
        return const Icon(Icons.directions_car, size: 16, color: textSecondary);
      case 'Food & Dining':
        return const Icon(Icons.restaurant, size: 16, color: textSecondary);
      case 'Utilities':
        return const Icon(Icons.electrical_services, size: 16, color: textSecondary);
      case 'Shopping':
        return const Icon(Icons.shopping_bag, size: 16, color: textSecondary);
      case 'Entertainment':
        return const Icon(Icons.movie, size: 16, color: textSecondary);
      case 'Healthcare':
        return const Icon(Icons.local_hospital, size: 16, color: textSecondary);
      case 'Education':
        return const Icon(Icons.school, size: 16, color: textSecondary);
      default:
        return const Icon(Icons.category, size: 16, color: textSecondary);
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}