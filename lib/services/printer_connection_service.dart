import 'package:shared_preferences/shared_preferences.dart';

class PrinterConnectionService {
  static const String _savedPrinterKey = 'saved_printer_address';

  /// Get saved printer address
  static Future<String?> getSavedPrinterAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_savedPrinterKey);
    } catch (e) {
      return null;
    }
  }

  /// Save printer address
  static Future<void> savePrinterAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedPrinterKey, address);
    } catch (e) {
      // Ignore error
    }
  }

  /// Clear saved printer
  static Future<void> clearSavedPrinter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedPrinterKey);
    } catch (e) {
      // Ignore error
    }
  }
}
