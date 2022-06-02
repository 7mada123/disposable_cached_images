part of disposable_cached_images;

/// [RawImage] with [BorderRadius] and [BoxShape]
class _RawImage extends RawImage {
  const _RawImage({
    required this.addRepaintBoundary,
    required this.shape,
    this.borderRadius,
    required final super.image,
    required final super.alignment,
    required final super.filterQuality,
    required final super.repeat,
    required final super.scale,
    required final super.invertColors,
    required final super.isAntiAlias,
    required final super.matchTextDirection,
    required final super.opacity,
    required final super.centerSlice,
    final super.height,
    final super.width,
    final super.fit,
    final super.color,
    final super.colorBlendMode,
    final super.key,
  });

  final BorderRadius? borderRadius;
  final BoxShape shape;
  final bool addRepaintBoundary;

  @override
  RenderImage createRenderObject(final BuildContext context) {
    assert(
      (!matchTextDirection && alignment is Alignment) ||
          debugCheckHasDirectionality(context),
    );
    assert(
      image?.debugGetOpenHandleStackTraces()?.isNotEmpty ?? true,
      'Creator of a RawImage disposed of the image when the RawImage still '
      'needed it.',
    );

    return _RenderImage(
      image: image!.clone(),
      borderRadius: borderRadius,
      shape: shape,
      width: width,
      height: height,
      scale: scale,
      color: color,
      opacity: opacity!,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      textDirection: matchTextDirection || alignment is! Alignment
          ? Directionality.of(context)
          : null,
      invertColors: invertColors,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
      addRepaintBoundary: addRepaintBoundary,
    );
  }

  @override
  void updateRenderObject(
    final BuildContext context,
    final _RenderImage renderObject,
  ) {
    super.updateRenderObject(
      context,
      renderObject
        ..borderRadius = borderRadius
        ..shape = shape,
    );
  }
}

class _RenderImage extends RenderImage {
  BorderRadius? borderRadius;
  BoxShape shape;

  final bool addRepaintBoundary;

  _RenderImage({
    required this.borderRadius,
    required this.shape,
    required this.addRepaintBoundary,
    required final super.image,
    final super.width,
    final super.height,
    final super.scale = 1.0,
    final super.color,
    required final super.opacity,
    final super.colorBlendMode,
    final super.fit,
    final super.alignment = Alignment.center,
    final super.repeat = ImageRepeat.noRepeat,
    final super.centerSlice,
    final super.matchTextDirection = false,
    final super.textDirection,
    final super.invertColors = false,
    final super.isAntiAlias = false,
    final super.filterQuality = FilterQuality.low,
  });

  @override
  void paint(final PaintingContext context, final Offset offset) {
    if (shape == BoxShape.circle) {
      context.canvas.clipPath(ovalPAth(offset, size));
    } else if (borderRadius != null) {
      context.canvas.clipRRect(borderRadius!.toRRect(offset & size));
    }

    super.paint(context, offset);
  }

  @override
  bool get isRepaintBoundary => addRepaintBoundary;

  static Path ovalPAth(final Offset offset, final Size size) {
    final rect = offset & size;

    return Path()
      ..addOval(Rect.fromCircle(
        center: rect.center,
        radius: rect.shortestSide / 2.0,
      ));
  }
}
