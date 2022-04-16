import 'dart:typed_data';

import '../../disposable_cached_images.dart';
import '../../images_isolate.dart';

mixin NetworkImageProviderPlatformMixin on BaseImageProvider {
  @override
  void dispose() {
    ImagesIsolate.cancleDownload(providerArguments.image);
    super.dispose();
  }

  Future<Uint8List> getImageByetsFromUrl() async {
    return ImagesIsolate.getImageFromUrl(
      providerArguments.image,
      providerArguments.headers,
    );
  }
}
