part of disposable_cached_images;

final _dynamicSizemageProvider = StateNotifierProvider.autoDispose.family<
    ImageCacheProviderInterface, _ImageProviderState, ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  final httpClient = http.Client();
  MemoryImage? imageProvider;
  bool mounted = true;

  ref.onDispose(() {
    mounted = false;
    imageProvider?.evict();
    httpClient.close();
  });

  return _DynamicSizemageProvider(
    ref.read,
    providerArguments,
    httpClient,
    (final newValue) {
      imageProvider = newValue;
      if (!mounted) imageProvider?.evict();
    },
  );
});

class _DynamicSizemageProvider extends ImageCacheProviderInterface {
  final ImageProviderArguments providerArguments;
  final http.Client httpClient;

  _DynamicSizemageProvider(
    final Reader read,
    final this.providerArguments,
    final this.httpClient,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  ) : super(
          read: read,
          image: providerArguments.image,
          onMemoryImage: onMemoryImage,
        );

  @override
  Future<void> getImage() async {
    try {
      final bytes = await read(imageDataBaseProvider).getBytes(image.key);

      if (bytes != null) {
        imageInfo = imageInfo.copyWith(memoryImage: MemoryImage(bytes));

        return handelImageProvider();
      }

      await handelNetworkImage();
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }

  Future<void> handelNetworkImage() async {
    final response = await httpClient.get(Uri.parse(image));

    imageInfo = imageInfo.copyWith(
      memoryImage: MemoryImage(response.bodyBytes),
    );

    httpClient.close();

    if (providerArguments.targetWidth != null) {
      imageInfo = await imageInfo.resizeImage(providerArguments.targetWidth!);

      await handelImageProvider();

      addImageToCache();

      return;
    }

    imageInfo = await imageInfo.setImageSize();

    await handelImageProvider();

    addImageToCache();
  }
}
