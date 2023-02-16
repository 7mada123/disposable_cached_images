part of disposable_cached_images;

class _ImageProviderState {
  final bool isLoading, isDownloading;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, ui.Image> uiImages;
  final int? height, width;

  const _ImageProviderState({
    this.isLoading = false,
    this.isDownloading = false,
    required this.uiImages,
    this.error,
    this.height,
    this.stackTrace,
    this.width,
  });

  _ImageProviderState.init()
      : error = null,
        height = null,
        width = null,
        stackTrace = null,
        uiImages = {},
        isLoading = false,
        isDownloading = false;

  ui.Image getImage(final String key) {
    return uiImages[key] ?? uiImages['']!;
  }

  _ImageProviderState copyWith({
    final bool? isLoading,
    final bool? isDownloading,
    final Object? error,
    final int? height,
    final int? width,
    final StackTrace? stackTrace,
  }) {
    return _ImageProviderState(
      isLoading: isLoading ?? this.isLoading,
      isDownloading: isDownloading ?? this.isDownloading,
      error: error ?? this.error,
      uiImages: uiImages,
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
        other.isDownloading == isDownloading &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode =>
      uiImages.hashCode ^
      isDownloading.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      stackTrace.hashCode;
}
