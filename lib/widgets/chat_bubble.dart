import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String? textId;
  final String? textEn;
  final String time;
  final bool isMe;
  final String? senderName;

  const ChatBubble({
    super.key,
    this.textId,
    this.textEn,
    required this.time,
    required this.isMe,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senderName != null && !isMe) ...[
                Text(senderName!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 4),
              ],
              if (!isMe) ...[
                const Text('Bahasa Inggris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(textEn ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                const SizedBox(height: 8),
                _TranslateBox(label: 'Bahasa Indonesia', text: textId ?? ''),
              ] else ...[
                const Text('Bahasa Indonesia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(textId ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                const SizedBox(height: 8),
                _TranslateBox(label: 'Bahasa Inggris', text: textEn ?? ''),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslateBox extends StatelessWidget {
  final String label;
  final String text;
  const _TranslateBox({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
