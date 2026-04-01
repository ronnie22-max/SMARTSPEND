import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smartspend/pages/cash.dart';


class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _cashBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _updateCashBalance();
  }

  void _updateCashBalance() {
    // Automatically fetch and update cash balance
    // Replace with actual data fetching logic from backend or local storage
    setState(() {
      _cashBalance = 0.0; // Update with real data
    });
  }

  void _addCash(double amount) {
    setState(() {
      _cashBalance += amount;
    });
  }

  void _navigateToCashPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashPage(onAddCash: _addCash),
      ),
    );
  }

  void _cashOut(double amount) {
    setState(() {
      if (_cashBalance >= amount) {
        _cashBalance -= amount;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient balance')),
        );
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
                    _buildAction(Icons.money, 'Send money'),
                    _buildAction(Icons.save, 'save'),
                    _buildAction(Icons.phone_android, 'Deposit'),
                    _buildAction(Icons.receipt_long, 'Bills'),
                    _buildAction(Icons.pie_chart, 'Budget'),
                    _buildAction(Icons.account_balance, 'Withdraw'),
                  ],
                ),
              ),
              const SizedBox(height: 3),
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

Widget _buildAction(IconData icon, String label) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isSmallScreen = constraints.maxWidth < 600;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
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
      );
    },
  );
}
