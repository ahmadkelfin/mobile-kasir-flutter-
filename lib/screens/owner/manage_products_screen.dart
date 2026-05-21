import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';

// ─── Top-level helper functions (accessible by all classes) ──────────────────

Color _getCategoryColor(String category) {
  final colors = {
    'Makanan': Colors.orange,
    'Minuman': Colors.blue,
    'Snack': Colors.purple,
    'Umum': Colors.grey,
    'Dessert': Colors.pink,
    'Paket': Colors.teal,
  };
  return colors[category] ?? Colors.grey;
}

Color _getStockColor(int stock) {
  if (stock <= 0) return const Color(0xFFEF4444);
  if (stock <= 5) return const Color(0xFFF59E0B);
  return const Color(0xFF10B981);
}

Widget _buildImagePlaceholder(String category) {
  return Container(
    color: _getCategoryColor(category),
    child: const Icon(Icons.inventory, color: Colors.white, size: 28),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  List<String> _categories = ['Semua'];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _firestoreService.getProductCategories();
      if (!mounted) return;
      setState(() {
        _categories = ['Semua', ...categories];
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kelola Produk',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF1A1A2E),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Produk',
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari produk...',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Category Filter
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B)),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _selectedCategory == 'Semua'
                  ? _firestoreService.getAllProducts()
                  : _firestoreService
                      .getProductsByCategory(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data ?? [];
                final filteredProducts = _searchQuery.isEmpty
                    ? products
                    : products
                        .where((product) =>
                            product.name
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            product.category
                                .toLowerCase()
                                .contains(_searchQuery))
                        .toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.inventory_2_outlined
                              : Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? (_selectedCategory == 'Semua'
                                  ? 'Belum ada produk'
                                  : 'Tidak ada produk di kategori ini')
                              : 'Tidak ada produk yang cocok',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_searchQuery.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showAddProductDialog(context),
                            icon: const Icon(Icons.add_rounded),
                            label:
                                const Text('Tambah Produk Pertama'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _ProductCard(
                      product: product,
                      onEdit: () =>
                          _showEditProductDialog(context, product),
                      onUpdateStock: () =>
                          _showUpdateStockDialog(context, product),
                      onUpdateImage: () =>
                          _showUpdateImageDialog(context, product),
                      onDelete: () =>
                          _showDeleteConfirmation(context, product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FIX: child moved to last position (sort_child_properties_last)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        tooltip: 'Tambah Produk',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddProductDialog(),
    ).then((_) => _loadCategories());
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => EditProductDialog(product: product),
    );
  }

  void _showUpdateStockDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => UpdateStockDialog(product: product),
    );
  }

  void _showUpdateImageDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => UpdateProductImageDialog(product: product),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content:
            Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _firestoreService.deleteProduct(product.id);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Produk berhasil dihapus')),
                );
              } catch (e) {
                messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─── _ProductCard ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onUpdateStock;
  final VoidCallback onUpdateImage;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onUpdateStock,
    required this.onUpdateImage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            // FIX: uses top-level _getCategoryColor & _buildImagePlaceholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 60,
                child: product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: _getCategoryColor(product.category)
                                .withValues(alpha: 0.2),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(product.category),
                      )
                    : _buildImagePlaceholder(product.category),
              ),
            ),
            const SizedBox(width: 16),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStockColor(product.stock)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Stok: ${product.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStockColor(product.stock),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(product.category)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getCategoryColor(product.category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions Menu
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF64748B),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'stock':
                    onUpdateStock();
                    break;
                  case 'image':
                    onUpdateImage();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 18, color: Color(0xFF6366F1)),
                      SizedBox(width: 8),
                      Text('Edit Produk'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stock',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_rounded,
                          size: 18, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Text('Update Stok'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      Icon(Icons.image_rounded,
                          size: 18, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Ubah Foto'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded,
                          size: 18, color: Color(0xFFEF4444)),
                      SizedBox(width: 8),
                      Text('Hapus'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper: Upload gambar ke Firebase Storage ───────────────────────────────

class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(ImageSource source) async {
    try {
      final picked = await _picker
          .pickImage(
            source: source,
            imageQuality: 75,
            maxWidth: 800,
            maxHeight: 800,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () =>
                throw TimeoutException('Image picker timeout'),
          );

      if (picked == null) return null;

      final file = File(picked.path);
      if (!await file.exists()) {
        throw Exception('File tidak ditemukan: ${picked.path}');
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar (maks 10MB)');
      }

      return file;
    } on TimeoutException {
      throw Exception('Timeout saat memilih gambar. Coba lagi.');
    } catch (e) {
      throw Exception('Error memilih gambar: $e');
    }
  }

  static String _getFileExtension(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    if (!fileName.contains('.')) return '';
    return fileName.split('.').last.toLowerCase();
  }

  static String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'image/jpeg';
    }
  }

  static String _storageFileName(String productId, String extension) {
    if (extension.isEmpty) return productId;
    return '$productId.$extension';
  }

  static String? _detectExtensionFromSignature(List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 6 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'gif';
    }
    if (bytes.length >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }
    if (bytes.length >= 4 && ((bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) ||
        (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A))) {
      return 'tiff';
    }
    return null;
  }

  static Future<List<int>> _readFileSignature(File file, int maxBytes) async {
    final stream = file.openRead(0, maxBytes);
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
      if (chunks.length >= maxBytes) break;
    }
    return chunks;
  }

  static Future<String> _resolveUploadExtension(File file) async {
    final extension = _getFileExtension(file);
    if (extension.isNotEmpty) {
      return extension;
    }

    final signature = await _readFileSignature(file, 12);
    return _detectExtensionFromSignature(signature) ?? 'jpg';
  }

  static Future<String> uploadProductImage(
      File file, String productId) async {
    try {
      debugPrint('[UploadHelper] ========== START FILE UPLOAD ==========');
      debugPrint('[UploadHelper] File path: ${file.path}');
      debugPrint('[UploadHelper] Product ID: $productId');
      
      if (!await file.exists()) {
        debugPrint('[UploadHelper] ERROR: File does not exist!');
        throw Exception('File tidak ditemukan: ${file.path}');
      }
      debugPrint('[UploadHelper] File exists: ✓');

      final fileSize = await file.length();
      debugPrint('[UploadHelper] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      
      if (fileSize == 0) {
        debugPrint('[UploadHelper] ERROR: File is empty!');
        throw Exception('File kosong');
      }

      final extension = await _resolveUploadExtension(file);
      debugPrint('[UploadHelper] Detected extension: $extension');
      
      final fileName = _storageFileName(productId, extension);
      debugPrint('[UploadHelper] Storage filename: $fileName');
      
      final contentType = _contentTypeForExtension(extension);
      debugPrint('[UploadHelper] Content-Type: $contentType');

      final ref = FirebaseStorage.instance
          .ref()
          .child('products')
          .child(fileName);

      debugPrint('[UploadHelper] Starting upload to: products/$fileName');
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException('Upload timeout'),
      );

      debugPrint('[UploadHelper] Upload task finished. State: ${snapshot.state}');
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload tidak berhasil, status: ${snapshot.state}');
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('[UploadHelper] Upload success ✓');
      debugPrint('[UploadHelper] Download URL: $downloadUrl');
      debugPrint('[UploadHelper] ========== END FILE UPLOAD ==========');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('[UploadHelper] Firebase error: ${e.code} - ${e.message}');
      if (e.code == 'object-not-found') {
        throw Exception('Storage Firebase belum diaktifkan atau file gagal diunggah. Pastikan Anda sudah klik "Get Started" di menu Storage Firebase Console.');
      }
      throw Exception('Firebase error: ${e.message}');
    } on TimeoutException {
      debugPrint('[UploadHelper] Upload timeout after 120 seconds');
      throw Exception(
          'Upload timeout - koneksi internet terlalu lambat');
    } catch (e) {
      debugPrint('[UploadHelper] Catch-all error: ${e.runtimeType} - $e');
      throw Exception('Error upload gambar: $e');
    }
  }

  static Future<File?> showImageSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: Colors.blue),
                ),
                title: const Text('Pilih dari Galeri'),
                subtitle: const Text('Gunakan foto yang sudah ada'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.green),
                ),
                title: const Text('Ambil Foto'),
                subtitle: const Text('Foto langsung dengan kamera'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    try {
      return await pickImage(source);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }
}

// ─── Widget: Preview & picker gambar ─────────────────────────────────────────

class ProductImagePicker extends StatelessWidget {
  final File? selectedImage;
  final String? existingImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const ProductImagePicker({
    super.key,
    required this.selectedImage,
    required this.onPickImage,
    this.existingImageUrl,
    this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImage != null ||
        (existingImageUrl != null && existingImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Produk',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    hasImage ? Colors.transparent : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: hasImage ? _buildPreview() : _buildPlaceholder(),
          ),
        ),
        if (hasImage && onRemoveImage != null) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: onRemoveImage,
            icon: const Icon(Icons.delete_outline,
                size: 16, color: Colors.red),
            label: const Text('Hapus Foto',
                style: TextStyle(color: Colors.red, fontSize: 12)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: selectedImage != null
              ? Image.file(selectedImage!, fit: BoxFit.cover)
              : Image.network(existingImageUrl!, fit: BoxFit.cover),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Ganti Foto',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tambah Foto Produk',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Dari galeri atau kamera',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }
}

// ─── AddProductDialog ────────────────────────────────────────────────────────

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _selectedCategory = 'Umum';
  bool _isLoading = false;
  File? _selectedImage;

  final List<String> _categories = [
    'Umum',
    'Makanan',
    'Minuman',
    'Snack',
    'Dessert',
    'Paket',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImageUploadHelper.showImageSourceSheet(context);
    if (file != null) setState(() => _selectedImage = file);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Produk Baru'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProductImagePicker(
                selectedImage: _selectedImage,
                onPickImage: _pickImage,
                onRemoveImage: () =>
                    setState(() => _selectedImage = null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga harus diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok Awal',
                  prefixIcon: Icon(Icons.inventory_2),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok harus diisi';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Stok harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode (Opsional)',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate image file exists if selected
    if (_selectedImage != null) {
      if (!await _selectedImage!.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File gambar sudah dihapus. Silakan pilih ulang.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      debugPrint('[AddProduct] Image file validated. Path: ${_selectedImage!.path}');
      debugPrint('[AddProduct] Image file size: ${await _selectedImage!.length()} bytes');
    }
    
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('[AddProduct] ========== START SAVE PRODUCT ==========');
      final product = Product(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        stock: int.parse(_stockController.text),
        barcode: _barcodeController.text.trim(),
      );

      debugPrint('[AddProduct] Creating product: ${product.name}');
      final docRef = await _firestoreService.addProduct(product);
      debugPrint('[AddProduct] Product created with ID: ${docRef.id}');

      if (_selectedImage != null) {
        debugPrint('[AddProduct] Uploading image to Firebase Storage...');
        try {
          final imageUrl = await ImageUploadHelper.uploadProductImage(
            _selectedImage!,
            docRef.id,
          );
          debugPrint('[AddProduct] Image uploaded successfully. URL: $imageUrl');
          
          debugPrint('[AddProduct] Updating Firestore document with imageUrl...');
          await _firestoreService.updateProductImageUrl(
              docRef.id, imageUrl);
          debugPrint('[AddProduct] Firestore document updated successfully');
        } catch (uploadError) {
          debugPrint('[AddProduct] IMAGE UPLOAD FAILED: $uploadError');
          throw Exception('Gagal upload gambar: $uploadError');
        }
      } else {
        debugPrint('[AddProduct] No image selected, skipping upload');
      }

      debugPrint('[AddProduct] ========== SAVE PRODUCT SUCCESS ==========');
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Produk berhasil ditambahkan')),
      );
    } catch (e) {
      debugPrint('[AddProduct] ========== SAVE PRODUCT ERROR ==========');
      debugPrint('[AddProduct] Error type: ${e.runtimeType}');
      debugPrint('[AddProduct] Error message: $e');
      debugPrint('[AddProduct] ========== END ERROR ==========');
      
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── EditProductDialog ───────────────────────────────────────────────────────

class EditProductDialog extends StatefulWidget {
  final Product product;
  const EditProductDialog({super.key, required this.product});

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _barcodeController;
  late String _selectedCategory;
  bool _isLoading = false;
  File? _selectedImage;
  bool _removeExistingImage = false;

  final List<String> _categories = [
    'Umum',
    'Makanan',
    'Minuman',
    'Snack',
    'Dessert',
    'Paket',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.product.name);
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _barcodeController =
        TextEditingController(text: widget.product.barcode);
    _selectedCategory = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImageUploadHelper.showImageSourceSheet(context);
    if (file != null) {
      setState(() {
        _selectedImage = file;
        _removeExistingImage = false;
      });
    }
  }

  String? get _currentImageUrl =>
      _removeExistingImage ? null : widget.product.imageUrl;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Produk'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProductImagePicker(
                selectedImage: _selectedImage,
                existingImageUrl: _currentImageUrl,
                onPickImage: _pickImage,
                onRemoveImage: () => setState(() {
                  _selectedImage = null;
                  _removeExistingImage = true;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga harus diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      String? imageUrl =
          _removeExistingImage ? null : widget.product.imageUrl;

      if (_selectedImage != null) {
        imageUrl = await ImageUploadHelper.uploadProductImage(
          _selectedImage!,
          widget.product.id,
        );
      }

      final updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        barcode: _barcodeController.text.trim(),
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateProduct(
          widget.product.id, updatedProduct);

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Produk berhasil diupdate')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── UpdateProductImageDialog ─────────────────────────────────────────────────

class UpdateProductImageDialog extends StatefulWidget {
  final Product product;
  const UpdateProductImageDialog({super.key, required this.product});

  @override
  State<UpdateProductImageDialog> createState() =>
      _UpdateProductImageDialogState();
}

class _UpdateProductImageDialogState
    extends State<UpdateProductImageDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final file = await ImageUploadHelper.showImageSourceSheet(context);
    if (file != null) setState(() => _selectedImage = file);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.image, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Foto: ${widget.product.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ProductImagePicker(
          selectedImage: _selectedImage,
          existingImageUrl: widget.product.imageUrl,
          onPickImage: _pickImage,
          onRemoveImage: () =>
              setState(() => _selectedImage = null),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed:
              (_isLoading || _selectedImage == null) ? null : _saveImage,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: const Text('Simpan Foto'),
        ),
      ],
    );
  }

  Future<void> _saveImage() async {
    if (_selectedImage == null) return;
    
    // Validate image file exists
    if (!await _selectedImage!.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File gambar sudah dihapus. Silakan pilih ulang.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    debugPrint('[UpdateImage] Image file validated. Path: ${_selectedImage!.path}');
    debugPrint('[UpdateImage] Image file size: ${await _selectedImage!.length()} bytes');
    
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('[UpdateImage] ========== START UPDATE IMAGE ==========');
      debugPrint('[UpdateImage] Uploading image for product: ${widget.product.id}');
      try {
        final imageUrl = await ImageUploadHelper.uploadProductImage(
          _selectedImage!,
          widget.product.id,
        );
        debugPrint('[UpdateImage] Image uploaded successfully. URL: $imageUrl');
        
        debugPrint('[UpdateImage] Updating Firestore document with new imageUrl...');
        await _firestoreService.updateProductImageUrl(
            widget.product.id, imageUrl);
        debugPrint('[UpdateImage] Firestore document updated successfully');
      } catch (uploadError) {
        debugPrint('[UpdateImage] IMAGE UPLOAD FAILED: $uploadError');
        throw Exception('Gagal upload gambar: $uploadError');
      }

      debugPrint('[UpdateImage] ========== UPDATE IMAGE SUCCESS ==========');
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Foto produk berhasil diupdate')),
      );
    } catch (e) {
      debugPrint('[UpdateImage] ========== UPDATE IMAGE ERROR ==========');
      debugPrint('[UpdateImage] Error type: ${e.runtimeType}');
      debugPrint('[UpdateImage] Error message: $e');
      debugPrint('[UpdateImage] ========== END ERROR ==========');
      
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error upload: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── UpdateStockDialog ───────────────────────────────────────────────────────

class UpdateStockDialog extends StatefulWidget {
  final Product product;
  const UpdateStockDialog({super.key, required this.product});

  @override
  State<UpdateStockDialog> createState() => _UpdateStockDialogState();
}

class _UpdateStockDialogState extends State<UpdateStockDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stockController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
        text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Stok - ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _stockController,
          decoration: const InputDecoration(
            labelText: 'Stok Baru',
            prefixIcon: Icon(Icons.inventory_2),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Stok harus diisi';
            }
            if (int.tryParse(value) == null) {
              return 'Stok harus berupa angka';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStock,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateStock() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final newStock = int.parse(_stockController.text);
      await _firestoreService.updateProductStock(
          widget.product.id, newStock);
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Stok berhasil diupdate')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}