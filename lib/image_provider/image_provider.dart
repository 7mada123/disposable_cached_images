part of disposable_cached_images;

final _imageProvider = StateNotifierProvider.autoDispose.family<
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

  return _CachedImageClass(
    ref.read,
    providerArguments,
    httpClient,
    (final newValue) {
      imageProvider = newValue;
      if (!mounted) imageProvider?.evict();
    },
  );
});

class _CachedImageClass extends ImageCacheProviderInterface {
  final ImageProviderArguments providerArguments;

  _CachedImageClass(
    final Reader read,
    final this.providerArguments,
    final http.Client httpClient,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  ) : super(
          read: read,
          image: providerArguments.image,
          onMemoryImage: onMemoryImage,
          httpClient: httpClient,
        );

  @override
  Future<void> getImage() async {
    try {
      if (providerArguments.imageType == ImageType.assets) {
        final bytes = await read(imageDataBaseProvider).getBytesFormAssets(
          image,
        );

        imageProvider = MemoryImage(bytes);
        handelImageProvider();

        return;
      }

      final bytes = await read(imageDataBaseProvider).getBytes(image.key);

      if (bytes != null) {
        imageProvider = MemoryImage(bytes);

        handelImageProvider();

        return;
      }

      handelNetworkImage();
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }

  Future<void> handelNetworkImage() async {
    try {
      final response = await httpClient.get(Uri.parse(image));

      if (providerArguments.targetHeight != null ||
          providerArguments.targetWidth != null) {
        final resizedBytes = await resizeBytes(
          response.bodyBytes,
          targetHeight: providerArguments.targetHeight,
          targetWidth: providerArguments.targetWidth,
        );

        imageProvider = MemoryImage(resizedBytes);

        read(imageDataBaseProvider).addNew(
          key: image.key,
          bytes: resizedBytes,
        );

        await handelImageProvider();

        return;
      }

      imageProvider = MemoryImage(response.bodyBytes);

      read(imageDataBaseProvider).addNew(
        key: image.key,
        bytes: response.bodyBytes,
      );

      await handelImageProvider();
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }
}
