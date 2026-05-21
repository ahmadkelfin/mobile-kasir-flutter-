import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../utils/formatters.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _paymentController = TextEditingController();
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  int _paidAmount = 0;
  bool _isCheckingOut = false;
  bool _isPrinting = false; // ← tambahan: loading state saat cetak

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void _updatePaidAmount(String value) {
    final cleaned = value.replaceAll(RegExp('[^0-9]'), '');
    setState(() {
      _paidAmount = int.tryParse(cleaned) ?? 0;
    });
  }

  // ── ESC/POS helpers ──────────────────────────────────────
  List<int> _esc(String text) => text.codeUnits;
  List<int> _line(String text) => [..._esc(text), 10];

  List<int> _centerText(String text, {int width = 32}) {
    final pad = ((width - text.length) / 2).floor();
    final padded = '${' ' * (pad < 0 ? 0 : pad)}$text';
    return _line(padded);
  }

  List<int> _leftRight(String left, String right, {int width = 32}) {
    final spaces = width - left.length - right.length;
    final row = spaces > 0 ? '$left${' ' * spaces}$right' : '$left $right';
    return _line(row);
  }

  List<int> _divider({int width = 32}) => _line('-' * width);

  static const List<int> _boldOn  = [0x1B, 0x45, 0x01];
  static const List<int> _boldOff = [0x1B, 0x45, 0x00];
  static const List<int> _init    = [0x1B, 0x40];
  static const List<int> _cut     = [0x1D, 0x56, 0x41, 0x00];
  static const List<int> _newLine = [10];

  Uint8List _buildReceipt(
    CartProvider cartProvider,
    int totalPrice,
    int paidAmount,
    int change,
  ) {
    final List<int> bytes = [];
    bytes.addAll(_init);
    bytes.addAll(_newLine);

    // Header
    bytes.addAll(_boldOn);
    bytes.addAll(_centerText('=== MOBILE KASIR ==='));
    bytes.addAll(_boldOff);
    bytes.addAll(_line('Tgl: ${DateTime.now().toString().split('.')[0]}'));
    bytes.addAll(_divider());

    // Items
    for (final item in cartProvider.items) {
      bytes.addAll(_line('${item.product.name} x${item.quantity}'));
      bytes.addAll(_leftRight('', formatRupiah(item.totalPrice)));
    }
    bytes.addAll(_divider());

    // Totals
    bytes.addAll(_boldOn);
    bytes.addAll(_leftRight('Total', formatRupiah(totalPrice)));
    bytes.addAll(_boldOff);
    bytes.addAll(_leftRight('Bayar', formatRupiah(paidAmount)));
    bytes.addAll(_leftRight('Kembalian', formatRupiah(change >= 0 ? change : 0)));
    bytes.addAll(_newLine);
    bytes.addAll(_boldOn);
    bytes.addAll(_centerText('=== TERIMA KASIH! ==='));
    bytes.addAll(_boldOff);
    bytes.addAll(_newLine);
    bytes.addAll(_newLine);
    bytes.addAll(_newLine);
    bytes.addAll(_cut);

    return Uint8List.fromList(bytes);
  }

  Future<void> _printReceipt(
    CartProvider cartProvider,
    int totalPrice,
    int paidAmount,
    int change,
  ) async {
    // Cegah double tap
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceAddress = prefs.getString('printer_device_address');
      final deviceName    = prefs.getString('printer_device_name');

      if (deviceAddress == null || deviceName == null) {
        _showSnackBar('Printer belum dikonfigurasi. Buka Pengaturan Printer.', isError: true);
        return;
      }

      bool? isConnected = await _printer.isConnected;
      if (isConnected != true) {
        final device = BluetoothDevice(deviceName, deviceAddress);
        await _printer.connect(device);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final receipt = _buildReceipt(cartProvider, totalPrice, paidAmount, change);
      await _printer.writeBytes(receipt);

      if (mounted) _showSnackBar('Nota berhasil dicetak');
    } catch (e) {
      if (mounted) _showSnackBar('Gagal mencetak nota: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _buildReceiptText(
    CartProvider cartProvider,
    int totalPrice,
    int paidAmount,
    int change,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════');
    buffer.writeln('    MOBILE KASIR');
    buffer.writeln('═══════════════════');
    buffer.writeln('Tanggal: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('───────────────────');
    
    for (final item in cartProvider.items) {
      buffer.writeln('${item.product.name} x${item.quantity}');
      buffer.writeln('    ${formatRupiah(item.totalPrice)}');
    }
    
    buffer.writeln('───────────────────');
    buffer.writeln('Total: ${formatRupiah(totalPrice)}');
    buffer.writeln('Bayar: ${formatRupiah(paidAmount)}');
    buffer.writeln('Kembalian: ${formatRupiah(change >= 0 ? change : 0)}');
    buffer.writeln('───────────────────');
    buffer.writeln('     TERIMA KASIH!');
    buffer.writeln('═══════════════════');
    
    return buffer.toString();
  }

  Future<void> _shareReceipt(
    CartProvider cartProvider,
    int totalPrice,
    int paidAmount,
    int change,
  ) async {
    try {
      final receiptText = _buildReceiptText(
        cartProvider,
        totalPrice,
        paidAmount,
        change,
      );
      
      await Share.share(receiptText, subject: 'Struk Pembayaran - Mobile Kasir');
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membagikan nota: $e', isError: true);
      }
    }
  }

  void _showReceiptDialog(
    BuildContext context,
    CartProvider cartProvider,
    int totalPrice,
    int paidAmount,
    int change,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Struk Pembayaran'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mobile Kasir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                'Tanggal: ${DateTime.now().toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(),
              ...cartProvider.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} x${item.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(formatRupiah(item.totalPrice),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const Divider(),
              _receiptRow('Total', formatRupiah(totalPrice), bold: true),
              _receiptRow('Bayar', formatRupiah(paidAmount)),
              _receiptRow('Kembalian', formatRupiah(change >= 0 ? change : 0)),
            ],
          ),
        ),
        actions: [
          // Tombol berbagi nota
          TextButton.icon(
            onPressed: () {
              _shareReceipt(cartProvider, totalPrice, paidAmount, change);
            },
            icon: const Icon(Icons.share),
            label: const Text('Bagikan'),
          ),
          // Tombol cetak dengan loading state
          StatefulBuilder(
            builder: (context, setStateDialog) => TextButton.icon(
              onPressed: _isPrinting
                  ? null
                  : () async {
                      setStateDialog(() {});
                      await _printReceipt(
                          cartProvider, totalPrice, paidAmount, change);
                      setStateDialog(() {});
                    },
              icon: _isPrinting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print),
              label: Text(_isPrinting ? 'Mencetak...' : 'Cetak Nota'),
            ),
          ),
          TextButton(
            onPressed: () {
              cartProvider.clear();
              _paymentController.clear();
              setState(() => _paidAmount = 0);
              Navigator.of(ctx).pop();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final totalPrice   = cartProvider.totalPrice;
    final change       = _paidAmount - totalPrice;
    final canCheckout  = !cartProvider.isEmpty && _paidAmount >= totalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        actions: [
          if (!cartProvider.isEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Kosongkan Keranjang',
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Kosongkan Keranjang'),
                  content: const Text(
                      'Apakah Anda yakin ingin mengosongkan keranjang?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        cartProvider.clear();
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Ya'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cartProvider.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 90, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Keranjang kosong',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(
                        'Tambahkan produk terlebih dahulu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: cartProvider.items.length,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return CartItemTile(
                      cartItem: item,
                      onRemove: () =>
                          cartProvider.removeProduct(item.product.id),
                      onQuantityChanged: (quantity) =>
                          cartProvider.updateQuantity(item.product.id, quantity),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Harga',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(formatRupiah(totalPrice),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _paymentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Uang Bayar',
                          prefixText: 'Rp ',
                          hintText: 'Masukkan jumlah yang dibayar pelanggan',
                        ),
                        onChanged: _updatePaidAmount,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          Text(
                            change >= 0 ? formatRupiah(change) : formatRupiah(0),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: change >= 0
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: canCheckout && !_isCheckingOut
                            ? () async {
                                setState(() => _isCheckingOut = true);
                                await Future.delayed(
                                    const Duration(milliseconds: 300));
                                if (mounted) {
                                  setState(() => _isCheckingOut = false);
                                  _showReceiptDialog(context, cartProvider,
                                      totalPrice, _paidAmount, change);
                                }
                              }
                            : null,
                        child: _isCheckingOut
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Checkout'),
                      ),
                      const SizedBox(height: 10),
                      if (_paidAmount > 0 && _paidAmount < totalPrice)
                        const Text(
                          'Uang bayar harus lebih besar atau sama dengan total.',
                          style: TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}