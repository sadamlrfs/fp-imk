import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_colors.dart';
import '../../widgets/settings_tile.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  String _lastSeen     = 'Semua orang';
  String _profilePhoto = 'Semua orang';
  String _status       = 'Semua orang';
  bool   _readReceipt  = true;
  bool   _onlineStatus = true;
  String _groups       = 'Semua orang';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lastSeen     = p.getString('priv_last_seen')    ?? 'Semua orang';
      _profilePhoto = p.getString('priv_photo')        ?? 'Semua orang';
      _status       = p.getString('priv_status')       ?? 'Semua orang';
      _groups       = p.getString('priv_groups')       ?? 'Semua orang';
      _readReceipt  = p.getBool('priv_read_receipt')   ?? true;
      _onlineStatus = p.getBool('priv_online_status')  ?? true;
    });
  }

  Future<void> _setS(String k, String v) async =>
      (await SharedPreferences.getInstance()).setString(k, v);
  Future<void> _setB(String k, bool v) async =>
      (await SharedPreferences.getInstance()).setBool(k, v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Privasi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Siapa yang bisa melihat',
              children: [
                _OptionTile(
                  icon: Icons.access_time,
                  label: 'Terakhir Dilihat',
                  value: _lastSeen,
                  options: const ['Semua orang', 'Kontak saya', 'Tidak ada'],
                  onChanged: (v) { setState(() => _lastSeen = v); _setS('priv_last_seen', v); },
                ),
                _OptionTile(
                  icon: Icons.account_circle_outlined,
                  label: 'Foto Profil',
                  value: _profilePhoto,
                  options: const ['Semua orang', 'Kontak saya', 'Tidak ada'],
                  onChanged: (v) { setState(() => _profilePhoto = v); _setS('priv_photo', v); },
                ),
                _OptionTile(
                  icon: Icons.circle_outlined,
                  label: 'Status',
                  value: _status,
                  options: const ['Semua orang', 'Kontak saya', 'Tidak ada'],
                  onChanged: (v) { setState(() => _status = v); _setS('priv_status', v); },
                ),
                _OptionTile(
                  icon: Icons.group_outlined,
                  label: 'Ditambahkan ke Grup',
                  value: _groups,
                  options: const ['Semua orang', 'Kontak saya', 'Tidak ada'],
                  onChanged: (v) { setState(() => _groups = v); _setS('priv_groups', v); },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Pesan',
              children: [
                SettingsTile(
                  icon: Icons.done_all,
                  title: 'Tanda Baca Pesan',
                  subtitle: 'Tampilkan tanda baca saat pesan dibaca',
                  trailing: Switch(
                    value: _readReceipt,
                    onChanged: (v) { setState(() => _readReceipt = v); _setB('priv_read_receipt', v); },
                    activeThumbColor: AppColors.primary,
                  ),
                  showDivider: true,
                ),
                SettingsTile(
                  icon: Icons.circle,
                  iconColor: Colors.green,
                  title: 'Status Online',
                  subtitle: 'Tampilkan status online-mu ke kontak',
                  trailing: Switch(
                    value: _onlineStatus,
                    onChanged: (v) { setState(() => _onlineStatus = v); _setB('priv_online_status', v); },
                    activeThumbColor: AppColors.primary,
                  ),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              children: [
                SettingsTile(
                  icon: Icons.block,
                  iconColor: Colors.red,
                  title: 'Kontak Diblokir',
                  subtitle: '0 kontak diblokir',
                  onTap: () {},
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final void Function(String) onChanged;
  final bool isLast;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      title: label,
      subtitle: value,
      showDivider: !isLast,
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => _OptionSheet(
          label: label,
          options: options,
          selected: value,
          onSelect: (v) { onChanged(v); Navigator.pop(ctx); },
        ),
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;

  const _OptionSheet({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...options.map((opt) => InkWell(
                onTap: () => onSelect(opt),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: opt == selected ? AppColors.primary : Colors.transparent,
                          border: Border.all(
                              color: opt == selected ? AppColors.primary : AppColors.divider,
                              width: 2),
                        ),
                        child: opt == selected
                            ? const Icon(Icons.check, color: Colors.white, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(opt,
                          style: TextStyle(
                              fontSize: 14,
                              color: opt == selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: opt == selected
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
