part of disposable_cached_images;

final _networkImageProvider = StateNotifierProvider.autoDispose.family<
    ImageCacheProviderInterface, _ImageProviderState, ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _NetworkImageProvider(
    ref.read,
    providerArguments,
  );
});

class _NetworkImageProvider extends ImageCacheProviderInterface {
  final httpClient = http.Client();

  _NetworkImageProvider(
    final Reader read,
    final ImageProviderArguments providerArguments,
  ) : super(
          read: read,
          providerArguments: providerArguments,
        );

  @override
  void dispose() {
    httpClient.close();
    super.dispose();
  }

  @override
  Future<void> getImage() async {
    try {
      final bytes = await read(imageDataBaseProvider).getBytes(key);

      if (bytes != null) {
        imageInfo = imageInfo.copyWith(imageBytes: bytes);

        await handelImageProvider();

        return;
      }

      await _handelNetworkImage();
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }

  Future<void> _handelNetworkImage() async {
    final response = await httpClient.get(Uri.parse(providerArguments.image));

    imageInfo = imageInfo.copyWith(imageBytes: response.bodyBytes);

    httpClient.close();

    if (providerArguments.targetWidth != null) {
      await handelImageProvider(
        targetWidth: providerArguments.targetWidth!,
        onReSizeFunc: (final image) {
          imageInfo = imageInfo.copyWith(
            height: image.height.toDouble(),
            width: image.width.toDouble(),
          );
        },
      );
    } else {
      await handelImageProvider(
        onSizeFunc: (final imageDescriptor) {
          imageInfo = imageInfo.copyWith(
            height: imageDescriptor.height.toDouble(),
            width: imageDescriptor.width.toDouble(),
          );
        },
      );
    }

    if (imageInfo.width == null) return;

    addImageToCache();
  }
}
