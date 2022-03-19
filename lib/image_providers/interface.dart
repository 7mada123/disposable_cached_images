part of disposable_cached_images;

abstract class ImageCacheProviderInterface
    extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final String image;
  final void Function(MemoryImage? memoryImage) onMemoryImage;

  ImageCacheProviderInterface({
    required final this.read,
    required final this.image,
    required final this.onMemoryImage,
  }) : super(const _ImageProviderState()) {
    final usedImageInfo = read(_usedImageProvider).getImageInfo(image.key);

    if (usedImageInfo != null) {
      imageInfo = usedImageInfo;

      state = state.copyWith(
        isLoading: true,
        height: usedImageInfo.height,
        width: usedImageInfo.width,
      );

      handelImageProvider();
    } else {
      final savedImageInfo = read(imageDataBaseProvider).getImageInfo(
        image.key,
      );

      if (savedImageInfo == null) {
        state = state.copyWith(isLoading: true);
        imageInfo = ImageInfoData.init(image.key);
      } else {
        state = state.copyWith(
          isLoading: true,
          height: savedImageInfo.height,
          width: savedImageInfo.width,
        );

        imageInfo = savedImageInfo;
      }

      getImage();
    }
  }

  late ImageInfoData imageInfo;

  Future<void> getImage();

  void onImageError(final Object e) {
    if (mounted) state = state.copyWith(isLoading: false, error: e);
  }

  Future<void> handelImageProvider() async {
    read(_usedImageProvider).add(imageInfo);

    try {
      onMemoryImage(imageInfo.memoryImage!);

      if (!mounted) return;

      final error = await preCache(imageInfo);

      if (!mounted) {
        imageInfo.memoryImage!.evict();
        return;
      }

      if (error != null) throw error;

      state = state.copyWith(
        isLoading: false,
        imageProvider: imageInfo.memoryImage,
        height: imageInfo.height,
        width: imageInfo.width,
      );
    } catch (e) {
      onImageError(e);

      imageInfo.memoryImage!.evict();
    }
  }

  Future<void> addImageToCache() {
    return read(imageDataBaseProvider).addNew(imageInfo);
  }

  static Future<Object?> preCache(final ImageInfoData imageInfo) async {
    final completer = Completer<void>();

    final stream = imageInfo.memoryImage!.resolve(ImageConfiguration.empty);

    late final ImageStreamListener listener;

    late final Object? error;

    listener = ImageStreamListener(
      (final image, final synchronousCall) {
        if (!completer.isCompleted) completer.complete();

        stream.removeListener(listener);

        error = null;
      },
      onError: (final exception, final stackTrace) {
        if (!completer.isCompleted) completer.complete();

        stream.removeListener(listener);

        error = exception;
      },
    );

    stream.addListener(listener);

    await completer.future;

    return error;
  }
}

extension on String {
  static final illegalFilenameCharacters = RegExp(r'[/#<>$+%!`&*|{}?"=\\ @:]');

  String get key {
    return substring(
      0,
      length > 255 ? 255 : length,
    ).replaceAll(illegalFilenameCharacters, '');
  }
}

typedef DisposableImageProvider = AutoDisposeStateNotifierProvider<
    ImageCacheProviderInterface, _ImageProviderState>;
