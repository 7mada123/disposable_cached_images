part of disposable_cached_images;

class _ImageProviderState {
  final bool isLoading;
  final Object? error;
  final StackTrace? stackTrace;
  final ui.Image? uiImage;
  final int? height, width;

  const _ImageProviderState({
    final this.isLoading = false,
    required final this.uiImage,
    this.error,
    this.height,
    this.stackTrace,
    this.width,
  });

  const _ImageProviderState.init()
      : error = null,
        height = null,
        width = null,
        stackTrace = null,
        uiImage = null,
        isLoading = false;

  _ImageProviderState copyWith({
    final bool? isLoading,
    final Object? error,
    final int? height,
    final int? width,
    final ui.Image? uiImage,
    final StackTrace? stackTrace,
  }) {
    return _ImageProviderState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      uiImage: uiImage ?? this.uiImage,
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
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => isLoading.hashCode ^ error.hashCode ^ stackTrace.hashCode;
}
