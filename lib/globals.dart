part of disposable_cached_images;

/// {@template runAppWithDisposableCachedImage}
/// A wrapper function to initialize [DisposableCachedImage].
/// Make sure the `scaffoldMessengerKey` is attached to the root `MaterialApp`.
///
/// If you are already using `flutter_riverpod`, you can pass `ProviderScope` arguments
/// `observers` and `overrides` without wrapping the root app with `ProviderScope`.
/// {@endtemplate}
Future<void> runAppWithDisposableCachedImage(
  final Widget app, {
  required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  List<Override> overrides = const [],
  List<ProviderObserver>? observers,
}) async {
  final dir = await getTemporaryDirectory();

  _scaffoldMessengerKey = scaffoldMessengerKey;

  final imageCache = _ImageDataBase(dir.path);

  runApp(
    ProviderScope(
      overrides: [
        _imageDataBaseProvider.overrideWithValue(imageCache),
        ...overrides,
      ],
      observers: observers,
      child: app,
    ),
  );
}

/// {@template clearCache}
/// Clear [DisposableCachedImage] storage cache.
/// {@endtemplate}
Future<void> clearCache() {
  return _ImageDataBase._clearCache();
}

late final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
