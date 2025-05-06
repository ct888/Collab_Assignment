import 'package:flutter/material.dart';

class PulsingWrapper extends StatefulWidget {
  final Widget child;

  const PulsingWrapper({super.key, required this.child});

  @override
  State<PulsingWrapper> createState() => _PulsingWrapperState();
}

class _PulsingWrapperState extends State<PulsingWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child
    );
  }
}
