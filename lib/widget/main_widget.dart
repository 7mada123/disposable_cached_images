part of disposable_cached_images;

class DisposableCachedImage extends ConsumerStatefulWidget {
  /// Provide a maximum value for image width,
  /// If the actual width of the image is less than the provided value,
  /// the provided value will be ignored.
  ///
  /// The image will be resized before it is saved to the device storage
  final int? maxCacheWidth;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// The duration of fade animation.
  final Duration fadeDuration;

  /// A widget to display when loading the image,
  /// downloading the image or getting it from device storage
  final WidgetBuilder? onLoading;

  /// A widget to display when an error occurs
  final OnError? onError;

  /// A widget for displaying the image by the ImageProvider [MemoryImage]
  final OnImage? onImage;

  final DisposableImageProvider _provider;

  /// If non-null, require the image to have this width.
  final double? width;

  /// If non-null, require the image to have this height.
  final double? height;

  /// {@macro flutter.widgets.image.filterQualityParameter}
  /// {@template flutter.widgets.image.filterQualityParameter}
  final FilterQuality filterQuality;

  // TODO
  final BorderRadius? borderRadius;
  // TODO
  final bool addRepaintBoundaries;

  // TODO
  final bool isDynamicSize;

  final bool keepAlive;

  final AlignmentGeometry alignment;

  final bool isAntiAlias;
  final bool invertColors;
  final bool matchTextDirection;
  final ImageRepeat repeat;
  final double scale;
  final Color? color;
  final BlendMode? colorBlendMode;

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
    this.maxCacheWidth,
    this.fit,
    this.scale = 1.0,
    this.addRepaintBoundaries = true,
    this.onImage,
    this.color,
    this.alignment = Alignment.center,
    this.onLoading,
    this.isAntiAlias = false,
    this.invertColors = false,
    this.height,
    this.colorBlendMode,
    this.isDynamicSize = false,
    this.matchTextDirection = false,
    this.borderRadius,
    this.width,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.none,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 500),
    Key? key,
  })  : assert(
          !isDynamicSize || width != null,
          'Image width must be specified for dynamic size',
        ),
        _provider = _networkImageProvider(
          ImageProviderArguments(
            image: imageUrl,
            targetWidth: maxCacheWidth,
            keepAlive: keepAlive,
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
    this.fadeDuration = const Duration(milliseconds: 500),
    this.onLoading,
    this.onError,
    this.scale = 1.0,
    this.height,
    this.colorBlendMode,
    this.color,
    this.alignment = Alignment.center,
    this.addRepaintBoundaries = true,
    this.filterQuality = FilterQuality.none,
    this.width,
    this.onImage,
    this.repeat = ImageRepeat.noRepeat,
    this.isAntiAlias = false,
    this.invertColors = false,
    this.isDynamicSize = false,
    this.matchTextDirection = false,
    this.borderRadius,
    final Key? key,
  })  : assert(
          !isDynamicSize || width != null,
          'Image width must be specified for dynamic size',
        ),
        maxCacheWidth = null,
        _provider = _localImageProvider(
          ImageProviderArguments(image: imagePath, keepAlive: keepAlive),
        ),
        super(key: key);

  /// [DisposableCachedImage.dynamicHeight] image widget width.
  /// /// TODO
  // final double? imageWidth;

  /// Creates a widget that displays image from the network with dynamic image
  /// height and cache it in cache directory.the
  ///
  /// The [imageWidth] argument should be specified to determine the dynamic
  /// image height, this value should be smaller than the device width
  /// otherwise you could end up with white space around the height of the image.
  /// prefer to use [MediaQuery] size if you want to use dynamic width

  /// Remove all cached images.
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

      if (widget.onLoading != null) loading = widget.onLoading!(context);

      if (widget.isDynamicSize) {
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

    Widget image = _RawImage(
      key: widget.key,
      opacity: fadeAnimationController,
      image: providerState.uiImage!,
      invertColors: widget.invertColors,
      matchTextDirection: widget.matchTextDirection,
      repeat: widget.repeat,
      scale: widget.scale,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      isAntiAlias: widget.isAntiAlias,
      borderRadius: widget.borderRadius,
      filterQuality: widget.filterQuality,
      alignment: widget.alignment,
      width: widget.width,
      fit: widget.isDynamicSize ? BoxFit.fitHeight : widget.fit,
      height: widget.isDynamicSize
          ? _getDynamicHeight(
              targetWidth: widget.width!,
              width: providerState.width,
              height: providerState.height,
            )
          : widget.height,
    );

    if (widget.addRepaintBoundaries) image = RepaintBoundary(child: image);

    if (widget.onImage != null) {
      return widget.onImage!(
        context,
        image,
        providerState.height,
        providerState.width,
      );
    }

    return image;
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

typedef OnError = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  VoidCallback? reDownload,
);

typedef OnImage = Widget Function(
  BuildContext context,
  Widget imageWidget,
  double? height,
  double? width,
);
