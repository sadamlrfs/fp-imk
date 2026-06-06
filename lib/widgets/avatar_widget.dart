import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? assetPath;
  final String name;
  final double radius;

  const AvatarWidget({super.key, this.assetPath, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFromName(name),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: Colors.white, fontSize: radius * 0.85, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _colorFromName(String name) {
    final colors = [
      const Color(0xFF1A56DB),
      const Color(0xFF0694A2),
      const Color(0xFF7E3AF2),
      const Color(0xFFE02424),
      const Color(0xFF057A55),
      const Color(0xFFFF5A1F),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
