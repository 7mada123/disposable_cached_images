part of disposable_cached_images;

class _ImageProviderState {
  final bool isLoading;
  final Object? error;
  final StackTrace? stackTrace;
  final MemoryImage? imageProvider;
  final double? height, width;

  const _ImageProviderState({
    final this.isLoading = false,
    final this.imageProvider,
    this.error,
    this.height,
    this.stackTrace,
    this.width,
  });

  _ImageProviderState copyWith({
    final bool? isLoading,
    final Object? error,
    final MemoryImage? imageProvider,
    final double? height,
    final double? width,
    final StackTrace? stackTrace,
  }) {
    return _ImageProviderState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      imageProvider: imageProvider ?? this.imageProvider,
      height: height ?? this.height,
      width: width ?? this.width,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is _ImageProviderState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.imageProvider == imageProvider;
  }

  @override
  int get hashCode =>
      isLoading.hashCode ^
      error.hashCode ^
      imageProvider.hashCode ^
      stackTrace.hashCode;
}
