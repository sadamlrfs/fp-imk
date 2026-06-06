import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/settings_tile.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _nameCtrl = TextEditingController(text: 'Sadam');
  final _emailCtrl = TextEditingController(text: 'sadam@example.com');
  final _phoneCtrl = TextEditingController(text: '+62 812 3456 7890');
  final _bioCtrl = TextEditingController(text: 'Tersedia untuk chat 😊');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil berhasil disimpan'), backgroundColor: AppColors.primary),
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar section
            Container(
              color: AppColors.primary,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const AvatarWidget(name: 'Sadam', radius: 48),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Ubah foto profil', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Info Profil',
              children: [
                _EditField(label: 'Nama Tampilan', controller: _nameCtrl, icon: Icons.person_outline),
                _EditField(label: 'Bio / Status', controller: _bioCtrl, icon: Icons.edit_note),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Kontak',
              children: [
                _EditField(label: 'Nomor Telepon', controller: _phoneCtrl, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                _EditField(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, isLast: true),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  title: 'Hapus Akun',
                  subtitle: 'Tindakan ini tidak dapat dibatalkan',
                  onTap: () => _showDeleteDialog(context),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text('Semua data kamu akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final bool isLast;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 50, color: AppColors.divider),
      ],
    );
  }
}
