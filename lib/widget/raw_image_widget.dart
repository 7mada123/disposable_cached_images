part of disposable_cached_images;

/// [RawImage] with [BorderRadius] and [BoxShape]
class _RawImage extends RawImage {
  const _RawImage({
    required final ui.Image image,
    required final AlignmentGeometry alignment,
    required final FilterQuality filterQuality,
    required final ImageRepeat repeat,
    required final double scale,
    required final bool invertColors,
    required final bool isAntiAlias,
    required final bool matchTextDirection,
    required final Animation<double> opacity,
    required final this.shape,
    final this.borderRadius,
    final double? height,
    final double? width,
    final BoxFit? fit,
    final Color? color,
    final BlendMode? colorBlendMode,
    final Key? key,
  }) : super(
          image: image,
          alignment: alignment,
          opacity: opacity,
          height: height,
          width: width,
          fit: fit,
          filterQuality: filterQuality,
          color: color,
          repeat: repeat,
          scale: scale,
          colorBlendMode: colorBlendMode,
          invertColors: invertColors,
          isAntiAlias: isAntiAlias,
          matchTextDirection: matchTextDirection,
          key: key,
        );

  final BorderRadius? borderRadius;
  final BoxShape shape;

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

  _RenderImage({
    required this.borderRadius,
    required this.shape,
    required final ui.Image image,
    final double? width,
    final double? height,
    final double scale = 1.0,
    final Color? color,
    required final Animation<double> opacity,
    final BlendMode? colorBlendMode,
    final BoxFit? fit,
    final AlignmentGeometry alignment = Alignment.center,
    final ImageRepeat repeat = ImageRepeat.noRepeat,
    final Rect? centerSlice,
    final bool matchTextDirection = false,
    final TextDirection? textDirection,
    final bool invertColors = false,
    final bool isAntiAlias = false,
    final FilterQuality filterQuality = FilterQuality.low,
  }) : super(
          alignment: alignment,
          centerSlice: centerSlice,
          color: color,
          colorBlendMode: colorBlendMode,
          filterQuality: filterQuality,
          fit: fit,
          image: image,
          matchTextDirection: matchTextDirection,
          width: width,
          height: height,
          invertColors: invertColors,
          opacity: opacity,
          isAntiAlias: isAntiAlias,
          repeat: repeat,
          scale: scale,
          textDirection: textDirection,
        );

  @override
  void paint(final PaintingContext context, final Offset offset) {
    if (shape == BoxShape.circle) {
      context.canvas.clipPath(ovalPAth(offset, size));
    } else if (borderRadius != null) {
      context.canvas.clipRRect(borderRadius!.toRRect(offset & size));
    }

    super.paint(context, offset);
  }

  static Path ovalPAth(final Offset offset, final Size size) {
    final rect = offset & size;

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: rect.center,
          radius: rect.shortestSide / 2.0,
        ),
      );
  }
}
