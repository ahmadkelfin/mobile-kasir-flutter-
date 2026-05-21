import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Bantuan & Dukungan',
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
            // Quick Help Section
            _buildSectionTitle('Bantuan Cepat'),
            _buildQuickHelpItem(
              icon: Icons.help_outline_rounded,
              title: 'FAQ',
              subtitle: 'Pertanyaan yang sering ditanyakan',
              onTap: () => _showFAQ(),
            ),
            _buildQuickHelpItem(
              icon: Icons.book_rounded,
              title: 'Panduan Pengguna',
              subtitle: 'Pelajari cara menggunakan aplikasi',
              onTap: () => _openUserGuide(),
            ),
            _buildQuickHelpItem(
              icon: Icons.video_library_rounded,
              title: 'Video Tutorial',
              subtitle: 'Tutorial video langkah demi langkah',
              onTap: () => _openVideoTutorials(),
            ),

            const SizedBox(height: 24),

            // Contact Support Section
            _buildSectionTitle('Hubungi Dukungan'),
            _buildContactItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Live Chat',
              subtitle: 'Chat langsung dengan tim dukungan',
              availability: 'Online 24/7',
              onTap: () => _startLiveChat(),
            ),
            _buildContactItem(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'Kirim email untuk bantuan detail',
              availability: 'Balas dalam 24 jam',
              onTap: () => _sendSupportEmail(),
            ),
            _buildContactItem(
              icon: Icons.phone_outlined,
              title: 'Telepon',
              subtitle: 'Hubungi hotline dukungan',
              availability: 'Senin-Jumat, 09:00-17:00',
              onTap: () => _callSupport(),
            ),

            const SizedBox(height: 24),

            // Report Issue Section
            _buildSectionTitle('Laporkan Masalah'),
            Container(
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
                    'Kirim Laporan Masalah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jelaskan masalah yang Anda alami secara detail agar tim dukungan dapat membantu dengan lebih baik.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan masalah Anda...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF3949AB),
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _submitIssueReport,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text(
                        'Kirim Laporan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3949AB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Info Section
            _buildSectionTitle('Informasi Aplikasi'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: Column(
                children: [
                  _buildAppInfoRow('Versi Aplikasi', '1.0.0'),
                  _buildAppInfoRow('Versi Build', '2024.1.0'),
                  _buildAppInfoRow('Terakhir Update', '21 April 2026'),
                  const SizedBox(height: 16),
                  const Text(
                    'Mobile Kasir adalah aplikasi point of sale modern untuk mengelola bisnis retail Anda dengan mudah dan efisien.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Social Media Section
            _buildSectionTitle('Ikuti Kami'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook_rounded,
                  label: 'Facebook',
                  onTap: () => _openSocialLink('facebook'),
                ),
                _buildSocialButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Instagram',
                  onTap: () => _openSocialLink('instagram'),
                ),
                _buildSocialButton(
                  icon: Icons.web_rounded,
                  label: 'Website',
                  onTap: () => _openSocialLink('website'),
                ),
              ],
            ),

            const SizedBox(height: 32),
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
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF616161),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuickHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String availability,
    required VoidCallback onTap,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
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
                  const SizedBox(height: 2),
                  Text(
                    availability,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3949AB),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('FAQ'),
        content: const SingleChildScrollView(
          child: Text(
            'Pertanyaan yang Sering Ditanyakan:\n\n'
            '1. Bagaimana cara menambah produk?\n'
            '   Pergi ke menu Produk > Tambah Produk\n\n'
            '2. Bagaimana cara membuat transaksi?\n'
            '   Pilih produk > Masukkan jumlah > Bayar\n\n'
            '3. Bagaimana cara melihat laporan?\n'
            '   Menu Laporan > Pilih periode waktu\n\n'
            '4. Bagaimana mengubah kata sandi?\n'
            '   Pengaturan > Ganti Sandi\n\n'
            'Untuk bantuan lebih lanjut, hubungi dukungan.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _openUserGuide() async {
    final Uri url = Uri.parse('https://docs.mobilekasir.com/panduan');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Tidak dapat membuka panduan pengguna'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _openVideoTutorials() async {
    final Uri url = Uri.parse('https://youtube.com/playlist?list=PLmobilekasir');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Tidak dapat membuka video tutorial'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  void _startLiveChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
          'Fitur live chat akan segera tersedia.\n\n'
          'Untuk saat ini, silakan hubungi kami melalui:\n\n'
          '📧 Email: support@mobilekasir.com\n'
          '📱 WhatsApp: +62 821-1234-5678\n'
          '☎️ Telepon: +62 21-1234-5678',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _sendSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@mobilekasir.com',
      queryParameters: {
        'subject': 'Bantuan Mobile Kasir',
        'body': 'Halo tim dukungan,\n\nSaya mengalami masalah berikut:\n\n',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Tidak dapat membuka aplikasi email'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    }
  }

  void _callSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+62211234567');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Tidak dapat membuka dialer telepon'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    }
  }

  void _submitIssueReport() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Harap isi deskripsi masalah'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Mengirim laporan...'),
          ],
        ),
      ),
    );

    try {
      // TODO: Submit issue report to backend (Firestore or REST API)
      // For now, simulate submission
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Laporan berhasil dikirim! Tim dukungan akan menghubungi Anda segera.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal mengirim laporan: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  void _openSocialLink(String platform) async {
    String url = '';
    switch (platform) {
      case 'facebook':
        url = 'https://facebook.com/mobilekasir';
        break;
      case 'instagram':
        url = 'https://instagram.com/mobilekasir';
        break;
      case 'website':
        url = 'https://mobilekasir.com';
        break;
    }

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Tidak dapat membuka $platform'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }
}