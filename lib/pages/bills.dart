import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspend/models/transaction_model.dart';
import 'package:smartspend/services/user_data_service.dart';
import 'package:uuid/uuid.dart';

class BillCategory {
  final String title;
  final String provider;
  final IconData icon;
  final Color color;
  final String fromAmount;

  const BillCategory({
    required this.title,
    required this.provider,
    required this.icon,
    required this.color,
    required this.fromAmount,
  });
}

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final List<BillCategory> _categories = const [
    BillCategory(
      title: 'Water Bills',
      provider: 'NWSC Uganda',
      icon: Icons.water_drop,
      color: Color(0xFF1976D2),
      fromAmount: 'UGX 5,000+',
    ),
    BillCategory(
      title: 'Electricity',
      provider: 'UMEME / Yaka',
      icon: Icons.flash_on,
      color: Color(0xFFFF8F00),
      fromAmount: 'UGX 2,000+',
    ),
    BillCategory(
      title: 'URA Taxes',
      provider: 'Uganda Revenue Authority',
      icon: Icons.account_balance,
      color: Color(0xFF2E7D32),
      fromAmount: 'UGX 10,000+',
    ),
    BillCategory(
      title: 'Betting Companies',
      provider: 'SportyBet, BetPawa, PremierBet',
      icon: Icons.sports_soccer,
      color: Color(0xFFD32F2F),
      fromAmount: 'UGX 1,000+',
    ),
    BillCategory(
      title: 'Hospital',
      provider: 'Mulago, Nakasero, IHK',
      icon: Icons.local_hospital,
      color: Color(0xFF00897B),
      fromAmount: 'UGX 20,000+',
    ),
    BillCategory(
      title: 'School Fees',
      provider: 'Primary, Secondary, University',
      icon: Icons.school,
      color: Color(0xFF5E35B1),
      fromAmount: 'UGX 50,000+',
    ),
    BillCategory(
      title: 'TV Services',
      provider: 'DSTV, GOtv, Startimes, Azam',
      icon: Icons.tv,
      color: Color(0xFF6D4C41),
      fromAmount: 'UGX 12,000+',
    ),
    BillCategory(
      title: 'Others',
      provider: 'Internet, Rent, Savings Groups',
      icon: Icons.more_horiz,
      color: Color(0xFF546E7A),
      fromAmount: 'UGX 3,000+',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F1),
      appBar: AppBar(
        title: const Text('Pay Bills'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Pay Your Bills SmartSpend',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap an icon to pay in UGX.',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isSmallScreen ? 3 : 4,
                    crossAxisSpacing: isSmallScreen ? 22 : 26,
                    mainAxisSpacing: isSmallScreen ? 26 : 30,
                    childAspectRatio: isSmallScreen ? 0.82 : 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _billIconTile(context, category, isSmallScreen);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _billIconTile(
    BuildContext context,
    BillCategory category,
    bool isSmallScreen,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BillPaymentPage(category: category),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmallScreen ? 72 : 80,
            height: isSmallScreen ? 72 : 80,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: isSmallScreen ? 34 : 38,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            category.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            category.fromAmount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class BillPaymentPage extends StatefulWidget {
  final BillCategory category;

  const BillPaymentPage({super.key, required this.category});

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TransactionManager _transactionManager = TransactionManager();
  static const String _cashBalanceKey = 'smartspend_cash_balance';
  static const String _cashUpdatedAtKey = 'smartspend_cash_updated_at_ms';
  bool _isSubmitting = false;
  double _currentCashBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.text = '10000';
    _loadCashBalance();
  }

  Future<void> _loadCashBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localBalance = prefs.getDouble(_cashBalanceKey) ?? 0.0;
      final localUpdatedAt = prefs.getInt(_cashUpdatedAtKey) ?? 0;

      final remoteData = await UserDataService().loadCashBalanceData();
      final remoteBalance = (remoteData?['cashBalance'] as num?)?.toDouble();
      final remoteUpdatedAt = (remoteData?['cashUpdatedAtMs'] as num?)?.toInt() ?? 0;

      final useRemote = remoteBalance != null && remoteUpdatedAt > localUpdatedAt;
      final balance = useRemote ? remoteBalance : localBalance;

      if (useRemote && balance != null) {
        await prefs.setDouble(_cashBalanceKey, balance);
        await prefs.setInt(_cashUpdatedAtKey, remoteUpdatedAt);
      }

      if (mounted) {
        setState(() => _currentCashBalance = balance ?? 0.0);
      }
    } catch (e) {
      debugPrint('Error loading bill payment balance: $e');
    }
  }

  Future<void> _saveCashBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setDouble(_cashBalanceKey, _currentCashBalance);
      await prefs.setInt(_cashUpdatedAtKey, now);
      await UserDataService().saveCashBalance(_currentCashBalance);
    } catch (e) {
      debugPrint('Error saving bill payment balance: $e');
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final accountNumber = _accountController.text.trim();
    final note = _noteController.text.trim();

    if (amount > _currentCashBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: UGX ${_currentCashBalance.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _transactionManager.loadTransactions();

      final transaction = TransactionRecord(
        id: const Uuid().v4(),
        title: '${widget.category.title} Payment',
        category: widget.category.title,
        icon: widget.category.icon,
        timestamp: DateTime.now(),
        amount: amount,
        type: TransactionType.expense,
        description: note.isEmpty
            ? 'Account: $accountNumber • ${widget.category.provider}'
            : 'Account: $accountNumber • $note',
      );

      _transactionManager.addTransaction(transaction);
      _currentCashBalance -= amount;
      await _saveCashBalance();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paid UGX ${amount.toStringAsFixed(0)} for ${widget.category.title}. Saved to transactions.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.title} Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.category.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: widget.category.color.withValues(alpha: 0.18),
                      child: Icon(widget.category.icon, color: widget.category.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(widget.category.provider),
                          Text('Minimum: ${widget.category.fromAmount}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Customer or Account Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter account number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (UGX)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Reference / Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(_isSubmitting ? 'Processing...' : 'Pay Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 