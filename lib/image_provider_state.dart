part of disposable_cached_images;

class _ImageProviderState {
  final bool isLoading;
  final bool hasError;
  final MemoryImage? imageProvider;

  _ImageProviderState loading() {
    return const _ImageProviderState(
      true,
      false,
      null,
    );
  }

  _ImageProviderState notLoading(
    final bool hasError,
    final MemoryImage? imageProvider,
  ) {
    return _ImageProviderState(
      false,
      hasError,
      imageProvider,
    );
  }

  factory _ImageProviderState.init() {
    return const _ImageProviderState(false, false, null);
  }

  const _ImageProviderState(
    final this.isLoading,
    final this.hasError,
    final this.imageProvider,
  );

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is _ImageProviderState &&
        other.isLoading == isLoading &&
        other.hasError == hasError &&
        other.imageProvider == imageProvider;
  }

  @override
  int get hashCode =>
      isLoading.hashCode ^ hasError.hashCode ^ imageProvider.hashCode;
}
