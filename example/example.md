[Open full example in github](https://github.com/7mada123/disposable_cached_images/tree/main/example)

```dart
import 'package:disposable_cached_images/disposable_cached_images.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  await DisposableImages.init();

  runApp(const DisposableImages(MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GridView.builder(
          // RepaintBoundaries is enabled by default in DisposableCachedImage widget
          addRepaintBoundaries: false,
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => DisposableCachedImage.network(imageUrl: images[index]),
        ),
      ),
    );
  }

  static final images = List.generate(
    500,
    (final i) => 'https://picsum.photos/id/$i/200/300',
  );
}

```
