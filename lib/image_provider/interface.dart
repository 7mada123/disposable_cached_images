part of disposable_cached_images;

abstract class ImageCacheProviderInterface
    extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final String image;
  final http.Client httpClient;
  final void Function(MemoryImage? memoryImage) onMemoryImage;

  ImageCacheProviderInterface({
    required final this.read,
    required final this.image,
    required final this.httpClient,
    required final this.onMemoryImage,
  })  : assert(
          _scaffoldMessengerKey.currentWidget != null,
          "scaffoldMessengerKey isn't attached to the MaterialApp",
        ),
        super(const _ImageProviderState.init()) {
    final usedImageInfo = read(_usedImageProvider).getImageInfo(image.key);

    if (usedImageInfo != null) {
      imageInfo = usedImageInfo;

      state = state.loading(usedImageInfo.height, usedImageInfo.width);

      handelImageProvider();
    } else {
      final savedImageInfo = read(imageDataBaseProvider).getImageInfo(
        image.key,
      );

      if (savedImageInfo == null) {
        state = state.loading(null, null);
        imageInfo = ImageInfoData.init(image.key);
      } else {
        state = state.loading(savedImageInfo.height, savedImageInfo.width);
        imageInfo = savedImageInfo;
      }

      getImage();
    }
  }

  late ImageInfoData imageInfo;

  Future<void> getImage();

  void onImageError(final Object e) {
    if (mounted) state = state.notLoading(error: e);
  }

  Future<void> handelImageProvider() async {
    httpClient.close();

    read(_usedImageProvider).add(imageInfo);

    try {
      onMemoryImage(imageInfo.memoryImage!);

      if (!mounted) return;

      await preCache(imageInfo);

      if (mounted) {
        state = state.notLoading(imageProvider: imageInfo.memoryImage);
      } else {
        imageInfo.memoryImage!.evict();
      }
    } catch (e) {
      onImageError(e);

      imageInfo.memoryImage!.evict();
    }
  }

  Future<void> addImageToCache() {
    return read(imageDataBaseProvider).addNew(imageInfo);
  }

  static Future<void> preCache(final ImageInfoData imageInfo) async {
    Object? error;

    await precacheImage(
      imageInfo.memoryImage!,
      _scaffoldMessengerKey.currentContext!,
      size: imageInfo.getSize(),
      onError: (final exception, final stackTrace) {
        imageInfo.memoryImage!.evict();
        error = exception;
      },
    );

    if (error != null) throw error!;
  }
}

extension on String {
  String get key {
    return substring(
      0,
      length > 200 ? 200 : length,
    ).replaceAll('/', '');
  }
}
