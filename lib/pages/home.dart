import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../context/app_context.dart';
import '../models/app_models.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';
import 'tabs/calls_tab.dart';
import 'tabs/contacts_tab.dart';
import 'tabs/profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    // Listen for incoming calls + in-app notification banners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appCtx = context.read<AppContext>();
      appCtx.incomingCallNotifier.addListener(_onIncomingCall);
      appCtx.bannerNotifier.addListener(_onBanner);
    });
  }

  @override
  void dispose() {
    final appCtx = context.read<AppContext>();
    appCtx.incomingCallNotifier.removeListener(_onIncomingCall);
    appCtx.bannerNotifier.removeListener(_onBanner);
    super.dispose();
  }

  void _onBanner() {
    if (!mounted) return;
    final appCtx = context.read<AppContext>();
    final n = appCtx.bannerNotifier.value;
    if (n == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.title,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          Text(n.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
      backgroundColor: const Color(0xFF1F2937),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      action: n.chatId != null
          ? SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => context.push('/chat/${n.chatId}'),
            )
          : null,
    ));
  }

  void _onIncomingCall() {
    if (!mounted) return;
    final incoming = context.read<AppContext>().incomingCallNotifier.value;
    if (incoming != null) _showIncomingCallDialog(incoming);
  }

  void _showIncomingCallDialog(IncomingCallInfo incoming) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget(name: incoming.fromUserName, radius: 36),
            const SizedBox(height: 12),
            Text(incoming.fromUserName,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              incoming.callType == 'video' ? 'Panggilan Video Masuk' : 'Panggilan Suara Masuk',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<AppContext>().declineCall(incoming);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ),
                // Accept
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final appCtx = context.read<AppContext>();
                    final router = GoRouter.of(context);
                    // Find or create a chat with the caller
                    final chatId = await appCtx.getOrCreateDirectChat(incoming.fromUserId);
                    appCtx.dismissIncomingCall();
                    router.push(
                      '/call/$chatId'
                      '?type=${incoming.callType}'
                      '&mode=callee'
                      '&roomId=${incoming.roomId}'
                      '&remoteUserId=${incoming.fromUserId}',
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.call, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          _MessagesTab(),
          ContactsTab(),
          CallsTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
    );
  }
}

class _MessagesTab extends StatefulWidget {
  const _MessagesTab();

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateGroupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _HomeHeader(searchController: _searchController),
            Expanded(child: _ChatList(query: _query)),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showCreateGroupSheet,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.group_add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  const _HomeHeader({required this.searchController});

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppContext>().currentUser;

    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  AvatarWidget(name: me?.name ?? 'User', radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pesan',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showNotifications(context),
                    child: Icon(Icons.notifications_outlined,
                        color: AppColors.textSecondary),
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
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari atau mulai chat',
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchController,
                      builder: (context, value, child) => value.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () => searchController.clear(),
                              child: Icon(Icons.clear,
                                  color: AppColors.textSecondary, size: 18),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final String query;
  const _ChatList({this.query = ''});

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<AppContext>();
    if (!ctx.isLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final chats = query.isEmpty
        ? ctx.chats
        : ctx.chats.where((chat) {
            if (chat.type == 'group') {
              return (chat.name ?? '').toLowerCase().contains(query);
            } else {
              final contact =
                  ctx.getUserById(chat.participantIds.firstOrNull ?? '');
              return (contact?.name ?? '').toLowerCase().contains(query);
            }
          }).toList();

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'Belum ada percakapan\nMulai chat dari tab Kontak'
                  : 'Tidak ada hasil untuk "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: chats.length,
      separatorBuilder: (_, i) =>
          Divider(height: 1, indent: 76, color: AppColors.divider),
      itemBuilder: (_, i) => _ChatTile(chat: chats[i]),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final ctx = context.read<AppContext>();
    final isGroup = chat.type == 'group';
    final name = isGroup ? (chat.name ?? 'Grup') : _contactName(ctx);

    return InkWell(
      onTap: () => isGroup
          ? context.push('/group/${chat.id}')
          : context.push('/chat/${chat.id}'),
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarWidget(name: name, radius: 26),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isGroup ? Colors.orange[700] : AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      isGroup ? Icons.group : Icons.person,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(chat.time,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unread > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: Text(
                            '${chat.unread}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _contactName(AppContext ctx) {
    if (chat.participantIds.isEmpty) return 'Unknown';
    final user = ctx.getUserById(chat.participantIds.first);
    return user?.name ?? 'Unknown';
  }
}

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet();

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  @override
  void initState() {
    super.initState();
    // Opening the sheet counts as seeing the notifications.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppContext>().markAllNotificationsRead();
    });
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppContext>().notifications;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Text(
                'Notifikasi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () {
                    context.read<AppContext>().clearNotifications();
                    Navigator.pop(context);
                  },
                  child: const Text('Hapus semua'),
                ),
            ],
          ),
        ),
        const Divider(height: 16),
        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Belum ada notifikasi baru',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, i) =>
                  Divider(height: 1, indent: 64, color: AppColors.divider),
              itemBuilder: (_, i) {
                final n = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      n.type == 'call' ? Icons.call : Icons.chat_bubble,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(n.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  subtitle: Text(n.body,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(_ago(n.time),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  onTap: n.chatId != null
                      ? () {
                          Navigator.pop(context);
                          context.push('/chat/${n.chatId}');
                        }
                      : null,
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final void Function(int) onTap;
  const _BottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.chat_bubble_outline, Icons.chat_bubble, 'Pesan'),
      (Icons.people_outline, Icons.people, 'Kontak'),
      (Icons.call_outlined, Icons.call, 'Panggilan'),
      (Icons.person_outline, Icons.person, 'Profil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = selected == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? items[i].$2 : items[i].$1,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$3,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isActive ? AppColors.primary : AppColors.textSecondary,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Create Group Sheet ─────────────────────────────────────

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama grup tidak boleh kosong')),
      );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 anggota')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final appCtx = context.read<AppContext>();
      final router = GoRouter.of(context);
      final chatId = await appCtx.createGroup(name, _selected.toList());
      if (!mounted) return;
      Navigator.pop(context);
      router.push('/group/$chatId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat grup: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final contacts = appCtx.contacts;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Buat Grup Baru',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Nama Grup',
                prefixIcon: const Icon(Icons.group, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.searchBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            if (_selected.isNotEmpty)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _selected.map((id) {
                    final u = appCtx.getUserById(id);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(u?.name ?? id,
                            style: const TextStyle(fontSize: 12, color: Colors.white)),
                        backgroundColor: AppColors.primary,
                        deleteIconColor: Colors.white,
                        onDeleted: () => setState(() => _selected.remove(id)),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (_selected.isNotEmpty) const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Pilih Anggota (${_selected.length})',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child: Text('Belum ada kontak',
                          style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: contacts.length,
                      itemBuilder: (_, i) {
                        final u = contacts[i];
                        final checked = _selected.contains(u.id);
                        return ListTile(
                          leading: AvatarWidget(name: u.name, radius: 20),
                          title: Text(u.name,
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          subtitle: u.phone != null && u.phone!.isNotEmpty
                              ? Text(u.phone!,
                                  style: TextStyle(fontSize: 12,
                                      color: AppColors.textSecondary))
                              : null,
                          trailing: Checkbox(
                            value: checked,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (_) => setState(() {
                              if (checked) {
                                _selected.remove(u.id);
                              } else {
                                _selected.add(u.id);
                              }
                            }),
                          ),
                          onTap: () => setState(() {
                            if (checked) {
                              _selected.remove(u.id);
                            } else {
                              _selected.add(u.id);
                            }
                          }),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _creating ? null : _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _creating
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Buat Grup',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
