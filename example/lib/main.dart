import 'package:disposable_cached_images/disposable_cached_images.dart';
import 'package:flutter/material.dart';

import './image_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          onPressed: () async {
            await clearCache();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cache cleared!')),
            );
          },
          icon: const Icon(Icons.clear),
        )
      ]),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) => ImageWidget(
          imageUrl: images[index],
        ),
      ),
    );
  }

  static final images = List.generate(
    500,
    (final i) => 'https://picsum.photos/id/$i/200/300',
  );
}
