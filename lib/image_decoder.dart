part of disposable_cached_images;

class _ImageDecoder {
  static const _maxDuration = Duration(milliseconds: 500);

  static late final int maximumDownload;

  static int currentCount = 0;

  static final _queue = Queue<Future<void> Function()>();

  static Future<void> _runImagesDecoder() async {
    while (_queue.isNotEmpty && currentCount < maximumDownload) {
      currentCount++;
      _queue
          .removeFirst()()
          .timeout(_maxDuration, onTimeout: () {})
          .then((value) {
        currentCount--;

        _runImagesDecoder();
      });
    }
  }

  static void schedule({
    required final Uint8List bytes,
    final int? height,
    final int? width,
    required final Completer<_ImageResolverResult?> completer,
  }) async {
    _queue.add(() => _getImage(bytes, height, width, completer));

    _runImagesDecoder();
  }

  static void scheduleWithResizedBytes({
    required final Uint8List bytes,
    final int? height,
    final int? width,
    required final Completer<_ImageResolverResult?> completer,
  }) async {
    _queue.add(() => _getResizedBytesImage(bytes, height, width, completer));

    _runImagesDecoder();
  }

  static Future<void> _getImage(
    final Uint8List bytes,
    final int? height,
    final int? width,
    final Completer<_ImageResolverResult?> completer,
  ) async {
    if (completer.isCompleted) return;

    try {
      final descriptor = await _getDescriptor(bytes);

      if (completer.isCompleted) {
        descriptor.dispose();
        return;
      }

      final codec = await descriptor.instantiateCodec(
        targetHeight: height,
        targetWidth: width,
      );

      if (completer.isCompleted) {
        descriptor.dispose();
        codec.dispose();
        return;
      }

      final frameInfo = await codec.getNextFrame();

      if (completer.isCompleted) {
        frameInfo.image.dispose();
        descriptor.dispose();
        codec.dispose();
        return;
      }

      descriptor.dispose();

      if (codec.frameCount > 1) {
        completer.complete(_ImageResolverResult(
          image: frameInfo.image,
          codec: codec,
          isAnimated: true,
        ));

        return;
      }

      codec.dispose();

      completer.complete(_ImageResolverResult(image: frameInfo.image));
    } catch (e) {
      completer.completeError(e);
    }
  }

  static Future<void> _getResizedBytesImage(
    final Uint8List bytes,
    final int? height,
    final int? width,
    final Completer<_ImageResolverResult?> completer,
  ) async {
    try {
      final descriptor = await _getDescriptor(bytes);

      final codec = await descriptor.instantiateCodec();

      final frameInfo = await codec.getNextFrame();

      if (codec.frameCount > 1) {
        descriptor.dispose();

        completer.complete(_ImageResolverResult(
          image: frameInfo.image,
          codec: codec,
          isAnimated: true,
          resizedBytes: bytes,
        ));
        return;
      }

      final targetHeight = getTargetSize(
        height,
        frameInfo.image.height,
      );

      final targetWidth = getTargetSize(
        width,
        frameInfo.image.width,
      );

      codec.dispose();

      if (targetHeight == null && targetWidth == null) {
        descriptor.dispose();

        completer.complete(_ImageResolverResult(
          image: frameInfo.image,
          resizedBytes: bytes,
        ));
        return;
      }

      frameInfo.image.dispose();

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

      completer.complete(
        _ImageResolverResult(
          image: resizedFrameInfo.image,
          resizedBytes: resizedBytes,
        ),
      );

      descriptor.dispose();
      resizedCodec.dispose();
    } catch (e) {
      completer.completeError(e);
    }
  }

  static Future<ui.ImageDescriptor> _getDescriptor(
    final Uint8List bytes,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);

    final descriptor = await ui.ImageDescriptor.encoded(buffer);

    buffer.dispose();

    return descriptor;
  }
}

class _ImageResolverResult {
  final ui.Image image;
  final ui.Codec? codec;
  final bool isAnimated;
  final Uint8List? resizedBytes;

  const _ImageResolverResult({
    required this.image,
    this.codec,
    this.resizedBytes,
    this.isAnimated = false,
  });
}
