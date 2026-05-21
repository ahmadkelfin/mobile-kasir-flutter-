import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final String? userId;
  final String title;

  const TransactionHistoryScreen({super.key, this.userId, required this.title});

  Stream<List<TransactionModel>> _transactionsStream() {
    final service = FirestoreService();
    if (userId == null) {
      return service.getAllTransactions();
    }
    return service.getUserTransactions(userId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return const Center(
              child: Text('Belum ada transaksi.', style: TextStyle(fontSize: 16)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            transaction.type == 'income' ? 'Pendapatan' : 'Pengeluaran',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Chip(
                            label: Text(
                              transaction.type == 'income' ? 'Income' : 'Expense',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: transaction.type == 'income' ? Colors.green : Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        transaction.description ?? 'Transaksi kasir',
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatRupiah(transaction.amount.toInt()),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            transaction.createdAt.toLocal().toString().split('.')[0],
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
