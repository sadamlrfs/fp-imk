import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../context/app_context.dart';
import '../../models/app_models.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_widget.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _query = _search.text.toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showAddContact(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tambah Kontak',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    Navigator.pop(ctx);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          name.isEmpty ? 'Kontak berhasil ditambahkan' : '"$name" berhasil ditambahkan',
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tambah Kontak',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
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
    final ctx = context.watch<AppContext>();
    final contacts = ctx.users
        .where((u) => u.id != 'me')
        .where((u) => _query.isEmpty || u.name.toLowerCase().contains(_query))
        .toList();

    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Kontak',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _search,
                                decoration: const InputDecoration(
                                  hintText: 'Cari kontak...',
                                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                  ],
                ),
              ),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada kontak ditemukan',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: contacts.length,
                      separatorBuilder: (_, i) => const Divider(height: 1, indent: 72, color: AppColors.divider),
                      itemBuilder: (_, i) => _ContactTile(user: contacts[i]),
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'add_contact_fab',
            onPressed: () => _showAddContact(context),
            backgroundColor: AppColors.primary,
            elevation: 4,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final UserModel user;
  const _ContactTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final langLabel = user.lang == 'en' ? '🇺🇸 English' : '🇮🇩 Indonesia';

    void gotoChat() {
      final ctx = context.read<AppContext>();
      final chat = ctx.chats
          .where((c) => c.type == 'personal' && c.participantIds.contains(user.id))
          .firstOrNull;
      if (chat != null) context.push('/chat/${chat.id}');
    }

    void gotoVoiceCall() {
      final ctx = context.read<AppContext>();
      final chat = ctx.chats
          .where((c) => c.type == 'personal' && c.participantIds.contains(user.id))
          .firstOrNull;
      if (chat != null) context.push('/call/${chat.id}?type=voice');
    }

    void gotoVideoCall() {
      final ctx = context.read<AppContext>();
      final chat = ctx.chats
          .where((c) => c.type == 'personal' && c.participantIds.contains(user.id))
          .firstOrNull;
      if (chat != null) context.push('/call/${chat.id}');
    }

    return InkWell(
      onTap: gotoChat,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AvatarWidget(name: user.name, radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  Text(langLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBtn(icon: Icons.chat_bubble_outline, onTap: gotoChat),
                const SizedBox(width: 6),
                _IconBtn(icon: Icons.call, onTap: gotoVoiceCall),
                const SizedBox(width: 6),
                _IconBtn(icon: Icons.videocam, onTap: gotoVideoCall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
    );
  }
}
