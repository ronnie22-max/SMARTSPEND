import 'package:flutter/material.dart';
import 'package:smartspend/models/transaction_model.dart';
import 'package:smartspend/services/user_data_service.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TransactionManager _transactionManager = TransactionManager();
  final UserDataService _userDataService = UserDataService();

  Future<void> _clearAllTransactions() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Transactions?'),
          content: const Text(
            'This will delete all transactions. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _transactionManager.clearTransactions();
                if (!dialogContext.mounted || !mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All transactions cleared'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<TransactionRecord>> _groupByDate(
    List<TransactionRecord> transactions,
  ) {
    final grouped = <String, List<TransactionRecord>>{};
    for (final txn in transactions) {
      grouped.putIfAbsent(txn.formattedDate, () => []).add(txn);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/home');
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Transactions",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<List<TransactionRecord>>(
                    stream: _userDataService.watchTransactions(),
                    builder: (context, snapshot) {
                      final transactions =
                          snapshot.data ?? const <TransactionRecord>[];
                      if (transactions.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        tooltip: 'Clear all transactions',
                        onPressed: _clearAllTransactions,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                child: StreamBuilder<List<TransactionRecord>>(
                  stream: _userDataService.watchTransactions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load transactions',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    final transactions =
                        snapshot.data ?? const <TransactionRecord>[];
                    final groupedTransactions = _groupByDate(transactions);

                    if (groupedTransactions.isEmpty) {
                      return Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }

                    return ListView(
                      children: groupedTransactions.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...entry.value.map(_transactionItem),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionItem(TransactionRecord txn) {
    return Dismissible(
      key: Key(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _transactionManager.removeTransaction(txn.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: txn.typeColor.withValues(alpha: 0.2),
            child: Icon(txn.icon, color: txn.typeColor),
          ),
          title: Text(
            txn.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                txn.formattedTime,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (txn.description != null)
                Text(
                  txn.description!,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${txn.type == TransactionType.income || txn.type == TransactionType.deposit ? '+' : '-'}UGX ${txn.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: txn.typeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                txn.typeLabel,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
