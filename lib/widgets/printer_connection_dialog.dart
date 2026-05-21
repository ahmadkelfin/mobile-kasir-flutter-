import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/receipt_printer_service.dart';
import '../services/printer_connection_service.dart';

class PrinterConnectionDialog extends StatefulWidget {
  final Function(BluetoothDevice) onPrinterSelected;
  final Function()? onSkip;

  const PrinterConnectionDialog({
    Key? key,
    required this.onPrinterSelected,
    this.onSkip,
  }) : super(key: key);

  @override
  State<PrinterConnectionDialog> createState() => _PrinterConnectionDialogState();
}

class _PrinterConnectionDialogState extends State<PrinterConnectionDialog> {
  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _scanDevices();
  }


  Future<void> _scanDevices() async {
    setState(() => _isLoading = true);
    try {
      final devices = await ReceiptPrinterService.getAvailableDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    try {
      final connected = await ReceiptPrinterService.connectToPrinter(device.address ?? '');
      if (connected) {
        await PrinterConnectionService.savePrinterAddress(device.address ?? '');
        if (mounted) {
          widget.onPrinterSelected(device);
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal terhubung ke printer')),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Printer'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? const Center(
                  child: Text('Tidak ada printer ditemukan'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device.name ?? 'Unknown'),
                      subtitle: Text(device.address ?? ''),
                      onTap: () => _connectToPrinter(device),
                    );
                  },
                ),
      actions: [
        TextButton(
          onPressed: _scanDevices,
          child: const Text('Scan Ulang'),
        ),
        if (widget.onSkip != null)
          TextButton(
            onPressed: () {
              widget.onSkip?.call();
              Navigator.pop(context);
            },
            child: const Text('Lewati'),
          ),
      ],
    );
  }
}
