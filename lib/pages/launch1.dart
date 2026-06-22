import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_background.dart';
import '../utils/app_colors.dart';

class Launch1Page extends StatelessWidget {
  const Launch1Page({super.key});

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
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          'assets/launch-1.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, trace) => const _PlaceholderImage(icon: Icons.translate),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    _DotIndicator(current: 0),
                    const SizedBox(height: 24),
                    _LaunchButton(label: 'Lanjut', onTap: () => context.go('/launch2')),
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

class _PlaceholderImage extends StatelessWidget {
  final IconData icon;
  const _PlaceholderImage({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, size: 120, color: Colors.white.withValues(alpha: 0.5)));
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

class _LaunchButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LaunchButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
