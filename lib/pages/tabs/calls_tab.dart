import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../context/app_context.dart';
import '../../models/app_models.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_widget.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  int _filter = 0; // 0=Semua, 1=Tak Terjawab, 2=Video

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final all = appCtx.calls;
    final calls = all.where((c) {
      if (_filter == 1) return c.direction == 'missed';
      if (_filter == 2) return c.type == 'video';
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Panggilan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined,
                            color: AppColors.textSecondary),
                        onPressed: () => _showNotifications(context),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _FilterChip(label: 'Semua',        selected: _filter == 0, onTap: () => setState(() => _filter = 0)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Tak Terjawab', selected: _filter == 1, onTap: () => setState(() => _filter = 1)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Video',        selected: _filter == 2, onTap: () => setState(() => _filter = 2)),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.divider),
              ],
            ),
          ),
        ),
        Expanded(
          child: calls.isEmpty
              ? _EmptyState(filter: _filter)
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: calls.length,
                  separatorBuilder: (_, i) => Divider(
                      height: 1, indent: 72, color: AppColors.divider),
                  itemBuilder: (_, i) => _CallTile(call: calls[i]),
                ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CallNotificationSheet(),
    );
  }
}

class _CallTile extends StatelessWidget {
  final CallModel call;
  const _CallTile({required this.call});

  Future<void> _callBack(BuildContext context, bool video) async {
    final router = GoRouter.of(context);
    final appCtx = context.read<AppContext>();
    if (call.contactId.isEmpty) return;
    final chatId = await appCtx.getOrCreateDirectChat(call.contactId);
    router.push(
      '/call/$chatId?type=${video ? 'video' : 'voice'}&remoteUserId=${call.contactId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.read<AppContext>();
    final name = appCtx.getUserById(call.contactId)?.name ?? 'Tidak dikenal';
    final missed = call.direction == 'missed';
    final outgoing = call.direction == 'outgoing';

    final IconData dirIcon;
    final Color dirColor;
    if (missed) {
      dirIcon = Icons.call_missed;
      dirColor = Colors.red;
    } else if (outgoing) {
      dirIcon = Icons.call_made;
      dirColor = Colors.green;
    } else {
      dirIcon = Icons.call_received;
      dirColor = AppColors.primary;
    }

    final subtitleParts = <String>[
      if (call.date.isNotEmpty) call.date,
      if (call.time.isNotEmpty) call.time,
      if (call.duration.isNotEmpty) call.duration,
    ];

    return ListTile(
      leading: AvatarWidget(name: name, radius: 24),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: missed ? Colors.red : AppColors.textPrimary,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(dirIcon, size: 14, color: dirColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              subtitleParts.join(' · '),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(call.type == 'video' ? Icons.videocam : Icons.call,
            color: AppColors.primary),
        onPressed: () => _callBack(context, call.type == 'video'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.searchBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final labels = ['panggilan', 'panggilan tak terjawab', 'panggilan video'];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(filter == 2 ? Icons.videocam : Icons.call,
                size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text('Tidak ada ${labels[filter]}',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Riwayat panggilan akan muncul di sini',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CallNotificationSheet extends StatelessWidget {
  const _CallNotificationSheet();

  @override
  Widget build(BuildContext context) {
    final calls = context.watch<AppContext>().calls.where((c) => c.direction == 'missed').toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Notifikasi Panggilan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ),
        const Divider(height: 24),
        if (calls.isEmpty)
          Padding(
            padding: EdgeInsets.all(24),
            child: Text('Belum ada panggilan tak terjawab',
                style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: calls.length,
              itemBuilder: (ctx, i) {
                final c = calls[i];
                final name = ctx.read<AppContext>().getUserById(c.contactId)?.name ?? 'Tidak dikenal';
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x14FF0000),
                    child: Icon(Icons.call_missed, color: Colors.red, size: 20),
                  ),
                  title: Text(name, style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text('${c.date} ${c.time}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
