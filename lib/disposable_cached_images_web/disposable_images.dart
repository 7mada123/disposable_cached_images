part of disposable_cached_images_io;

class DisposableImages extends StatelessWidget {
  const DisposableImages(this.child, {super.key});

  /// decode images before showing them in the UI
  ///
  /// using this api you have to handle images disposing manually or provide `decodedImagesCount` so you don't end up with memory issue

  final Widget child;

  static Future<void> init({
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
  }) async {}

  @override
  Widget build(BuildContext context) => child;
}
