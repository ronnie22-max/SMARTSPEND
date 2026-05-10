import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smartspend/models/transaction_model.dart';
import 'package:smartspend/services/user_data_service.dart';
import 'package:uuid/uuid.dart';

enum TransferChannel { mobileMoney, bank }

class FundsTransferPage extends StatefulWidget {
  final bool isDeposit;
  final double initialBalance;

  const FundsTransferPage({
    super.key,
    required this.isDeposit,
    required this.initialBalance,
  });

  @override
  State<FundsTransferPage> createState() => _FundsTransferPageState();
}

class _FundsTransferPageState extends State<FundsTransferPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TransactionManager _transactionManager = TransactionManager();

  TransferChannel _selectedChannel = TransferChannel.mobileMoney;
  bool _isSubmitting = false;
  double _currentBalance = 0.0;

  final List<String> _mobileMoneyProviders = const ['MTN MoMo', 'Airtel Money'];

  final List<String> _bankProviders = const [
    'Stanbic Bank',
    'Centenary Bank',
    'DFCU Bank',
    'Absa Bank',
    'Equity Bank',
  ];

  String _selectedProvider = 'MTN MoMo';

  final Map<String, Color> _providerColors = {
    'MTN MoMo': const Color(0xFFFFB81C),
    'Airtel Money': const Color(0xFFE41C23),
    'Stanbic Bank': const Color(0xFF003087),
    'Centenary Bank': const Color(0xFF2EA539),
    'DFCU Bank': const Color(0xFF00205B),
    'Absa Bank': const Color(0xFF00205B),
    'Equity Bank': const Color(0xFF00A651),
  };

  final Map<String, String> _providerLogos = {
    'MTN MoMo': 'images/logos/mtn_momo.svg',
    'Airtel Money': 'images/logos/airtel_money.svg',
    'Stanbic Bank': 'images/logos/stanbic_bank.svg',
    'Centenary Bank': 'images/logos/centenary_bank.svg',
    'DFCU Bank': 'images/logos/dfcu_bank.svg',
    'Absa Bank': 'images/logos/absa_bank.svg',
    'Equity Bank': 'images/logos/equity_bank.svg',
  };

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.initialBalance;
  }

  bool get _isDeposit => widget.isDeposit;

  List<String> get _providers {
    if (_selectedChannel == TransferChannel.mobileMoney) {
      return _mobileMoneyProviders;
    }
    return _bankProviders;
  }

  String get _pageTitle => _isDeposit ? 'Deposit Funds' : 'Withdraw Funds';

  String get _submitLabel {
    if (_isDeposit) {
      return 'Deposit to SmartSpend';
    }
    return 'Withdraw from SmartSpend';
  }

  Future<void> _submitTransfer() async {
    if (_isSubmitting) return;

    final rawAmount = _amountController.text.trim();
    final reference = _referenceController.text.trim();
    final note = _noteController.text.trim();

    if (rawAmount.isEmpty || reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount and account/phone are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid positive amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isDeposit && amount > _currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: UGX ${_currentBalance.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final description =
          '${_selectedChannel == TransferChannel.mobileMoney ? 'Mobile Money' : 'Bank'} • $_selectedProvider • Ref: $reference${note.isEmpty ? '' : ' • $note'}';

      final transaction = TransactionRecord(
        id: const Uuid().v4(),
        title: _isDeposit ? 'Account Deposit' : 'Account Withdrawal',
        category: _selectedChannel == TransferChannel.mobileMoney
            ? 'Mobile Money'
            : 'Bank',
        icon: _isDeposit
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded,
        timestamp: DateTime.now(),
        amount: amount,
        type: _isDeposit ? TransactionType.deposit : TransactionType.withdrawal,
        description: description,
      );

      _transactionManager.addTransaction(transaction);

      final updatedBalance = _isDeposit
          ? (_currentBalance + amount)
          : (_currentBalance - amount);
      await UserDataService().saveCashBalance(updatedBalance);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDeposit
                ? 'Deposit successful: UGX ${amount.toStringAsFixed(2)}'
                : 'Withdrawal successful: UGX ${amount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction failed: $e'),
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
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Available balance: UGX ${_currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Transfer Channel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Mobile Money'),
                    selected: _selectedChannel == TransferChannel.mobileMoney,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _selectedChannel = TransferChannel.mobileMoney;
                        _selectedProvider = _mobileMoneyProviders.first;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Bank Account'),
                    selected: _selectedChannel == TransferChannel.bank,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _selectedChannel = TransferChannel.bank;
                        _selectedProvider = _bankProviders.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Select Provider',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _providers
                  .map(
                    (provider) => GestureDetector(
                      onTap: () {
                        setState(() => _selectedProvider = provider);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedProvider == provider
                                ? (_providerColors[provider] ?? Colors.grey)
                                : Colors.grey.shade300,
                            width: _selectedProvider == provider ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedProvider == provider
                              ? (_providerColors[provider] ?? Colors.grey)
                                    .withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: SvgPicture.asset(
                                _providerLogos[provider] ??
                                    'images/logos/mtn_momo.svg',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              provider,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _referenceController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: _selectedChannel == TransferChannel.mobileMoney
                    ? 'Phone Number'
                    : 'Account Number',
                hintText: _selectedChannel == TransferChannel.mobileMoney
                    ? 'e.g. 07XXXXXXXX'
                    : 'e.g. 001234567890',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (UGX)',
                prefixText: 'UGX ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: SizedBox(
                width: screenWidth * 0.58,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _submitLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
