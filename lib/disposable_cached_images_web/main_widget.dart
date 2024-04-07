part of disposable_cached_images_io;

class DisposableCachedImage extends StatelessWidget {
  DisposableCachedImage.bytes({
    this.keepAlive = false,
    required final Uint8List bytes,
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
    this.colorBlendMode,
    this.resizeImage = false,
    this.isDynamicHeight = false,
    this.matchTextDirection = false,
    this.borderRadius,
    this.width,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.none,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 300),
    final Key? key,
    this.keepBytesInMemory = true,
    this.progressBuilder,
  })  : assert(
          !isDynamicHeight || width != null,
          'Image width must be specified for dynamic size',
        ),
        assert(
          !resizeImage || width != null || height != null,
          'Either height or width must be specified when resizeImage is enabled',
        ),
        imageProvider = MemoryImage(bytes, scale: scale),
        super(key: key);

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
    this.colorBlendMode,
    this.resizeImage = false,
    this.isDynamicHeight = false,
    this.matchTextDirection = false,
    this.borderRadius,
    this.width,
    this.repeat = ImageRepeat.noRepeat,
    this.filterQuality = FilterQuality.none,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 300),
    final Key? key,
    this.keepBytesInMemory = true,
    this.progressBuilder,
  })  : assert(
          !isDynamicHeight || width != null,
          'Image width must be specified for dynamic size',
        ),
        assert(
          !resizeImage || width != null || height != null,
          'Either height or width must be specified when resizeImage is enabled',
        ),
        imageProvider = NetworkImage(imageUrl, headers: headers, scale: scale),
        super(key: key);

  /// Create a widget that displays a local image from device storage
  /// by providing the image path.
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
    this.resizeImage = false,
    this.shape = BoxShape.rectangle,
    this.alignment = Alignment.center,
    this.addRepaintBoundaries = true,
    this.filterQuality = FilterQuality.none,
    this.width,
    this.onImage,
    this.repeat = ImageRepeat.noRepeat,
    this.isAntiAlias = false,
    this.invertColors = false,
    this.isDynamicHeight = false,
    this.matchTextDirection = false,
    this.keepBytesInMemory = true,
    this.borderRadius,
    final Key? key,
  })  : assert(
          !isDynamicHeight || width != null,
          'Image width must be specified for dynamic height images',
        ),
        assert(
          !resizeImage || width != null || height != null,
          'Either height or width must be specified when resizeImage is enabled',
        ),
        maxCacheWidth = null,
        maxCacheHeight = null,
        imageProvider = FileImage(File(imagePath), scale: scale),
        progressBuilder = null,
        super(key: key);

  /// Create a widget that displays a local image from
  /// asset by providing the image path.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  DisposableCachedImage.asset({
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
    this.resizeImage = false,
    this.shape = BoxShape.rectangle,
    this.alignment = Alignment.center,
    this.addRepaintBoundaries = true,
    this.filterQuality = FilterQuality.none,
    this.width,
    this.onImage,
    this.repeat = ImageRepeat.noRepeat,
    this.isAntiAlias = false,
    this.invertColors = false,
    this.isDynamicHeight = false,
    this.matchTextDirection = false,
    this.borderRadius,
    final Key? key,
    this.keepBytesInMemory = true,
  })  : assert(
          !isDynamicHeight || width != null,
          'Image width must be specified for dynamic height images',
        ),
        assert(
          !resizeImage || width != null || height != null,
          'Either height or width must be specified when resizeImage is enabled',
        ),
        maxCacheWidth = null,
        maxCacheHeight = null,
        imageProvider = AssetImage(imagePath),
        progressBuilder = null,
        super(key: key);

  /// option to save this image bytes into memory and reuse it later instead of reading from storage
  final bool keepBytesInMemory;

  /// Resize the image and save the resized bytes to storage, see [resizeImage].
  ///
  /// If only one of maxCacheWidth or maxCacheHeight are specified,
  /// the other dimension will be scaled according to the aspect ratio of
  /// the supplied dimension.

  /// If either maxCacheWidth or maxCacheHeight is less than the original value,
  /// it will be ignored.
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

  /// isolates image repaints.
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

  /// Resize the image to the given values [width] and/or [height] before painting
  ///
  /// This will reduce raster thread usage when using high-resolution images
  /// with a slight increase in memory
  ///
  /// Animated images wouldn't resize
  final bool resizeImage;

  final Widget Function(BuildContext context, double progress)? progressBuilder;

  /// Remove all cached images form device storage.
  static Future<void> clearCache() async {}

  final ImageProvider imageProvider;

  @override
  Widget build(final context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            colorFilter: color != null
                ? ColorFilter.mode(
                    color!,
                    BlendMode.srcIn,
                  )
                : null,
            centerSlice: centerSlice,
            alignment: alignment,
            filterQuality: filterQuality,
            fit: fit,
            invertColors: invertColors,
            isAntiAlias: isAntiAlias,
            matchTextDirection: matchTextDirection,
            onError: (exception, stackTrace) {
              if (onError == null) return;

              onError!(
                context,
                exception,
                stackTrace ?? StackTrace.current,
                () {
                  // not supported
                },
              );
            },
            repeat: repeat,
            scale: scale,
          ),
          shape: shape,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Builder function to handel the image widget
typedef OnImage = Widget Function(
  BuildContext context,
  Widget imageWidget,
  int? height,
  int? width,
);

/// Builder function to create a placeholder widget while the image is loading
typedef OnLoading = Widget Function(
  BuildContext context,
  int? height,
  int? width,
);

/// Builder function to create an error widget
typedef OnError = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  VoidCallback retryCall,
);
