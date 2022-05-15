// ignore_for_file: library_private_types_in_public_api

part of disposable_cached_images;

abstract class BaseImageProvider extends StateNotifier<_ImageProviderState> {
  final Reader read;
  final _ImageProviderArguments providerArguments;
  final String key;

  bool isAnimatedImage = false;

  ImageInfoData imageInfo = const ImageInfoData.init('');

  final completer = Completer<_ImageResolverResult?>();

  @override
  void dispose() {
    for (final image in state.uiImages.values) {
      image.dispose();
    }

    if (!completer.isCompleted) completer.complete();

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

  Future<void> handelImageProvider({
    final void Function(ui.Image)? onImage,
  }) async {
    _ImageDecoder.schedule(
      bytes: imageInfo.imageBytes!,
      completer: completer,
    );

    final result = await completer.future;

    if (result == null) {
      return;
    }

    if (onImage != null) onImage(result.image);

    // don't resize animated images
    if (result.isAnimated) {
      isAnimatedImage = true;
      return _handelAnimatedImage(result.codec!, image: result.image);
    }

    state.uiImages.putIfAbsent('', () => result.image);

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
      height: result.image.height,
      width: result.image.width,
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

    final completer = Completer<_ImageResolverResult>();

    _ImageDecoder.schedule(
      bytes: imageInfo.imageBytes!,
      completer: completer,
      height: tHeight,
      width: tWidth,
    );

    final result = await completer.future;

    if (mounted) {
      state.uiImages.putIfAbsent(key, () => result.image);
      state = state.copyWith(isLoading: false);
    } else {
      result.image.dispose();
    }
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
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        state.uiImages.update(key, (final oldImage) {
          oldImage.dispose();

          return state.uiImages['']!.clone();
        });

        state = state.copyWith(isLoading: false);
      });

      return;
    }

    final completer = Completer<_ImageResolverResult>();

    _ImageDecoder.schedule(
      bytes: imageInfo.imageBytes!,
      completer: completer,
      height: tHeight,
      width: tWidth,
    );

    final result = await completer.future;

    if (mounted) {
      state.uiImages.update(key, (final oldImage) {
        oldImage.dispose();

        return result.image;
      });

      state = state.copyWith(isLoading: false);
    } else {
      result.image.dispose();
    }
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
