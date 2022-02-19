part of disposable_cached_images;

class DisposableCachedImageWidget extends ConsumerStatefulWidget {
  /// Provide a maximum value for image height and width,
  ///  If the actual height or width of the image is less than the provided value, the provided value will be ignored.
  ///
  ///  The image will be resized before it is displayed in the UI and saved to the device storage
  final int? maxCacheWidth, maxCacheHeight;

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

  /// Image url or asset image path
  /// note : image url should start with http
  final String image;

  /// Determine the type of image, whether it is from the Internet or assets
  final ImageType imageType;

  const DisposableCachedImageWidget({
    required this.image,
    this.maxCacheWidth,
    this.maxCacheHeight,
    this.imageType = ImageType.network,
    this.fit,
    this.onImage,
    this.onLoading,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 500),
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DisposableCachedImageWidget> createState() =>
      _DisposableCachedImageWidgetState();
}

class _DisposableCachedImageWidgetState
    extends ConsumerState<DisposableCachedImageWidget> {
  late final DisposableImageProvider provider =
      _imageProvider(ImageProviderArguments(
    image: widget.image,
    targetHeight: widget.maxCacheHeight,
    targetWidth: widget.maxCacheWidth,
    imageType: widget.imageType,
  ));

  @override
  Widget build(final context) {
    final providerState = ref.watch(provider);

    return AnimatedSwitcher(
      duration: widget.fadeDuration,
      key: widget.key,
      child: providerState.isLoading
          ? widget.onLoading != null
              ? widget.onLoading!(context)
              : const SizedBox()
          : providerState.error != null
              ? widget.onError != null
                  ? widget.onError!(
                      context,
                      providerState.error!,
                      () => ref.refresh(provider.notifier),
                    )
                  : const SizedBox()
              : widget.onImage != null
                  ? widget.onImage!(context, providerState.imageProvider!)
                  : Image.memory(
                      providerState.imageProvider!.bytes,
                      fit: widget.fit,
                    ),
    );
  }
}

typedef OnError = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback? reDownload,
);

typedef OnImage = Widget Function(
  BuildContext context,
  MemoryImage memoryImage,
);

typedef DisposableImageProvider = AutoDisposeStateNotifierProvider<
    ImageCacheProviderInterface, _ImageProviderState>;
