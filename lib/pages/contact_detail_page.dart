import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../context/app_context.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';

class ContactDetailPage extends StatefulWidget {
  final String userId;

  const ContactDetailPage({super.key, required this.userId});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _aboutCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppContext>().getUserById(widget.userId);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _aboutCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    context.read<AppContext>().updateUserName(widget.userId, name);
    final bio = _aboutCtrl.text.trim();
    if (bio.isNotEmpty) context.read<AppContext>().updateUserBio(widget.userId, bio);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kontak berhasil diperbarui'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<String> _ensureChat() =>
      context.read<AppContext>().getOrCreateDirectChat(widget.userId);

  Future<void> _openChat() async {
    final chatId = await _ensureChat();
    if (mounted) context.push('/chat/$chatId');
  }

  Future<void> _voiceCall() async {
    final chatId = await _ensureChat();
    if (mounted) context.push('/call/$chatId?type=voice&remoteUserId=${widget.userId}');
  }

  Future<void> _videoCall() async {
    final chatId = await _ensureChat();
    if (mounted) context.push('/call/$chatId?remoteUserId=${widget.userId}');
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<AppContext>();
    final user = ctx.getUserById(widget.userId);
    final name = user?.name ?? _nameCtrl.text;
    final isEn = user?.lang == 'en';
    final langLabel = isEn ? 'English 🇺🇸' : 'Indonesia 🇮🇩';
    final phone = user?.phone ?? 'Belum diatur';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Edit',
                  onPressed: () => setState(() => _isEditing = true),
                )
              else ...[
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Batal', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _AvatarHeader(
                name: name,
                subtitle: phone,
                isEditing: _isEditing,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons
                  _Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionBtn(
                            icon: Icons.chat_bubble_outline,
                            label: 'Pesan',
                            color: AppColors.primary,
                            onTap: _openChat,
                          ),
                          _ActionBtn(
                            icon: Icons.call,
                            label: 'Panggil',
                            color: const Color(0xFF0E9F6E),
                            onTap: _voiceCall,
                          ),
                          _ActionBtn(
                            icon: Icons.videocam,
                            label: 'Video',
                            color: const Color(0xFF7E3AF2),
                            onTap: _videoCall,
                          ),
                          _ActionBtn(
                            icon: Icons.notifications_outlined,
                            label: 'Bisukan',
                            color: AppColors.textSecondary,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info card
                  _Card(
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: 'Nama',
                          value: name,
                          isEditing: _isEditing,
                          controller: _nameCtrl,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.info_outline,
                          label: 'Tentang',
                          value: _aboutCtrl.text.isEmpty ? 'Belum ada tentang' : _aboutCtrl.text,
                          isEditing: _isEditing,
                          controller: _aboutCtrl,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.language,
                          label: 'Bahasa',
                          value: langLabel,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Telepon',
                          value: phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Media section
                  _Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                          child: Row(
                            children: [
                              const Icon(Icons.perm_media_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Media & File',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Row(
                            children: [
                              _MediaThumb(icon: Icons.videocam_outlined, bg: Colors.purple[50]!),
                              const SizedBox(width: 8),
                              _MediaThumb(icon: Icons.image_outlined, bg: Colors.blue[50]!),
                              const SizedBox(width: 8),
                              _MediaThumb(icon: Icons.insert_drive_file_outlined, bg: Colors.orange[50]!),
                              const SizedBox(width: 8),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text('+5', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Danger zone
                  _Card(
                    child: Column(
                      children: [
                        _DangerTile(
                          icon: Icons.volume_off_outlined,
                          label: 'Bisukan Notifikasi',
                          color: Colors.orange,
                          onTap: () {},
                          showDivider: true,
                        ),
                        _DangerTile(
                          icon: Icons.block,
                          label: 'Blokir Kontak',
                          color: Colors.red,
                          onTap: () {},
                          showDivider: true,
                        ),
                        _DangerTile(
                          icon: Icons.delete_outline,
                          label: 'Hapus Chat',
                          color: Colors.red,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── shared sub-widgets ─────────────────

class _AvatarHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isEditing;
  const _AvatarHeader({required this.name, required this.subtitle, required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                  ),
                  child: AvatarWidget(name: name, radius: 50),
                ),
                if (isEditing)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.divider);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final TextEditingController? controller;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEditing = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                if (isEditing && controller != null)
                  TextField(
                    controller: controller,
                    style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  )
                else
                  Text(value, style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: onTap != null ? color.withValues(alpha: 0.12) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: onTap != null ? color : Colors.grey, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: onTap != null ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final IconData icon;
  final Color bg;
  const _MediaThumb({required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 28, color: AppColors.textSecondary),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _DangerTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color, size: 22),
          title: Text(label, style: TextStyle(fontSize: 15, color: color)),
          trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          onTap: onTap,
        ),
        if (showDivider) Divider(height: 1, indent: 56, color: AppColors.divider),
      ],
    );
  }
}
