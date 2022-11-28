import 'dart:typed_data';

import 'package:disposable_cached_images/images_isolate.dart';

Future<Uint8List> getImageBytesFromUrl(String url,
    {Map<String, String>? headers}) {
  return ImagesIsolate.getNetworkBytes(url, headers);
}
