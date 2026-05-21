import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  String _selectedCountryCode = '+62';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    // Extract phone number without country code
    final phone = user?.phone ?? '';
    if (phone.startsWith('+62')) {
      _phoneController = TextEditingController(text: phone.substring(3));
    } else {
      _phoneController = TextEditingController(text: phone);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Nomor Telepon',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Color(0xFF3949AB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Phone Display
              Container(
                padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3949AB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF3949AB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nomor Telepon Saat Ini',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.phone ?? 'Belum diatur',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF3949AB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Phone Number Input Section
              _buildSectionTitle('Ubah Nomor Telepon'),
              Row(
                children: [
                  // Country Code Dropdown
                  Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCountryCode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: '+62',
                          child: Text('+62 (ID)'),
                        ),
                        DropdownMenuItem(
                          value: '+1',
                          child: Text('+1 (US)'),
                        ),
                        DropdownMenuItem(
                          value: '+65',
                          child: Text('+65 (SG)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCountryCode = value ?? '+62');
                      },
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Phone Number Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          hintText: '81234567890',
                          border: InputBorder.none,
                          labelStyle: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 14,
                          ),
                          hintStyle: TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 14,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Nomor telepon tidak boleh kosong';
                          }
                          if (!RegExp(r'^\d{10,13}$').hasMatch(value!)) {
                            return 'Format nomor telepon tidak valid';
                          }
                          return null;
                        },
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Verification Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBBDEFB),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF1976D2),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nomor telepon baru akan diverifikasi melalui SMS untuk memastikan keamanan akun Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Warning Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFEAA7),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFF856404),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mengubah nomor telepon akan memengaruhi proses login dan verifikasi keamanan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF856404),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Send Verification Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _sendVerification,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Kirim Kode Verifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3949AB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF616161),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      final newPhone = _selectedCountryCode + _phoneController.text;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Menyimpan nomor telepon...'),
            ],
          ),
        ),
      );

      try {
        final authProvider = context.read<AuthProvider>();
        
        // Update profile data
        await authProvider.updateProfile({
          'phone': newPhone,
        });

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nomor telepon berhasil diperbarui!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendVerification() async {
    if (_formKey.currentState?.validate() ?? false) {
      final newPhone = _selectedCountryCode + _phoneController.text;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mengirim kode...'),
            ],
          ),
        ),
      );

      try {
        // TODO: Implement SMS verification with backend Firebase or Twilio service
        // For now, show success message
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Kode verifikasi telah dikirim ke $newPhone'),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Show verification dialog
        _showVerificationDialog(newPhone);
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengirim kode: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVerificationDialog(String phone) {
    final verificationCodeController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Nomor Telepon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan kode verifikasi yang telah kami kirim ke $phone',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: verificationCodeController,
              decoration: InputDecoration(
                hintText: 'Masukkan kode 6 digit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (verificationCodeController.text.length != 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Kode harus 6 digit'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // TODO: Verify code with backend
              // For now, just save the phone number
              _saveChanges();
              
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }
}