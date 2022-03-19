import '../image_info_data.dart';

extension ImageSizeFunc on ImageInfoData {
  Future<ImageInfoData> resizeImage(final int targetWidth) {
    throw UnsupportedError('unsupported platform');
  }

  Future<ImageInfoData> setImageSize() {
    throw UnsupportedError('unsupported platform');
  }
}
