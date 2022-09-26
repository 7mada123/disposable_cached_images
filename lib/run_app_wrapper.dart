part of disposable_cached_images;

/// {@template runAppWithDisposableCachedImage}
/// A wrapper function to initialize [DisposableCachedImage].
///
/// If you are already using `flutter_riverpod`, you can pass `ProviderScope` arguments
/// `observers` and `overrides` without wrapping the root app with `ProviderScope`.
/// {@endtemplate}
///
/// `enableWebCache` Enable or disable web caching
Future<void> runAppWithDisposableCachedImage(
  final Widget app, {
  final List<Override> overrides = const [],
  final List<ProviderObserver>? observers,
  final bool enableWebCache = true,
}) async {
  final cache = ImageCacheManger.getPlatformInstance();

  await cache.init(enableWebCache);

  runApp(
    ProviderScope(
      overrides: [
        imageDataBaseProvider.overrideWithValue(cache),
        ...overrides,
      ],
      observers: observers,
      child: app,
    ),
  );
}
