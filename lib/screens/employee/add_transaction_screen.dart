import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/receipt_printer_service.dart';
import '../../models/transaction_model.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../widgets/printer_connection_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _customerController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');

  final List<CartItem> _cartItems = [];
  String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Card',
    'Digital Wallet',
    'Transfer',
  ];

  @override
  void dispose() {
    _customerController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  void _addProductToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + 1,
        );
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: _cartItems[index].quantity - 1,
        );
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  void _clearCart() {
    setState(() => _cartItems.clear());
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _tax => double.tryParse(_taxController.text) ?? 0;
  double get _total => _subtotal - _discount + _tax;

  Future<void> _processTransaction() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // Verify user is authenticated
      if (authProvider.userModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not loaded')),
        );
        return;
      }

      final items = _cartItems.map((cartItem) => TransactionItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        price: cartItem.product.price,
        quantity: cartItem.quantity,
        category: cartItem.product.category,
      )).toList();

      final transaction = TransactionModel(
        id: '',
        userId: authProvider.userModel!.uid,
        amount: _total,
        type: 'income',
        createdAt: DateTime.now(),
        description: 'Penjualan POS - ${items.length} item(s)',
        paymentMethod: _selectedPaymentMethod,
        customerName: _customerController.text.isEmpty ? null : _customerController.text,
        items: items,
        discount: _discount > 0 ? _discount : null,
        tax: _tax > 0 ? _tax : null,
      );

      await _firestoreService.addTransaction(transaction);

      // Update product stock
      for (var cartItem in _cartItems) {
        final newStock = cartItem.product.stock - cartItem.quantity;
        await _firestoreService.updateProductStock(cartItem.product.id, newStock);
      }

      if (mounted) {
        // Show print dialog
        _showPrintOptions(transaction);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPrintOptions(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cetak Nota?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Cetak Nota'),
              onPressed: () {
                Navigator.pop(context);
                _printReceipt(transaction);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Bagikan Nota'),
              onPressed: () {
                Navigator.pop(context);
                _shareReceipt(transaction);
                _completeTransaction();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Lewati'),
              onPressed: () {
                Navigator.pop(context);
                _completeTransaction();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt(TransactionModel transaction) async {
    try {
      // Check if printer is connected
      final isConnected = await ReceiptPrinterService.isConnected();

      if (!isConnected) {
        // Show printer selection dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => PrinterConnectionDialog(
              onPrinterSelected: (device) async {
                await ReceiptPrinterService.printReceipt(transaction);
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Nota berhasil dicetak!')),
                  );
                  _completeTransaction();
                }
              },
              onSkip: _completeTransaction,
            ),
          );
        }
      } else {
        // Print directly
        await ReceiptPrinterService.printReceipt(transaction);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Nota berhasil dicetak!')),
          );
          _completeTransaction();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _completeTransaction() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil diproses')),
    );
  }

  String _generateReceiptText(TransactionModel transaction) {
    final buffer = StringBuffer();
    buffer.writeln('=== NOTA TRANSAKSI ===');
    buffer.writeln('Tanggal: ${transaction.createdAt.toLocal().toString().split('.')[0]}');
    if (transaction.customerName != null) {
      buffer.writeln('Pelanggan: ${transaction.customerName}');
    }
    buffer.writeln('Metode Pembayaran: ${transaction.paymentMethod}');
    buffer.writeln('');
    buffer.writeln('Item:');
    if (transaction.items != null) {
      for (var item in transaction.items!) {
        buffer.writeln('${item.productName} x${item.quantity} - Rp${item.price * item.quantity}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Subtotal: Rp${transaction.amount + (transaction.discount ?? 0) - (transaction.tax ?? 0)}');
    if (transaction.discount != null && transaction.discount! > 0) {
      buffer.writeln('Diskon: -Rp${transaction.discount}');
    }
    if (transaction.tax != null && transaction.tax! > 0) {
      buffer.writeln('Pajak: +Rp${transaction.tax}');
    }
    buffer.writeln('Total: Rp${transaction.amount}');
    buffer.writeln('');
    buffer.writeln('Terima kasih atas kunjungannya!');
    return buffer.toString();
  }

  Future<void> _shareReceipt(TransactionModel transaction) async {
    final receiptText = _generateReceiptText(transaction);
    await SharePlus.instance.share(
      ShareParams(
        text: receiptText,
        subject: 'Nota Transaksi',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Kasir'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Kosongkan Keranjang',
              onPressed: _clearCart,
            ),
        ],
      ),
      body: Column(
        children: [
          // Product selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: StreamBuilder<List<Product>>(
                    stream: _firestoreService.getAllProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final products = snapshot.data ?? [];
                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            'Belum ada produk',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _addProductToCart(product),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 38,
                                      width: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Rp ${product.price.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Stok ${product.stock}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Keranjang',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('${_cartItems.length} item'),
                          backgroundColor: Colors.blue[50],
                          labelStyle: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Keranjang masih kosong',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ketuk produk untuk menambah ke keranjang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _cartItems.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final cartItem = _cartItems[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Rp ${cartItem.product.price.toStringAsFixed(0)} x ${cartItem.quantity}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Rp ${cartItem.total.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: () => _removeFromCart(index),
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Checkout section
          if (_cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Customer and payment info
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Pelanggan (Opsional)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Pembayaran',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedPaymentMethod = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Discount and tax
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          decoration: const InputDecoration(
                            labelText: 'Diskon (Rp)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _taxController,
                          decoration: const InputDecoration(
                            labelText: 'Pajak (Rp)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('Rp ${_subtotal.toStringAsFixed(0)}'),
                          ],
                        ),
                        if (_discount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diskon:'),
                              Text('-Rp ${_discount.toStringAsFixed(0)}'),
                            ],
                          ),
                        if (_tax > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pajak:'),
                              Text('+Rp ${_tax.toStringAsFixed(0)}'),
                            ],
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Rp ${_total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Process button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Proses Transaksi',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}