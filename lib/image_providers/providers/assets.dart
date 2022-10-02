part of disposable_cached_images;

final _assetsImageProvider = StateNotifierProvider.autoDispose
    .family<BaseImageProvider, _ImageProviderState, _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  // if (providerArguments.keepAlive) ref.keepAlive();

  ref.maintainState = providerArguments.keepAlive;

  return _AssetsImageProvider(
    ref: ref,
    providerArguments: providerArguments,
  );
});

class _AssetsImageProvider extends BaseImageProvider {
  _AssetsImageProvider({
    required super.ref,
    required super.providerArguments,
  });

  @override
  Future<void> getImage() async {
    try {
      state = state.copyWith(isLoading: true);
      imageInfo = ImageInfoData.init(key);

      final bytes = await _imageStorage.getAssetBytes(
        providerArguments.image,
      );

      imageInfo = imageInfo.copyWith(imageBytes: bytes);

      await handelImageProvider(
        onImage: (final image) {
          imageInfo = imageInfo.copyWith(
            height: image.height,
            width: image.width,
            imageBytes: bytes,
          );
        },
      );

      ref.read(_usedImageProvider).add(imageInfo);
    } catch (e, s) {
      onImageError(e, s);
    }
  }
}
