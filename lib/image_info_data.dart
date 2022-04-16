import 'dart:typed_data';

/// class to handle the necessary image data
class ImageInfoData {
  final Uint8List? imageBytes;
  final int? width, height;
  final String key;

  const ImageInfoData({
    required final this.height,
    required final this.width,
    required final this.key,
    final this.imageBytes,
  });

  ImageInfoData copyWith({
    final Uint8List? imageBytes,
    final String? key,
    final int? height,
    final int? width,
  }) {
    return ImageInfoData(
      imageBytes: imageBytes ?? this.imageBytes,
      height: height ?? this.height,
      width: width ?? this.width,
      key: key ?? this.key,
    );
  }

  const ImageInfoData.init(final this.key)
      : imageBytes = null,
        height = null,
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
