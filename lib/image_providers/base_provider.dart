part of disposable_cached_images;

abstract class _BaseImageProvider extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final _ImageProviderArguments providerArguments;
  final String key;

  late ImageInfoData imageInfo;

  @override
  void dispose() {
    state.uiImage?.dispose();
    super.dispose();
  }

  _BaseImageProvider({
    required final this.read,
    required final this.providerArguments,
  })  : key = providerArguments.image.key,
        super(const _ImageProviderState.init()) {
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

  Future<void> getImage();

  void onImageError(final Object e) {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: false,
      error: e,
      stackTrace: StackTrace.current,
    );
  }

  Future<void> _handelAnimatedImage(
    final ui.Codec codec, {
    required final ui.Image image,
  }) async {
    state.uiImage?.dispose();

    state = state.copyWith(isLoading: false, uiImage: image);

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

  Future<ui.ImageDescriptor> getDescriptor(final Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    buffer.dispose();

    return descriptor;
  }

  Future<void> handelImageProvider({
    final void Function(ui.Image)? onImage,
  }) async {
    final descriptor = await getDescriptor(imageInfo.imageBytes!);

    final codec = await descriptor.instantiateCodec();

    final frameInfo = await codec.getNextFrame();

    descriptor.dispose();

    if (onImage != null) onImage(frameInfo.image);

    if (!mounted) {
      codec.dispose();
      frameInfo.image.dispose();
      return;
    }

    // don't resize animated images
    if (codec.frameCount > 1) {
      return _handelAnimatedImage(codec, image: frameInfo.image);
    }

    codec.dispose();

    state = state.copyWith(
      isLoading: false,
      uiImage: frameInfo.image,
      height: frameInfo.image.height,
      width: frameInfo.image.width,
    );
  }
}

typedef DisposableImageProvider
    = AutoDisposeStateNotifierProvider<_BaseImageProvider, _ImageProviderState>;

extension on String {
  /// remove illegal file name characters when saving file
  static final illegalFilenameCharacters = RegExp(r'[/#<>$+%!`&*|{}?"=\\ @:]');

  String get key {
    return substring(0, length > 255 ? 255 : length)
        .replaceAll(illegalFilenameCharacters, '');
  }
}
