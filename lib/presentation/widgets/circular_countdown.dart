import 'dart:math';
import 'package:flutter/cupertino.dart';

/// 圆形倒计时指示器
/// 环形进度条，使用 app 主题色
class CircularCountdown extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;

  const CircularCountdown({
    super.key,
    required this.remainingSeconds,
    this.totalSeconds = 30,
    this.size = 20,
  });

  /// 根据剩余时间计算颜色（主题蓝色为主）
  Color _getProgressColor() {
    final progress = remainingSeconds / totalSeconds;

    if (progress <= 0.2) {
      // 最后 20% 时间：从蓝色渐变到红色（警告）
      final t = progress / 0.2; // 0.0 到 1.0
      return Color.lerp(
        const Color(0xFFFF3B30), // 红色（警告）
        CupertinoColors.activeBlue, // 主题蓝色
        t,
      )!;
    } else {
      // 其余时间：保持主题蓝色
      return CupertinoColors.activeBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;
    final progressColor = _getProgressColor();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularCountdownPainter(
          progress: progress,
          color: progressColor,
        ),
      ),
    );
  }
}

class _CircularCountdownPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularCountdownPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.15; // 环的宽度为直径的15%

    // 绘制背景圆环（灰色）
    final bgPaint = Paint()
      ..color = CupertinoColors.systemGrey5
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // 绘制进度圆环（彩色，逆时针递减）
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth / 2,
      );

      // 从顶部开始（-90度），逆时针绘制
      final startAngle = -pi / 2;
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_CircularCountdownPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
