import 'dart:typed_data';

import '../image_info_data.dart';
import 'image_storage_stub.dart'
    if (dart.library.io) './cache.dart'
    if (dart.library.html) './web_cache.dart';

/// The image cache interface
abstract class ImageStorageManger {
  static ImageStorageManger getPlatformInstance() {
    return getInstance();
  }

  const ImageStorageManger();

  Future<void> init(final bool enableWebCache);

  void add(final ImageInfoData imageInfo);

  ImageInfoData? getImageInfo(final String key);

  Future<Uint8List?> getBytes(final String key);

  Future<Uint8List> getLocalBytes(final String imagePath);

  Future<Uint8List> getAssetBytes(final String imagePath);

  /// Clear [DisposableCachedImage] storage cache.
  Future<void> clearCache();
}
