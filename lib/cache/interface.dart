import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import './image_cache_stub.dart'
    if (dart.library.io) './cache.dart'
    if (dart.library.html) './web_cache.dart';

/// Provider for handling image cache
final imageDataBaseProvider = Provider.autoDispose<ImageCacheManger>(
  (final ref) => throw UnimplementedError(),
);

/// The image cache interface
abstract class ImageCacheManger {
  static ImageCacheManger? _instance;

  static ImageCacheManger get instance {
    _instance ??= getInstance();
    return _instance!;
  }

  const ImageCacheManger();

  Future<void> init();

  Future<void> addNew({
    required final String key,
    required final Uint8List bytes,
  });

  Future<Uint8List?> getBytes(final String key);

  Future<Uint8List> getBytesFormAssets(final String imagePath);

  /// Clear [DisposableCachedImage] storage cache.
  Future<void> clearCache();
}
