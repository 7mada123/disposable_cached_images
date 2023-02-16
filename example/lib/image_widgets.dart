import 'package:disposable_cached_images/disposable_cached_images.dart';
import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  final String imageUrl;

  const ImageWidget({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewScreen(
            imageUrl: imageUrl,
          ),
        ),
      ),
      child: Hero(
        tag: imageUrl,
        child: DisposableCachedImage.network(
          imageUrl: imageUrl,
          width: MediaQuery.of(context).size.width * 0.5,
          // Resize the image to this width to reduce raster thread usage
          resizeImage: true,
          fit: BoxFit.cover,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          onLoading: (context, height, width) => const Center(
            child: Icon(Icons.downloading),
          ),
          progressBuilder: (context, progress) => Center(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.red,
            ),
          ),
          onError: (context, error, stackTrace, retryCall) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(error.toString()),
                const SizedBox(height: 10),
                IconButton(
                  onPressed: retryCall,
                  icon: const Icon(Icons.download),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({
    required this.imageUrl,
  }) : super(key: const Key('view_screen'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: DisposableCachedImage.network(
              imageUrl: imageUrl,
              width: MediaQuery.of(context).size.width,
              onLoading: (context, height, width) => const Center(
                child: Icon(Icons.downloading),
              ),
              onError: (context, error, stackTrace, retryCall) {
                return Text(
                  error.toString(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
