 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartspend/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class CashPage extends StatefulWidget {
  final Function(double)? onAddCash;
  const CashPage({super.key, this.onAddCash});

  @override
  State<CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<CashPage> {
  final TextEditingController _amountController = TextEditingController();
  final TransactionManager _transactionManager = TransactionManager();

  void _addCash(double amount) {
    // Record deposit transaction
    final transaction = TransactionRecord(
      id: const Uuid().v4(),
      title: 'Cash Deposit',
      category: 'Deposit',
      icon: Icons.arrow_downward,
      timestamp: DateTime.now(),
      amount: amount,
      type: TransactionType.deposit,
      description: 'Cash added to account',
    );
    _transactionManager.addTransaction(transaction);

    // Call the callback to update balance on home page
    if (widget.onAddCash != null) {
      widget.onAddCash!(amount);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Added UGX ${amount.toStringAsFixed(2)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Clear the input field
    _amountController.clear();
    
    // Navigate back to home after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Add Cash',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Amount Input
              Text(
                'Enter Amount',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                decoration: InputDecoration(
                  hintText: 'Enter amount in UGX',
                  prefixText: 'UGX ',
                  prefixStyle: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Preset Amounts
              Text(
                'Quick Add',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: screenWidth * 0.03,
                mainAxisSpacing: screenHeight * 0.015,
                childAspectRatio: 1.5,
                children: [
                  _buildPresetButton('5,000', 5000, isSmallScreen),
                  _buildPresetButton('10,000', 10000, isSmallScreen),
                  _buildPresetButton('25,000', 25000, isSmallScreen),
                  _buildPresetButton('50,000', 50000, isSmallScreen),
                  _buildPresetButton('100,000', 100000, isSmallScreen),
                  _buildPresetButton('500,000', 500000, isSmallScreen),
                ],
              ),
              SizedBox(height: screenHeight * 0.04),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final inputText = _amountController.text.trim();
                    
                    if (inputText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an amount'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final amount = double.tryParse(inputText);
                    
                    if (amount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid number only'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Amount must be a positive number'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    _addCash(amount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add Cash',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildPresetButton(String label, double amount, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: () async => _addCash(amount),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: colorScheme.outline,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'UGX ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
