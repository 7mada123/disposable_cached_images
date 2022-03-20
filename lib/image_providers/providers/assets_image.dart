part of disposable_cached_images;

final _assetsImageProvider = StateNotifierProvider.autoDispose.family<
    ImageCacheProviderInterface, _ImageProviderState, ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  MemoryImage? imageProvider;
  bool mounted = true;

  ref.onDispose(() {
    mounted = false;
    imageProvider?.evict();
  });

  return _AssetsImageProvider(
    ref.read,
    providerArguments,
    (final newValue) {
      imageProvider = newValue;
      if (!mounted) imageProvider?.evict();
    },
  );
});

class _AssetsImageProvider extends ImageCacheProviderInterface {
  final ImageProviderArguments providerArguments;

  _AssetsImageProvider(
    final Reader read,
    final this.providerArguments,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  ) : super(
          read: read,
          image: providerArguments.image,
          onMemoryImage: onMemoryImage,
        );

  @override
  Future<void> getImage() async {
    try {
      final bytes = await read(imageDataBaseProvider).getBytesFormAssets(
        image,
      );

      imageInfo = imageInfo.copyWith(memoryImage: MemoryImage(bytes));
      await handelImageProvider();
    } catch (e) {
      onImageError(e);
    }
  }
}
