part of disposable_cached_images;

class DisposableCachedImage extends ConsumerStatefulWidget {
  /// Create a widget that displays image from the network and
  /// cache it in cache directory.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.

  DisposableCachedImage.network({
    this.keepAlive = false,
    required final String imageUrl,
    final Map<String, String>? headers,
    this.maxCacheWidth,
    this.maxCacheHeight,
    this.fit,
    this.centerSlice,
    this.scale = 1.0,
    this.addRepaintBoundaries = true,
    this.onImage,
    this.shape = BoxShape.rectangle,
    this.color,
    this.alignment = Alignment.center,
    this.onLoading,
    this.isAntiAlias = false,
    this.invertColors = false,
    this.height,
    this.enableRasterthreadreducer = true,
    this.colorBlendMode,
    this.isDynamicHeight = false,
    this.matchTextDirection = false,
    this.borderRadius,
    this.width,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.none,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 300),
    final Key? key,
  })  : assert(
          !isDynamicHeight || width != null,
          'Image width must be specified for dynamic size',
        ),
        _provider = _networkImageProvider(
          _ImageProviderArguments(
            image: imageUrl,
            maxCacheWidth: maxCacheWidth,
            maxCacheHeight: maxCacheHeight,
            keepAlive: keepAlive,
            headers: headers,
          ),
        ),
        super(key: key);

  /// Create a widget that displays a local image either from a file
  /// or from an asset by providing the image path.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  DisposableCachedImage.local({
    required final String imagePath,
    this.keepAlive = false,
    this.fit,
    this.centerSlice,
    this.fadeDuration = const Duration(milliseconds: 300),
    this.onLoading,
    this.onError,
    this.scale = 1.0,
    this.height,
    this.colorBlendMode,
    this.color,
    this.shape = BoxShape.rectangle,
    this.alignment = Alignment.center,
    this.addRepaintBoundaries = true,
    this.filterQuality = FilterQuality.none,
    this.width,
    this.onImage,
    this.enableRasterthreadreducer = true,
    this.repeat = ImageRepeat.noRepeat,
    this.isAntiAlias = false,
    this.invertColors = false,
    this.isDynamicHeight = false,
    this.matchTextDirection = false,
    this.borderRadius,
    final Key? key,
  })  : assert(
          !isDynamicHeight || width != null,
          'Image width must be specified for dynamic height images',
        ),
        maxCacheWidth = null,
        maxCacheHeight = null,
        _provider = _localImageProvider(
          _ImageProviderArguments(image: imagePath, keepAlive: keepAlive),
        ),
        super(key: key);

  // TODO doc
  final bool enableRasterthreadreducer;

  /// Resize the image
  ///
  /// If only one of maxCacheWidth or maxCacheHeight are specified,
  /// the other dimension will be scaled according to the aspect ratio of
  /// the supplied dimension.

  /// If either maxCacheWidth or maxCacheHeight is less than the original value,
  /// it will be ignored.
  ///
  /// The image will be resized before it is saved to the device storage
  ///
  /// Animated images wouldn't resize
  final int? maxCacheHeight, maxCacheWidth;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// The duration of fade animation.
  final Duration fadeDuration;

  /// A widget to display when loading the image,
  /// downloading the image or getting it from device storage
  final OnLoading? onLoading;

  /// A widget to display when an error occurs
  final OnError? onError;

  /// A widget for displaying the image
  final OnImage? onImage;

  /// If non-null, require the image to have this width.
  final double? width;

  /// If non-null, require the image to have this height.
  final double? height;

  /// {@macro flutter.widgets.image.filterQualityParameter}
  final FilterQuality filterQuality;

  /// If non-null, the corners of this image are rounded by this [BorderRadius].
  ///
  /// Applies only when shape [BoxShape.rectangle]
  final BorderRadius? borderRadius;

  /// The image shape.
  ///
  /// If this is [BoxShape.circle] then [borderRadius] is ignored.
  final BoxShape shape;

  /// Creates this widget that isolates repaints.
  final bool addRepaintBoundaries;

  /// This should only be enabled for images that must be in memory
  /// for the entire application lifecycle
  final bool keepAlive;

  /// Display dynamic height image, this must be enabled if you want to display
  /// dynamic height images to avoid UI jumping.
  ///
  /// The [width] argument should be specified to determine the dynamic
  /// image height, this value should be smaller than the device\widget width
  /// otherwise you could end up with a white vertical space around the image.
  ///
  /// prefer to use [MediaQuery] size if you want to use dynamic width
  ///
  /// ```dart
  /// isDynamicSize: true,
  /// width: MediaQuery.of(context).size.width * 0.4,
  /// ```
  final bool isDynamicHeight;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a subpart of an image, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// Whether to paint the image with anti-aliasing.
  ///
  /// Anti-aliasing alleviates the sawtooth artifact when the image is rotated.
  final bool isAntiAlias;

  /// Whether the colors of the image are inverted when drawn.
  ///
  /// Inverting the colors of an image applies a new color filter to the paint.
  /// If there is another specified color filter, the invert will be applied
  /// after it. This is primarily used for implementing smart invert on iOS.
  ///
  /// See also:
  ///
  ///  * [Paint.invertColors], for the dart:ui implementation.
  final bool invertColors;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect? centerSlice;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Specifies the image's scale.
  ///
  /// Used when determining the best display size for the image.
  final double scale;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color? color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode? colorBlendMode;

  final DisposableImageProvider _provider;

  /// Remove all cached images form device storage.
  static Future<void> clearCache() {
    return ImageCacheManger.getPlatformInstance().clearCache();
  }

  @override
  ConsumerState<DisposableCachedImage> createState() =>
      _DisposableCachedImageState();
}

class _DisposableCachedImageState extends ConsumerState<DisposableCachedImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController fadeAnimationController;

  @override
  void initState() {
    fadeAnimationController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
      value: ref.read(widget._provider).uiImage == null ? 0.0 : 1.0,
    );
    super.initState();
  }

  @override
  void dispose() {
    fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final context) {
    final providerState = ref.watch(widget._provider);

    if (providerState.isLoading) {
      Widget loading = const SizedBox();

      if (widget.onLoading != null) {
        loading = widget.onLoading!(
          context,
          providerState.height,
          providerState.width,
        );
      }

      if (widget.isDynamicHeight) {
        loading = SizedBox(
          height: _getDynamicHeight(
            targetWidth: widget.width!,
            width: providerState.width,
            height: providerState.height,
          ),
          width: widget.width!,
          child: loading,
        );
      }

      return loading;
    }

    if (providerState.error != null) {
      Widget error = const SizedBox();

      if (widget.onError != null) {
        error = widget.onError!(
          context,
          providerState.error!,
          providerState.stackTrace!,
          () => ref.refresh(widget._provider.notifier),
        );
      }

      return error;
    }

    fadeAnimationController.forward();

    final imageWidget = _RawImage(
      key: widget.key,
      opacity: fadeAnimationController,
      image: providerState.uiImage!,
      invertColors: widget.invertColors,
      matchTextDirection: widget.matchTextDirection,
      repeat: widget.repeat,
      scale: widget.scale,
      centerSlice: widget.centerSlice,
      addRepaintBoundary: widget.addRepaintBoundaries,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      isAntiAlias: widget.isAntiAlias,
      borderRadius: widget.borderRadius,
      filterQuality: widget.filterQuality,
      alignment: widget.alignment,
      width: widget.width,
      shape: widget.shape,
      fit: widget.isDynamicHeight ? BoxFit.fitHeight : widget.fit,
      height: widget.isDynamicHeight
          ? _getDynamicHeight(
              targetWidth: widget.width!,
              width: providerState.width,
              height: providerState.height,
            )
          : widget.height,
    );

    if (widget.onImage != null) {
      return widget.onImage!(
        context,
        imageWidget,
        providerState.height,
        providerState.width,
      );
    }

    return imageWidget;
  }

  static double? _getDynamicHeight({
    required final double targetWidth,
    required final double? width,
    required final double? height,
  }) {
    if (width == null || height == null) return null;

    return height * (targetWidth / width);
  }
}

/// Builder function to handel the image widget
typedef OnImage = Widget Function(
  BuildContext context,
  Widget imageWidget,
  double? height,
  double? width,
);

/// Builder function to create a placeholder widget while the image is loading
typedef OnLoading = Widget Function(
  BuildContext context,
  double? height,
  double? width,
);

/// Builder function to create an error widget
typedef OnError = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  VoidCallback retryCall,
);
