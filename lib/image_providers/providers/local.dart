part of disposable_cached_images;

final _localImageProvider = StateNotifierProvider.autoDispose.family<
    ImageCacheProviderInterface, _ImageProviderState, ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _LocalImageProvider(
    ref.read,
    providerArguments,
  );
});

class _LocalImageProvider extends ImageCacheProviderInterface {
  _LocalImageProvider(
    final Reader read,
    final ImageProviderArguments providerArguments,
  ) : super(
          read: read,
          providerArguments: providerArguments,
        );

  @override
  Future<void> getImage() async {
    try {
      final bytes = await read(imageDataBaseProvider).getBytesFormAssets(
        providerArguments.image,
      );

      imageInfo = imageInfo.copyWith(imageBytes: bytes);

      await handelImageProvider(
        onSizeFunc: (final descriptor) => imageInfo = imageInfo.copyWith(
          height: descriptor.height.toDouble(),
          width: descriptor.width.toDouble(),
        ),
      );
    } catch (e) {
      onImageError(e);
    }
  }
}
