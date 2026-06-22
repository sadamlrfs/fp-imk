import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_background.dart';
import '../utils/app_colors.dart';

class Launch2Page extends StatelessWidget {
  const Launch2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Image.asset(
                    'assets/launch-2.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, trace) => const Center(
                      child: Icon(Icons.video_call, size: 120, color: Colors.white54),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    _DotIndicator(current: 1),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _OutlineButton(label: 'Sebelumnya', onTap: () => context.go('/')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FilledButton(label: 'Lanjut', onTap: () => context.go('/launch3')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int current;
  const _DotIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: i == current ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: i == current ? AppColors.surface : AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
      )),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilledButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}
