import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/settings_tile.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _myLang = 'Indonesia (ID)';
  String _targetLang = 'English (EN)';
  bool _autoTranslate = true;
  bool _showOriginal = true;
  bool _translateVoice = true;
  bool _translateVideo = true;
  String _quality = 'Standar';

  static const _languages = [
    'Indonesia (ID)',
    'English (EN)',
    'Mandarin (ZH)',
    'Japanese (JA)',
    'Korean (KO)',
    'Spanish (ES)',
    'French (FR)',
    'Arabic (AR)',
  ];

  void _pickLanguage(BuildContext ctx, String title, String current, void Function(String) onPick) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: sc,
                  children: _languages.map((lang) => InkWell(
                    onTap: () { onPick(lang); Navigator.pop(ctx); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lang == current ? AppColors.primary : Colors.transparent,
                              border: Border.all(color: lang == current ? AppColors.primary : AppColors.divider, width: 2),
                            ),
                            child: lang == current ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
                          ),
                          const SizedBox(width: 14),
                          Text(lang, style: TextStyle(fontSize: 14,
                              fontWeight: lang == current ? FontWeight.w600 : FontWeight.normal,
                              color: lang == current ? AppColors.primary : AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Bahasa & Terjemahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Translate preview card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.translate, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text('Preview Terjemahan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Bahasa Inggris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  const Text('Hello! How are you today?', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bahasa Indonesia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        SizedBox(height: 2),
                        Text('Halo! Apa kabar hari ini?', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: 'Bahasa',
              children: [
                SettingsTile(
                  icon: Icons.language,
                  iconColor: const Color(0xFF0694A2),
                  title: 'Bahasa Saya',
                  subtitle: _myLang,
                  onTap: () => _pickLanguage(context, 'Bahasa Saya', _myLang, (v) => setState(() => _myLang = v)),
                ),
                SettingsTile(
                  icon: Icons.swap_horiz,
                  iconColor: const Color(0xFF0694A2),
                  title: 'Terjemahkan ke',
                  subtitle: _targetLang,
                  onTap: () => _pickLanguage(context, 'Terjemahkan ke', _targetLang, (v) => setState(() => _targetLang = v)),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Terjemahan Otomatis',
              children: [
                SettingsTile(
                  icon: Icons.auto_awesome,
                  iconColor: AppColors.primary,
                  title: 'Terjemahan Otomatis',
                  subtitle: 'Terjemahkan pesan secara otomatis',
                  trailing: Switch(value: _autoTranslate, onChanged: (v) => setState(() => _autoTranslate = v), activeThumbColor: AppColors.primary),
                ),
                SettingsTile(
                  icon: Icons.visibility_outlined,
                  title: 'Tampilkan Teks Asli',
                  subtitle: 'Tampilkan teks asli di bawah terjemahan',
                  trailing: Switch(value: _showOriginal, onChanged: (v) => setState(() => _showOriginal = v), activeThumbColor: AppColors.primary),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Terjemahkan Media',
              children: [
                SettingsTile(
                  icon: Icons.mic_outlined,
                  title: 'Voice Note',
                  subtitle: 'Terjemahkan transkrip voice note',
                  trailing: Switch(value: _translateVoice, onChanged: (v) => setState(() => _translateVoice = v), activeThumbColor: AppColors.primary),
                ),
                SettingsTile(
                  icon: Icons.videocam_outlined,
                  title: 'Video',
                  subtitle: 'Terjemahkan subtitle video',
                  trailing: Switch(value: _translateVideo, onChanged: (v) => setState(() => _translateVideo = v), activeThumbColor: AppColors.primary),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Kualitas',
              children: [
                SettingsTile(
                  icon: Icons.high_quality_outlined,
                  title: 'Kualitas Terjemahan',
                  subtitle: _quality,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kualitas Terjemahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Kualitas lebih tinggi menggunakan lebih banyak data.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          ...['Hemat Data', 'Standar', 'Tinggi'].map((q) => InkWell(
                            onTap: () { setState(() => _quality = q); Navigator.pop(ctx); },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(children: [
                                Icon(_quality == q ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: _quality == q ? AppColors.primary : AppColors.textSecondary, size: 20),
                                const SizedBox(width: 12),
                                Text(q, style: TextStyle(fontSize: 14, color: _quality == q ? AppColors.primary : AppColors.textPrimary, fontWeight: _quality == q ? FontWeight.w600 : FontWeight.normal)),
                              ]),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
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
}
