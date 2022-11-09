part of disposable_cached_images;

final _localImageProvider = StateNotifierProvider.autoDispose
    .family<BaseImageProvider, _ImageProviderState, _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  if (providerArguments.keepAlive) ref.keepAlive();

  return _LocalImageProvider(
    ref: ref,
    providerArguments: providerArguments,
  );
});

class _LocalImageProvider extends BaseImageProvider {
  _LocalImageProvider({
    required super.ref,
    required super.providerArguments,
  });

  @override
  Future<void> getImage() async {
    try {
      state = state.copyWith(isLoading: true);
      imageInfo = ImageInfoData.init(key);

      final bytes = await _imageStorage.getLocalBytes(
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
