part of disposable_cached_images;

class DisposableCachedImageWidget extends ConsumerWidget {
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Duration fadeDuration;
  final String imageUrl;

  final WidgetBuilder? onLoading;

  final Widget Function(
    BuildContext context,
    VoidCallback? reDownload,
  )? onError;

  final Widget Function(
    BuildContext context,
    MemoryImage memoryImage,
  )? onImage;

  const DisposableCachedImageWidget({
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
  Widget build(final context, final ref) {
    final providerState = ref.watch(_imageProvider(imageUrl));

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
                      () => ref.refresh(_imageProvider(imageUrl).notifier),
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
