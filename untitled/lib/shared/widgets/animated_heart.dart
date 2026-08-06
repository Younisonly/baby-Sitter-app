import 'package:flutter/material.dart';

class AnimatedHeart extends StatefulWidget {
  final bool isFavorited;
  final double size;
  final VoidCallback? onToggle;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedHeart({
    super.key,
    required this.isFavorited,
    this.size = 24,
    this.onToggle,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AnimatedHeart> createState() => _AnimatedHeartState();
}

class _AnimatedHeartState extends State<AnimatedHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _bounceAnim = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.elasticOut)),
    );
  }

  @override
  void didUpdateWidget(AnimatedHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorited && !oldWidget.isFavorited) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _controller.isAnimating
              ? _bounceAnim.value
              : (widget.isFavorited ? 1.0 : 1.0);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Icon(
          widget.isFavorited ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          size: widget.size,
          color: widget.isFavorited
              ? (widget.activeColor ?? Colors.red)
              : (widget.inactiveColor ?? Colors.grey),
        ),
      ),
    );
  }
}
