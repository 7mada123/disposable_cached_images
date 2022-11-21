// ignore_for_file: library_private_types_in_public_api

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

/// instead of using `runAppWithDisposableCachedImage` use `DisposableImages` as shown below
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // initialize the package
///   await DisposableImages.init();
///
///   // warp the root widget with `DisposableImages`
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

/// `DisposableImages` used to initialize the pacakge
///
/// ```dart
///Future<void> main() async {
///  WidgetsFlutterBinding.ensureInitialized();
///
///  await DisposableImages.init();
///
///  runApp(DisposableImages(MyApp()));
///}
///```
class DisposableImages extends StatelessWidget {
  const DisposableImages(this.child, {super.key});

  static late final _DecodedImages decodedImages;

  final Widget child;

  static Future<void> init({
    final bool enableWebCache = true,
    // TODO doc
    final int? decodedImagesCount,
  }) {
    decodedImages = _DecodedImages(decodedImagesCount);

    return _imageStorage.init(enableWebCache);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: child);
  }
}
