import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../context/app_context.dart';
import '../models/app_models.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';

class GroupDetailPage extends StatefulWidget {
  final String chatId;

  const GroupDetailPage({super.key, required this.chatId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;

  static const _descriptions = {
    'g1': 'Grup diskusi IMK — Interaksi Manusia Komputer. Tempat berbagi materi dan informasi perkuliahan.',
    'g2': 'Tim pengembangan proyek IMK Semester Genap. Koordinasi sprint dan review desain.',
    'g3': 'Kelas B — Sesi Sore, Semester 4. Info tugas, jadwal, dan pengumuman.',
  };

  @override
  void initState() {
    super.initState();
    final chat = context.read<AppContext>().getChatById(widget.chatId);
    _nameCtrl = TextEditingController(text: chat?.name ?? '');
    _descCtrl = TextEditingController(
      text: _descriptions[widget.chatId] ?? 'Grup chat IMK Translate.',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    context.read<AppContext>().updateGroupName(widget.chatId, name);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Grup berhasil diperbarui'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAddMember(BuildContext context, List<String> existingIds) {
    final appCtx = context.read<AppContext>();
    final available = appCtx.users
        .where((u) => u.id != 'me' && !existingIds.contains(u.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kontak sudah menjadi anggota')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tambah Anggota',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ),
          const Divider(height: 1),
          ...available.map(
            (u) => ListTile(
              leading: AvatarWidget(name: u.name, radius: 22),
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                u.lang == 'en' ? '🇺🇸 English' : '🇮🇩 Indonesia',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${u.name} ditambahkan ke grup'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<AppContext>();
    final chat = ctx.getChatById(widget.chatId);
    final groupName = chat?.name ?? _nameCtrl.text;
    final memberIds = chat?.participantIds ?? [];
    final members = memberIds
        .map((id) => ctx.getUserById(id))
        .whereType<UserModel>()
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
              background: _GroupAvatarHeader(
                groupName: groupName,
                members: members,
                memberCount: memberIds.length,
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
                            icon: Icons.call,
                            label: 'Panggil',
                            color: const Color(0xFF0E9F6E),
                            onTap: () => context.push('/call/${widget.chatId}?type=voice'),
                          ),
                          _ActionBtn(
                            icon: Icons.videocam,
                            label: 'Video',
                            color: const Color(0xFF7E3AF2),
                            onTap: () => context.push('/group-call/${widget.chatId}'),
                          ),
                          _ActionBtn(
                            icon: Icons.notifications_outlined,
                            label: 'Bisukan',
                            color: AppColors.textSecondary,
                            onTap: () {},
                          ),
                          _ActionBtn(
                            icon: Icons.search,
                            label: 'Cari',
                            color: AppColors.primary,
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
                          icon: Icons.group_outlined,
                          label: 'Nama Grup',
                          value: groupName,
                          isEditing: _isEditing,
                          controller: _nameCtrl,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.description_outlined,
                          label: 'Deskripsi',
                          value: _descCtrl.text,
                          isEditing: _isEditing,
                          controller: _descCtrl,
                          maxLines: 3,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          icon: Icons.people_outline,
                          label: 'Anggota',
                          value: '${memberIds.length} anggota',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Members section
                  _Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Anggota Grup',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showAddMember(context, memberIds),
                                icon: const Icon(Icons.person_add_outlined, size: 16, color: AppColors.primary),
                                label: const Text('Tambah', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
                        // Self (me) first
                        _MemberTile(
                          name: ctx.currentUser?.name ?? 'Saya',
                          lang: ctx.currentUser?.lang ?? 'id',
                          isAdmin: true,
                          isMe: true,
                        ),
                        ...members.map((u) {
                          return Column(
                            children: [
                              const Divider(height: 1, indent: 72, color: AppColors.divider),
                              _MemberTile(
                                name: u.name,
                                lang: u.lang,
                                isAdmin: u.id == memberIds.firstOrNull,
                              ),
                            ],
                          );
                        }),
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
                          icon: Icons.logout,
                          label: 'Keluar dari Grup',
                          color: Colors.red,
                          onTap: () {},
                          showDivider: true,
                        ),
                        _DangerTile(
                          icon: Icons.delete_outline,
                          label: 'Hapus Riwayat Chat',
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

// ───────────────── sub-widgets ─────────────────

class _GroupAvatarHeader extends StatelessWidget {
  final String groupName;
  final List<UserModel> members;
  final int memberCount;
  final bool isEditing;

  const _GroupAvatarHeader({
    required this.groupName,
    required this.members,
    required this.memberCount,
    required this.isEditing,
  });

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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < members.length.clamp(0, 4); i++)
                        Positioned(
                          left: 16.0 + i * 10,
                          top: 20.0 + (i.isEven ? 0 : 10),
                          child: AvatarWidget(name: members[i].name, radius: 16),
                        ),
                    ],
                  ),
                ),
                if (isEditing)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              groupName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '$memberCount anggota',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final String lang;
  final bool isAdmin;
  final bool isMe;

  const _MemberTile({
    required this.name,
    required this.lang,
    this.isAdmin = false,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AvatarWidget(name: name, radius: 22),
      title: Row(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
          if (isMe) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Saya', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            lang == 'en' ? '🇺🇸 English' : '🇮🇩 Indonesia',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (isAdmin && !isMe) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Admin', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
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
        color: Colors.white,
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
      const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.divider);
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final TextEditingController? controller;
  final int maxLines;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEditing = false,
    this.controller,
    this.maxLines = 1,
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
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                if (isEditing && controller != null)
                  TextField(
                    controller: controller,
                    maxLines: maxLines,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
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
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4),
                  ),
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
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
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
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 56, color: AppColors.divider),
      ],
    );
  }
}
