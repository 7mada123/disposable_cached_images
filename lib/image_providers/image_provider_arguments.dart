part of disposable_cached_images;

class ImageProviderArguments {
  final String image;
  final int? targetWidth;

  const ImageProviderArguments({
    required final this.image,
    final this.targetWidth,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImageProviderArguments && other.image == image;
  }

  @override
  int get hashCode => image.hashCode;
}
