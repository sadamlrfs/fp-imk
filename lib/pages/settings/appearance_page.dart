import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../context/theme_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/settings_tile.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  String _theme             = 'Terang';
  double _fontSize          = 14;
  String _wallpaper         = 'Pola Gelombang (Default)';
  bool   _bubbleTranslation = true;
  String _bubbleStyle       = 'Kartu Putih';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _theme             = p.getString('app_theme')              ?? 'Terang';
      _fontSize          = p.getDouble('app_font_size')          ?? 14;
      _wallpaper         = p.getString('app_wallpaper')          ?? 'Pola Gelombang (Default)';
      _bubbleTranslation = p.getBool('app_bubble_translation')   ?? true;
      _bubbleStyle       = p.getString('app_bubble_style')       ?? 'Kartu Putih';
    });
  }

  Future<void> _setS(String k, String v)  async => (await SharedPreferences.getInstance()).setString(k, v);
  Future<void> _setB(String k, bool v)    async => (await SharedPreferences.getInstance()).setBool(k, v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Tampilan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Tema',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: ['Terang', 'Gelap', 'Sistem'].map((t) => Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _theme = t);
                          // Drives MaterialApp.themeMode + persists.
                          context.read<ThemeController>().setThemeLabel(t);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _theme == t ? AppColors.primary : AppColors.searchBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                t == 'Terang' ? Icons.light_mode
                                    : t == 'Gelap' ? Icons.dark_mode
                                    : Icons.phone_android,
                                color: _theme == t ? Colors.white : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(t,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _theme == t ? Colors.white : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Ukuran Teks',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_fields, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Preview teks dengan ukuran ${_fontSize.toInt()}px',
                            style: TextStyle(fontSize: _fontSize, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Slider(
                        value: _fontSize,
                        min: 12, max: 20, divisions: 4,
                        label: '${_fontSize.toInt()}px',
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          setState(() => _fontSize = v);
                          // Drives MediaQuery text scaling globally + persists.
                          context.read<ThemeController>().setFontSize(v);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kecil',  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('Sedang', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('Besar',  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SettingsSection(
              title: 'Chat',
              children: [
                SettingsTile(
                  icon: Icons.wallpaper,
                  iconColor: const Color(0xFF7E3AF2),
                  title: 'Wallpaper Chat',
                  subtitle: _wallpaper,
                  onTap: () => _pickWallpaper(context),
                ),
                SettingsTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Gaya Bubble',
                  subtitle: _bubbleStyle,
                  onTap: () => _pickBubbleStyle(context),
                ),
                SettingsTile(
                  icon: Icons.translate,
                  iconColor: const Color(0xFF0694A2),
                  title: 'Tampilkan Terjemahan di Bubble',
                  subtitle: 'Selalu tampilkan EN dan ID di bubble pesan',
                  trailing: Switch(
                    value: _bubbleTranslation,
                    onChanged: (v) {
                      setState(() => _bubbleTranslation = v);
                      _setB('app_bubble_translation', v);
                    },
                    activeThumbColor: AppColors.primary,
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

  void _pickWallpaper(BuildContext context) {
    final wallpapers = [
      'Pola Gelombang (Default)',
      'Biru Polos',
      'Gradien Biru-Ungu',
      'Putih Bersih',
      'Gelap',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wallpaper Chat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...wallpapers.map((w) => InkWell(
                  onTap: () {
                    setState(() => _wallpaper = w);
                    _setS('app_wallpaper', w);
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Icon(
                          _wallpaper == w
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _wallpaper == w
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(w,
                          style: TextStyle(
                              fontSize: 14,
                              color: _wallpaper == w
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _pickBubbleStyle(BuildContext context) {
    final styles = ['Kartu Putih', 'Warna (Biru/Abu)', 'Minimalis'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gaya Bubble',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...styles.map((s) => InkWell(
                  onTap: () {
                    setState(() => _bubbleStyle = s);
                    _setS('app_bubble_style', s);
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Icon(
                          _bubbleStyle == s
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _bubbleStyle == s
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(s,
                          style: TextStyle(
                              fontSize: 14,
                              color: _bubbleStyle == s
                                  ? AppColors.primary
                                  : AppColors.textPrimary)),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
