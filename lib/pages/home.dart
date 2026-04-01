import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:carousel_slider/carousel_slider.dart';


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

  void _showAddCashDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController customAmountController =
            TextEditingController();
        return AlertDialog(
          title: const Text('Add Cash'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select an amount or enter a custom amount:'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildAmountButton('5,000', 5000, dialogContext),
                      _buildAmountButton('10,000', 10000, dialogContext),
                      _buildAmountButton('25,000', 25000, dialogContext),
                      _buildAmountButton('50,000', 50000, dialogContext),
                    ],
                  ),
                ),





                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Or enter a custom amount:'),
                const SizedBox(height: 12),
                TextField(
                  controller: customAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount in UGX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: 'UGX ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (customAmountController.text.isNotEmpty) {
                  final amount =
                      double.tryParse(customAmountController.text) ?? 0;
                  if (amount > 0) {
                    _addCash(amount);
                    Navigator.pop(dialogContext);
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter an amount')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountButton(String label, double amount, BuildContext dialogContext) {
    return ElevatedButton(
      onPressed: () {
        _addCash(amount);
        Navigator.pop(dialogContext);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
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
    
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('SmartSpend '),
         actions: [
            IconButton(
               icon: Icon(Icons.search, color: const Color.fromARGB(255, 0, 0, 0),),
               onPressed: (){},
               ),

               IconButton(
               icon: Icon(Icons.person, color: const Color.fromARGB(255, 0, 0, 0),),
               onPressed: (){
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
               },
               ),
           ],
      ),

      
      
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                        const Text(
                          "Cash Balance",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              "Dear: ${widget.username}",
                              style: TextStyle(fontSize: 14),
                            ),
                            Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "UGX ${_cashBalance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _showAddCashDialog();
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Center(
                                child: Text(
                                  "Add Cash",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _cashOut(500);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Center(
                                child: Text(
                                  "Cash Out",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
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
              const SizedBox(height: 10),
              const Text(
                'Welcome to SmartSpend!',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 300,
                      children: [
                        _buildAction(Icons.money, 'Send money'),
                        _buildAction(Icons.save, 'save'),
                        _buildAction(Icons.phone_android, 'Deposit'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 300,
                      children: [
                        _buildAction(Icons.receipt_long, 'Bills'),
                        _buildAction(Icons.pie_chart, 'Budget'),
                        _buildAction(Icons.account_balance, 'Withdraw'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              CarouselSlider(
                items: [
                  Image.asset('images/tip1.png',
                      fit: BoxFit.cover, width: double.infinity),
                  Image.asset('images/tip2.png',
                      fit: BoxFit.cover, width: double.infinity),
                  Image.asset('images/tip3.png',
                      fit: BoxFit.cover, width: double.infinity),
                  Image.asset('images/tip4.png',
                      fit: BoxFit.cover, width: double.infinity),
                  Image.asset('images/tip5.png',
                      fit: BoxFit.cover, width: double.infinity),
                ],
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                ),
              ),
            ],
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
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 28, color: Colors.green),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
