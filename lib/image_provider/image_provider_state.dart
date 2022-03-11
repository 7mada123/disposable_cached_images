part of disposable_cached_images;

class _ImageProviderState {
  final bool isLoading;
  final Object? error;
  final MemoryImage? imageProvider;
  final double? height, width;

  const _ImageProviderState(
    final this.isLoading,
    final this.imageProvider,
    this.error,
    this.height,
    this.width,
  );

  const _ImageProviderState.init()
      : isLoading = false,
        error = null,
        imageProvider = null,
        height = null,
        width = null;

  _ImageProviderState loading(
    final double? height,
    final double? width,
  ) {
    return _ImageProviderState(
      true,
      null,
      null,
      height,
      width,
    );
  }

  _ImageProviderState notLoading({
    final MemoryImage? imageProvider,
    final Object? error,
  }) {
    return _ImageProviderState(
      false,
      imageProvider,
      error,
      height,
      width,
    );
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is _ImageProviderState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.imageProvider == imageProvider;
  }

  @override
  int get hashCode =>
      isLoading.hashCode ^ error.hashCode ^ imageProvider.hashCode;
}
