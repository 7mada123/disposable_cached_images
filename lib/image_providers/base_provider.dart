part of disposable_cached_images;

abstract class BaseImageProvider extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final _ImageProviderArguments providerArguments;
  final String key;

  late final bool isAnimatedImage;

  ImageInfoData imageInfo = const ImageInfoData.init('');

  ui.ImageDescriptor? descriptor;

  @override
  void dispose() {
    for (final image in state.uiImages.values) {
      image.dispose();
    }

    super.dispose();
  }

  BaseImageProvider({
    required final this.read,
    required final this.providerArguments,
  })  : key = providerArguments.image.key,
        super(_ImageProviderState.init()) {
    final usedImageInfo = read(_usedImageProvider).getImageInfo(key);

    if (usedImageInfo != null) {
      imageInfo = usedImageInfo;

      descriptor = usedImageInfo.imageDescriptor;

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

  void onImageError(final Object e, final StackTrace stackTrace) {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: false,
      error: e,
      stackTrace: stackTrace,
    );
  }

  Future<void> _handelAnimatedImage(
    final ui.Codec codec, {
    required final ui.Image image,
  }) async {
    state.uiImages.update(
      '',
      (final oldImage) {
        oldImage.dispose();
        return image;
      },
      ifAbsent: () => image,
    );

    state = state.copyWith(isLoading: false);

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

  Future<void> setDescriptor(final Uint8List bytes) async {
    if (descriptor != null) return;

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

    descriptor = await ui.ImageDescriptor.encoded(buffer);

    buffer.dispose();

    imageInfo = imageInfo.copyWith(imageDescriptor: descriptor);

    read(_usedImageProvider).add(imageInfo);
  }

  Future<void> handelImageProvider({
    final void Function(ui.Image)? onImage,
  }) async {
    await setDescriptor(imageInfo.imageBytes!);

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
      isAnimatedImage = true;
      return _handelAnimatedImage(codec, image: frameInfo.image);
    }

    isAnimatedImage = false;

    state.uiImages.putIfAbsent('', () => frameInfo.image);

    codec.dispose();

    if (providerArguments.resizeImage) {
      return addResizedImage(
        uiImageSizekey(
          providerArguments.widgetWidth,
          providerArguments.widgetHeight,
        ),
        providerArguments.widgetWidth,
        providerArguments.widgetHeight,
      );
    }

    state = state.copyWith(
      isLoading: false,
      height: frameInfo.image.height,
      width: frameInfo.image.width,
    );
  }

  Future<void> addResizedImage(
    final String key,
    final int? width,
    final int? height,
  ) async {
    if (state.uiImages.isEmpty ||
        isAnimatedImage ||
        state.uiImages.containsKey(key)) return;

    final tWidth = getTargetSize(width, imageInfo.width!);
    final tHeight = getTargetSize(height, imageInfo.height!);

    await setDescriptor(imageInfo.imageBytes!);

    final codec = await descriptor!.instantiateCodec(
      targetHeight: tHeight,
      targetWidth: tWidth,
    );

    final frameInfo = await codec.getNextFrame();

    if (mounted) {
      state.uiImages.putIfAbsent(key, () => frameInfo.image);
      state = state.copyWith(isLoading: false);
    } else {
      frameInfo.image.dispose();
    }

    codec.dispose();
  }

  Future<void> updateResizedImage(
    final String key,
    final int? width,
    final int? height,
  ) async {
    if (state.uiImages.isEmpty ||
        isAnimatedImage ||
        !state.uiImages.keys.contains(key)) return;

    final tWidth = getTargetSize(width, imageInfo.width!);
    final tHeight = getTargetSize(height, imageInfo.height!);

    if (tHeight == null && tWidth == null) {
      WidgetsBinding.instance!.addPostFrameCallback((final _) {
        state.uiImages.update(key, (final oldImage) {
          oldImage.dispose();

          return state.uiImages['']!.clone();
        });

        state = state.copyWith(isLoading: false);
      });

      return;
    }

    await setDescriptor(imageInfo.imageBytes!);

    final codec = await descriptor!.instantiateCodec(
      targetHeight: tHeight,
      targetWidth: tWidth,
    );

    final frameInfo = await codec.getNextFrame();

    if (mounted) {
      state.uiImages.update(key, (final oldImage) {
        oldImage.dispose();

        return frameInfo.image;
      });

      state = state.copyWith(isLoading: false);
    } else {
      frameInfo.image.dispose();
    }

    codec.dispose();
  }
}

typedef DisposableImageProvider
    = AutoDisposeStateNotifierProvider<BaseImageProvider, _ImageProviderState>;

extension on String {
  /// remove illegal file name characters when saving file
  static final illegalFilenameCharacters = RegExp(r'[/#<>$+%!`&*|{}?"=\\ @:]');

  String get key {
    return substring(0, length > 255 ? 255 : length)
        .replaceAll(illegalFilenameCharacters, '');
  }
}

int? getTargetSize(final int? target, final int origanl) {
  if (target != null && target > 0 && target < origanl) {
    return target;
  } else {
    return null;
  }
}

String uiImageSizekey(final int? width, final int? height) {
  return '${height}x$width';
}
