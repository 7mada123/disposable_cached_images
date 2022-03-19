import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../image_info_data.dart';
import './image_cache_stub.dart'
    if (dart.library.io) './cache.dart'
    if (dart.library.html) './web_cache.dart';

/// Provider for handling image cache
final imageDataBaseProvider = Provider.autoDispose<ImageCacheManger>(
  (final ref) => throw UnimplementedError(),
);

/// The image cache interface
abstract class ImageCacheManger {
  static ImageCacheManger getPlatformInstance() {
    return getInstance();
  }

  const ImageCacheManger();

  Future<void> init(final bool enableWebCache);

  Future<void> addNew(final ImageInfoData imageInfo);

  ImageInfoData? getImageInfo(final String key);

  Future<Uint8List?> getBytes(final String key);

  Future<Uint8List> getBytesFormAssets(final String imagePath);

  /// Clear [DisposableCachedImage] storage cache.
  Future<void> clearCache();
}
