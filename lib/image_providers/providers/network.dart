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
      final savedImageInfo = read(imageDataBaseProvider).getImageInfo(key);

      if (savedImageInfo == null) {
        state = state.copyWith(isLoading: true);
        imageInfo = ImageInfoData.init(key);

        await _handelNetworkImage();

        super.getImage();

        return;
      }

      state = state.copyWith(
        isLoading: true,
        height: savedImageInfo.height,
        width: savedImageInfo.width,
      );

      imageInfo = savedImageInfo;

      final bytes = await read(imageDataBaseProvider).getBytes(key);

      if (bytes != null) {
        httpClient.close();

        imageInfo = imageInfo.copyWith(imageBytes: bytes);

        await handelImageProvider();

        super.getImage();

        return;
      }

      await _handelNetworkImage();

      super.getImage();
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

    if (response.statusCode == 404) throw Exception('Image not found');

    // TODO
    /// resize image bytes
    imageInfo = imageInfo.copyWith(imageBytes: response.bodyBytes);

    return handelImageProvider(
      onImage: (final image) {
        imageInfo = imageInfo.copyWith(
          height: image.height.toDouble(),
          width: image.width.toDouble(),
        );

        read(imageDataBaseProvider).addNew(imageInfo);
      },
    );
  }
}
