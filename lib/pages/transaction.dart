import 'package:flutter/material.dart';


class Transaction {
  final String title;
  final IconData icon;
  final DateTime time;
  final double amount;
  final double? subAmount;

  Transaction({
    required this.title,
    required this.icon,
    required this.time,
    required this.amount,
    this.subAmount,
  });
}

class TransactionsPage extends StatelessWidget {
  TransactionsPage({super.key});

  final List<Transaction> transactions = [];

Map<String, List<Transaction>> groupTransactions(List<Transaction> txns) {
  final Map<String, List<Transaction>> grouped = {};
  for (var txn in txns) {
    final date = "${txn.time.year}-${txn.time.month}-${txn.time.day}";
    grouped.putIfAbsent(date, () => []).add(txn);
  }
  return grouped;
}

@override
Widget build(BuildContext context) {
  // Group the transactions using your dynamic logic
  final groupedTransactions = groupTransactions(transactions);

  return Scaffold(
    backgroundColor: Colors.green[300],
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 0, 0, 0)),
                  onPressed: () {
                     Navigator.pop(context);
                    Navigator.pushNamed(context,'/home');
                  },
                ),
                const SizedBox(width: 12),
                const Text("Transactions",
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 20),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200]),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Filter chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: const [
                  Icon(Icons.filter_alt_outlined, size: 18),
                  SizedBox(width: 8),
                  Text("All accounts"),
                ],
              ),
            ),

            const SizedBox(height: 25),
            
            Expanded(
              child: ListView(
                children: groupedTransactions.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ...entry.value.map((txn) {
                        return transactionItem(txn);
                      }),

                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Reusable UI Widget
  Widget transactionItem(Transaction txn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(txn.icon, color: Colors.black),
        ),
        title: Text(txn.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text("${txn.time.hour}:${txn.time.minute.toString().padLeft(2, '0')}"),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${txn.amount > 0 ? '+' : ''}${txn.amount}",
              style: TextStyle(
                color: txn.amount > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (txn.subAmount != null)
              Text(
                "${txn.subAmount! > 0 ? '+' : ''}${txn.subAmount}",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}
 