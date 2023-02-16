part of disposable_cached_images;

final _downloadProgressProvider =
    StateProvider.family.autoDispose<double, String>(
  (ref, key) {
    return 0;
  },
);

class _DownloadProgressWidget extends ConsumerWidget {
  final Widget Function(BuildContext context, double progress) progressBuilder;
  final String url;

  const _DownloadProgressWidget({
    required this.progressBuilder,
    required this.url,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return progressBuilder(context, ref.watch(_downloadProgressProvider(url)));
  }
}
