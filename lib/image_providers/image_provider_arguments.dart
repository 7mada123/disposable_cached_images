part of disposable_cached_images;

class ImageProviderArguments {
  final String image;
  final int? targetWidth;
  final bool keepAlive;

  const ImageProviderArguments({
    required final this.image,
    final this.targetWidth,
    final this.keepAlive = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageProviderArguments &&
        other.image == image &&
        other.keepAlive == keepAlive;
  }

  @override
  int get hashCode => image.hashCode ^ keepAlive.hashCode;
}
