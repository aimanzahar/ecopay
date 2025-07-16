import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/database_helper.dart';
import '../models/balance.dart';
import '../models/contribution.dart';
import '../models/contribution.dart';
import '../models/transaction.dart';
import '../widgets/receipt_modal.dart';
import 'touch_n_go_homepage.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final String merchantName;
  final double? ecoPayAmount;

  const PaymentConfirmationScreen({
    super.key,
    required this.merchantName,
    this.ecoPayAmount,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _ecoPayController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  Balance? _currentBalance;
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _enableEcoPay = false;
  double _customEcoPayAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    
    // Initialize EcoPay settings
    if (widget.ecoPayAmount != null && widget.ecoPayAmount! > 0) {
      _enableEcoPay = true;
      _customEcoPayAmount = widget.ecoPayAmount!;
      _ecoPayController.text = widget.ecoPayAmount!.toStringAsFixed(2);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh balance when returning from other screens
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final balance = await _databaseHelper.getBalance();
      setState(() {
        _currentBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading balance: $e');
    }
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
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF60A5FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildMerchantCard(),
                        const SizedBox(height: 24),
                        _buildBalanceCard(),
                        const SizedBox(height: 24),
                        _buildAmountInput(),
                        const SizedBox(height: 24),
                        _buildEcoPaySection(),
                        const SizedBox(height: 32),
                        _buildPayButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Payment Confirmation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildMerchantCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.store,
              size: 40,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.merchantName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'DUITNOW QR',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  'RM ${_currentBalance?.amount.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixText: 'RM ',
                prefixStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final double? amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }
                if (amount > 10000) {
                  return 'Amount cannot exceed RM 10,000';
                }
                if (_currentBalance != null && amount > _currentBalance!.amount) {
                  return 'Insufficient balance';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcoPaySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'EcoPay Environmental Contribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Help protect our environment by contributing to eco-friendly projects',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: _enableEcoPay,
                onChanged: (value) {
                  setState(() {
                    _enableEcoPay = value;
                    if (!value) {
                      _customEcoPayAmount = 0.0;
                      _ecoPayController.clear();
                    } else {
                      _customEcoPayAmount = 0.50;
                      _ecoPayController.text = '0.50';
                    }
                  });
                },
                activeColor: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                _enableEcoPay ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _enableEcoPay ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          if (_enableEcoPay) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _ecoPayController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'EcoPay Amount',
                hintText: '0.50',
                prefixText: 'RM ',
                prefixStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onChanged: (value) {
                setState(() {
                  _customEcoPayAmount = double.tryParse(value) ?? 0.0;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'PAY NOW',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final double amount = double.parse(_amountController.text);
      final double ecoPayAmount = _enableEcoPay ? _customEcoPayAmount : 0.0;
      final double totalAmount = amount + ecoPayAmount;

      // Process payment using DatabaseHelper
      final success = await _databaseHelper.processPayment(
        widget.merchantName,
        totalAmount,
      );

      if (success) {
        if (_enableEcoPay && ecoPayAmount > 0) {
          print('DEBUG: PaymentConfirmation - Creating contribution record');
          final contribution = Contribution(
            userId: 1, // Assuming user ID 1
            projectId: 1, // Assuming project ID 1
            amount: ecoPayAmount,
            timestamp: DateTime.now(),
          );
          await _databaseHelper.insertContribution(contribution);
          print('DEBUG: PaymentConfirmation - Contribution record created');
        }
        // Payment successful - show receipt modal
        await _showReceiptModal(totalAmount);
      } else {
        // Payment failed - show error
        _showErrorSnackBar('Payment failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error processing payment: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showReceiptModal(double totalAmount) async {
    print('DEBUG: PaymentConfirmation - _showReceiptModal called with amount: $totalAmount');

    // Get the latest balance after payment
    final updatedBalance = await _databaseHelper.getBalance();
    print('DEBUG: PaymentConfirmation - Updated balance after payment: ${updatedBalance.amount}');

    // Get the latest transaction from database to ensure correct transaction ID
    final transactions = await _databaseHelper.getTransactions();
    Transaction? latestTransaction;

    if (transactions.isNotEmpty) {
      // Find the most recent transaction that matches our merchant and amount
      latestTransaction = transactions.firstWhere(
        (t) => t.merchantName == widget.merchantName && t.amount == totalAmount,
        orElse: () => transactions.first,
      );
    }

    // Fallback: Create transaction object if not found (shouldn't happen normally)
    final transaction = latestTransaction ??
        Transaction(
          transactionId: Transaction.generateTransactionId(),
          merchantName: widget.merchantName,
          amount: totalAmount,
          remainingBalance: updatedBalance.amount,
          transactionDate: DateTime.now(),
          status: 'completed',
        );

    if (mounted) {
      print('DEBUG: PaymentConfirmation - About to show receipt dialog');

      // Show the receipt modal and wait for it to close
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ReceiptModal(
          transaction: transaction,
          ecoPayAmount: _enableEcoPay ? _customEcoPayAmount : null,
        ),
      );
      
      print('DEBUG: PaymentConfirmation - Receipt dialog closed');
      
      // Navigate back to home after dialog is closed (from main screen context)
      if (mounted) {
        print('DEBUG: PaymentConfirmation - Starting navigation to home page');
        print('DEBUG: PaymentConfirmation - Current context is mounted: $mounted');
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) {
            print('DEBUG: PaymentConfirmation - MaterialPageRoute builder called');
            return const TouchNGoHomepage();
          }),
          (route) {
            print('DEBUG: PaymentConfirmation - Route predicate called for route: ${route.runtimeType}');
            return false;
          },
        );
        
        print('DEBUG: PaymentConfirmation - Navigation completed');
      } else {
        print('DEBUG: PaymentConfirmation - Widget not mounted, skipping navigation');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _ecoPayController.dispose();
    super.dispose();
  }
}