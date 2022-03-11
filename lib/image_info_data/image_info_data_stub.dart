import 'dart:typed_data';

import './image_info_data.dart';

extension ImageSizeFunc on ImageInfoData {
  Future<ImageInfoData> resizeImage(
    final int? targetHeight,
    final int? targetWidth,
    final Uint8List bytes,
  ) {
    throw UnsupportedError('unsupported platform');
  }

  Future<ImageInfoData> setImageActualSize(final Uint8List bytes) {
    throw UnsupportedError('unsupported platform');
  }
}
