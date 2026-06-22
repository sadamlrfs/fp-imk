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

  void _showFindUser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FindUserSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();

    // Only show users that have been added as contacts
    final myContacts = appCtx.contacts
        .where((u) => _query.isEmpty || u.name.toLowerCase().contains(_query))
        .toList();

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Kontak',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
                        tooltip: 'Tambah Kontak',
                        onPressed: () => _showFindUser(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.searchBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            decoration: InputDecoration(
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
                Divider(height: 1, color: AppColors.divider),
              ],
            ),
          ),
        ),
        Expanded(
          child: myContacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _query.isEmpty
                            ? 'Belum ada kontak\nTambahkan kontak dengan tombol + di atas'
                            : 'Tidak ada kontak ditemukan',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      if (_query.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showFindUser(context),
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: const Text('Tambah Kontak'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: myContacts.length,
                  separatorBuilder: (_, i) =>
                      Divider(height: 1, indent: 72, color: AppColors.divider),
                  itemBuilder: (_, i) => _ContactTile(user: myContacts[i]),
                ),
        ),
      ],
    );
  }
}

// ── Find & Add User Bottom Sheet ─────────────────────────────────────────────

class _FindUserSheet extends StatefulWidget {
  const _FindUserSheet();

  @override
  State<_FindUserSheet> createState() => _FindUserSheetState();
}

class _FindUserSheetState extends State<_FindUserSheet> {
  final _ctrl = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final results = await context.read<AppContext>().searchUsers(query.trim());
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Tambah Kontak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Cari berdasarkan nama, nomor HP, atau ID',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'Nama, nomor HP, atau ID pengguna...',
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
          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.divider),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
          else if (_results.isEmpty && _ctrl.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Text('Pengguna tidak ditemukan',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, i) =>
                    Divider(height: 1, indent: 72, color: AppColors.divider),
                itemBuilder: (_, i) => _FindResultTile(user: _results[i]),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FindResultTile extends StatefulWidget {
  final UserModel user;
  const _FindResultTile({required this.user});

  @override
  State<_FindResultTile> createState() => _FindResultTileState();
}

class _FindResultTileState extends State<_FindResultTile> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final alreadyContact = appCtx.isContact(widget.user.id);
    final shortId = widget.user.id.length >= 8
        ? widget.user.id.substring(0, 8).toUpperCase()
        : widget.user.id.toUpperCase();

    return ListTile(
      leading: AvatarWidget(name: widget.user.name, radius: 22),
      title: Text(widget.user.name,
          style: TextStyle(fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      subtitle: Text(
        widget.user.phone != null && widget.user.phone!.isNotEmpty
            ? widget.user.phone!
            : 'ID: $shortId',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: alreadyContact
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Text('Kontak', style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            )
          : _adding
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : OutlinedButton.icon(
                  onPressed: () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    final appCtx = context.read<AppContext>();
                    setState(() => _adding = true);
                    try {
                      await appCtx.addContact(widget.user.id);
                      if (mounted) {
                        scaffold.showSnackBar(SnackBar(
                          content: Text('${widget.user.name} ditambahkan ke kontak'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffold.showSnackBar(SnackBar(
                          content: Text('Gagal: $e'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    } finally {
                      if (mounted) setState(() => _adding = false);
                    }
                  },
                  icon: const Icon(Icons.person_add, size: 14),
                  label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
    );
  }
}

// ── Contact Tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final UserModel user;
  const _ContactTile({required this.user});

  Future<void> _openChat(BuildContext context) async {
    final router = GoRouter.of(context);
    final appCtx = context.read<AppContext>();
    try {
      final chatId = await appCtx.getOrCreateDirectChat(user.id);
      router.push('/chat/$chatId');
    } catch (e) {
      debugPrint('_openChat error: $e');
    }
  }

  Future<void> _voiceCall(BuildContext context) async {
    final router = GoRouter.of(context);
    final appCtx = context.read<AppContext>();
    try {
      final chatId = await appCtx.getOrCreateDirectChat(user.id);
      router.push('/call/$chatId?type=voice&remoteUserId=${user.id}');
    } catch (e) {
      debugPrint('_voiceCall error: $e');
    }
  }

  Future<void> _videoCall(BuildContext context) async {
    final router = GoRouter.of(context);
    final appCtx = context.read<AppContext>();
    try {
      final chatId = await appCtx.getOrCreateDirectChat(user.id);
      router.push('/call/$chatId?remoteUserId=${user.id}');
    } catch (e) {
      debugPrint('_videoCall error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final langLabel = user.lang == 'en' ? '🇺🇸 English' : '🇮🇩 Indonesia';

    return InkWell(
      onTap: () => _openChat(context),
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AvatarWidget(name: user.name, radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(langLabel,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBtn(icon: Icons.chat_bubble_outline, onTap: () => _openChat(context)),
                const SizedBox(width: 6),
                _IconBtn(icon: Icons.call, onTap: () => _voiceCall(context)),
                const SizedBox(width: 6),
                _IconBtn(icon: Icons.videocam, onTap: () => _videoCall(context)),
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
  Widget build(BuildContext context) => GestureDetector(
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
