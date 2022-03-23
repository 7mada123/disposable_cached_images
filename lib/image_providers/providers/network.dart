part of disposable_cached_images;

final _networkImageProvider = StateNotifierProvider.autoDispose.family<
    _ImageCacheProviderInterface,
    _ImageProviderState,
    _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _NetworkImageProvider(
    ref.read,
    providerArguments,
  );
});

class _NetworkImageProvider extends _ImageCacheProviderInterface {
  final httpClient = http.Client();

  _NetworkImageProvider(
    final Reader read,
    final _ImageProviderArguments providerArguments,
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
        httpClient.close();

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
    final response = await httpClient.get(
      Uri.parse(providerArguments.image),
      headers: providerArguments.headers,
    );

    httpClient.close();

    if (response.statusCode == 404) throw response.body;

    imageInfo = imageInfo.copyWith(imageBytes: response.bodyBytes);

    await handelImageProvider(
      targetWidth: providerArguments.targetWidth,
      targetHeight: providerArguments.targetHeight,
      onSizeFunc: (final height, final width) {
        imageInfo = imageInfo.copyWith(height: height, width: width);
        addImageToCache();
      },
    );
  }
}
