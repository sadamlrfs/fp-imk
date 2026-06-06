import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/call_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/avatar_widget.dart';

class CallsTab extends StatefulWidget {
  const CallsTab({super.key});

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  int _filter = 0; // 0=Semua, 1=Tak Terjawab, 2=Video

  List<CallModel> get _filtered {
    switch (_filter) {
      case 1:
        return dummyCalls.where((c) => c.isMissed).toList();
      case 2:
        return dummyCalls.where((c) => c.isVideo).toList();
      default:
        return dummyCalls;
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CallNotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                          'Panggilan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => _showNotifications(context),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _filter == 0,
                        onTap: () => setState(() => _filter = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Tak Terjawab',
                        selected: _filter == 1,
                        onTap: () => setState(() => _filter = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Video',
                        selected: _filter == 2,
                        onTap: () => setState(() => _filter = 2),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? _EmptyState(filter: _filter)
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, i) => const Divider(
                    height: 1,
                    indent: 76,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (_, i) => _CallTile(call: _filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  final CallModel call;
  const _CallTile({required this.call});

  @override
  Widget build(BuildContext context) {
    final dirIcon = call.isMissed
        ? Icons.call_missed
        : call.isIncoming
        ? Icons.call_received
        : Icons.call_made;
    final dirColor = call.isMissed ? Colors.red : AppColors.primary;

    return InkWell(
      onTap: () => context.push('/call-detail/${call.id}'),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AvatarWidget(name: call.contactName, radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.contactName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: call.isMissed ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(dirIcon, size: 14, color: dirColor),
                      const SizedBox(width: 4),
                      Icon(
                        call.isVideo ? Icons.videocam : Icons.call,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${call.date} · ${call.time}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      call.isVideo ? Icons.videocam : Icons.call,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  call.duration.isEmpty ? 'Tak terjawab' : call.duration,
                  style: TextStyle(
                    fontSize: 10,
                    color: call.isMissed ? Colors.red : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            child: Icon(
              filter == 2 ? Icons.videocam : Icons.call,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada ${labels[filter]}',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallNotificationSheet extends StatelessWidget {
  const _CallNotificationSheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.call_missed,
        'Rizal Hafiyyan',
        'Panggilan tak terjawab',
        '10 mnt lalu',
      ),
      (Icons.videocam, 'Erika', 'Mengajak video call', '30 mnt lalu'),
      (Icons.call, 'James', 'Panggilan masuk terjawab', '2 jam lalu'),
      (
        Icons.notifications,
        'Pengingat',
        'Jadwal panggilan tim pukul 15.00',
        'Hari ini',
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Notifikasi Panggilan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              item.$3,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Text(
              item.$4,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
