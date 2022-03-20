part of disposable_cached_images;

typedef OnError = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  VoidCallback? reDownload,
);

typedef OnImage = Widget Function(
  BuildContext context,
  MemoryImage memoryImage,
);

double? _getDynamicHeight({
  required final double targetWidth,
  required final double? width,
  required final double? height,
}) {
  if (width == null || height == null) return null;

  return height * (targetWidth / width);
}

class _LoadingWidget extends StatelessWidget {
  final DisposableCachedImage widget;

  const _LoadingWidget(
    this.widget, {
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return widget.onLoading != null
        ? widget.onLoading!(context)
        : const SizedBox();
  }
}

class _ErrorWidget extends StatelessWidget {
  final DisposableCachedImage widget;
  final Object error;
  final StackTrace stackTrace;
  final VoidCallback refreshProvider;

  const _ErrorWidget(
    this.widget, {
    final Key? key,
    required this.error,
    required this.stackTrace,
    required this.refreshProvider,
  }) : super(key: key);

  @override
  Widget build(final context) {
    return widget.onError != null
        ? widget.onError!(
            context,
            error,
            stackTrace,
            refreshProvider,
          )
        : const SizedBox();
  }
}

class _DynamicHeightImageWidge extends StatelessWidget {
  const _DynamicHeightImageWidge(
    this.widget, {
    final Key? key,
    required this.imageProvider,
    required this.height,
  }) : super(key: key);

  final DisposableCachedImage widget;
  final MemoryImage imageProvider;
  final double? height;

  @override
  Widget build(final context) {
    return widget.onImage != null
        ? widget.onImage!(context, imageProvider)
        : Container(
            height: height,
            width: widget.imageWidth!,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.fitWidth,
                filterQuality: widget.filterQuality,
              ),
            ),
          );
  }
}

class _ImageWidge extends StatelessWidget {
  const _ImageWidge(
    this.widget, {
    final Key? key,
    required this.imageProvider,
  }) : super(key: key);

  final DisposableCachedImage widget;
  final MemoryImage imageProvider;

  @override
  Widget build(final context) {
    return widget.onImage != null
        ? widget.onImage!(context, imageProvider)
        : Image.memory(
            imageProvider.bytes,
            fit: widget.fit,
            height: widget.height,
            width: widget.width,
            filterQuality: widget.filterQuality,
          );
  }
}
