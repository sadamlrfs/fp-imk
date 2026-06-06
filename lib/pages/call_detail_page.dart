import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/call_model.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';

class CallDetailPage extends StatelessWidget {
  final String callId;
  const CallDetailPage({super.key, required this.callId});

  CallModel? get _call => dummyCalls.where((c) => c.id == callId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final call = _call;
    if (call == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          title: const Text('Detail'),
        ),
        body: const Center(child: Text('Panggilan tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Panggilan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Blue header with avatar
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AvatarWidget(name: call.contactName, radius: 48),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        call.isVideo ? Icons.videocam : Icons.call,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(call.contactName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                _StatusBadge(call: call),
              ],
            ),
          ),
          // Info cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoCard(children: [
                    _InfoRow(label: 'Tanggal', value: call.date),
                    _InfoRow(label: 'Waktu', value: call.time),
                    _InfoRow(label: 'Durasi', value: call.duration.isEmpty ? '-' : call.duration, isLast: true),
                  ]),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _InfoRow(label: 'Jenis', value: call.isVideo ? 'Video Call' : 'Suara'),
                    _InfoRow(
                      label: 'Status',
                      value: call.isMissed ? 'Tak Terjawab' : (call.isIncoming ? 'Masuk' : 'Keluar'),
                      valueColor: call.isMissed ? Colors.red : null,
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.chat_bubble_outline,
                          label: 'Pesan',
                          onTap: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.call,
                          label: 'Panggil',
                          filled: true,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.videocam,
                          label: 'Video',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CallModel call;
  const _StatusBadge({required this.call});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = call.isMissed
        ? ('Tak Terjawab', Icons.call_missed)
        : call.isIncoming
            ? ('Panggilan Masuk', Icons.call_received)
            : ('Panggilan Keluar', Icons.call_made);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  const _InfoRow({required this.label, required this.value, this.valueColor, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, color: AppColors.divider),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, this.filled = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: filled ? null : Border.all(color: AppColors.divider),
          boxShadow: filled ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: filled ? Colors.white : AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: filled ? Colors.white : AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
