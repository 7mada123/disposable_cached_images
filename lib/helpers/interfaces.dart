part of disposable_cached_images_io;

/// The image cache interface
abstract class HelperBase {
  static HelperBase getPlatformInstance() => getInstance();

  ThreadOperationBase get threadOperation;

  const HelperBase();

  Future<void> init(int maximumDownload);

  void add(final ImageInfoData imageInfo);

  ImageInfoData? getImageInfo(final String key);

  Future<Uint8List?> getBytes(final String key);

  Future<Uint8List> getLocalBytes(final String imagePath);

  Future<Uint8List> getAssetBytes(final String imagePath);

  /// Clear [DisposableCachedImage] storage cache.
  Future<void> clearCache();
}

// this class is for operations that could run in isolate and Web Workers
abstract class ThreadOperationBase {
  Future<void> addToCache({
    required String key,
    required int width,
    required int height,
    required Uint8List bytes,
  });

  Future<Uint8List?> getBytes(final String key);

  Future<void> clearData();

  Stream<dynamic> getNetworkBytes(
    final String url,
    final Map<String, String>? headers,
  );

  void cancelDownload(final String url);
}
