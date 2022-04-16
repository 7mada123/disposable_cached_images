import 'dart:typed_data';

import '../../disposable_cached_images.dart';

mixin NetworkImageProviderPlatformMixin on BaseImageProvider {
  Future<Uint8List> getImageByetsFromUrl() async {
    throw UnsupportedError('unsupported platform');
  }
}
