part of disposable_cached_images;

final _networkImageProvider = StateNotifierProvider.autoDispose
    .family<BaseImageProvider, _ImageProviderState, _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _NetworkImageProvider(
    read: ref.read,
    providerArguments: providerArguments,
  );
});

class _NetworkImageProvider extends BaseImageProvider
    with NetworkImageProviderPlatformMixin {
  _NetworkImageProvider({
    required super.read,
    required super.providerArguments,
  });

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
    final completer = Completer<_ImageResolverResult>();

    _ImageDecoder.scheduleWithResizedBytes(
      bytes: bytes,
      completer: completer,
      height: providerArguments.maxCacheHeight,
      width: providerArguments.maxCacheWidth,
    );

    final result = await completer.future;

    imageInfo = imageInfo.copyWith(
      height: result.image.height,
      width: result.image.width,
      imageBytes: result.resizedBytes,
    );

    read(imageDataBaseProvider).add(imageInfo);

    if (mounted) {
      if (result.isAnimated) {
        return _handelAnimatedImage(result.codec!, image: result.image);
      } else {
        _onDownloadedImage(result.image);
      }
    } else {
      result.image.dispose();
      result.codec?.dispose();
    }
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
