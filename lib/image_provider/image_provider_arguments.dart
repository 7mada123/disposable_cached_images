part of disposable_cached_images;

class ImageProviderArguments {
  final String image;
  final ImageType imageType;
  final int? targetWidth, targetHeight;

  const ImageProviderArguments({
    required final this.image,
    final this.targetWidth,
    final this.targetHeight,
    final this.imageType = ImageType.network,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageProviderArguments &&
        other.image == image &&
        other.targetWidth == targetWidth &&
        other.targetHeight == targetHeight;
  }

  @override
  int get hashCode =>
      image.hashCode ^ targetWidth.hashCode ^ targetHeight.hashCode;
}
