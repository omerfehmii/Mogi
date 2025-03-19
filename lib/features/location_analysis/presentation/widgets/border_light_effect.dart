import 'package:flutter/material.dart';

class BorderLightEffect extends StatefulWidget {
  final Widget child;
  final Color lightColor;

  const BorderLightEffect({
    super.key,
    required this.child,
    this.lightColor = Colors.white,
  });

  @override
  State<BorderLightEffect> createState() => _BorderLightEffectState();
}

class _BorderLightEffectState extends State<BorderLightEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: false, period: const Duration(milliseconds: 8000));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Alt gölge (daha koyu ve geniş)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        // Üst ışık efekti
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.lightColor.withOpacity(0.3),
                  widget.lightColor.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.lightColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: -2,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
          ),
        ),
        // İç gölge efekti
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
        widget.child,
        // Işıltı efekti
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ShimmerPainter(
                    progress: _controller.value,
                    lightColor: widget.lightColor,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color lightColor;

  _ShimmerPainter({
    required this.progress,
    required this.lightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(20),
    );

    final clipPath = Path()..addRRect(rrect);
    canvas.clipPath(clipPath);

    final shimmerPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          lightColor.withOpacity(0.0),
          lightColor.withOpacity(0.0),
          lightColor.withOpacity(0.2),
          lightColor.withOpacity(0.3),
          lightColor.withOpacity(0.2),
          lightColor.withOpacity(0.0),
          lightColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
        begin: Alignment(-2 + (progress * 4), 0),
        end: Alignment(-1 + (progress * 4), 0),
      ).createShader(rect);

    canvas.drawRect(rect, shimmerPaint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 