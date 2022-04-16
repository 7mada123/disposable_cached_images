import 'dart:typed_data';
import 'dart:ui' as ui;

/// class to handle the necessary image data
class ImageInfoData {
  final Uint8List? imageBytes;
  final int? width, height;
  final String key;
  final ui.ImageDescriptor? imageDescriptor;

  const ImageInfoData({
    required final this.height,
    required final this.width,
    required final this.key,
    final this.imageBytes,
    final this.imageDescriptor,
  });

  ImageInfoData copyWith(
      {final Uint8List? imageBytes,
      final String? key,
      final int? height,
      final int? width,
      final ui.ImageDescriptor? imageDescriptor}) {
    return ImageInfoData(
      imageBytes: imageBytes ?? this.imageBytes,
      height: height ?? this.height,
      width: width ?? this.width,
      key: key ?? this.key,
      imageDescriptor: imageDescriptor ?? this.imageDescriptor,
    );
  }

  ImageInfoData withOutBytes() {
    return ImageInfoData(
      height: height,
      width: width,
      key: key,
      imageDescriptor: imageDescriptor,
    );
  }

  const ImageInfoData.init(final this.key)
      : imageBytes = null,
        height = null,
        imageDescriptor = null,
        width = null;

  Map<String, int> sizeToMap() {
    return {
      'height': height!,
      'width': width!,
    };
  }

  factory ImageInfoData.fromMap(
    final Map<String, dynamic> map,
    final String key,
  ) {
    return ImageInfoData(
      height: map['height'],
      width: map['width'],
      key: key,
    );
  }

  @override
  bool operator ==(final other) {
    if (identical(this, other)) return true;

    return other is ImageInfoData &&
        other.imageBytes == imageBytes &&
        other.height == height &&
        other.width == width &&
        other.key == key;
  }

  @override
  int get hashCode {
    return imageBytes.hashCode ^
        height.hashCode ^
        width.hashCode ^
        key.hashCode;
  }
}
