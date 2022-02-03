part of disposable_cached_images;

abstract class DisposableCachedImageProviderAbstract
    extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final String image;
  final void Function(MemoryImage? memoryImage) onMemoryImage;
  bool hasError = false;

  DisposableCachedImageProviderAbstract({
    required final this.read,
    required final this.image,
    required final this.onMemoryImage,
  })  : assert(
          _scaffoldMessengerKey.currentWidget != null,
          "scaffoldMessengerKey isn't attached to the MaterialApp",
        ),
        super(_ImageProviderState.init()) {
    getImage();
  }

  Future<void> getImage();

  void onImageError(final MemoryImage? imageProvider) {
    hasError = true;
    onMemoryImage(imageProvider);

    if (mounted) state = state.notLoading(hasError, null);

    imageProvider?.evict();
  }

  Future<void> handelImageBytes(
    final MemoryImage memoryImage, {
    final Uint8List? saveBytes,
  }) async {
    onMemoryImage(memoryImage);

    if (!mounted) return;

    hasError = await preCache(memoryImage);

    if (hasError) {
      memoryImage.evict();
    } else if (saveBytes != null) {
      read(_imageDataBaseProvider).addNew(key: image.key, bytes: saveBytes);
    }

    if (mounted) {
      state = state.notLoading(hasError, memoryImage);
    } else {
      memoryImage.evict();
    }
  }

  static Future<bool> preCache(final MemoryImage imageProvider) async {
    bool hasError = false;

    await precacheImage(
      imageProvider,
      _scaffoldMessengerKey.currentContext!,
      onError: (final exception, final stackTrace) {
        hasError = true;
        imageProvider.evict();
      },
    );

    return hasError;
  }
}

extension on String {
  String get key {
    return substring(
      0,
      length > 200 ? 200 : length,
    ).replaceAll('/', '');
  }
}
