import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShimmerBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) childBuilder;
  final Widget Function(BuildContext context)? sampleBuilder;
  final bool? enableShimmer;
  final bool wrapWithSliverToBoxAdapter;
  const ShimmerBuilder({
    super.key,
    this.enableShimmer,
    required this.childBuilder,
    this.sampleBuilder,
    this.wrapWithSliverToBoxAdapter = false,
  });
  @override
  Widget build(BuildContext context) {
    bool enabled = enableShimmer ?? Shimmer.maybeOf(context)?.enable ?? false;
    Widget getShimmer() => ShimmerPaintOver(
      enable: true,
      child: (sampleBuilder ?? childBuilder)(context),
    );
    return enabled
        ? wrapWithSliverToBoxAdapter
              ? SliverToBoxAdapter(child: getShimmer())
              : getShimmer()
        : childBuilder(context);
  }
}

class Shimmer extends StatelessWidget {
  const Shimmer({
    super.key,
    required this.enable,
    this.backgroundColor,
    this.forgroundColor,
    this.radius,
    this.duration = const Duration(seconds: 1),
    required this.child,
    this.offset,
    this.rotation,
  });
  final bool enable;
  final Color? backgroundColor;
  final Color? forgroundColor;
  final double? radius;
  final double? offset;
  final double? rotation;
  final Duration duration;
  final Widget child;

  static ShimmerInherited? maybeOf(BuildContext context) =>
      ShimmerInherited.maybeOf(context);

  static ShimmerInherited of(BuildContext context) =>
      ShimmerInherited.of(context);

  @override
  Widget build(BuildContext context) {
    Brightness? brightness;
    if (backgroundColor == null || forgroundColor == null) {
      brightness = Theme.brightnessOf(context);
    }
    return ShimmerInherited(
      enable: enable,
      backgroundColor:
          backgroundColor ??
          (brightness == Brightness.light
              ? Colors.grey.shade300
              : Colors.grey.shade800),
      forgroundColor:
          forgroundColor ??
          (brightness == Brightness.light
              ? Colors.grey.shade100
              : Colors.grey.shade600),
      radius: Radius.circular(radius ?? 10),
      duration: duration,
      offset: offset ?? 0.2,
      rotation: rotation ?? 0.6,
      child: child,
    );
  }
}

class ShimmerInherited extends InheritedWidget {
  const ShimmerInherited({
    super.key,
    this.enable = false,
    required this.backgroundColor,
    required this.forgroundColor,
    required super.child,
    required this.radius,
    required this.duration,
    required this.offset,
    required this.rotation,
  });
  final bool enable;
  final Color backgroundColor;
  final Color forgroundColor;
  final Radius radius;
  final Duration duration;
  final double offset;
  final double rotation;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  static ShimmerInherited? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShimmerInherited>();
  }

  static ShimmerInherited of(BuildContext context) {
    final ShimmerInherited? result = maybeOf(context);
    assert(result != null, "No ShimmerInherited found in context");
    return result!;
  }
}

class ShimmerPaintOver extends StatefulWidget {
  const ShimmerPaintOver({
    super.key,
    this.duration,
    this.radius,
    this.offset,
    this.rotation,
    this.enable,
    required this.child,
  });
  final Widget child;
  final Duration? duration;
  final Radius? radius;
  final double? offset;
  final double? rotation;
  final bool? enable;
  @override
  State<ShimmerPaintOver> createState() => _ShimmerPaintOverState();
}

class _ShimmerPaintOverState extends State<ShimmerPaintOver>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? Duration(seconds: 1),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    ShimmerInherited shimmerInherited = Shimmer.of(context);
    return (widget.enable ?? shimmerInherited.enable)
        ? AnimatedBuilder(
            animation: controller,
            child: widget.child,
            builder: (context, child) => CustomPaint(
              foregroundPainter: ShimmerCustomPainter(
                backgroundColor: shimmerInherited.backgroundColor,
                forgroundColor: shimmerInherited.forgroundColor,
                radius: widget.radius ?? shimmerInherited.radius,
                progress: controller.value,
                rotation: widget.rotation ?? shimmerInherited.rotation,
                offset: widget.offset ?? shimmerInherited.offset,
              ),
              child: child,
            ),
          )
        : widget.child;
  }
}

class ShimmerCustomPainter extends CustomPainter {
  ShimmerCustomPainter({
    required this.backgroundColor,
    required this.forgroundColor,
    required this.radius,
    required this.progress,
    required this.rotation,
    required this.offset,
  });

  final Color backgroundColor;
  final Color forgroundColor;
  final Radius radius;
  final double progress;
  final double rotation;
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final rRect = RRect.fromRectAndRadius(Offset.zero & size, radius);

    final paint = Paint()..color = backgroundColor;
    canvas.drawRRect(rRect, paint);

    if (size.isEmpty) return;

    // Calculate the rotated gradients required travel distance to ensure it
    // starts and ends outside the widgets bounds, allowing a smooth shimmer transition
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final gradiantWidth = math.cos(rotation) * diagonal;

    final outer = rRect.outerRect;
    paint.shader =
        LinearGradient(
          colors: [backgroundColor, forgroundColor, backgroundColor],
          stops: [progress - offset, progress, progress + offset],
          transform: GradientRotation(rotation),
        ).createShader(
          Rect.fromLTRB(
            outer.left - gradiantWidth,
            outer.top,
            outer.right + gradiantWidth,
            outer.bottom,
          ),
        );

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant ShimmerCustomPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.forgroundColor != forgroundColor ||
        oldDelegate.radius != radius;
  }
}
