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

  Future<void> _resetOnboarding() async {
    final appCtx = context.read<AppContext>();
    final router = GoRouter.of(context);
    await appCtx.resetAll();
    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _MessagesTab(onReset: _resetOnboarding),
          const ContactsTab(),
          const CallsTab(),
          const ProfileTab(),
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
  final VoidCallback onReset;
  const _MessagesTab({required this.onReset});

  @override
  State<_MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<_MessagesTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HomeHeader(onReset: widget.onReset, searchController: _searchController),
        Expanded(child: _ChatList(query: _query)),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onReset;
  final TextEditingController searchController;
  const _HomeHeader({required this.onReset, required this.searchController});

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  const AvatarWidget(name: 'Sadam', radius: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pesan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onLongPress: onReset,
                    onTap: () => _showNotifications(context),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
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
                    const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari atau mulai chat',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchController,
                      builder: (context, value, _) => value.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () => searchController.clear(),
                              child: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final chats = query.isEmpty
        ? ctx.chats
        : ctx.chats.where((chat) {
            if (chat.type == 'group') {
              return (chat.name ?? '').toLowerCase().contains(query);
            } else {
              final contact = ctx.getUserById(chat.participantIds.firstOrNull ?? '');
              return (contact?.name ?? '').toLowerCase().contains(query);
            }
          }).toList();

    if (chats.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty ? 'Belum ada percakapan' : 'Tidak ada hasil untuk "$query"',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: chats.length,
      separatorBuilder: (_, i) => const Divider(height: 1, indent: 76, color: AppColors.divider),
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
    final name = isGroup ? (chat.name ?? 'Group') : _getContactName(ctx, chat);

    return InkWell(
      onTap: () => isGroup ? context.push('/group/${chat.id}') : context.push('/chat/${chat.id}'),
      child: Container(
        color: Colors.white,
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
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(chat.time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unread > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: Text(
                            '${chat.unread}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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

  String _getContactName(AppContext ctx, ChatModel chat) {
    if (chat.participantIds.isEmpty) return 'Unknown';
    final user = ctx.getUserById(chat.participantIds.first);
    return user?.name ?? 'Unknown';
  }
}

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.chat_bubble, 'Rizal Hafiyyan', 'Mengirim pesan baru', '2 mnt lalu'),
      (Icons.group, 'Group IMK', 'James: mengirim pesan suara', '5 mnt lalu'),
      (Icons.videocam, 'Erika', 'Melewatkan panggilan video', '1 jam lalu'),
      (Icons.person_add, 'Sarah', 'Ingin terhubung denganmu', '2 jam lalu'),
      (Icons.notifications, 'Pengingat', 'Pertemuan grup pukul 14.00', 'Hari ini'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Notifikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ),
        const Divider(height: 24),
        ...items.map(
          (item) => ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.$1, color: AppColors.primary, size: 20),
            ),
            title: Text(
              item.$2,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
            subtitle: Text(item.$3, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: Text(item.$4, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
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
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
