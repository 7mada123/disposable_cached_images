import 'package:disposable_cached_images/disposable_cached_images.dart';
import 'package:flutter/material.dart';

import './image_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runAppWithDisposableCachedImage(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              await DisposableCachedImage.clearCache();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared!')),
              );
            },
            icon: const Icon(Icons.clear),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        // RepaintBoundaries is enabled by default in DisposableCachedImage widget
        addRepaintBoundaries: false,
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
    (final i) => 'https://picsum.photos/id/$i/800/900',
  );
}
