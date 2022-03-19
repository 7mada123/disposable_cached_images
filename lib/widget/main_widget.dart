part of disposable_cached_images;

class DisposableCachedImage extends ConsumerWidget {
  /// Remove all cached images.
  static Future<void> clearCache() {
    return ImageCacheManger.getPlatformInstance().clearCache();
  }

  /// Provide a maximum value for image width,
  ///  If the actual width of the image is less than the provided value, the provided value will be ignored.
  ///
  ///  The image will be resized before it is displayed in the UI and saved to the device storage
  final int? maxCacheWidth;

  /// [BoxFit] How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  // TODO
  ///
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

  /// [FilterQuality] The rendering quality of the image.
  final FilterQuality filterQuality;

  /// Creates a widget that displays image from the network and cache it in cache directory.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.

  DisposableCachedImage.network({
    required final String imageUrl,
    this.maxCacheWidth,
    this.fit,
    this.onImage,
    this.onLoading,
    this.height,
    this.width,
    this.filterQuality = FilterQuality.none,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 500),
    Key? key,
  })  : imageWidth = null,
        _provider = _imageProvider(
          ImageProviderArguments(
            image: imageUrl,
            targetWidth: maxCacheWidth,
          ),
        ),
        super(key: key);

  /// Creates a widget that displays image from assets.
  DisposableCachedImage.assets({
    required final String imagePath,
    this.fit,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.onLoading,
    this.onError,
    this.height,
    this.filterQuality = FilterQuality.none,
    this.width,
    this.onImage,
    final Key? key,
  })  : imageWidth = null,
        maxCacheWidth = null,
        _provider = _assetsImageProvider(
          ImageProviderArguments(image: imagePath),
        ),
        super(key: key);

  /// [dynamicHeight] image widget width
  final double? imageWidth;

  /// Creates a widget that displays image from the network with dynamic image
  /// height and cache it in cache directory.the
  ///
  /// The [imageWidth] argument should be specified to determine the dynamic
  /// image height, this value should be smaller than the device width
  /// otherwise you could end up with white space around the height of the image.
  /// prefer to use [MediaQuery] size if you want to use dynamic width
  DisposableCachedImage.dynamicHeight({
    required final String imageUrl,
    this.maxCacheWidth,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.onLoading,
    this.filterQuality = FilterQuality.none,
    this.onError,
    this.onImage,
    final Key? key,
    required final this.imageWidth,
    this.fit = BoxFit.fitHeight,
    this.height,
    this.width,
  })  : _provider = _dynamicSizemageProvider(
          ImageProviderArguments(
            image: imageUrl,
            targetWidth: maxCacheWidth,
          ),
        ),
        super(key: key);

  @override
  Widget build(final context, final ref) {
    final providerState = ref.watch(_provider);

    if (imageWidth != null) {
      final height = _getDynamicHeight(
        targetWidth: imageWidth!,
        width: providerState.width,
        height: providerState.height,
      );

      return SizedBox(
        key: key,
        width: imageWidth,
        height: height,
        child: AnimatedSwitcher(
          duration: fadeDuration,
          child: providerState.isLoading
              ? _LoadingWidget(this)
              : providerState.error != null
                  ? _ErrorWidget(
                      this,
                      error: providerState.error!,
                      refreshProvider: () => ref.refresh(_provider.notifier),
                    )
                  : _DynamicHeightImageWidge(
                      this,
                      imageProvider: providerState.imageProvider!,
                      height: height,
                      width: imageWidth,
                    ),
        ),
      );
    } else {
      return AnimatedSwitcher(
        duration: fadeDuration,
        child: providerState.isLoading
            ? _LoadingWidget(this)
            : providerState.error != null
                ? _ErrorWidget(
                    this,
                    error: providerState.error!,
                    refreshProvider: () => ref.refresh(_provider.notifier),
                  )
                : _ImageWidge(
                    this,
                    imageProvider: providerState.imageProvider!,
                  ),
      );
    }
  }
}
