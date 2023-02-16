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
final _imagesHelper = HelperBase.getPlatformInstance();

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

  /// decode images before showing them in the UI
  ///
  /// using this api you have to handle images disposing manually or provide `decodedImagesCount` so you don't end up with memory issue
  static late final _DecodedImages decodedImages;

  final Widget child;

  static Future<void> init({
    final bool enableWebCache = true,

    /// specify the maximum number of images to be decoded simultaneously
    ///
    /// increasing this number may impact the performance, default to 1
    final int maximumDecode = 1,

    /// specify the maximum number of images to be downloaded simultaneously, this wouldn't have effect on web
    ///
    /// using big number may lead to exception depending on the platform
    final int maximumDownload = 4,

    /// specify the maximum number of decoded images that should be kept in memory when using [DisposableImages.decodedImages]
    final int? maximumDecodedImagesCount,
  }) {
    decodedImages = _DecodedImages(maximumDecodedImagesCount);

    _ImageDecoder.maximumDownload = maximumDecode;

    return _imagesHelper.init(enableWebCache, maximumDownload);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: child);
  }
}
