part of disposable_cached_images;

abstract class DisposableCachedImageProviderAbstract
    extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final String image;
  final void Function(MemoryImage? memoryImage) onMemoryImage;

  DisposableCachedImageProviderAbstract({
    required final this.read,
    required final this.image,
    required final this.onMemoryImage,
  })  : assert(
          _scaffoldMessengerKey.currentWidget != null,
          "scaffoldMessengerKey isn't attached to the MaterialApp",
        ),
        super(_ImageProviderState.init()) {
    getImage();
  }

  Future<void> getImage();

  void onImageError(final Object e) {
    if (mounted) state = state.notLoading(null, error: e);
  }

  Future<void> handelImageBytes(
    final MemoryImage memoryImage, {
    final Uint8List? saveBytes,
  }) async {
    try {
      onMemoryImage(memoryImage);

      if (!mounted) return;

      await preCache(memoryImage);

      if (saveBytes != null) {
        read(_imageDataBaseProvider).addNew(key: image.key, bytes: saveBytes);
      }

      if (mounted) {
        state = state.notLoading(
          memoryImage,
        );
      } else {
        memoryImage.evict();
      }
    } catch (e) {
      onImageError(e);

      memoryImage.evict();
    }
  }

  Future<Uint8List> resizeBytes(
    Uint8List bytes, {
    final int? targetHeight,
    final int? targetWidth,
  }) async {
    final image = await decodeImageFromList(bytes);

    final codec = await instantiateImageCodec(
      bytes,
      targetHeight: _getTargetSize(image.height, targetHeight),
      targetWidth: _getTargetSize(image.width, targetWidth),
    );

    image.dispose();

    final frameInfo = await codec.getNextFrame();

    codec.dispose();

    final targetUiImage = frameInfo.image;

    final rezizedByteData = await targetUiImage.toByteData(
      format: ImageByteFormat.png,
    );

    targetUiImage.dispose();

    return rezizedByteData!.buffer.asUint8List();
  }

  int? _getTargetSize(final int imageSize, final int? targetSize) {
    if (targetSize != null && imageSize > targetSize) {
      return targetSize;
    } else {
      return null;
    }
  }

  static Future<void> preCache(final MemoryImage imageProvider) async {
    Object? error;

    await precacheImage(
      imageProvider,
      _scaffoldMessengerKey.currentContext!,
      onError: (final exception, final stackTrace) {
        imageProvider.evict();
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
