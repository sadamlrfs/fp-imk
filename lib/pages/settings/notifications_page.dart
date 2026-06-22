import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../../widgets/settings_tile.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _msgNotif = true;
  bool _groupNotif = true;
  bool _callNotif = true;
  bool _previewMsg = true;
  bool _sound = true;
  bool _vibrate = true;
  bool _translateNotif = true;
  String _ringtonePesan = 'Default';
  String _ringtonePanggilan = 'Default';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _msgNotif          = p.getBool('notif_msg')        ?? true;
      _groupNotif        = p.getBool('notif_group')      ?? true;
      _callNotif         = p.getBool('notif_call')       ?? true;
      _previewMsg        = p.getBool('notif_preview')    ?? true;
      _sound             = p.getBool('notif_sound')      ?? true;
      _vibrate           = p.getBool('notif_vibrate')    ?? true;
      _translateNotif    = p.getBool('notif_translate')  ?? true;
      _ringtonePesan     = p.getString('notif_tone_msg') ?? 'Default';
      _ringtonePanggilan = p.getString('notif_tone_call')?? 'Default';
    });
  }

  Future<void> _setB(String k, bool v)   async => (await SharedPreferences.getInstance()).setBool(k, v);
  Future<void> _setS(String k, String v) async => (await SharedPreferences.getInstance()).setString(k, v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Notifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Pesan',
              children: [
                SettingsTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Notifikasi Pesan',
                  subtitle: 'Tampilkan notifikasi untuk pesan baru',
                  trailing: Switch(value: _msgNotif, onChanged: (v) { setState(() => _msgNotif = v); _setB('notif_msg', v); }, activeThumbColor: AppColors.primary),
                ),
                SettingsTile(
                  icon: Icons.group_outlined,
                  title: 'Notifikasi Grup',
                  subtitle: 'Tampilkan notifikasi untuk chat grup',
                  trailing: Switch(value: _groupNotif, onChanged: (v) { setState(() => _groupNotif = v); _setB('notif_group', v); }, activeThumbColor: AppColors.primary),
                ),
                SettingsTile(
                  icon: Icons.visibility_outlined,
                  title: 'Pratinjau Pesan',
                  subtitle: 'Tampilkan isi pesan di notifikasi',
                  trailing: Switch(value: _previewMsg, onChanged: (v) { setState(() => _previewMsg = v); _setB('notif_preview', v); }, activeThumbColor: AppColors.primary),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Panggilan',
              children: [
                SettingsTile(
                  icon: Icons.call_outlined,
                  title: 'Notifikasi Panggilan',
                  subtitle: 'Tampilkan notifikasi untuk panggilan masuk',
                  trailing: Switch(value: _callNotif, onChanged: (v) { setState(() => _callNotif = v); _setB('notif_call', v); }, activeThumbColor: AppColors.primary),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Terjemahan',
              children: [
                SettingsTile(
                  icon: Icons.translate,
                  iconColor: const Color(0xFF0694A2),
                  title: 'Notifikasi Terjemahan Selesai',
                  subtitle: 'Beritahu saat terjemahan voice note selesai',
                  trailing: Switch(value: _translateNotif, onChanged: (v) { setState(() => _translateNotif = v); _setB('notif_translate', v); }, activeThumbColor: AppColors.primary),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Suara & Getaran',
              children: [
                SettingsTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Suara Notifikasi',
                  trailing: Switch(value: _sound, onChanged: (v) { setState(() => _sound = v); _setB('notif_sound', v); }, activeThumbColor: AppColors.primary),
                ),
                SettingsTile(
                  icon: Icons.vibration,
                  title: 'Getaran',
                  trailing: Switch(value: _vibrate, onChanged: (v) { setState(() => _vibrate = v); _setB('notif_vibrate', v); }, activeThumbColor: AppColors.primary),
                ),
                SettingsTile(
                  icon: Icons.music_note_outlined,
                  title: 'Nada Dering Pesan',
                  subtitle: _ringtonePesan,
                  onTap: () => _pickRingtone(context, 'Pesan', 'notif_tone_msg', (v) => setState(() => _ringtonePesan = v)),
                ),
                SettingsTile(
                  icon: Icons.ring_volume_outlined,
                  title: 'Nada Dering Panggilan',
                  subtitle: _ringtonePanggilan,
                  onTap: () => _pickRingtone(context, 'Panggilan', 'notif_tone_call', (v) => setState(() => _ringtonePanggilan = v)),
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

  void _pickRingtone(BuildContext context, String label, String prefKey, void Function(String) onPick) {
    const tones = ['Default', 'Ringtone 1', 'Ringtone 2', 'Tanpa Suara'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nada Dering $label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...tones.map((t) => ListTile(
              title: Text(t),
              onTap: () { onPick(t); _setS(prefKey, t); Navigator.pop(ctx); },
            )),
          ],
        ),
      ),
    );
  }
}
