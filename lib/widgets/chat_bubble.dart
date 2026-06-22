import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String? textId;
  final String? textEn;
  final String time;
  final bool isMe;
  final String? senderName;
  final String userLang;

  const ChatBubble({
    super.key,
    this.textId,
    this.textEn,
    required this.time,
    required this.isMe,
    this.senderName,
    this.userLang = 'id',
  });

  @override
  Widget build(BuildContext context) {
    // Decide which text + label to show on top vs in blue translate box
    final bool preferId = userLang != 'en';
    final String topText    = preferId ? (textId ?? '') : (textEn ?? '');
    final String bottomText = preferId ? (textEn ?? '') : (textId ?? '');
    final String topLabel    = preferId ? 'Bahasa Indonesia' : 'Bahasa Inggris';
    final String bottomLabel = preferId ? 'Bahasa Inggris'  : 'Bahasa Indonesia';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
              // User's language on top
              Text(topLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(topText, style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
              // Translation in blue below
              if (bottomText.isNotEmpty) ...[
                const SizedBox(height: 8),
                _TranslateBox(label: bottomLabel, text: bottomText),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(time, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
        color: const Color(0xFFDCEEFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
