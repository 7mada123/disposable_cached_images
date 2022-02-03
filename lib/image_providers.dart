part of disposable_cached_images;

typedef ImageProvider = AutoDisposeStateNotifierProvider<
    DisposableCachedImageProviderAbstract, _ImageProviderState>;

final _networkImageProvider = StateNotifierProvider.autoDispose
    .family<DisposableCachedImageProviderAbstract, _ImageProviderState, String>(
        (
  final ref,
  final imageUrl,
) {
  final httpClient = http.Client();
  MemoryImage? imageProvider;
  bool mounted = true;

  ref.onDispose(() {
    mounted = false;
    imageProvider?.evict();
    httpClient.close();
  });

  return _CachedImageClass(
    ref.read,
    imageUrl,
    httpClient,
    (final newValue) {
      imageProvider = newValue;
      if (!mounted) imageProvider?.evict();
    },
  );
});

class _CachedImageClass extends DisposableCachedImageProviderAbstract {
  final http.Client httpClient;

  _CachedImageClass(
    final Reader read,
    final String imageUrl,
    final this.httpClient,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  ) : super(
          read: read,
          image: imageUrl,
          onMemoryImage: onMemoryImage,
        );

  @override
  Future<void> getImage() async {
    final key = image.key;

    MemoryImage? imageProvider;

    state = state.loading();

    final bytes = await read(_imageDataBaseProvider).getBytes(key);

    if (bytes != null) {
      imageProvider = MemoryImage(bytes);

      handelImageBytes(imageProvider);

      return;
    }

    try {
      final response = await httpClient.get(Uri.parse(image));

      httpClient.close();

      final bytes = response.bodyBytes;

      imageProvider = MemoryImage(bytes);

      await handelImageBytes(imageProvider, saveBytes: bytes);
    } catch (e) {
      onImageError(imageProvider);
    }
  }
}

final _assetsImageProvider = StateNotifierProvider.autoDispose
    .family<DisposableCachedImageProviderAbstract, _ImageProviderState, String>(
        (
  final ref,
  final imagePath,
) {
  MemoryImage? imageProvider;
  bool mounted = true;

  ref.onDispose(() {
    mounted = false;
    imageProvider?.evict();
  });

  return _AssetsImageClass(
    ref.read,
    imagePath,
    (final newValue) {
      imageProvider = newValue;
      if (!mounted) imageProvider?.evict();
    },
  );
});

class _AssetsImageClass extends DisposableCachedImageProviderAbstract {
  _AssetsImageClass(
    final Reader read,
    final String imagePath,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  ) : super(
          read: read,
          image: imagePath,
          onMemoryImage: onMemoryImage,
        );

  @override
  Future<void> getImage() async {
    MemoryImage? imageProvider;

    state = state.loading();

    try {
      final bytes = await read(_imageDataBaseProvider).getBytesFormAssets(
        image,
      );

      imageProvider = MemoryImage(bytes);

      handelImageBytes(imageProvider, saveBytes: bytes);
    } catch (e) {
      onImageError(imageProvider);
    }
  }
}
