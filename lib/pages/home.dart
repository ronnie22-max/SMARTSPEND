import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smartspend/pages/budget.dart';
import 'package:smartspend/pages/funds_transfer.dart';
import 'package:smartspend/models/transaction_model.dart';
import 'package:smartspend/services/user_data_service.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _cashBalance = 0.0;
  final TransactionManager _transactionManager = TransactionManager();
  int _currentTipIndex = 0;
  bool _hasSecurityPin = false;
  bool _isBalanceUnlocked = false;
  bool _pinDialogOpen = false;
  final List<String> _tipImages = const [
    'images/tip1.png',
    'images/tip2.png',
    'images/tip3.png',
    'images/tip4.png',
    'images/tip5.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load persisted cash balance
    await _loadCashBalance();
    // Load persisted transactions
    await _transactionManager.loadTransactions();
    await _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    try {
      final pin = await UserDataService().loadSecurityPin();
      if (!mounted) return;
      setState(() {
        _hasSecurityPin = pin != null;
        _isBalanceUnlocked = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pinDialogOpen) return;
        if (pin == null) {
          _ensureMandatoryPin();
        }
      });
    } catch (e) {
      debugPrint('Error loading security pin: $e');
    }
  }

  Future<void> _loadCashBalance() async {
    try {
      final balance = await UserDataService().loadCashBalance();
      if (mounted) {
        setState(() {
          _cashBalance = balance ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading cash balance: $e');
    }
  }

  Future<void> _openFundsTransfer({required bool isDeposit}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FundsTransferPage(
          isDeposit: isDeposit,
          initialBalance: _cashBalance,
        ),
      ),
    );
    await _loadCashBalance();
    await _transactionManager.loadTransactions();
  }

  Future<bool> _showCreatePinDialog({bool allowCancel = true}) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorText;

    _pinDialogOpen = true;
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: allowCancel,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Create 4-Digit PIN'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'A 4-digit PIN is required before you can view your cash balance or access deposits and withdrawals.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'Enter PIN',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (allowCancel)
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      final pin = pinController.text.trim();
                      final confirmPin = confirmPinController.text.trim();
                      if (pin.length != 4 || int.tryParse(pin) == null) {
                        setDialogState(() {
                          errorText = 'PIN must be exactly 4 digits';
                        });
                        return;
                      }
                      if (pin != confirmPin) {
                        setDialogState(() {
                          errorText = 'PINs do not match';
                        });
                        return;
                      }
                      await UserDataService().saveSecurityPin(pin);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Save PIN'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    _pinDialogOpen = false;

    pinController.dispose();
    confirmPinController.dispose();

    if (created == true && mounted) {
      setState(() {
        _hasSecurityPin = true;
        _isBalanceUnlocked = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN created successfully')));
      return true;
    }

    return false;
  }

  Future<bool> _showVerifyPinDialog({
    required String purpose,
    bool allowCancel = true,
  }) async {
    final savedPin = await UserDataService().loadSecurityPin();
    if (!mounted) return false;
    if (savedPin == null) {
      return _showCreatePinDialog(allowCancel: false);
    }

    final pinController = TextEditingController();
    String? errorText;
    _pinDialogOpen = true;
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: allowCancel,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Enter 4-Digit PIN'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Enter your PIN to $purpose.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
                actions: [
                  if (allowCancel)
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      if (pinController.text.trim() != savedPin) {
                        setDialogState(() {
                          errorText = 'Incorrect PIN';
                        });
                        return;
                      }
                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Verify'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    _pinDialogOpen = false;

    pinController.dispose();
    return verified == true;
  }

  Future<void> _toggleBalanceVisibility() async {
    if (_isBalanceUnlocked) {
      setState(() {
        _isBalanceUnlocked = false;
      });
      return;
    }

    final verified = await _showVerifyPinDialog(
      purpose: 'view your balance',
      allowCancel: true,
    );
    if (!verified || !mounted) return;
    setState(() {
      _isBalanceUnlocked = true;
    });
  }

  Future<void> _ensureMandatoryPin() async {
    final created = await _showCreatePinDialog(allowCancel: false);
    if (!created || !mounted) return;
    final verified = await _showVerifyPinDialog(
      purpose: 'view your balance',
      allowCancel: false,
    );
    if (!verified || !mounted) return;
    setState(() {
      _isBalanceUnlocked = true;
    });
  }

  Future<void> _navigateToBudget(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetPage(totalBalance: _cashBalance),
      ),
    );
    await _loadCashBalance();
  }

  Future<void> _navigateToBills() async {
    await Navigator.pushNamed(context, '/bills');
    await _loadCashBalance();
    await _transactionManager.loadTransactions();
  }

  void _openMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'More Options',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Pay Bills'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _navigateToBills();
                },
              ),
              ListTile(
                leading: const Icon(Icons.pie_chart_outline),
                title: const Text('Budget Planner'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _navigateToBudget(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Transaction History'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, '/transactions');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Profile & Settings'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support coming soon')),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;
    final contentWidth = screenWidth * 0.90;
    final authUser = FirebaseAuth.instance.currentUser;
    final displayName = widget.username.trim().isNotEmpty
        ? widget.username.trim()
        : (authUser?.displayName?.trim() ?? '');
    final avatarInitial = displayName.isEmpty
        ? 'U'
        : displayName.substring(0, 1).toUpperCase();

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'SmartSpend',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),

          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                padding: EdgeInsets.all(contentWidth * 0.05),
                width: contentWidth,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
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
                              Text(
                                'Cash Balance',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _toggleBalanceVisibility,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    _hasSecurityPin
                                        ? (_isBalanceUnlocked
                                              ? Icons.visibility_off
                                              : Icons.visibility)
                                        : Icons.pin_outlined,
                                    size: isSmallScreen ? 18 : 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: isSmallScreen ? 15 : 17,
                                    backgroundColor: Colors.green.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Text(
                                      avatarInitial,
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 12 : 13,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.015),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isSmallScreen
                                          ? screenWidth * 0.28
                                          : screenWidth * 0.22,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isBalanceUnlocked
                            ? 'UGX ${_cashBalance.toStringAsFixed(2)}'
                            : 'UGX ****',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 32 : 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openFundsTransfer(isDeposit: true),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "Add Cash",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: contentWidth * 0.03),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _openFundsTransfer(isDeposit: false);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "Cash Out",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Welcome to SmartSpend!',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.01,
                ),
                child: GridView.count(
                  crossAxisCount: isSmallScreen ? 3 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: contentWidth * 0.02,
                  mainAxisSpacing: screenHeight * 0.002,
                  childAspectRatio: isSmallScreen ? 0.85 : 2.6,
                  children: [
                    _buildAction(Icons.money, 'Send money', null),
                    _buildAction(Icons.save, 'save', null),
                    _buildAction(
                      Icons.phone_android,
                      'Deposit',
                      () => _openFundsTransfer(isDeposit: true),
                    ),
                    _buildAction(Icons.receipt_long, 'Bills', _navigateToBills),
                    _buildAction(
                      Icons.pie_chart,
                      'Budget',
                      () => _navigateToBudget(context),
                    ),
                    _buildAction(
                      Icons.account_balance,
                      'Withdraw',
                      () => _openFundsTransfer(isDeposit: false),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Text(
                  'Financial Tips',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.008),
              SizedBox(
                height: 320,
                width: contentWidth,
                child: CarouselSlider.builder(
                  itemCount: _tipImages.length,
                  itemBuilder: (context, index, realIndex) {
                    final isCenter = index == _currentTipIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.symmetric(
                        vertical: isCenter ? 8 : 22,
                        horizontal: 4,
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isCenter ? 1 : 0.72,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            _tipImages[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Text('Image not found'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 320,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    enlargeCenterPage: true,
                    enlargeFactor: 0.28,
                    viewportFraction: 0.68,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentTipIndex = index;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),

      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.email), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/transactions');
          } else if (index == 2) {
            _openMoreOptions();
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}

Widget _buildAction(IconData icon, String label, Function()? onTap) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isSmallScreen = constraints.maxWidth < 600;
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: isSmallScreen ? 24 : 28,
                color: Colors.green,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              label,
              style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    },
  );
}
