part of disposable_cached_images;

/// [RawImage] with [BorderRadius] and [BoxShape]
class _RawImage extends RawImage {
  const _RawImage({
    required this.addRepaintBoundary,
    required this.shape,
    this.borderRadius,
    required super.image,
    required super.alignment,
    required super.filterQuality,
    required super.repeat,
    required super.scale,
    required super.invertColors,
    required super.isAntiAlias,
    required super.matchTextDirection,
    required super.opacity,
    required super.centerSlice,
    super.height,
    super.width,
    super.fit,
    super.color,
    super.colorBlendMode,
    super.key,
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
    required super.image,
    super.width,
    super.height,
    super.scale = 1.0,
    super.color,
    required super.opacity,
    super.colorBlendMode,
    super.fit,
    super.alignment = Alignment.center,
    super.repeat = ImageRepeat.noRepeat,
    super.centerSlice,
    super.matchTextDirection = false,
    super.textDirection,
    super.invertColors = false,
    super.isAntiAlias = false,
    super.filterQuality = FilterQuality.low,
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
