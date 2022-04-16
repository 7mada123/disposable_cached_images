part of disposable_cached_images;

final _networkImageProvider = StateNotifierProvider.autoDispose
    .family<BaseImageProvider, _ImageProviderState, _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _NetworkImageProvider(
    ref.read,
    providerArguments,
  );
});

class _NetworkImageProvider extends BaseImageProvider
    with NetworkImageProviderPlatformMixin {
  _NetworkImageProvider(
    final Reader read,
    final _ImageProviderArguments providerArguments,
  ) : super(
          read: read,
          providerArguments: providerArguments,
        );

  @override
  Future<void> getImage() async {
    try {
      final savedImageInfo = read(imageDataBaseProvider).getImageInfo(key);

      if (savedImageInfo == null) {
        state = state.copyWith(isLoading: true);
        imageInfo = ImageInfoData.init(key);

        await handelNetworkImage();
      } else {
        state = state.copyWith(
          isLoading: true,
          height: savedImageInfo.height,
          width: savedImageInfo.width,
        );

        imageInfo = savedImageInfo;

        final bytes = await read(imageDataBaseProvider).getBytes(key);

        if (bytes != null) {
          imageInfo = imageInfo.copyWith(imageBytes: bytes);

          await handelImageProvider();
        } else {
          await handelNetworkImage();
        }
      }

      read(_usedImageProvider).add(imageInfo);
    } catch (e, s) {
      onImageError(e, s);
    }
  }

  Future<void> handelNetworkImage() async {
    final response = await getImageByetsFromUrl();

    imageInfo = imageInfo.copyWith(imageBytes: response);

    if (providerArguments.maxCacheHeight != null ||
        providerArguments.maxCacheWidth != null) {
      return handelDownloadedImageSize(response);
    }

    return handelImageProvider(
      onImage: (final image) {
        imageInfo = imageInfo.copyWith(
          height: image.height,
          width: image.width,
        );

        read(imageDataBaseProvider).add(imageInfo);
      },
    );
  }

  Future<void> handelDownloadedImageSize(final Uint8List bytes) async {
    await setDescriptor(bytes);

    final originalCodec = await descriptor!.instantiateCodec();

    final originalFrameInfo = await originalCodec.getNextFrame();

    imageInfo = imageInfo.copyWith(
      height: originalFrameInfo.image.height,
      width: originalFrameInfo.image.width,
      imageBytes: bytes,
    );

    // don't resize animated images
    if (originalCodec.frameCount > 1) {
      read(_usedImageProvider).add(imageInfo);
      read(imageDataBaseProvider).add(imageInfo);

      isAnimatedImage = true;

      return _handelAnimatedImage(
        originalCodec,
        image: originalFrameInfo.image,
      );
    }

    isAnimatedImage = false;

    final targetHeight = getTargetSize(
      providerArguments.maxCacheHeight,
      originalFrameInfo.image.height,
    );

    final targetWidth = getTargetSize(
      providerArguments.maxCacheWidth,
      originalFrameInfo.image.width,
    );

    originalCodec.dispose();

    if (targetWidth == null && targetHeight == null) {
      read(imageDataBaseProvider).add(imageInfo);

      if (mounted) _onDownloadedImage(originalFrameInfo.image);

      return;
    }

    originalFrameInfo.image.dispose();

    final resizedCodec = await descriptor!.instantiateCodec(
      targetHeight: targetHeight,
      targetWidth: targetWidth,
    );

    final resizedFrameInfo = await resizedCodec.getNextFrame();

    final resizedBytes = (await resizedFrameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!
        .buffer
        .asUint8List();

    descriptor!.dispose();
    descriptor = null;
    await setDescriptor(resizedBytes);

    imageInfo = imageInfo.copyWith(
      height: resizedFrameInfo.image.height,
      width: resizedFrameInfo.image.width,
      imageBytes: resizedBytes,
    );

    resizedCodec.dispose();

    if (mounted) {
      _onDownloadedImage(resizedFrameInfo.image);
    } else {
      resizedFrameInfo.image.dispose();
    }

    read(imageDataBaseProvider).add(imageInfo);
  }

  void _onDownloadedImage(final ui.Image image) {
    state.uiImages.putIfAbsent('', () => image);

    if (providerArguments.resizeImage) {
      addResizedImage(
        uiImageSizekey(
          providerArguments.widgetWidth,
          providerArguments.widgetHeight,
        ),
        providerArguments.widgetWidth,
        providerArguments.widgetHeight,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        height: imageInfo.height,
        width: imageInfo.width,
      );
    }
  }
}
