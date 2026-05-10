import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartspend/models/transaction_model.dart';
import 'package:smartspend/services/user_data_service.dart';
import 'package:uuid/uuid.dart';

class BudgetPage extends StatefulWidget {
  final double totalBalance;
  const BudgetPage({super.key, this.totalBalance = 0.0});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late Map<String, double> expenses = {
    'Food': 0.0,
    'Transport': 0.0,
    'Health': 0.0,
    'Saving': 0.0,
    'Rent': 0.0,
    'Personal': 0.0,
  };

  final TransactionManager _transactionManager = TransactionManager();
  double _currentCashBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBudgetAndCash();
  }

  Future<void> _loadBudgetAndCash() async {
    try {
      final remoteCash = await UserDataService().loadCashBalance();
      _currentCashBalance = widget.totalBalance > 0
          ? widget.totalBalance
          : (remoteCash ?? 0.0);

      if (widget.totalBalance > 0) {
        await UserDataService().saveCashBalance(widget.totalBalance);
      }

      final remoteBudget = await UserDataService().loadBudget();
      if (remoteBudget != null) {
        setState(() {
          expenses.forEach((key, _) {
            expenses[key] = remoteBudget[key] ?? 0.0;
          });
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading budget: $e');
    }
  }

  Future<void> _saveBudgetAndCash() async {
    try {
      await UserDataService().saveBudget(Map<String, double>.from(expenses));
      await UserDataService().saveCashBalance(_currentCashBalance);
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  final Map<String, Color> categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Health': Colors.red,
    'Saving': Colors.green,
    'Rent': Colors.purple,
    'Personal': Colors.pink,
  };

  final Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Health': Icons.health_and_safety,
    'Saving': Icons.savings,
    'Rent': Icons.home,
    'Personal': Icons.person,
  };

  final List<Color> _expensePalette = const [
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
    Colors.brown,
    Colors.cyan,
    Colors.amber,
  ];

  double get totalExpenses => expenses.values.fold(0, (sum, val) => sum + val);
  double get remainingBalance => totalBalance - totalExpenses;

  double get totalBalance => _currentCashBalance + totalExpenses;

  Future<void> _showAddExpenseDialog() async {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: 'UGX ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final rawCategory = categoryController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    final category = rawCategory
                        .split(RegExp(r'\s+'))
                        .where((part) => part.isNotEmpty)
                        .map(
                          (part) =>
                              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
                        )
                        .join(' ');

                    if (category.isEmpty) {
                      setDialogState(() {
                        errorText = 'Enter a category name';
                      });
                      return;
                    }

                    if (expenses.containsKey(category)) {
                      setDialogState(() {
                        errorText = 'This category already exists';
                      });
                      return;
                    }

                    if (amount == null || amount <= 0) {
                      setDialogState(() {
                        errorText = 'Enter a valid amount';
                      });
                      return;
                    }

                    if (amount > _currentCashBalance) {
                      setDialogState(() {
                        errorText =
                            'Amount exceeds available cash (UGX ${_currentCashBalance.toStringAsFixed(2)})';
                      });
                      return;
                    }

                    final color =
                        _expensePalette[expenses.length %
                            _expensePalette.length];
                    final transaction = TransactionRecord(
                      id: const Uuid().v4(),
                      title: 'Budget Spending',
                      category: category,
                      icon: Icons.playlist_add,
                      timestamp: DateTime.now(),
                      amount: amount,
                      type: TransactionType.budgetSpend,
                      description: 'Allocated to $category budget',
                      budgetRemaining: remainingBalance - amount,
                    );
                    _transactionManager.addTransaction(transaction);

                    setState(() {
                      expenses[category] = amount;
                      categoryColors[category] = color;
                      categoryIcons[category] = Icons.receipt_long;
                      _currentCashBalance -= amount;
                    });
                    _saveBudgetAndCash();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Add Expense'),
                ),
              ],
            );
          },
        );
      },
    );

    categoryController.dispose();
    amountController.dispose();
  }

  void _editExpense(String category) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        final previousAmount = expenses[category]!;
        return AlertDialog(
          title: Text('Edit $category'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter amount',
              prefixText: 'UGX ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 0;
                if (amount > 0) {
                  final difference = amount - previousAmount;
                  if (difference > _currentCashBalance) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Amount exceeds available cash. Remaining: UGX ${_currentCashBalance.toStringAsFixed(2)}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Record budget spending transaction
                  final transaction = TransactionRecord(
                    id: const Uuid().v4(),
                    title: 'Budget Spending',
                    category: category,
                    icon: categoryIcons[category]!,
                    timestamp: DateTime.now(),
                    amount: amount,
                    type: TransactionType.budgetSpend,
                    description: 'Allocated to $category budget',
                    budgetRemaining: remainingBalance - difference,
                  );
                  _transactionManager.addTransaction(transaction);

                  setState(() {
                    expenses[category] = amount;
                    _currentCashBalance -= difference;
                  });
                  _saveBudgetAndCash();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeExpense(String category) async {
    final amount = expenses[category] ?? 0.0;
    if (amount <= 0) return;

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Expense'),
          content: Text(
            'Remove $category and restore UGX ${amount.toStringAsFixed(2)} to cash balance?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !mounted) return;

    setState(() {
      expenses[category] = 0.0;
      _currentCashBalance += amount;
    });
    await _saveBudgetAndCash();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category removed'),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Budget Tracker',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
              // Total Balance Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UGX ${totalBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Spent',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UGX ${totalExpenses.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UGX ${remainingBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),

              // Expense Categories
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Expenses by Category',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Add a new expense',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00A76F), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _showAddExpenseDialog,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.keys.length,
                itemBuilder: (context, index) {
                  final category = expenses.keys.elementAt(index);
                  final amount = expenses[category]!;
                  final percentage = totalBalance > 0
                      ? (amount / totalBalance * 100)
                      : 0.0;

                  return Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.012),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.92, end: 1.0),
                      duration: Duration(milliseconds: 260 + (index * 40)),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(scale: value, child: child),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: categoryColors[category]!.withValues(
                              alpha: 0.45,
                            ),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              categoryColors[category]!.withValues(alpha: 0.13),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: categoryColors[category]!
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          categoryIcons[category],
                                          color: categoryColors[category],
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'UGX ${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColors[category],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 6,
                                backgroundColor: categoryColors[category]!
                                    .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(
                                  categoryColors[category],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of total budget',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const Spacer(),
                                Tooltip(
                                  message: 'Edit expense',
                                  child: IconButton(
                                    onPressed: () => _editExpense(category),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: categoryColors[category],
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Remove expense',
                                  child: IconButton(
                                    onPressed: () => _removeExpense(category),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
