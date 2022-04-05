part of disposable_cached_images;

final _networkImageProvider = StateNotifierProvider.autoDispose
    .family<_BaseImageProvider, _ImageProviderState, _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _NetworkImageProvider(
    ref.read,
    providerArguments,
  );
});

class _NetworkImageProvider extends _BaseImageProvider {
  final httpClient = http.Client();

  _NetworkImageProvider(
    final Reader read,
    final _ImageProviderArguments providerArguments,
  ) : super(
          read: read,
          providerArguments: providerArguments,
        );

  @override
  void dispose() {
    httpClient.close();
    read(imageDataBaseProvider).cancleImageDownload(providerArguments.image);
    super.dispose();
  }

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
          httpClient.close();

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
    final response = await read(imageDataBaseProvider).getImageFromUrl(
      httpClient,
      providerArguments.image,
      providerArguments.headers,
    );

    httpClient.close();

    if (response is! Uint8List) throw response;

    if (providerArguments.maxCacheHeight != null ||
        providerArguments.maxCacheWidth != null) {
      return handelDownloadedImageSize(response);
    }

    imageInfo = imageInfo.copyWith(imageBytes: response);

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
    final descriptor = await getDescriptor(bytes);

    final originalCodec = await descriptor.instantiateCodec();

    final originalFrameInfo = await originalCodec.getNextFrame();

    descriptor.dispose();

    imageInfo = imageInfo.copyWith(
      height: originalFrameInfo.image.height,
      width: originalFrameInfo.image.width,
      imageBytes: bytes,
    );

    // don't resize animated images
    if (originalCodec.frameCount > 1) {
      read(_usedImageProvider).add(imageInfo);
      read(imageDataBaseProvider).add(imageInfo);

      return _handelAnimatedImage(
        originalCodec,
        image: originalFrameInfo.image,
      );
    }

    final targetHeight = getTargetSize(
      providerArguments.maxCacheHeight,
      originalFrameInfo.image.height,
    );

    final targetWidth = getTargetSize(
      providerArguments.maxCacheWidth,
      originalFrameInfo.image.width,
    );

    originalCodec.dispose();
    originalFrameInfo.image.dispose();

    final resizedCodec = await descriptor.instantiateCodec(
      targetHeight: targetHeight,
      targetWidth: targetWidth,
    );

    final resizedFrameInfo = await resizedCodec.getNextFrame();

    final resizedBytes = (await resizedFrameInfo.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!
        .buffer
        .asUint8List();

    imageInfo = imageInfo.copyWith(
      height: resizedFrameInfo.image.height,
      width: resizedFrameInfo.image.width,
      imageBytes: resizedBytes,
    );

    resizedCodec.dispose();

    if (mounted) {
      state = state.copyWith(
        isLoading: false,
        height: imageInfo.height,
        width: imageInfo.width,
        uiImage: resizedFrameInfo.image,
      );
    } else {
      resizedFrameInfo.image.dispose();
    }

    read(_usedImageProvider).add(imageInfo);
    read(imageDataBaseProvider).add(imageInfo);
  }
}

int? getTargetSize(final int? target, int origanl) {
  if (target != null && target > 0 && target < origanl) {
    return target;
  } else {
    return null;
  }
}
