import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cash_provider.dart';
import 'open_cash_screen.dart';
import 'close_cash_screen.dart';
import 'cash_transaction_form.dart';
import 'cash_history_screen.dart';

class KasShiftScreen extends StatefulWidget {
  const KasShiftScreen({super.key});

  @override
  State<KasShiftScreen> createState() => _KasShiftScreenState();
}

class _KasShiftScreenState extends State<KasShiftScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Kas & Shift',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Kas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CashHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<CashProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                _buildStatusCard(provider),
                const SizedBox(height: 16),

                if (provider.isCashOpen) ...[
                  // Ringkasan saldo
                  _buildSummaryRow(provider),
                  const SizedBox(height: 16),

                  // Aksi kas masuk / keluar
                  _buildCashActionButtons(context, provider),
                  const SizedBox(height: 16),

                  // Daftar transaksi kas hari ini
                  _buildTransactionList(provider),
                  const SizedBox(height: 80),
                ],
              ],
            ),
          );
        },
      ),

      // FAB: buka kas / tutup kas
      floatingActionButton: Consumer<CashProvider>(
        builder: (context, provider, _) {
          if (provider.isCashOpen) {
            return FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloseCashScreen()),
              ),
              icon: const Icon(Icons.lock_clock_rounded),
              label: const Text('Tutup Kas'),
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            );
          }
          return FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OpenCashScreen()),
            ),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Buka Kas'),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  // ─── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _buildStatusCard(CashProvider provider) {
    final session = provider.currentSession;
    final isOpen = provider.isCashOpen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
              : [const Color(0xFF37474F), const Color(0xFF78909C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? const Color(0xFF2E7D32) : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF69F0AE)
                            : Colors.red.shade200,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'KAS BUKA' : 'KAS TUTUP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (session != null) ...[
            Text(
              'Modal Awal',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _currencyFormat.format(session.initialBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  'Dibuka: ${DateFormat('dd MMM yyyy, HH:mm').format(session.openedAt)}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  session.userName,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Belum ada sesi kas aktif',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Tekan tombol Buka Kas untuk memulai shift',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(CashProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Kas Masuk',
            amount: provider.totalCashIn,
            color: const Color(0xFF2E7D32),
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            label: 'Kas Keluar',
            amount: provider.totalCashOut,
            color: const Color(0xFFC62828),
            icon: Icons.arrow_upward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  _currencyFormat.format(amount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashActionButtons(
      BuildContext context, CashProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Kas Masuk',
            icon: Icons.add_circle_outline_rounded,
            color: const Color(0xFF2E7D32),
            onTap: () => _showCashTransactionForm(context, 'in'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Kas Keluar',
            icon: Icons.remove_circle_outline_rounded,
            color: const Color(0xFFC62828),
            onTap: () => _showCashTransactionForm(context, 'out'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(CashProvider provider) {
    final txns = provider.cashTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaksi Kas Hari Ini',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        if (txns.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 40, color: Color(0xFFBDBDBD)),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada transaksi kas',
                    style:
                        TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _buildTransactionItem(txns[i]),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(cashTxn) {
    final isIn = cashTxn.type == 'in';
    final color =
        isIn ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cashTxn.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (cashTxn.category != null)
                  Text(
                    cashTxn.category!,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9E9E9E)),
                  ),
                Text(
                  DateFormat('HH:mm').format(cashTxn.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFBDBDBD)),
                ),
              ],
            ),
          ),
          Text(
            '${isIn ? '+' : '-'} ${_currencyFormat.format(cashTxn.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCashTransactionForm(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CashTransactionForm(type: type),
    );
  }
}