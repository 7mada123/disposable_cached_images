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

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  final Duration fadeDuration;

  /// A widget to display when loading the image,
  /// downloading the image or getting it from device storage
  final WidgetBuilder? onLoading;

  /// A widget to display when an error occurs
  final OnError? onError;

  /// A widget for displaying the image by the ImageProvider [MemoryImage]
  final OnImage? onImage;

  final DisposableImageProvider provider;

  // TODO
  // doc
  DisposableCachedImage.network({
    required final String imageUrl,
    this.maxCacheWidth,
    this.fit,
    this.onImage,
    this.onLoading,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 500),
    Key? key,
  })  : imageWidth = null,
        provider = _imageProvider(
          ImageProviderArguments(
            image: imageUrl,
            targetWidth: maxCacheWidth,
          ),
        ),
        super(key: key);

  // TODO
  // doc
  DisposableCachedImage.assets({
    required final String imagePath,
    this.maxCacheWidth,
    this.fit,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.onLoading,
    this.onError,
    this.onImage,
    final Key? key,
  })  : imageWidth = null,
        provider = _assetsImageProvider(
          ImageProviderArguments(
            image: imagePath,
            targetWidth: maxCacheWidth,
          ),
        ),
        super(key: key);

  final double? imageWidth;

  // TODO
  // doc
  DisposableCachedImage.dynamicHeight({
    required final String imageUrl,
    this.maxCacheWidth,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.onLoading,
    this.onError,
    this.onImage,
    final Key? key,
    // TODO
    // add required parmeters
    required final this.imageWidth,
    this.fit = BoxFit.fitHeight,
  })  : provider = _dynamicSizemageProvider(
          ImageProviderArguments(
            image: imageUrl,
            targetWidth: maxCacheWidth,
          ),
        ),
        super(key: key);

  // TODO
  // add .file consructer

  @override
  Widget build(final context, final ref) {
    final providerState = ref.watch(provider);

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
                      refreshProvider: () => ref.refresh(provider.notifier),
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
                    refreshProvider: () => ref.refresh(provider.notifier),
                  )
                : _ImageWidge(
                    this,
                    imageProvider: providerState.imageProvider!,
                  ),
      );
    }
  }
}
