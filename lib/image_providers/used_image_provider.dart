part of disposable_cached_images;

final _usedImageProvider = Provider<_UsedImageProviders>((final ref) {
  return const _UsedImageProviders();
});

class _UsedImageProviders {
  const _UsedImageProviders();

  static final Map<String, ImageInfoData> usedImageProvidersList = {};

  ImageInfoData? getImageInfo(final String key) {
    return usedImageProvidersList[key];
  }

  void add(final ImageInfoData imageInfo) {
    usedImageProvidersList.putIfAbsent(imageInfo.key, () => imageInfo);
  }
}
