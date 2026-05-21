import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Logo & Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mobile Kasir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Description
            _buildInfoCard(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mobile Kasir adalah aplikasi point of sale modern yang dirancang untuk memudahkan pengelolaan transaksi penjualan, inventaris, dan laporan keuangan bisnis Anda.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF616161),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // App Details
            _buildSectionTitle('Informasi Aplikasi'),
            _buildDetailRow('Versi Aplikasi', '1.0.0'),
            _buildDetailRow('Build Number', '100'),
            _buildDetailRow('Platform', 'Flutter'),
            _buildDetailRow('Minimum OS', 'Android 6.0 / iOS 12'),

            const SizedBox(height: 20),

            // Links Section
            _buildSectionTitle('Tautan'),
            _buildTapItem(
              icon: Icons.policy_rounded,
              title: 'Kebijakan Privasi',
              onTap: () => _launchUrl('https://mobilekasir.com/privacy'),
            ),
            _buildTapItem(
              icon: Icons.gavel_rounded,
              title: 'Syarat & Ketentuan',
              onTap: () => _launchUrl('https://mobilekasir.com/terms'),
            ),
            _buildTapItem(
              icon: Icons.star_rounded,
              title: 'Beri Penilaian',
              onTap: () => _rateApp(),
            ),
            _buildTapItem(
              icon: Icons.share_rounded,
              title: 'Bagikan Aplikasi',
              onTap: () => _shareApp(),
            ),

            const SizedBox(height: 20),

            // Footer
            const Text(
              '© 2024 Mobile Kasir. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF616161),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF3949AB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF3949AB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }


  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Tidak dapat membuka: $urlString'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  Future<void> _rateApp() async {
    // iOS App Store and Android Google Play
    final appStoreUrl = 'https://apps.apple.com/app/mobile-kasir/id123456789';
    final playStoreUrl = 'https://play.google.com/store/apps/details?id=com.mobilekasir';
    
    try {
      // Try Play Store first (Android)
      final Uri playStoreUri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Fallback to App Store (iOS)
      final Uri appStoreUri = Uri.parse(appStoreUrl);
      if (await canLaunchUrl(appStoreUri)) {
        await launchUrl(appStoreUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Tidak dapat membuka app store'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Download Mobile Kasir - Aplikasi Point of Sale Modern untuk Android dan iOS\n\n'
        'Google Play: https://play.google.com/store/apps/details?id=com.mobilekasir\n'
        'App Store: https://apps.apple.com/app/mobile-kasir/id123456789',
        subject: 'Mobile Kasir - Aplikasi POS Terbaik',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal membagikan: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }
}