import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../models/product.dart';
import '../../models/transaction_model.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class StorageCacheScreen extends StatefulWidget {
  const StorageCacheScreen({super.key});

  @override
  State<StorageCacheScreen> createState() => _StorageCacheScreenState();
}

class _StorageCacheScreenState extends State<StorageCacheScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final double _cacheSize = 0;
  double _imageCacheSize = 0;
  double _dataCacheSize = 0;
  final double _totalStorage = 512.0;
  double _usedStorage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    try {
      final stats = await StorageService.getStorageStats();
      if (mounted) {
        setState(() {
          _dataCacheSize = stats['appSize'] ?? 0;
          _imageCacheSize = stats['tempSize'] ?? 0;
          _usedStorage = stats['totalSize'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text(
            'Penyimpanan & Cache',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A2E),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Penyimpanan & Cache',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Overview
            _buildStorageOverview(),
            const SizedBox(height: 24),

            // Cache Management Section
            _buildSectionTitle('Manajemen Cache'),
            _buildCacheItem(
              icon: Icons.image_outlined,
              title: 'Cache Gambar',
              subtitle: 'Gambar produk dan avatar yang disimpan',
              size: _imageCacheSize,
              onClear: () => _clearImageCache(),
            ),
            _buildCacheItem(
              icon: Icons.data_usage_rounded,
              title: 'Cache Data',
              subtitle: 'Data sementara dan file offline',
              size: _dataCacheSize,
              onClear: () => _clearDataCache(),
            ),
            _buildCacheItem(
              icon: Icons.storage_rounded,
              title: 'Cache Aplikasi',
              subtitle: 'File sementara dan konfigurasi',
              size: _cacheSize,
              onClear: () => _clearAppCache(),
            ),

            const SizedBox(height: 20),

            // Clear All Cache Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _clearAllCache,
                icon: const Icon(Icons.cleaning_services_rounded),
                label: const Text(
                  'Bersihkan Semua Cache',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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

            const SizedBox(height: 24),

            // Data Management Section
            _buildSectionTitle('Manajemen Data'),
            _buildDataManagementItem(
              icon: Icons.backup_rounded,
              title: 'Cadangkan Data',
              subtitle: 'Buat cadangan data aplikasi ke cloud',
              onTap: () => _backupData(),
            ),
            _buildDataManagementItem(
              icon: Icons.restore_rounded,
              title: 'Pulihkan Data',
              subtitle: 'Pulihkan data dari cadangan',
              onTap: () => _restoreData(),
            ),
            _buildDataManagementItem(
              icon: Icons.delete_forever_rounded,
              title: 'Hapus Semua Data',
              subtitle: 'Hapus semua data aplikasi (tidak bisa dibatalkan)',
              onTap: () => _showDeleteAllDataDialog(),
              isDestructive: true,
            ),

            const SizedBox(height: 24),

            // Storage Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBBDEFB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tips Hemat Penyimpanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Bersihkan cache secara berkala'),
                  _buildTipItem('Hapus gambar produk yang tidak digunakan'),
                  _buildTipItem('Gunakan penyimpanan cloud untuk data besar'),
                  _buildTipItem('Aktifkan sinkronisasi otomatis untuk backup'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOverview() {
    final usedPercentage = (_usedStorage / _totalStorage) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Penyimpanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          // Storage Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: usedPercentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: usedPercentage > 80
                      ? const Color(0xFFE53935)
                      : const Color(0xFF3949AB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Storage Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_usedStorage.toStringAsFixed(1)} MB digunakan',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF616161),
                ),
              ),
              Text(
                '${_totalStorage.toStringAsFixed(0)} MB total',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(100 - usedPercentage).toStringAsFixed(1)}% tersedia',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: usedPercentage > 80
                  ? const Color(0xFFE53935)
                  : const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF616161),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCacheItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required double size,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3949AB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${size.toStringAsFixed(1)} MB',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Bersihkan',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFFE53935).withValues(alpha: 0.1)
                    : const Color(0xFF3949AB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? const Color(0xFFE53935)
                    : const Color(0xFF3949AB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? const Color(0xFFE53935)
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text(
            '•',
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearImageCache() async {
    try {
      final success = await StorageService.clearCache();
      if (success) {
        await _loadStorageStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cache gambar berhasil dibersihkan!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal membersihkan cache gambar'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _clearDataCache() async {
    try {
      final success = await StorageService.clearAppData();
      if (success) {
        await _loadStorageStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cache data berhasil dibersihkan!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal membersihkan cache data'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _clearAppCache() async {
    try {
      final success1 = await StorageService.clearCache();
      final success2 = await StorageService.clearAppData();
      if (success1 || success2) {
        await _loadStorageStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cache aplikasi berhasil dibersihkan!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal membersihkan cache aplikasi'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _clearAllCache() async {
    try {
      final success1 = await StorageService.clearCache();
      final success2 = await StorageService.clearAppData();
      if (success1 || success2) {
        await _loadStorageStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Semua cache berhasil dibersihkan!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal membersihkan semua cache'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _backupData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Memulai proses backup data...'),
        ),
      );

      final firestoreService = FirestoreService();

      // Get all products
      final products = await firestoreService.getAllProducts().first;

      // Get all transactions
      final transactions = await firestoreService.getAllTransactions().first;

      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'products': products.map((p) => {
          'id': p.id,
          'name': p.name,
          'price': p.price,
          'category': p.category,
          'stock': p.stock,
          'description': p.description,
          'imageUrl': p.imageUrl,
        }).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      final jsonString = jsonEncode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      // Share the backup file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup data Mobile Kasir - ${DateTime.now().toLocal().toString().split('.')[0]}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup berhasil dibuat dan dibagikan'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal membuat backup: $e'),
          ),
        );
      }
    }
  }

  void _restoreData() async {
    try {
      // Show dialog to paste backup JSON
      final jsonContent = await showDialog<String>(
        context: context,
        builder: (ctx) => const _RestoreDataDialog(),
      );

      if (jsonContent == null || jsonContent.isEmpty) {
        return; // User canceled
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Memproses data backup...'),
        ),
      );

      // Parse JSON
      final Map<String, dynamic> backupData = json.decode(jsonContent);

      // Validate backup structure
      if (!backupData.containsKey('products') ||
          !backupData.containsKey('transactions') ||
          !backupData.containsKey('timestamp')) {
        throw Exception('Format data backup tidak valid');
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi Restore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tanggal backup: ${DateFormat('dd/MM/yyyy HH:mm').format(
                DateTime.parse(backupData['timestamp']),
              )}'),
              const SizedBox(height: 8),
              Text('Produk: ${backupData['products'].length}'),
              Text('Transaksi: ${backupData['transactions'].length}'),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Data yang ada akan ditimpa. Pastikan backup sudah benar.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      if (!mounted) return;
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memulihkan data...'),
            ],
          ),
        ),
      );

      // Restore products
      final products = (backupData['products'] as List)
          .map((p) => Product.fromMap(p, p['id']))
          .toList();

      for (final product in products) {
        await _firestoreService.addProduct(product);
      }

      // Restore transactions
      final transactions = (backupData['transactions'] as List)
          .map((t) => TransactionModel.fromMap(t, t['id']))
          .toList();

      for (final transaction in transactions) {
        await _firestoreService.addTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Restore berhasil! ${products.length} produk dan ${transactions.length} transaksi dipulihkan.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        // Close any open dialogs
        if (Navigator.canPop(context)) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal restore data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAllDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Data?'),
        content: const Text(
          'Tindakan ini akan menghapus semua data aplikasi secara permanen. Data yang dihapus tidak dapat dikembalikan. Apakah Anda yakin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Show progress dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Menghapus semua data...'),
                      ],
                    ),
                  ),
                );

                await _firestoreService.deleteAllData();

                if (mounted) {
                  Navigator.pop(context); // Close progress dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Semua data berhasil dihapus'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Close any open dialogs
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Gagal menghapus data: $e'),
                      backgroundColor: Color(0xFFE53935),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
class _RestoreDataDialog extends StatefulWidget {
  const _RestoreDataDialog();

  @override
  State<_RestoreDataDialog> createState() => _RestoreDataDialogState();
}

class _RestoreDataDialogState extends State<_RestoreDataDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pulihkan Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tempel konten file backup JSON di bawah ini:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 8,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Tempel JSON backup di sini...',
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️ Pastikan JSON valid dan dari sumber terpercaya.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Pulihkan'),
        ),
      ],
    );
  }
}