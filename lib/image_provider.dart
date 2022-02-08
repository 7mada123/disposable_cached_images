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
  final http.Client httpClient;
  final ImageProviderArguments providerArguments;

  _CachedImageClass(
    final Reader read,
    final this.providerArguments,
    final this.httpClient,
    final void Function(MemoryImage? memoryImage) onMemoryImage,
  ) : super(
          read: read,
          image: providerArguments.image,
          onMemoryImage: onMemoryImage,
        );

  @override
  Future<void> getImage() async {
    try {
      final key = image.key;

      MemoryImage? imageProvider;

      state = state.loading();

      if (!image.startsWith('http')) {
        httpClient.close();

        final bytes = await read(_imageDataBaseProvider).getBytesFormAssets(
          image,
        );

        imageProvider = MemoryImage(bytes);
        handelImageBytes(imageProvider);
      }

      final bytes = await read(_imageDataBaseProvider).getBytes(key);

      if (bytes != null) {
        httpClient.close();

        imageProvider = MemoryImage(bytes);

        handelImageBytes(imageProvider, saveBytes: bytes);

        return;
      }

      final response = await httpClient.get(Uri.parse(image));

      httpClient.close();

      if (providerArguments.targetHeight != null ||
          providerArguments.targetWidth != null) {
        final resizedBytes = await resizeBytes(
          response.bodyBytes,
          targetHeight: providerArguments.targetHeight,
          targetWidth: providerArguments.targetWidth,
        );

        imageProvider = MemoryImage(resizedBytes);

        handelImageBytes(imageProvider, saveBytes: resizedBytes);

        return;
      }

      imageProvider = MemoryImage(response.bodyBytes);

      await handelImageBytes(imageProvider, saveBytes: response.bodyBytes);
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }
}

class ImageProviderArguments {
  final String image;
  final int? targetWidth, targetHeight;

  const ImageProviderArguments({
    required final this.image,
    final this.targetWidth,
    final this.targetHeight,
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
