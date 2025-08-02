import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../helpers/database_helper.dart';
import '../models/balance.dart';
import 'qr_scanner_screen.dart';
import 'ecopay_screen.dart';
import 'language_settings_screen.dart';

class TouchNGoHomepage extends StatefulWidget {
  const TouchNGoHomepage({super.key});

  @override
  State<TouchNGoHomepage> createState() => _TouchNGoHomepageState();
}

class _TouchNGoHomepageState extends State<TouchNGoHomepage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Balance? _currentBalance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('DEBUG: TouchNGoHomepage - initState called');
    _loadBalance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('DEBUG: TouchNGoHomepage - didChangeDependencies called');
    // Refresh balance when returning from other screens
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    print('DEBUG: TouchNGoHomepage._loadBalance - Starting to load balance');
    setState(() {
      _isLoading = true;
    });

    try {
      final balance = await _databaseHelper.getBalance();
      print(
        'DEBUG: TouchNGoHomepage._loadBalance - Loaded balance: ${balance.amount}',
      );
      setState(() {
        _currentBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('Error loading balance: $e');
    }
  }

  Future<void> _showCustomBalanceDialog() async {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.editBalance),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.enterAmountToAdd,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.amountRM,
                    hintText: '0.00',
                    prefixText: 'RM ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterAmount;
                    }
                    final double? amount = double.tryParse(value);
                    if (amount == null) {
                      return AppLocalizations.of(context)!.pleaseEnterValidNumber;
                    }
                    if (amount <= 0) {
                      return AppLocalizations.of(context)!.amountMustBeGreaterThanZero;
                    }
                    if (amount > 10000) {
                      return AppLocalizations.of(context)!.amountCannotExceed;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.addBalance),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final double amount = double.parse(amountController.text);
                  Navigator.of(context).pop();
                  await _reloadBalance(amount);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _reloadBalance(double amount) async {
    try {
      await _databaseHelper.reloadBalance(amount);
      await _loadBalance(); // Refresh the balance display

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Balance updated with RM ${amount.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update balance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'User Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: Text(AppLocalizations.of(context)!.language),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Dark blue
              Color(0xFF3B82F6), // Medium blue
              Color(0xFF60A5FA), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // eWallet Balance Section
                      _buildWalletSection(),

                      const SizedBox(height: 30),

                      // Main Service Icons
                      _buildMainServiceIcons(),

                      const SizedBox(height: 20),

                      // Goals and Vouchers Cards
                      _buildFeatureCards(),

                      const SizedBox(height: 20),

                      // All Services Grid
                      _buildAllServicesGrid(),

                      const SizedBox(height: 20),

                      // Highlights Section
                      _buildHighlightsSection(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.ewalletBalance,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? Text(
                          AppLocalizations.of(context)!.loading,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Row(
                          children: [
                            Image.asset(
                              'assets/images/malaysia-flag.png',
                              width: 28,
                              height: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RM ${_currentBalance?.amount.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
              GestureDetector(
                onTap: _showUserMenu,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset(
                      'assets/images/profile.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showCustomBalanceDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.reload,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to transaction history page
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.transactionHistory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainServiceIcons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildServiceIcon(
            Icons.qr_code_scanner,
            AppLocalizations.of(context)!.scan,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QrScannerScreen(),
                ),
              );
            },
          ),
          _buildServiceIcon(Icons.payment, AppLocalizations.of(context)!.pay),
          _buildServiceIcon(Icons.swap_horiz, AppLocalizations.of(context)!.transfer),
          _buildServiceIcon(Icons.star, AppLocalizations.of(context)!.goPlus),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 60,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.goals,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.oneReward,
                      style: const TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 60,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.vouchers,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.threeVouchers,
                      style: const TextStyle(
                        color: Color(0xFFEA580C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllServicesGrid() {
    final services = [
      {'icon': Icons.toll, 'label': 'Toll'},
      {'icon': Icons.local_parking, 'label': 'Parking'},
      {'icon': Icons.phone, 'label': 'Prepaid'},
      {'icon': Icons.receipt_long, 'label': 'Bills'},
      {'icon': Icons.sports_esports, 'label': 'Game Credits'},
      {'icon': Icons.store, 'label': 'Merchant'},
      {'icon': Icons.local_cafe, 'label': 'Tealive'},
      {'icon': Icons.flash_on, 'label': 'EASI'},
      {'icon': Icons.games, 'label': 'Goama Games'},
      {'icon': Icons.shopping_bag, 'label': 'Lazada'},
      {'icon': Icons.play_circle_fill, 'label': 'Play Store'},
      {
        'icon': Icons.eco,
        'label': 'EcoPay',
        'isCustomIcon': true,
        'assetPath': 'assets/images/EcoPayIcon.png',
      },
    ];
    print(
      'DEBUG: TouchNGoHomepage._buildAllServicesGrid - Building grid with ${services.length} services',
    );
    print(
      'DEBUG: TouchNGoHomepage._buildAllServicesGrid - EcoPay is at index: ${services.indexWhere((s) => s['label'] == 'EcoPay')}',
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return _buildGridServiceIcon(
            service['icon'] as IconData,
            service['label'] as String,
            isCustom: (service['isCustomIcon'] as bool?) ?? false,
            assetPath: service['assetPath'] as String?,
          );
        },
      ),
    );
  }

  Widget _buildGridServiceIcon(
    IconData? icon,
    String label, {
    bool isCustom = false,
    String? assetPath,
  }) {
    return GestureDetector(
      onTap: () {
        if (label == 'EcoPay') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EcoPayScreen()));
        }
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: label == 'EcoPay'
                  ? Colors.green.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isCustom && assetPath != null
                ? Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(assetPath),
                  )
                : Icon(
                    icon,
                    color: label == 'EcoPay'
                        ? Colors.green.shade100
                        : Colors.white,
                    size: 24,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: label == 'EcoPay' ? Colors.green.shade100 : Colors.white,
              fontSize: 10,
              fontWeight: label == 'EcoPay'
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.highlights,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.promotionalContent,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
