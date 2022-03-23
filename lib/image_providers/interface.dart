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

      return;
    }

    getImage();
  }

  late ImageInfoData imageInfo;

  @mustCallSuper
  Future<void> getImage() async {
    read(_usedImageProvider).add(imageInfo);
  }

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
    try {
      final descriptor = await _getImageDescriptor(imageInfo.imageBytes!);

      final codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );

      final frameInfo = await codec.getNextFrame();

      descriptor.dispose();

      if (onSizeFunc != null) {
        onSizeFunc(
          frameInfo.image.height.toDouble(),
          frameInfo.image.width.toDouble(),
        );
      }

      if (!mounted) {
        codec.dispose();
        frameInfo.image.dispose();
        return;
      }

      if (codec.frameCount > 1) {
        return _handelAnimatedImage(
          codec,
          image: frameInfo.image,
        );
      }

      codec.dispose();

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

  @override
  void dispose() {
    state.uiImage?.dispose();
    super.dispose();
  }

  Future<void> _handelAnimatedImage(
    final ui.Codec codec, {
    required final ui.Image image,
  }) async {
    state.uiImage?.dispose();

    state = state.copyWith(uiImage: image, isLoading: false);

    final delayed = Stopwatch()..start();

    final newFrame = await codec.getNextFrame();

    await Future.delayed(newFrame.duration - delayed.elapsed);

    if (!mounted) {
      newFrame.image.dispose();
      codec.dispose();
      return;
    }

    return _handelAnimatedImage(codec, image: newFrame.image);
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
