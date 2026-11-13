import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Critically damped spring matching damping: 20, stiffness: 300
class LiquidSpring {
  static const SpringDescription standard = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 20.0,
  );

  static const Curve curve = Curves.easeOutCubic;
  static const Duration duration = Duration(milliseconds: 420);
}

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final bool showTopReflection;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blurSigma = 24.0,
    this.opacity = 0.06,
    this.padding,
    this.tintColor,
    this.showTopReflection = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseTint = tintColor ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          if (tintColor != null)
            BoxShadow(
              color: tintColor!.withValues(alpha: 0.14),
              blurRadius: 24,
              spreadRadius: -4,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseTint.withValues(alpha: opacity + 0.03),
                  Colors.white.withValues(alpha: opacity * 0.6),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                if (showTopReflection)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 1.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile pressable wrapper that scales smoothly with haptic feedback
class TactileBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const TactileBounce({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<TactileBounce> createState() => _TactileBounceState();
}

class _TactileBounceState extends State<TactileBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: widget.scaleDown,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.animateTo(
      widget.scaleDown,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails _) {
    _springBack();
    widget.onTap?.call();
  }

  void _springBack() {
    final simulation = SpringSimulation(
      LiquidSpring.standard,
      _controller.value,
      1.0,
      2.5,
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _springBack,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.scale(
          scale: _controller.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
