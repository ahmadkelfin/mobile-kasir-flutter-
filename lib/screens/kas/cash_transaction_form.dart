import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/cash_provider.dart';

class CashTransactionForm extends StatefulWidget {
  final String type; // 'in' | 'out'

  const CashTransactionForm({super.key, required this.type});

  @override
  State<CashTransactionForm> createState() => _CashTransactionFormState();
}

class _CashTransactionFormState extends State<CashTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;

  bool get isIn => widget.type == 'in';

  final List<String> _categoriesIn = [
    'Modal tambahan',
    'Pembayaran hutang',
    'Lainnya',
  ];

  final List<String> _categoriesOut = [
    'Listrik',
    'Gas',
    'Air',
    'Belanja bahan',
    'Gaji karyawan',
    'Biaya operasional',
    'Lainnya',
  ];

  List<String> get _categories => isIn ? _categoriesIn : _categoriesOut;

  Color get _themeColor =>
      isIn ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(
          _amountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;

    final provider = context.read<CashProvider>();
    final success = await provider.addCashTransaction(
      type: widget.type,
      amount: amount,
      description: _descController.text.trim(),
      category: _selectedCategory,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ ${isIn ? 'Kas masuk' : 'Kas keluar'} berhasil dicatat!'),
          backgroundColor: _themeColor,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(provider.errorMessage ?? 'Gagal menyimpan transaksi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isIn
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: _themeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isIn ? 'Kas Masuk' : 'Kas Keluar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _themeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Jumlah
            Text('Jumlah',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _themeColor,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _themeColor,
                ),
                hintText: '0',
                hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD), fontSize: 24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _themeColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _themeColor, width: 2),
                ),
                filled: true,
                fillColor: _themeColor.withValues(alpha: 0.03),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Masukkan jumlah' : null,
            ),
            const SizedBox(height: 14),

            // Kategori
            Text('Kategori',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? _themeColor
                          : _themeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _themeColor
                            : _themeColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : _themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Keterangan
            Text('Keterangan',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                hintText: isIn
                    ? 'Contoh: Tambah modal dari owner'
                    : 'Contoh: Bayar tagihan listrik',
                hintStyle:
                    const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
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
                  borderSide: BorderSide(color: _themeColor, width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Masukkan keterangan' : null,
            ),
            const SizedBox(height: 20),

            // Tombol simpan
            Consumer<CashProvider>(
              builder: (_, provider, __) => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: provider.isLoading ? null : _submit,
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isIn
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded),
                  label: Text(
                    provider.isLoading
                        ? 'Menyimpan...'
                        : 'Simpan ${isIn ? 'Kas Masuk' : 'Kas Keluar'}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}