part of disposable_cached_images;

abstract class _ImageCacheProviderInterface
    extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final _ImageProviderArguments providerArguments;
  final String key;

  _ImageCacheProviderInterface({
    required final this.read,
    required final this.providerArguments,
  })  : key = providerArguments.image.key,
        super(const _ImageProviderState()) {
    final usedImageInfo = read(_usedImageProvider).getImageInfo(key);

    if (usedImageInfo != null) {
      imageInfo = usedImageInfo;

      state = state.copyWith(
        isLoading: true,
        height: usedImageInfo.height,
        width: usedImageInfo.width,
      );

      handelImageProvider();
    } else {
      final savedImageInfo = read(imageDataBaseProvider).getImageInfo(key);

      if (savedImageInfo == null) {
        state = state.copyWith(isLoading: true);
        imageInfo = ImageInfoData.init(key);
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

  Future<void> handelImageProvider({
    final int? targetWidth,
    final int? targetHeight,
    final OnSizeFunc? onSizeFunc,
  }) async {
    read(_usedImageProvider).add(imageInfo);

    try {
      final descriptor = await _getImageDescriptor(imageInfo.imageBytes!);

      final codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );

      if (codec.frameCount > 1) {
        descriptor.dispose();
        return _handelAnimatedImage(codec, onSizeFunc: onSizeFunc);
      }

      final frameInfo = await codec.getNextFrame();

      descriptor.dispose();
      codec.dispose();

      if (onSizeFunc != null) {
        onSizeFunc(
          frameInfo.image.height.toDouble(),
          frameInfo.image.width.toDouble(),
        );
      }

      if (!mounted) {
        frameInfo.image.dispose();
        return;
      }

      state = state.copyWith(
        isLoading: false,
        uiImage: frameInfo.image,
        height: imageInfo.height,
        width: imageInfo.width,
      );
    } catch (e) {
      onImageError(e);
    }
  }

  Future<void> addImageToCache() {
    return read(imageDataBaseProvider).addNew(imageInfo);
  }

  @override
  void dispose() {
    state.uiImage?.dispose();
    super.dispose();
  }

  Future<void> _handelAnimatedImage(
    final ui.Codec codec, {
    final OnSizeFunc? onSizeFunc,
  }) async {
    final delayed = Stopwatch()..start();

    final newFrame = await codec.getNextFrame();

    if (onSizeFunc != null) {
      onSizeFunc(
        newFrame.image.height.toDouble(),
        newFrame.image.width.toDouble(),
      );
    }

    if (!mounted) {
      newFrame.image.dispose();
      codec.dispose();
      delayed.stop();
      return;
    }

    state = state.copyWith(uiImage: newFrame.image, isLoading: false);

    await Future.delayed(newFrame.duration - delayed.elapsed);

    return _handelAnimatedImage(codec);
  }

  static Future<ui.ImageDescriptor> _getImageDescriptor(
    final Uint8List bytes,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    buffer.dispose();

    return descriptor;
  }
}

typedef DisposableImageProvider = AutoDisposeStateNotifierProvider<
    _ImageCacheProviderInterface, _ImageProviderState>;

typedef OnSizeFunc = void Function(double height, double width);

extension on String {
  /// remove illegal file name characters when saving file
  static final illegalFilenameCharacters = RegExp(r'[/#<>$+%!`&*|{}?"=\\ @:]');

  String get key {
    return substring(0, length > 255 ? 255 : length)
        .replaceAll(illegalFilenameCharacters, '');
  }
}
