import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cash_provider.dart';
import '../../models/cash_session.dart';

class CashHistoryScreen extends StatelessWidget {
  const CashHistoryScreen({super.key});

  static final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashProvider>();
    final sessions = provider.sessionHistory
        .where((s) => s.status == 'closed')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Riwayat Kas',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: Color(0xFFBDBDBD)),
                  SizedBox(height: 12),
                  Text('Belum ada riwayat kas',
                      style: TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _buildSessionCard(context, sessions[i]),
            ),
    );
  }

  Widget _buildSessionCard(BuildContext context, CashSession session) {
    final diff = session.difference ?? 0;
    final diffColor = diff == 0
        ? const Color(0xFF2E7D32)
        : diff > 0
            ? const Color(0xFF1565C0)
            : const Color(0xFFB71C1C);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF37474F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale_rounded,
                  size: 18, color: Color(0xFF37474F)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd MMM yyyy', 'id_ID')
                        .format(session.openedAt),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    '${DateFormat('HH:mm').format(session.openedAt)} - ${session.closedAt != null ? DateFormat('HH:mm').format(session.closedAt!) : '-'}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${diff >= 0 ? '+' : ''}${_currencyFormat.format(diff)}',
                style: TextStyle(
                  color: diffColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow('Modal Awal',
              _currencyFormat.format(session.initialBalance)),
          _infoRow('Total Penjualan',
              _currencyFormat.format(session.totalSales ?? 0)),
          _infoRow('Kas Masuk',
              '+ ${_currencyFormat.format(session.totalCashIn ?? 0)}',
              color: const Color(0xFF2E7D32)),
          _infoRow('Kas Keluar',
              '- ${_currencyFormat.format(session.totalCashOut ?? 0)}',
              color: const Color(0xFFC62828)),
          const Divider(height: 20),
          _infoRow('Ekspektasi Saldo',
              _currencyFormat.format(session.expectedBalance)),
          _infoRow('Uang Fisik',
              _currencyFormat.format(session.finalBalance ?? 0)),
          _infoRow(
            'Selisih',
            '${diff >= 0 ? '+' : ''}${_currencyFormat.format(diff)}',
            color: diffColor,
            bold: true,
          ),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.notes!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF616161)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 13, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text(session.userName,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9E9E9E))),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF616161))),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}