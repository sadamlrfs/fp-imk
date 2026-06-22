import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/settings_tile.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Tentang',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App logo & version
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'IMK Translate',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0 (Build 1)',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Prototype · IMK 2024',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Informasi',
              children: [
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Syarat Layanan',
                  onTap: () =>
                      _showSheet(context, 'Syarat Layanan', _termsText),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Kebijakan Privasi',
                  onTap: () =>
                      _showSheet(context, 'Kebijakan Privasi', _privacyText),
                ),
                SettingsTile(
                  icon: Icons.code,
                  title: 'Lisensi Open Source',
                  onTap: () => _showSheet(
                    context,
                    'Lisensi',
                    'App ini dibuat menggunakan Flutter dan berbagai package open source.',
                  ),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Tim',
              children: [
                SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Sadam Ali Rafsanjani',
                  subtitle: 'Developer & Designer',
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '© 2026 Multilang Chat',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
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

  static const _termsText =
      '''IMK Translate adalah aplikasi prototype untuk keperluan penelitian usability testing. Dengan menggunakan aplikasi ini, kamu menyetujui:

1. Aplikasi ini hanya untuk keperluan pengujian dan tidak untuk penggunaan produksi.
2. Data yang kamu masukkan tidak disimpan secara permanen.
3. Fitur terjemahan bersifat simulasi dan tidak menggunakan layanan terjemahan nyata.
4. Kami berhak mengubah atau menghentikan layanan kapan saja.

Terima kasih telah berpartisipasi dalam penelitian ini.''';

  static const _privacyText = '''Kebijakan Privasi IMK Translate:

Data yang dikumpulkan:
- Kami hanya menyimpan data sesi secara lokal di perangkatmu.
- Tidak ada data yang dikirim ke server eksternal.
- Pesan yang kamu kirim hanya tersimpan di localStorage.

Keamanan:
- Semua interaksi bersifat lokal dan tidak terhubung ke internet.
- Tidak ada akun nyata yang dibuat dalam prototipe ini.

Kontak: Untuk pertanyaan, hubungi tim peneliti IMK.''';
}
