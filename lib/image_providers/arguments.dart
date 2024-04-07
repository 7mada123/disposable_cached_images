part of disposable_cached_images_io;

class _ImageProviderArguments {
  final int? maxCacheWidth, maxCacheHeight;
  final int? widgetWidth, widgetHeight;
  final Map<String, String>? headers;
  final bool keepAlive, resizeImage, keepBytesInMemory;
  final String image;
  final Uint8List? bytes;

  const _ImageProviderArguments({
    required this.resizeImage,
    required this.image,
    this.maxCacheWidth,
    this.keepBytesInMemory = true,
    this.maxCacheHeight,
    this.widgetHeight,
    this.widgetWidth,
    this.bytes,
    this.headers,
    this.keepAlive = false,
  });

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is _ImageProviderArguments &&
        other.hashCode == hashCode &&
        listEquals(other.bytes, bytes);
  }

  @override
  int get hashCode => image.hashCode ^ bytes.hashCode;
}
