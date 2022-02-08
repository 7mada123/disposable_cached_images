part of disposable_cached_images;

final _usedImageProvider = Provider<_UsedImageProviders>((ref) {
  return const _UsedImageProviders();
});

class _UsedImageProviders {
  const _UsedImageProviders();

  static final Map<String, MemoryImage> usedImageProvidersList = {};

  MemoryImage? getImageProvider(final String key) {
    return usedImageProvidersList[key];
  }

  void add(final String key, final MemoryImage memoryImage) {
    usedImageProvidersList.putIfAbsent(key, () => memoryImage);
  }
}
