part of disposable_cached_images;

abstract class _BaseImageProvider extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final _ImageProviderArguments providerArguments;
  final String key;

  late ImageInfoData imageInfo;

  ui.ImageDescriptor? descriptor;

  final List<int> constraintsList = [];

  @override
  void dispose() {
    state.uiImage?.dispose();
    descriptor?.dispose();
    super.dispose();
  }

  _BaseImageProvider({
    required final this.read,
    required final this.providerArguments,
  })  : key = providerArguments.image.key,
        super(const _ImageProviderState.init()) {
    constraintsList.add(providerArguments.widgetWidth);

    final usedImageInfo = read(_usedImageProvider).getImageInfo(key);

    if (usedImageInfo != null) {
      imageInfo = usedImageInfo;

      state = state.copyWith(
        isLoading: true,
        height: usedImageInfo.height,
        width: usedImageInfo.width,
      );

      initDescriptor(imageInfo.imageBytes!).then(
        (value) => handelImageProvider(),
      );

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

  Future<void> initDescriptor(final Uint8List bytes) async {
    if (descriptor != null) return;

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

    descriptor = await ui.ImageDescriptor.encoded(buffer);

    buffer.dispose();

    if (!mounted) descriptor!.dispose();
  }

  Future<void> handelImageProvider({
    final void Function(ui.Image)? onImage,
  }) async {
    final codec = await descriptor!.instantiateCodec();

    final frameInfo = await codec.getNextFrame();

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

    if (!providerArguments.autoResize) {
      state = state.copyWith(
        isLoading: false,
        uiImage: frameInfo.image,
        height: frameInfo.image.height,
        width: frameInfo.image.width,
      );
    } else {
      handelNewImageSize(constraintsList.last);
    }
  }

  Future<void> handelNewImageSize(final int widgetWidth) async {
    final targetWidth = getTargetSize(
      widgetWidth,
      imageInfo.width!,
    );

    if (!mounted) return;

    final codec = await descriptor!.instantiateCodec(
      targetWidth: targetWidth,
    );

    final frameInfo = await codec.getNextFrame();

    codec.dispose();

    if (mounted) {
      state.uiImage?.dispose();

      state = state.copyWith(
        isLoading: false,
        height: imageInfo.height,
        width: imageInfo.width,
        uiImage: frameInfo.image,
      );
    } else {
      frameInfo.image.dispose();
    }
  }

  void addWidgetConstrain(final int widgetWidth, final bool autoResize) {
    if (!autoResize && state.uiImage?.width != imageInfo.width) {
      if (constraintsList.contains(imageInfo.width)) return;

      constraintsList.add(imageInfo.width!);

      handelNewImageSize(imageInfo.width!);

      return;
    }

    if (constraintsList.contains(widgetWidth)) return;

    constraintsList.add(widgetWidth);

    handelNewImageSize(widgetWidth);
  }

  void removeWidgetConstrain(final int boxConstraints) {
    if (constraintsList.length <= 1) return;

    constraintsList.removeLast();

    handelNewImageSize(constraintsList.last);
  }

  void updateWidgetConstrain(final int widgetWidth) {
    if (widgetWidth == constraintsList.last) return;

    handelNewImageSize(widgetWidth);
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

int? getTargetSize(final int? target, int origanl) {
  if (target != null && target > 0 && target < origanl) {
    return target;
  } else {
    return null;
  }
}
