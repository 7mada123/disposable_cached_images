part of disposable_cached_images;

final _localImageProvider = StateNotifierProvider.autoDispose.family<
    _ImageCacheProviderInterface,
    _ImageProviderState,
    _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _LocalImageProvider(
    ref.read,
    providerArguments,
  );
});

class _LocalImageProvider extends _ImageCacheProviderInterface {
  _LocalImageProvider(
    final Reader read,
    final _ImageProviderArguments providerArguments,
  ) : super(
          read: read,
          providerArguments: providerArguments,
        );

  @override
  Future<void> getImage() async {
    try {
      state = state.copyWith(isLoading: true);
      imageInfo = ImageInfoData.init(key);

      final bytes = await read(imageDataBaseProvider).getLocalBytes(
        providerArguments.image,
      );

      imageInfo = imageInfo.copyWith(imageBytes: bytes);

      await handelImageProvider(
        onSizeFunc: (final height, final width) {
          imageInfo = imageInfo.copyWith(height: height, width: width);
        },
      );

      super.getImage();
    } catch (e) {
      onImageError(e);
    }
  }
}
