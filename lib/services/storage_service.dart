import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();

      // Calculate sizes
      double tempSize = 0;
      double appSize = 0;

      if (await tempDir.exists()) {
        tempSize = (await _calculateDirectorySize(tempDir)).toDouble();
      }

      if (await appDir.exists()) {
        appSize = (await _calculateDirectorySize(appDir)).toDouble();
      }

      return {
        'tempSize': tempSize / (1024 * 1024), // Convert to MB
        'appSize': appSize / (1024 * 1024),
        'totalSize': (tempSize + appSize) / (1024 * 1024),
      };
    } catch (e) {
      return {
        'tempSize': 0.0,
        'appSize': 0.0,
        'totalSize': 0.0,
      };
    }
  }

  /// Calculate directory size recursively
  static Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        final files = dir.listSync(recursive: true, followLinks: false);
        for (var file in files) {
          if (file is File) {
            size += await file.length();
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return size;
  }

  /// Clear cache directory
  static Future<bool> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        tempDir.deleteSync(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear app documents
  static Future<bool> clearAppData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      if (await appDir.exists()) {
        final files = appDir.listSync();
        for (var file in files) {
          if (file is File) {
            await file.delete();
          } else if (file is Directory) {
            await file.delete(recursive: true);
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test Firebase Storage connectivity
  static Future<bool> testStorageConnectivity() async {
    try {
      // Try to access the bucket info
      await _storage.ref().getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete file from Firebase Storage
  static Future<void> deleteProductImage(String productId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('products');
      final items = await ref.listAll();
      for (var item in items.items) {
        final name = item.name;
        final baseName = name.contains('.')
            ? name.substring(0, name.lastIndexOf('.'))
            : name;
        if (baseName == productId) {
          await item.delete();
        }
      }
    } catch (e) {
      // Ignore if file doesn't exist or cannot be deleted
    }
  }

  /// Get Firebase Storage usage
  static Future<Map<String, dynamic>> getFirebaseStorageInfo() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('products');
      final items = await ref.listAll();

      int totalFiles = items.items.length;
      double totalSize = 0;

      for (var item in items.items) {
        try {
          final metadata = await item.getMetadata();
          totalSize += metadata.size ?? 0;
        } catch (e) {
          // Skip files we can't get metadata for
        }
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize / (1024 * 1024), // Convert to MB
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'totalSize': 0.0,
      };
    }
  }
}
