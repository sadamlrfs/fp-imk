import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class MobileFrame extends StatelessWidget {
  final Widget child;
  final bool showStatusBar;

  const MobileFrame({super.key, required this.child, this.showStatusBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          if (showStatusBar) _StatusBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.statusBar,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('9:41', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          Row(
            children: const [
              Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Icon(Icons.wifi, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Icon(Icons.battery_full, color: Colors.white, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
