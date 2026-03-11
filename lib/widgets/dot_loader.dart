import 'dart:math';
import 'package:flutter/material.dart';

class DotLoader extends StatefulWidget {
  final double size;
  final Color color;
  final int dotCount;

  const DotLoader({
    super.key,
    this.size = 50.0,
    this.color = const Color(0xFF1B8D4B),
    this.dotCount = 12,
  });

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        const double dotSize = 6;
        final double radius = (widget.size - dotSize) / 2;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(widget.dotCount, (index) {
              final double angle = (index * 2 * pi) / widget.dotCount;
              final double x = radius * cos(angle);
              final double y = radius * sin(angle);

              // Calculate opacity based on controller value and dot index
              // This creates the "trailing" effect
              double opacity =
                  (index / widget.dotCount + _controller.value) % 1.0;

              // Map opacity to make it look like the image (some dots fully visible, others fading)
              if (opacity < 0.3) {
                opacity = 0.1;
              } else if (opacity > 0.8) {
                opacity = 1.0;
              } else {
                opacity = (opacity - 0.3) / 0.5 * 0.9 + 0.1;
              }

              return Positioned(
                left: widget.size / 2 + x - dotSize / 2,
                top: widget.size / 2 + y - dotSize / 2,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
