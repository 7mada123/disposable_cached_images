import 'dart:typed_data';

/// A class to handle the necessary image data
class ImageInfoData {
  final double? width;
  final double? height;
  final String key;
  final Uint8List? imageBytes;

  const ImageInfoData({
    required final this.width,
    required final this.height,
    required final this.key,
    final this.imageBytes,
  });

  ImageInfoData copyWith({
    final double? width,
    final double? height,
    final String? key,
    final Uint8List? imageBytes,
  }) {
    return ImageInfoData(
      width: width ?? this.width,
      height: height ?? this.height,
      key: key ?? this.key,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  ImageInfoData.init(final this.key)
      : height = null,
        width = null,
        imageBytes = null;

  Map<String, double> sizeToMap() {
    return {
      'width': width!,
      'height': height!,
    };
  }

  factory ImageInfoData.fromMap(
    final Map<String, dynamic> map,
    final String key,
  ) {
    return ImageInfoData(
      width: map['width'],
      height: map['height'],
      key: key,
    );
  }

  @override
  bool operator ==(final other) {
    if (identical(this, other)) return true;

    return other is ImageInfoData &&
        other.width == width &&
        other.height == height &&
        other.key == key &&
        other.imageBytes == imageBytes;
  }

  @override
  int get hashCode {
    return width.hashCode ^
        height.hashCode ^
        key.hashCode ^
        imageBytes.hashCode;
  }
}
