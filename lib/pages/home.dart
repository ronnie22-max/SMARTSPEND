import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspend/pages/cash.dart';
import 'package:smartspend/pages/budget.dart';
import 'package:smartspend/models/transaction_model.dart';
import 'package:uuid/uuid.dart';


class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _cashBalance = 0.0;
  final TransactionManager _transactionManager = TransactionManager();
  static const String _cashBalanceKey = 'smartspend_cash_balance';
  int _currentTipIndex = 0;
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
  }

  Future<void> _loadCashBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _cashBalance = prefs.getDouble(_cashBalanceKey) ?? 0.0;
      });
    } catch (e) {
      debugPrint('Error loading cash balance: $e');
    }
  }

  Future<void> _saveCashBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_cashBalanceKey, _cashBalance);
    } catch (e) {
      debugPrint('Error saving cash balance: $e');
    }
  }

  void _addCash(double amount) {
    setState(() {
      _cashBalance += amount;
    });
    _saveCashBalance();
  }

  void _navigateToCashPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashPage(onAddCash: _addCash),
      ),
    );
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

  void _cashOut(double amount) {
    if (_cashBalance >= amount) {
      // Record withdrawal transaction
      final transaction = TransactionRecord(
        id: const Uuid().v4(),
        title: 'Cash Withdrawal',
        category: 'Withdrawal',
        icon: Icons.arrow_upward,
        timestamp: DateTime.now(),
        amount: amount,
        type: TransactionType.withdrawal,
        description: 'Cash withdrawn from account',
      );
      _transactionManager.addTransaction(transaction);

      setState(() {
        _cashBalance -= amount;
      });
      _saveCashBalance();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Withdrawn UGX ${amount.toStringAsFixed(2)}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;
    final contentWidth = screenWidth * 0.90;
    final displayName = widget.username.trim().isEmpty
        ? 'Guest User'
        : widget.username.trim();
    final avatarInitial = displayName.substring(0, 1).toUpperCase();
    
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('SmartSpend',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
         actions: [
            IconButton(
               icon: const Icon(Icons.search),
               onPressed: (){},
               ),

               IconButton(
               icon: const Icon(Icons.person),
               onPressed: (){
                  Navigator.pop(context);
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
                          child: Text(
                            "Cash Balance",
                            style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600),
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
                                    backgroundColor: Colors.green.withValues(alpha: 0.2),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Welcome back',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
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
                        "UGX ${_cashBalance.toStringAsFixed(2)}",
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
                            onTap: _navigateToCashPage,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015
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
                              _cashOut(500);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015
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
                    _buildAction(Icons.phone_android, 'Deposit', null),
                    _buildAction(Icons.receipt_long, 'Bills', null),
                    _buildAction(Icons.pie_chart, 'Budget', () => _navigateToBudget(context)),
                    _buildAction(Icons.account_balance, 'Withdraw', null),
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
            Navigator.pop(context);
            Navigator.pushNamed(context, '/transactions');
          } 
          else if 
          (index == 3) {
            Navigator.pop(context);
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
