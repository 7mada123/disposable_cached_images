part of disposable_cached_images;

final _imageProvider = StateNotifierProvider.autoDispose.family<
    DisposableCachedImageProviderAbstract,
    _ImageProviderState,
    ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  final httpClient = http.Client();
  MemoryImage? imageProvider;
  bool mounted = true;

  ref.onDispose(() {
    mounted = false;
    imageProvider?.evict();
    httpClient.close();
  });

  return _CachedImageClass(
    ref.read,
    providerArguments,
    httpClient,
    (final newValue) {
      imageProvider = newValue;
      if (!mounted) imageProvider?.evict();
    },
  );
});

class _CachedImageClass extends DisposableCachedImageProviderAbstract {
  final ImageProviderArguments providerArguments;

  _CachedImageClass(
    final Reader read,
    final this.providerArguments,
    final http.Client httpClient,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  )   : assert(
          !kIsWeb ||
              (kIsWeb && providerArguments.imageType != ImageType.assets),
          "asste image not suported on web",
        ),
        super(
          read: read,
          image: providerArguments.image,
          onMemoryImage: onMemoryImage,
          httpClient: httpClient,
        );

  @override
  Future<void> getImage() async {
    try {
      if (kIsWeb) {
        await handelNetworkImage();
        return;
      }

      if (providerArguments.imageType == ImageType.assets) {
        final bytes = await read(_imageDataBaseProvider).getBytesFormAssets(
          image,
        );

        imageProvider = MemoryImage(bytes);
        handelImageProvider();

        return;
      }

      final bytes = await read(_imageDataBaseProvider).getBytes(image.key);

      if (bytes != null) {
        imageProvider = MemoryImage(bytes);

        handelImageProvider();

        return;
      }

      handelNetworkImage();
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }

  Future<void> handelNetworkImage() async {
    try {
      final response = await httpClient.get(Uri.parse(image));

      if (providerArguments.targetHeight != null ||
          providerArguments.targetWidth != null) {
        final resizedBytes = await resizeBytes(
          response.bodyBytes,
          targetHeight: providerArguments.targetHeight,
          targetWidth: providerArguments.targetWidth,
        );

        imageProvider = MemoryImage(resizedBytes);

        if (!kIsWeb) {
          read(_imageDataBaseProvider).addNew(
            key: image.key,
            bytes: resizedBytes,
          );
        }

        await handelImageProvider();

        return;
      }

      imageProvider = MemoryImage(response.bodyBytes);

      if (!kIsWeb) {
        read(_imageDataBaseProvider).addNew(
          key: image.key,
          bytes: response.bodyBytes,
        );
      }

      await handelImageProvider();
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }
}

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
