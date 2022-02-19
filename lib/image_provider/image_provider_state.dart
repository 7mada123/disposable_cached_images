part of disposable_cached_images;

class _ImageProviderState {
  final bool isLoading;
  final Object? error;
  final MemoryImage? imageProvider;

  _ImageProviderState loading() {
    return const _ImageProviderState(
      true,
      null,
      null,
    );
  }

  _ImageProviderState notLoading(
    final MemoryImage? imageProvider, {
    final Object? error,
  }) {
    return _ImageProviderState(
      false,
      imageProvider,
      error,
    );
  }

  factory _ImageProviderState.init() {
    return const _ImageProviderState(false, null, null);
  }

  const _ImageProviderState(
    final this.isLoading,
    final this.imageProvider,
    this.error,
  );

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
