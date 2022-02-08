[Open in github](https://github.com/7mada123/disposable_cached_images/tree/main/example)

```dart
import 'package:flutter/material.dart';

import 'package:disposable_cached_images/disposable_cached_images.dart';

void main() {
  runAppWithDisposableCachedImage(
    const MyApp(),
    scaffoldMessengerKey: scaffoldMessengerKey,
  );
}

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}


class ImageWidget extends StatelessWidget {
  final String imageUrl;
  const ImageWidget({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  DisposableCachedImageWidget(
        image: imageUrl,
        onLoading: (context) => const Center(
          child: Icon(Icons.downloading),
        ),
        onError: (context, reDownload) => Center(
          child: IconButton(
            onPressed: reDownload,
            icon: const Icon(Icons.download),
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
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) => ImageWidget(imageUrl: images[index]),
      ),
    );
  }

  static final images = List.generate(
    500,
    (final i) => 'https://picsum.photos/id/$i/200/300',
  );
}

```
