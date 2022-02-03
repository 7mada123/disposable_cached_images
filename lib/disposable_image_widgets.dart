part of disposable_cached_images;

class DisposableNetworkImage extends StatelessWidget {
  final double? width, height;
  final BoxFit? fit;
  final Duration fadeDuration;
  final String imageUrl;
  final WidgetBuilder? onLoading;
  final OnError? onError;
  final OnImage? onImage;

  const DisposableNetworkImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.onImage,
    this.onLoading,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 500),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _DisposableCachedImageWidget(
      imageProvider: _networkImageProvider(imageUrl),
      fadeDuration: fadeDuration,
      fit: fit,
      height: height,
      key: key,
      onError: onError,
      onImage: onImage,
      onLoading: onLoading,
      width: width,
    );
  }
}

class DisposableAssetsImage extends StatelessWidget {
  final double? width, height;
  final BoxFit? fit;
  final Duration fadeDuration;
  final String imagePath;
  final WidgetBuilder? onLoading;
  final OnError? onError;
  final OnImage? onImage;

  const DisposableAssetsImage({
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.onImage,
    this.onLoading,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 500),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _DisposableCachedImageWidget(
      imageProvider: _assetsImageProvider(imagePath),
      fadeDuration: fadeDuration,
      fit: fit,
      height: height,
      key: key,
      onError: onError,
      onImage: onImage,
      onLoading: onLoading,
      width: width,
    );
  }
}

class _DisposableCachedImageWidget extends ConsumerWidget {
  final double? width, height;
  final BoxFit? fit;
  final Duration fadeDuration;
  final WidgetBuilder? onLoading;
  final OnError? onError;
  final OnImage? onImage;
  final ImageProvider imageProvider;

  const _DisposableCachedImageWidget({
    required this.imageProvider,
    this.width,
    this.height,
    this.fit,
    this.onImage,
    this.onLoading,
    this.onError,
    this.fadeDuration = const Duration(milliseconds: 500),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(final context, final ref) {
    final providerState = ref.watch(imageProvider);

    return AnimatedSwitcher(
      duration: fadeDuration,
      key: key,
      child: providerState.isLoading
          ? onLoading != null
              ? onLoading!(context)
              : const SizedBox()
          : providerState.hasError
              ? onError != null
                  ? onError!(
                      context,
                      () => ref.refresh(imageProvider.notifier),
                    )
                  : const SizedBox()
              : onImage != null
                  ? onImage!(context, providerState.imageProvider!)
                  : Image.memory(
                      providerState.imageProvider!.bytes,
                      width: width,
                      height: height,
                      fit: fit,
                    ),
    );
  }
}

typedef OnError = Widget Function(
  BuildContext context,
  VoidCallback? reDownload,
);

typedef OnImage = Widget Function(
  BuildContext context,
  MemoryImage memoryImage,
);
