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
    
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('SmartSpend',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
         actions: [
            IconButton(
               icon: const Icon(Icons.search, color: Color.fromARGB(255, 0, 0, 0)),
               onPressed: (){},
               ),

               IconButton(
               icon: const Icon(Icons.person, color: Color.fromARGB(255, 0, 0, 0)),
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
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              padding: EdgeInsets.all(screenWidth * 0.05),
              width: screenWidth * 0.92,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 242, 241, 241),
                borderRadius: BorderRadius.circular(24),
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Cash Balance",
                          style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16, 
                              fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              "Dear: ${widget.username}",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "UGX ${_cashBalance.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 32 : 40,
                        fontWeight: FontWeight.bold,
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
                        SizedBox(width: screenWidth * 0.03),
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
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.01,
                ),
                child: GridView.count(
                  crossAxisCount: isSmallScreen ? 3 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: screenWidth * 0.02,
                  mainAxisSpacing: screenHeight * 0.002,
                  childAspectRatio: 0.85,
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
                height: 200,
                width: screenWidth * 0.95,
                child: CarouselSlider(
                  items: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'images/tip1.png',
                        fit: BoxFit.cover,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'images/tip2.png',
                        fit: BoxFit.cover,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'images/tip3.png',
                        fit: BoxFit.cover,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'images/tip4.png',
                        fit: BoxFit.cover,
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'images/tip5.png',
                        fit: BoxFit.cover,
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
                  ],
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
        ),
      
      
      

      bottomNavigationBar: NavigationBar(
         backgroundColor: Colors.white, 
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
