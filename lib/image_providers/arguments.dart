part of disposable_cached_images;

class _ImageProviderArguments {
  final int? maxCacheWidth, maxCacheHeight;
  final Map<String, String>? headers;
  final bool keepAlive;
  final String image;

  const _ImageProviderArguments({
    required final this.image,
    final this.maxCacheWidth,
    final this.maxCacheHeight,
    final this.headers,
    final this.keepAlive = false,
  });

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is _ImageProviderArguments &&
        other.image == image &&
        other.keepAlive == keepAlive &&
        other.headers == headers;
  }

  @override
  int get hashCode => image.hashCode ^ keepAlive.hashCode ^ headers.hashCode;
}
