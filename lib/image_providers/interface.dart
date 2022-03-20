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
    if (!mounted) return;

    state = state.copyWith(
      isLoading: false,
      error: e,
      stackTrace: StackTrace.current,
    );
  }

  Future<void> handelImageProvider() async {
    read(_usedImageProvider).add(imageInfo);

    try {
      onMemoryImage(imageInfo.memoryImage!);

      if (!mounted) return;

      await preCache(imageInfo);

      if (!mounted) {
        imageInfo.memoryImage!.evict();
        return;
      }

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

  static Future<void> preCache(final ImageInfoData imageInfo) async {
    final completer = Completer<void>();

    final stream = imageInfo.memoryImage!.resolve(ImageConfiguration.empty);

    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (final image, final synchronousCall) {
        if (!completer.isCompleted) completer.complete();

        stream.removeListener(listener);
      },
      onError: (final exception, final stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(
            exception,
            stackTrace,
          );
        }

        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);

    return completer.future;
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
