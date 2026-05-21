import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final BlueThermalPrinter _printer = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDevice();
    _checkConnection();
  }

  Future<void> _loadSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('printer_device_name');
    final address = prefs.getString('printer_device_address');
    if (name != null && address != null && mounted) {
      setState(() {
        _selectedDevice = BluetoothDevice(name, address);
      });
    }
  }

  Future<void> _checkConnection() async {
    final connected = await _printer.isConnected;
    if (mounted) setState(() => _isConnected = connected ?? false);
  }

  Future<void> _saveDevice(BluetoothDevice? device) async {
    final prefs = await SharedPreferences.getInstance();
    if (device != null) {
      await prefs.setString('printer_device_name', device.name ?? '');
      await prefs.setString('printer_device_address', device.address ?? '');
    } else {
      await prefs.remove('printer_device_name');
      await prefs.remove('printer_device_address');
    }
  }

  Future<void> _scanDevices() async {
    setState(() => _isScanning = true);
    try {
      final devices = await _printer.getBondedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _showSnackBar('Error mencari perangkat: $e', isError: true);
      }
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      await _printer.connect(device);
      if (mounted) {
        setState(() {
          _selectedDevice = device;
          _isConnected = true;
          _isConnecting = false;
        });
        await _saveDevice(device);
        _showSnackBar('Printer berhasil terhubung');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isConnecting = false;
        });
        _showSnackBar('Gagal menghubungkan: $e', isError: true);
      }
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await _printer.disconnect();
      if (mounted) {
        setState(() {
          _selectedDevice = null;
          _isConnected = false;
        });
        await _saveDevice(null);
        _showSnackBar('Printer terputus');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memutus koneksi: $e', isError: true);
      }
    }
  }

  // Fungsi test print
Future<void> _testPrint() async {
  if (!_isConnected) {
    _showSnackBar('Printer belum terhubung', isError: true);
    return;
  }
  try {
    await _printer.printNewLine();
    await _printer.printLeftRight('=== TEST PRINT ===', '', 1);
    await _printer.printNewLine();
    await _printer.printLeftRight('Printer terhubung!', '', 1);
    await _printer.printLeftRight('Toko Anda', '', 1);
    await _printer.printNewLine();
    await _printer.printLeftRight('================================', '', 1);
    await _printer.printNewLine();
    await _printer.paperCut();
    _showSnackBar('Test print berhasil!');
  } catch (e) {
    _showSnackBar('Gagal test print: $e', isError: true);
  }
}

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Pengaturan Printer',
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
            // Status Card
            _buildSectionTitle('Status Printer'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected ? 'Terhubung' : 'Tidak Terhubung',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDevice != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.print, 'Printer', _selectedDevice!.name ?? '-'),
                      _buildInfoRow(Icons.bluetooth, 'Alamat', _selectedDevice!.address ?? '-'),
                    ],
                  ],
                ),
              ),
            ),

            // Tombol Test Print (hanya muncul jika terhubung)
            if (_isConnected) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _testPrint,
                icon: const Icon(Icons.print),
                label: const Text('Test Print Struk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Scan Devices
            _buildSectionTitle('Cari Perangkat Printer'),
            const Text(
              'Pastikan printer sudah di-pair di pengaturan Bluetooth HP terlebih dahulu.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanDevices,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(_isScanning ? 'Mencari...' : 'Tampilkan Perangkat Paired'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Device List
            if (_devices.isEmpty && !_isScanning)
              const Center(
                child: Text(
                  'Belum ada perangkat. Tekan tombol di atas untuk mencari.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_devices.isNotEmpty) ...[
              Text(
                '${_devices.length} Perangkat Ditemukan:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._devices.map(
                (device) => Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: const Icon(Icons.print, color: Color(0xFF6366F1)),
                    title: Text(device.name ?? 'Unknown Device'),
                    subtitle: Text(device.address ?? ''),
                    trailing: _selectedDevice?.address == device.address && _isConnected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _isConnecting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : ElevatedButton(
                                onPressed: () => _connectDevice(device),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Hubungkan'),
                              ),
                  ),
                ),
              ),
            ],

            // Disconnect Button
            if (_isConnected) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _disconnectDevice,
                icon: const Icon(Icons.link_off),
                label: const Text('Putuskan Koneksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}