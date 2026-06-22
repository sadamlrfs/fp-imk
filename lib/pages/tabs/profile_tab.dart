import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../context/app_context.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/settings_tile.dart';
import '../settings/account_page.dart';
import '../settings/privacy_page.dart';
import '../settings/notifications_page.dart';
import '../settings/language_page.dart';
import '../settings/appearance_page.dart';
import '../settings/help_page.dart';
import '../settings/about_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<AppContext>();
    final me = ctx.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          Container(
            width: double.infinity,
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AvatarWidget(name: me?.name ?? 'User', radius: 44),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: AppColors.surface, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                color: AppColors.primary, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      me?.name ?? 'User',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      me?.lang == 'en' ? '🇺🇸 English' : '🇮🇩 Indonesia',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    // Short user ID chip with copy button
                    if (me != null) ...[
                      Builder(builder: (context) {
                        final shortId = me.id.substring(0, me.id.length.clamp(0, 8)).toUpperCase();
                        return GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shortId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ID "$shortId" disalin ke clipboard'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tag, color: Colors.white70, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'ID: $shortId',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.5),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy, color: Colors.white54, size: 12),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (me.phone != null && me.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          me.phone!,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _navigate(context, const AccountPage()),
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text('Edit Profil',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SettingsSection(
            title: 'Pengaturan Akun',
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Akun',
                subtitle: 'Nomor, email, nama tampilan',
                onTap: () => _navigate(context, const AccountPage()),
              ),
              SettingsTile(
                icon: Icons.lock_outline,
                title: 'Privasi',
                subtitle: 'Siapa yang dapat melihat profilmu',
                onTap: () => _navigate(context, const PrivacyPage()),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsSection(
            title: 'Preferensi',
            children: [
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Nada dering, getaran, popup',
                onTap: () => _navigate(context, const NotificationsPage()),
              ),
              SettingsTile(
                icon: Icons.translate,
                title: 'Bahasa & Terjemahan',
                subtitle: 'Bahasa saya · Terjemahan otomatis',
                iconColor: const Color(0xFF0694A2),
                onTap: () => _navigate(context, const LanguagePage()),
              ),
              SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Tampilan',
                subtitle: 'Tema, wallpaper chat, ukuran font',
                iconColor: const Color(0xFF7E3AF2),
                onTap: () => _navigate(context, const AppearancePage()),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsSection(
            title: 'Lainnya',
            children: [
              SettingsTile(
                icon: Icons.help_outline,
                title: 'Bantuan',
                subtitle: 'FAQ, hubungi kami, laporkan masalah',
                iconColor: const Color(0xFF057A55),
                onTap: () => _navigate(context, const HelpPage()),
              ),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'Tentang IMK Translate',
                subtitle: 'Versi 1.0.0',
                iconColor: AppColors.textSecondary,
                onTap: () => _navigate(context, const AboutPage()),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            color: AppColors.surface,
            child: SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Keluar',
              onTap: () => _showLogoutDialog(context),
              showDivider: false,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah kamu yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppContext>().signOut();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
