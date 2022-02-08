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
      child: DisposableCachedImageWidget(
        image: imageUrl,
        onLoading: (context) => const Center(
          child: Icon(Icons.downloading),
        ),
        onError: (context, error, reDownload) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              const SizedBox(height: 10),
              IconButton(
                onPressed: reDownload,
                icon: const Icon(Icons.download),
              ),
            ],
          ),
        ),
        onImage: (context, memoryImage) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: memoryImage,
              fit: BoxFit.cover,
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
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ImageWidget(imageUrl: imageUrl),
      ),
    );
  }
}
