// ignore_for_file: curly_braces_in_flow_control_structures

part of disposable_cached_images;

final _networkImageProvider = StateNotifierProvider.autoDispose
    .family<BaseImageProvider, _ImageProviderState, _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  if (providerArguments.keepAlive) ref.keepAlive();

  return _NetworkImageProvider(
    ref: ref,
    providerArguments: providerArguments,
  );
});

class _NetworkImageProvider extends BaseImageProvider {
  _NetworkImageProvider({
    required super.ref,
    required super.providerArguments,
  });

  @override
  Future<void> getImage() async {
    try {
      final savedImageInfo = _imagesHelper.getImageInfo(key);

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

        final bytes = await _imagesHelper.getBytes(key);

        if (bytes != null) {
          imageInfo = imageInfo.copyWith(imageBytes: bytes);

          await handelImageProvider();
        } else {
          await handelNetworkImage();
        }
      }

      if (providerArguments.keepBytesInMemory)
        ref.read(_usedImageProvider).add(imageInfo);
    } catch (e, s) {
      onImageError(e, s);
    }
  }

  Future<void> handelNetworkImage() async {
    state = state.copyWith(isDownloading: true);

    final Completer<Uint8List> responseCompleter = Completer();

    _imagesHelper.threadOperation
        .getNetworkBytes(
      providerArguments.image,
      providerArguments.headers,
    )
        .listen(
      (event) {
        if (event is Uint8List) {
          responseCompleter.complete(event);
        } else {
          ref
              .read(_downloadProgressProvider(providerArguments.image).notifier)
              .state = event;
        }
      },
      onError: (e, s) {
        responseCompleter.completeError(e, s);
      },
    );

    final response = await responseCompleter.future;

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

        _imagesHelper.add(imageInfo);
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

    _imagesHelper.add(imageInfo);

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
        uiImageSizeKey(
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
