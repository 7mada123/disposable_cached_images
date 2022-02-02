part of disposable_cached_images;

final _imageProvider = StateNotifierProvider.autoDispose
    .family<DisposableCachedImageProviderAbstract, _ImageProviderState, String>(
        (
  final ref,
  final imageUrl,
) {
  final cancelToken = CancelToken();
  MemoryImage? imageProvider;
  bool mounted = true;

  ref.onDispose(() {
    mounted = false;
    cancelToken.cancel();
    imageProvider?.evict();
  });

  return _CachedImageClass(
    ref.read,
    imageUrl,
    cancelToken,
    (final newValue) {
      imageProvider = newValue;
      if (!mounted) imageProvider?.evict();
    },
  );
});

class _CachedImageClass extends DisposableCachedImageProviderAbstract {
  _CachedImageClass(
    final Reader read,
    final String imageUrl,
    final CancelToken cancelToken,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  ) : super(
          read: read,
          cancelToken: cancelToken,
          imageUrl: imageUrl,
          onMemoryImage: onMemoryImage,
        );
}
