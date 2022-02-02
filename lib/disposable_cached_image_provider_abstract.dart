part of disposable_cached_images;

abstract class DisposableCachedImageProviderAbstract
    extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final String imageUrl;
  final CancelToken cancelToken;
  final void Function(MemoryImage? memoryImage) onMemoryImage;
  bool hasError = false;

  static final dio = Dio();

  DisposableCachedImageProviderAbstract({
    required final this.read,
    required final this.imageUrl,
    required final this.cancelToken,
    required final this.onMemoryImage,
  })  : assert(
          _scaffoldMessengerKey.currentWidget != null,
          "scaffoldMessengerKey isn't attached to the MaterialApp",
        ),
        super(_ImageProviderState.init()) {
    getImage();
  }

  Future<void> getImage() async {
    final key = imageUrl.key;

    MemoryImage? imageProvider;

    hasError = false;
    state = state.loading();

    final bytes = await read(_imageDataBaseProvider).getBytes(key);

    if (bytes != null) {
      imageProvider = MemoryImage(bytes);

      if (!mounted) return;

      hasError = await _preCache(imageProvider);

      if (!hasError) imageProvider.evict();

      onMemoryImage(imageProvider);

      if (mounted) {
        state = state.notLoading(hasError, imageProvider);
      } else {
        imageProvider.evict();
      }

      return;
    }

    try {
      final response = await dio.get<Uint8List>(
        imageUrl,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.bytes),
      );

      final Uint8List bytes = response.data!;

      imageProvider = MemoryImage(bytes);

      if (!mounted) return;

      hasError = await _preCache(imageProvider);

      if (!hasError) {
        read(_imageDataBaseProvider).addNew(key: key, bytes: bytes);
      } else {
        imageProvider.evict();
      }

      onMemoryImage(imageProvider);
    } catch (e) {
      hasError = true;
      onMemoryImage(imageProvider);

      if (mounted) state = state.notLoading(hasError, null);

      imageProvider?.evict();

      return;
    }

    if (mounted) {
      state = state.notLoading(hasError, imageProvider);
    } else {
      imageProvider.evict();
    }

    onMemoryImage(imageProvider);
  }

  static Future<bool> _preCache(final MemoryImage imageProvider) async {
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
