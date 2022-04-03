import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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

  void add(final ImageInfoData imageInfo);

  ImageInfoData? getImageInfo(final String key);

  Future<Uint8List?> getBytes(final String key);

  Future<Uint8List> getLocalBytes(final String imagePath);

  Future<dynamic> getImageFromUrl(
    final http.Client httpClient,
    final String url,
    final Map<String, String>? headers,
  );

  void cancleImageDownload(final String url);

  /// Clear [DisposableCachedImage] storage cache.
  Future<void> clearCache();
}
