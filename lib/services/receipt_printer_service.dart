import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../models/transaction_model.dart';

class ReceiptPrinterService {
  static final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  /// Check if printer is connected
  static Future<bool> isConnected() async {
    try {
      final connected = await _printer.isConnected;
      return connected ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get available bonded devices
  static Future<List<BluetoothDevice>> getAvailableDevices() async {
    try {
      final devices = await _printer.getBondedDevices();
      return devices;
    } catch (e) {
      return [];
    }
  }

  /// Connect to printer
  static Future<bool> connectToPrinter(String address) async {
    try {
      // Create a basic device object - the actual name might not be needed for connection
      final device = BluetoothDevice('', address);
      await _printer.connect(device);
      return await isConnected();
    } catch (e) {
      return false;
    }
  }

  /// Disconnect printer
  static Future<void> disconnectPrinter() async {
    try {
      await _printer.disconnect();
    } catch (e) {
      // Ignore error
    }
  }

  /// Print receipt
  static Future<void> printReceipt(
    TransactionModel transaction, {
    String? businessName,
  }) async {
    try {
      if (!await isConnected()) {
        throw Exception('Printer tidak terhubung');
      }

      await _printer.printNewLine();

      // Header
      await _printer.printLeftRight(
        '═══════════════════════════════════',
        '',
        1,
      );
      await _printer.printLeftRight(
        businessName ?? 'MOBILE KASIR',
        '',
        1,
      );
      await _printer.printLeftRight(
        '═══════════════════════════════════',
        '',
        1,
      );
      await _printer.printNewLine();

      // Transaction info
      await _printer.printLeftRight(
        'No. Transaksi:',
        transaction.id,
        1,
      );
      await _printer.printLeftRight(
        'Tanggal:',
        _formatDate(transaction.createdAt),
        1,
      );
      await _printer.printLeftRight(
        'Jam:',
        _formatTime(transaction.createdAt),
        1,
      );

      if (transaction.customerName != null && transaction.customerName!.isNotEmpty) {
        await _printer.printLeftRight(
          'Pelanggan:',
          transaction.customerName!,
          1,
        );
      }

      await _printer.printLeftRight(
        'Metode:',
        transaction.paymentMethod ?? 'Cash',
        1,
      );
      await _printer.printNewLine();
      await _printer.printLeftRight(
        '───────────────────────────────────',
        '',
        1,
      );

      // Items
      if (transaction.items != null && transaction.items!.isNotEmpty) {
        for (var item in transaction.items!) {
          final itemLine = '${item.productName} x${item.quantity}';
          final priceLine = 'Rp ${item.total.toStringAsFixed(0)}';
          await _printer.printLeftRight(itemLine, priceLine, 1);
          await _printer.printLeftRight(
            'Rp ${item.price.toStringAsFixed(0)}/item',
            '',
            0,
          );
        }
      }

      await _printer.printNewLine();
      await _printer.printLeftRight(
        '═══════════════════════════════════',
        '',
        1,
      );

      // Totals
      await _printer.printLeftRight(
        'Subtotal:',
        'Rp ${transaction.subtotal.toStringAsFixed(0)}',
        1,
      );

      if (transaction.totalDiscount > 0) {
        await _printer.printLeftRight(
          'Diskon:',
          '-Rp ${transaction.totalDiscount.toStringAsFixed(0)}',
          1,
        );
      }

      if (transaction.totalTax > 0) {
        await _printer.printLeftRight(
          'Pajak:',
          '+Rp ${transaction.totalTax.toStringAsFixed(0)}',
          1,
        );
      }

      await _printer.printLeftRight(
        '═══════════════════════════════════',
        '',
        1,
      );
      await _printer.printLeftRight(
        'TOTAL:',
        'Rp ${transaction.amount.toStringAsFixed(0)}',
        1,
      );
      await _printer.printLeftRight(
        '═══════════════════════════════════',
        '',
        1,
      );

      await _printer.printNewLine();
      await _printer.printLeftRight(
        'Terima kasih telah berbelanja!',
        '',
        1,
      );
      await _printer.printNewLine();
      await _printer.printLeftRight(
        '═══════════════════════════════════',
        '',
        1,
      );
      await _printer.printNewLine();
      await _printer.printNewLine();

      // Cut paper
      await _printer.paperCut();
    } catch (e) {
      throw Exception('Gagal mencetak: $e');
    }
  }

  /// Print test receipt
  static Future<void> printTestReceipt() async {
    try {
      if (!await isConnected()) {
        throw Exception('Printer tidak terhubung');
      }

      await _printer.printNewLine();
      await _printer.printLeftRight('=== TEST PRINT ===', '', 1);
      await _printer.printNewLine();
      await _printer.printLeftRight('Printer terhubung!', '', 1);
      await _printer.printLeftRight('Toko Anda', '', 1);
      await _printer.printNewLine();
      await _printer.printLeftRight('════════════════════════════════════', '', 1);
      await _printer.printNewLine();
      await _printer.printNewLine();
      await _printer.paperCut();
    } catch (e) {
      throw Exception('Gagal mencetak: $e');
    }
  }

  static String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}

