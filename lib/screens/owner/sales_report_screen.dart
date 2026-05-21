import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      // Get transactions for the selected date
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestoreService.getAllTransactions().first;
      final transactions = snapshot
          .where((transaction) =>
              transaction.createdAt.isAfter(startOfDay) &&
              transaction.createdAt.isBefore(endOfDay))
          .toList();

      // Calculate report data
      double totalSales = 0;
      double totalIncome = 0;
      double totalExpense = 0;
      int transactionCount = transactions.length;

      Map<String, double> categorySales = {};
      Map<String, int> paymentMethods = {};

      for (var transaction in transactions) {
        if (transaction.type == 'income') {
          totalIncome += transaction.amount;
          totalSales += transaction.amount;

          // Count payment methods
          String paymentMethod = transaction.paymentMethod ?? 'Cash';
          paymentMethods[paymentMethod] = (paymentMethods[paymentMethod] ?? 0) + 1;

          // Count category sales (if available in transaction)
          // This would need to be enhanced based on your transaction model
        } else {
          totalExpense += transaction.amount;
        }
      }

      setState(() {
        _reportData = {
          'totalSales': totalSales,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
          'transactionCount': transactionCount,
          'categorySales': categorySales,
          'paymentMethods': paymentMethods,
          'transactions': transactions,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Pilih Tanggal',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
              ? const Center(child: Text('Tidak ada data laporan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                'Laporan Tanggal: ${_selectedDate.toString().split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Summary cards
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _SummaryCard(
                            title: 'Total Penjualan',
                            value: 'Rp ${_reportData!['totalSales'].toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                          _SummaryCard(
                            title: 'Jumlah Transaksi',
                            value: '${_reportData!['transactionCount']}',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                          _SummaryCard(
                            title: 'Total Pemasukan',
                            value: 'Rp ${_reportData!['totalIncome'].toStringAsFixed(0)}',
                            icon: Icons.trending_up,
                            color: Colors.green,
                          ),
                          _SummaryCard(
                            title: 'Total Pengeluaran',
                            value: 'Rp ${_reportData!['totalExpense'].toStringAsFixed(0)}',
                            icon: Icons.trending_down,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Payment methods
                      if ((_reportData!['paymentMethods'] as Map).isNotEmpty) ...[
                        const Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: (_reportData!['paymentMethods'] as Map<String, int>)
                                  .entries
                                  .map((entry) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(entry.key),
                                            Text('${entry.value} transaksi'),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Recent transactions
                      const Text(
                        'Transaksi Hari Ini',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_reportData!['transactions'] as List<TransactionModel>)
                          .take(10) // Show only last 10 transactions
                          .map((transaction) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: transaction.type == 'income'
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      transaction.type == 'income'
                                          ? Icons.trending_up
                                          : Icons.trending_down,
                                      color: transaction.type == 'income'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  title: Text(transaction.description ?? 'Transaksi'),
                                  subtitle: Text(
                                    transaction.createdAt.toString().split('.')[0],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Text(
                                    'Rp ${transaction.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: transaction.type == 'income'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              )),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}