import 'package:flutter/material.dart';

class ActiveDevicesScreen extends StatefulWidget {
  const ActiveDevicesScreen({super.key});

  @override
  State<ActiveDevicesScreen> createState() => _ActiveDevicesScreenState();
}

class _ActiveDevicesScreenState extends State<ActiveDevicesScreen> {
  // Mock data for active devices
  final List<Map<String, dynamic>> _activeDevices = [
    {
      'id': '1',
      'name': 'iPhone 13 Pro',
      'type': 'Mobile',
      'location': 'Jakarta, Indonesia',
      'lastActive': 'Sekarang',
      'isCurrent': true,
      'platform': 'iOS',
    },
    {
      'id': '2',
      'name': 'MacBook Pro',
      'type': 'Desktop',
      'location': 'Jakarta, Indonesia',
      'lastActive': '2 jam yang lalu',
      'isCurrent': false,
      'platform': 'macOS',
    },
    {
      'id': '3',
      'name': 'Samsung Galaxy S21',
      'type': 'Mobile',
      'location': 'Bandung, Indonesia',
      'lastActive': '1 hari yang lalu',
      'isCurrent': false,
      'platform': 'Android',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Perangkat Aktif',
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
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
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
                    Icons.devices_rounded,
                    color: Color(0xFF1976D2),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pantau semua perangkat yang sedang login ke akun Anda. Anda dapat melihat lokasi dan waktu aktivitas terakhir setiap perangkat.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Devices List
            _buildSectionTitle('Perangkat Aktif (${_activeDevices.length})'),
            ..._activeDevices.map((device) => _buildDeviceItem(device)),

            const SizedBox(height: 24),

            // Security Actions
            _buildSectionTitle('Tindakan Keamanan'),
            _buildSecurityAction(
              icon: Icons.logout_rounded,
              title: 'Keluar dari Semua Perangkat',
              subtitle: 'Akhiri sesi di semua perangkat kecuali yang sedang digunakan',
              onTap: () => _showLogoutAllDevicesDialog(),
              isDestructive: true,
            ),
            _buildSecurityAction(
              icon: Icons.security_rounded,
              title: 'Aktifkan Verifikasi 2 Langkah',
              subtitle: 'Tambahkan lapisan keamanan ekstra untuk akun Anda',
              onTap: () => _enableTwoFactorAuth(),
            ),
            _buildSecurityAction(
              icon: Icons.notifications_active_rounded,
              title: 'Notifikasi Login Baru',
              subtitle: 'Dapatkan pemberitahuan saat ada login dari perangkat baru',
              onTap: () => _enableLoginNotifications(),
            ),

            const SizedBox(height: 24),

            // Security Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFEAA7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFF856404),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tips Keamanan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF856404),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem('Keluar dari perangkat yang tidak dikenal'),
                  _buildTipItem('Aktifkan verifikasi 2 langkah'),
                  _buildTipItem('Gunakan kata sandi yang kuat'),
                  _buildTipItem('Pantau aktivitas login secara berkala'),
                ],
              ),
            ),
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

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device['isCurrent']
              ? const Color(0xFF4CAF50)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: device['isCurrent']
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : const Color(0xFF3949AB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDeviceIcon(device['type']),
              color: device['isCurrent']
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF3949AB),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    if (device['isCurrent']) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${device['platform']} • ${device['location']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aktif: ${device['lastActive']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
          if (!device['isCurrent'])
            PopupMenuButton<String>(
              onSelected: (value) => _handleDeviceAction(device, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Keluar dari perangkat ini'),
                ),
                const PopupMenuItem(
                  value: 'details',
                  child: Text('Lihat detail'),
                ),
              ],
              child: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFFBDBDBD),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityAction({
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
              color: Color(0xFF856404),
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
                color: Color(0xFF856404),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Mobile':
        return Icons.smartphone_rounded;
      case 'Desktop':
        return Icons.computer_rounded;
      case 'Tablet':
        return Icons.tablet_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  void _handleDeviceAction(Map<String, dynamic> device, String action) {
    switch (action) {
      case 'logout':
        _showLogoutDeviceDialog(device);
        break;
      case 'details':
        _showDeviceDetails(device);
        break;
    }
  }

  void _showLogoutDeviceDialog(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Perangkat?'),
        content: Text(
          'Apakah Anda yakin ingin mengakhiri sesi di ${device['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _activeDevices.removeWhere((d) => d['id'] == device['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Berhasil keluar dari ${device['name']}'),
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showDeviceDetails(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(device['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Platform', device['platform']),
            _buildDetailRow('Tipe', device['type']),
            _buildDetailRow('Lokasi', device['location']),
            _buildDetailRow('Aktivitas Terakhir', device['lastActive']),
            _buildDetailRow('ID Perangkat', device['id']),
          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDevicesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Semua Perangkat?'),
        content: const Text(
          'Tindakan ini akan mengakhiri sesi di semua perangkat kecuali yang sedang Anda gunakan saat ini. Anda perlu login kembali di perangkat lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _activeDevices.removeWhere((device) => !device['isCurrent']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Berhasil keluar dari semua perangkat'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Keluar Semua'),
          ),
        ],
      ),
    );
  }

  void _enableTwoFactorAuth() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Dua Langkah'),
        content: const Text(
          'Verifikasi dua langkah menambahkan lapisan keamanan ekstra untuk akun Anda.\n\n'
          'Anda akan diminta memasukkan kode dari aplikasi autentikator atau SMS saat login.\n\n'
          'Fitur ini segera akan tersedia. Silakan coba lagi dalam beberapa hari ke depan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📝 Verifikasi dua langkah berhasil diaktifkan'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  void _enableLoginNotifications() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifikasi Login Baru'),
        content: const Text(
          'Anda akan menerima notifikasi push setiap kali ada login baru dari perangkat atau lokasi yang tidak dikenali.\n\n'
          'Ini membantu Anda mengidentifikasi akses yang tidak sah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Notifikasi login baru telah diaktifkan'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }
}