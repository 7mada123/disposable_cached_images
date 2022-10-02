part of disposable_cached_images;

/// {@template runAppWithDisposableCachedImage}
/// A wrapper function to initialize [DisposableCachedImage].
///
/// If you are already using `flutter_riverpod`, you can pass `ProviderScope` arguments
/// `observers` and `overrides` without wrapping the root app with `ProviderScope`.
/// {@endtemplate}
///
/// `enableWebCache` Enable or disable web caching
final _imageStorage = ImageStorageManger.getPlatformInstance();

@Deprecated('use [DisposableImages]')

/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await DisposableImages.init(enableWebCache: false);
///
///   runApp(const DisposableImages(MyApp()));
/// }
/// ```
Future<void> runAppWithDisposableCachedImage(
  final Widget app, {
  final List<Override> overrides = const [],
  final List<ProviderObserver>? observers,
  final bool enableWebCache = true,
}) async {
  await _imageStorage.init(enableWebCache);

  runApp(
    ProviderScope(
      overrides: [
        ...overrides,
      ],
      observers: observers,
      child: app,
    ),
  );
}
// TODO
// running on web html renderer
// html.document.body?.getAttribute("flt-renderer")?.contains("html")

class DisposableImages extends StatelessWidget {
  const DisposableImages(
    this.child, {
    super.key,
    this.overrides = const [],
    this.observers,
  });

  final List<Override> overrides;
  final List<ProviderObserver>? observers;

  final Widget child;

  static Future<void> init({final bool enableWebCache = true}) {
    return _imageStorage.init(enableWebCache);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        ...overrides,
      ],
      observers: observers,
      child: child,
    );
  }
}
