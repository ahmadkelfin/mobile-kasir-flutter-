import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cash_provider.dart';

class CloseCashScreen extends StatefulWidget {
  const CloseCashScreen({super.key});

  @override
  State<CloseCashScreen> createState() => _CloseCashScreenState();
}

class _CloseCashScreenState extends State<CloseCashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _finalBalanceController = TextEditingController();
  final _totalSalesController = TextEditingController();
  final _notesController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  double _expectedBalance = 0;
  double _difference = 0;

  @override
  void initState() {
    super.initState();
    _finalBalanceController.addListener(_recalculate);
    _totalSalesController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _finalBalanceController.dispose();
    _totalSalesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final provider = context.read<CashProvider>();
    final session = provider.currentSession;
    if (session == null) return;

    final finalBalance = double.tryParse(
          _finalBalanceController.text
              .replaceAll('.', '')
              .replaceAll(',', ''),
        ) ??
        0;
    final totalSales = double.tryParse(
          _totalSalesController.text
              .replaceAll('.', '')
              .replaceAll(',', ''),
        ) ??
        0;

    final expected = session.initialBalance +
        totalSales +
        provider.totalCashIn -
        provider.totalCashOut;

    setState(() {
      _expectedBalance = expected;
      _difference = finalBalance - expected;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final finalBalance = double.tryParse(
          _finalBalanceController.text
              .replaceAll('.', '')
              .replaceAll(',', ''),
        ) ??
        0;
    final totalSales = double.tryParse(
          _totalSalesController.text
              .replaceAll('.', '')
              .replaceAll(',', ''),
        ) ??
        0;

    // Konfirmasi tutup kas
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Kas?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan penutupan kas:'),
            const SizedBox(height: 12),
            _dialogRow(
                'Total Penjualan', _currencyFormat.format(totalSales)),
            _dialogRow('Ekspektasi Saldo',
                _currencyFormat.format(_expectedBalance)),
            _dialogRow('Uang Fisik', _currencyFormat.format(finalBalance)),
            const Divider(),
            _dialogRow(
              'Selisih',
              _currencyFormat.format(_difference),
              valueColor: _difference == 0
                  ? Colors.green
                  : _difference > 0
                      ? Colors.blue
                      : Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935)),
            child: const Text('Ya, Tutup Kas',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<CashProvider>();
    final success = await provider.closeCashSession(
      finalBalance: finalBalance,
      totalSales: totalSales,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kas berhasil ditutup!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menutup kas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _dialogRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF616161))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashProvider>();
    final session = provider.currentSession;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Tutup Kas',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header info session
            if (session != null)
              _buildInfoCard(session, provider),
            const SizedBox(height: 16),

            // Input total penjualan
            _buildCard(
              title: 'Total Penjualan Hari Ini',
              child: _buildAmountField(
                controller: _totalSalesController,
                hint: '0',
                color: const Color(0xFF1565C0),
                validator: (v) => v == null || v.isEmpty
                    ? 'Masukkan total penjualan'
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Input uang fisik
            _buildCard(
              title: 'Uang Fisik di Laci (Hitung Manual)',
              child: _buildAmountField(
                controller: _finalBalanceController,
                hint: '0',
                color: const Color(0xFF6A1B9A),
                validator: (v) => v == null || v.isEmpty
                    ? 'Masukkan jumlah uang fisik'
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Kalkulasi otomatis
            _buildCalculationCard(provider),
            const SizedBox(height: 12),

            // Catatan
            _buildCard(
              title: 'Catatan Penutupan (Opsional)',
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration('Tambahkan catatan...'),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol tutup kas
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _submit,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_clock_rounded),
                label: Text(
                  provider.isLoading ? 'Memproses...' : 'Tutup Kas Sekarang',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(session, CashProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF37474F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip('Modal Awal',
                  _currencyFormat.format(session.initialBalance)),
              _infoChip('Kas Masuk',
                  '+ ${_currencyFormat.format(provider.totalCashIn)}',
                  color: Colors.green.shade300),
              _infoChip('Kas Keluar',
                  '- ${_currencyFormat.format(provider.totalCashOut)}',
                  color: Colors.red.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            )),
      ],
    );
  }

  Widget _buildCalculationCard(CashProvider provider) {
    final isMatch = _difference == 0;
    final isPlus = _difference > 0;
    final color = isMatch
        ? const Color(0xFF2E7D32)
        : isPlus
            ? const Color(0xFF1565C0)
            : const Color(0xFFB71C1C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ekspektasi Saldo',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF616161))),
              Text(
                _currencyFormat.format(_expectedBalance),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selisih',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
              Text(
                '${isPlus ? '+' : ''} ${_currencyFormat.format(_difference)}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ],
          ),
          if (!isMatch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                isPlus
                    ? '⚠️ Uang lebih dari ekspektasi'
                    : '⚠️ Uang kurang dari ekspektasi',
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String hint,
    required Color color,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: color),
      decoration: InputDecoration(
        prefixText: 'Rp ',
        prefixStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: color),
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFBDBDBD), fontSize: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF43A047), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }
}