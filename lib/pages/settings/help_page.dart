import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/settings_tile.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faqs = [
    ('Bagaimana cara mengaktifkan terjemahan?', 'Terjemahan diaktifkan otomatis. Kamu dapat mengubah pengaturan bahasa di Profil → Bahasa & Terjemahan.'),
    ('Bahasa apa saja yang didukung?', 'Saat ini mendukung Bahasa Indonesia dan Inggris. Dukungan bahasa lain akan segera hadir.'),
    ('Apakah terjemahan real-time bekerja saat video call?', 'Ya! Terjemahan real-time tersedia saat 1-on-1 dan group video call. Tap ikon terjemahan untuk mengaktifkan.'),
    ('Bagaimana cara mengirim voice note?', 'Tap ikon mikrofon di chat input, rekam pesan, lalu tap ikon kirim. Transkrip akan muncul otomatis.'),
    ('Apakah pesan saya aman?', 'Semua pesan dienkripsi end-to-end. Kami tidak menyimpan isi percakapanmu.'),
    ('Bagaimana cara melaporkan masalah?', 'Buka Bantuan → Laporkan Masalah dan isi formulir yang tersedia.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Bantuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.searchBg, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 8),
                    Text('Cari pertanyaan...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Hubungi Kami',
              children: [
                SettingsTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: const Color(0xFF057A55),
                  title: 'Chat dengan Tim Dukungan',
                  subtitle: 'Biasanya membalas dalam < 1 jam',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF057A55),
                  title: 'Kirim Email',
                  subtitle: 'support@imktranslate.id',
                  onTap: () {},
                ),
                SettingsTile(
                  icon: Icons.bug_report_outlined,
                  iconColor: Colors.orange,
                  title: 'Laporkan Masalah',
                  subtitle: 'Bantu kami meningkatkan aplikasi',
                  onTap: () => _showReportDialog(context),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'FAQ',
              children: List.generate(_faqs.length, (i) {
                final (q, a) = _faqs[i];
                return _FaqTile(question: q, answer: a, isLast: i == _faqs.length - 1);
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Laporkan Masalah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Jelaskan masalah yang kamu alami...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim. Terima kasih!'), backgroundColor: AppColors.primary));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Kirim Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  final bool isLast;
  const _FaqTile({required this.question, required this.answer, required this.isLast});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.searchBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(widget.answer, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ),
        if (!widget.isLast) Divider(height: 1, indent: 16, color: AppColors.divider),
      ],
    );
  }
}
