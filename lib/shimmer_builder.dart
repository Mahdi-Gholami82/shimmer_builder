import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    this.paintChildren = false,
  });
  final bool enable;
  final Color? backgroundColor;
  final Color? forgroundColor;
  final double? radius;
  final double? offset;
  final double? rotation;
  final bool paintChildren;
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
      paintChildren: paintChildren,
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
    required this.paintChildren,
  });
  final bool enable;
  final Color backgroundColor;
  final Color forgroundColor;
  final Radius radius;
  final Duration duration;
  final double offset;
  final double rotation;
  final bool paintChildren;

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
    this.child,
    this.paintChild = false,
  });
  final Widget? child;
  final bool? paintChild;
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
      duration: widget.duration ?? Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final ShimmerInherited shimmer = Shimmer.of(context);

    controller
      ..stop()
      ..duration = shimmer.duration
      ..reset();

    if (shimmer.enable) {
      controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    ShimmerInherited shimmerInherited = Shimmer.of(context);
    return SizedBox(
      child: (widget.enable ?? shimmerInherited.enable)
          ? AnimatedBuilder(
              animation: controller,
              child: widget.child,
              builder: (context, child) => ShimmerSingleChildPainter(
                backgroundColor: shimmerInherited.backgroundColor,
                forgroundColor: shimmerInherited.forgroundColor,
                radius: widget.radius ?? shimmerInherited.radius,
                progress: controller.value,
                rotation: widget.rotation ?? shimmerInherited.rotation,
                gradiantOffset: widget.offset ?? shimmerInherited.offset,
                paintChild: widget.paintChild ?? shimmerInherited.paintChildren,
                child: child,
              ),
            )
          : widget.child,
    );
  }
}

class ShimmerSingleChildRenderBox extends RenderProxyBox {
  ShimmerSingleChildRenderBox({
    required this.backgroundColor,
    required this.forgroundColor,
    required this.radius,
    required this.progress,
    required this.rotation,
    required this.gradiantOffset,
    required this.paintChild,
  });
  Color backgroundColor;
  Color forgroundColor;
  Radius radius;
  double progress;
  double rotation;
  double gradiantOffset;
  bool paintChild;

  @override
  void performLayout() {
    if (child == null) {
      size = computeSizeForNoChild(constraints);
      return;
    }
    size = constraints.constrain(
      (child!..layout(constraints.loosen(), parentUsesSize: true)).size,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || size.isEmpty) return;
    final Canvas canvas = context.canvas;
    layer ??= ContainerLayer();
    if (paintChild) {
      context.paintChild(child!, offset);
    }
    Rect childBoundingBox = offset & (child!.size);

    final rRect = RRect.fromRectAndRadius(childBoundingBox, radius);

    final paint = Paint()..color = backgroundColor;
    canvas.drawRRect(rRect, paint);

    // Calculate the rotated gradients required travel distance to ensure it
    // starts and ends outside the widgets bounds, allowing a smooth shimmer transition
    final diagonal = math.sqrt(
      childBoundingBox.width * childBoundingBox.width +
          childBoundingBox.height * childBoundingBox.height,
    );
    final gradientWidth = math.cos(rotation) * diagonal;

    final outer = rRect.outerRect;

    var gradiantPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [backgroundColor, forgroundColor, backgroundColor],
            stops: [
              progress - gradiantOffset,
              progress,
              progress + gradiantOffset,
            ],
            transform: GradientRotation(rotation),
          ).createShader(
            Rect.fromLTRB(
              outer.left - gradientWidth,
              outer.top,
              outer.right + gradientWidth,
              outer.bottom,
            ),
          );
    canvas.drawRRect(rRect, gradiantPaint);
  }
}

class ShimmerSingleChildPainter extends SingleChildRenderObjectWidget {
  final Color backgroundColor;
  final Color forgroundColor;
  final Radius radius;
  final double progress;
  final double rotation;
  final double gradiantOffset;
  final bool paintChild;

  const ShimmerSingleChildPainter({
    super.key,
    required this.backgroundColor,
    required this.forgroundColor,
    required this.radius,
    required this.progress,
    required this.rotation,
    required this.gradiantOffset,
    required super.child,
    required this.paintChild,
  });

  @override
  ShimmerSingleChildRenderBox createRenderObject(BuildContext context) {
    return ShimmerSingleChildRenderBox(
      backgroundColor: backgroundColor,
      forgroundColor: forgroundColor,
      radius: radius,
      progress: progress,
      rotation: rotation,
      gradiantOffset: gradiantOffset,
      paintChild: paintChild,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant ShimmerSingleChildRenderBox renderObject,
  ) {
    renderObject.backgroundColor = backgroundColor;
    renderObject.forgroundColor = forgroundColor;
    renderObject.progress = progress;
    renderObject.radius = radius;
    renderObject.rotation = rotation;
    renderObject.gradiantOffset = gradiantOffset;
    renderObject.markNeedsPaint();
  }
}
