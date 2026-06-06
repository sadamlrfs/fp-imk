import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ChatBackground extends StatelessWidget {
  final Widget child;
  const ChatBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.chatBg,
      child: CustomPaint(
        painter: _DoodlePainter(),
        child: child,
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const style = TextStyle(
      color: Color(0x12FFFFFF),
      fontSize: 28,
      fontWeight: FontWeight.bold,
      fontFamily: 'Roboto',
    );
    const spacing = 52.0;
    const chars = ['W', 'M', 'w', 'm'];
    int charIdx = 0;

    for (double y = -10; y < size.height + spacing; y += spacing) {
      for (double x = -10; x < size.width + spacing; x += spacing) {
        final span = TextSpan(text: chars[charIdx % chars.length], style: style);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x, y));
        charIdx++;
      }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => false;
}
