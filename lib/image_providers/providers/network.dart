part of disposable_cached_images;

final _networkImageProvider = StateNotifierProvider.autoDispose.family<
    _ImageCacheProviderInterface,
    _ImageProviderState,
    _ImageProviderArguments>((
  final ref,
  final providerArguments,
) {
  ref.maintainState = providerArguments.keepAlive;

  return _NetworkImageProvider(
    ref.read,
    providerArguments,
  );
});

class _NetworkImageProvider extends _ImageCacheProviderInterface {
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

        super.getImage();

        return;
      }

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

        super.getImage();

        return;
      }

      await handelNetworkImage();

      super.getImage();
    } catch (e) {
      httpClient.close();
      onImageError(e);
    }
  }

  Future<void> handelNetworkImage() async {
    // TODO save in isloate
    final response = await read(imageDataBaseProvider).getImageFromUrl(
      httpClient,
      providerArguments.image,
      providerArguments.headers,
    );

    if (response is! Uint8List) throw Exception(response);

    httpClient.close();

    // if (response.statusCode == 404) throw Exception('Image not found');

    if (providerArguments.maxCacheHeight != null ||
        providerArguments.maxCacheWidth != null) {
      return handelDownloadedImageSize(response);
    }

    imageInfo = imageInfo.copyWith(imageBytes: response);

    return handelImageProvider(
      onImage: (final image) {
        imageInfo = imageInfo.copyWith(
          height: image.height.toDouble(),
          width: image.width.toDouble(),
        );

        read(imageDataBaseProvider).addNew(imageInfo);
      },
    );
  }

  Future<void> handelDownloadedImageSize(final Uint8List bytes) async {
    final descriptor = await getImageDescriptor(bytes);

    final originalCodec = await descriptor.instantiateCodec();

    final originalFrameInfo = await originalCodec.getNextFrame();

    // don't resize animated images
    if (originalCodec.frameCount > 1) {
      descriptor.dispose();

      imageInfo = imageInfo.copyWith(
        height: originalFrameInfo.image.height.toDouble(),
        width: originalFrameInfo.image.width.toDouble(),
        imageBytes: bytes,
      );

      read(_usedImageProvider).add(imageInfo);
      read(imageDataBaseProvider).addNew(imageInfo);

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
      height: resizedFrameInfo.image.height.toDouble(),
      width: resizedFrameInfo.image.width.toDouble(),
      imageBytes: resizedBytes,
    );

    descriptor.dispose();
    resizedCodec.dispose();

    if (mounted) {
      state = state.copyWith(
        uiImage: resizedFrameInfo.image,
        isLoading: false,
        height: imageInfo.height,
        width: imageInfo.width,
      );
    } else {
      resizedFrameInfo.image.dispose();
    }

    read(imageDataBaseProvider).addNew(imageInfo);
  }

  static int? getTargetSize(final int? target, int origanl) {
    if (target != null && target < origanl) {
      return target;
    } else {
      return null;
    }
  }
}
