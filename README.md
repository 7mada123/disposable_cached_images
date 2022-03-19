<!--

This README describes the package. If you publish this package to pub.dev,

this README's contents appear on the landing page for your package.



For information about how to write a good package README, see the guide for

[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).



For general information about developing packages, see the Dart guide for

[creating packages](https://dart.dev/guides/libraries/create-library-packages)

and the Flutter guide for

[developing packages and plugins](https://flutter.dev/developing-packages).

-->

A flutter package for downloading, caching, displaying and releasing images from memory.

## Features

Display images from assets and/or the Internet.

Caching images in the cache directory.

Cancel the download if the image widget has been disposed to reduce bandwidth usage.

Remove the image from memory if the image widget has been disposed to reduce device memory usage.

## Usage

### Setting up

All you have to do is to warp the root widget with `runAppWithDisposableCachedImage` instead of `runApp`.

```dart
void main() {
  runAppWithDisposableCachedImage(const MyApp());
}
```

> If you are already using [flutter_riverpod](https://pub.dev/packages/flutter_riverpod), you can pass `ProviderScope` arguments `observers` and `overrides` to the `runAppWithDisposableCachedImage` function.

Now your app is ready to use the package.

### Displaying images

Use `DisposableCachedImage` named constructors to display images.

##### Obtaining an image from a URL

```dart
DisposableCachedImage.network(imageUrl: 'https://picsum.photos/id/23/200/300');
```

##### Obtaining an image from assets using path

```dart
DisposableCachedImage.assets(imagePath: 'images/a_dot_burr.jpeg');
```

##### Obtaining an image from a URL with dynamic height 

```dart
DisposableCachedImage.dynamicHeight(
  imageUrl: 'https://picsum.photos/id/23/200/300',
  // Provide the width of the widget so that the height can be calculated accordingly
  imageWidth: MediaQuery.of(context).size.width * 0.5,
);
```

______

You can display your custom widgets while the image is loading, has an error and when it is ready as shown below

```dart
DisposableCachedImage.network(
 imageUrl: imageUrl,
 onLoading: (context) => const Center(
   child: Icon(Icons.downloading),
 ),
 onError: (context, error, reDownload) => Center(
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
```

You can Provide a maximum width value for the image by passing the it to `maxCacheWidth` argument, If the actual width of the image is less than the provided value, the provided value will be ignored.

The image will be resized before it's displayed in the UI and saved to the device storage.

```dart
DisposableCachedImageWidget(
 image: imageUrl,
 maxCacheWidth: 300,
);
```
> Animated images will not be resized due to animation loss issue.

#### Caching images on the web

If you want to enable web caching, you must declare it in `runAppWithDisposableCachedImage` as shown below.

```dart
runAppWithDisposableCachedImage(
  const MyApp(),  
  // enable Web cache, default false
  enableWebCache: true,
);
```

> In both cases the images will be saved in memory as variables, and the web storage cache should not be enabled if your application uses many images because of the local storage size limit.

#### Remove all cached images

```dart
DisposableCachedImage.clearCache();
```

## How it works

Stores and retrieves files using [localStorage](https://api.flutter.dev/flutter/dart-html/Window/localStorage.html) on web and [dart:io](https://api.flutter.dev/flutter/dart-io/dart-io-library.html) on other platforms.

Disposing and changing image state using [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) with [state_notifier](https://pub.dev/packages/state_notifier).

Using [http](https://pub.dev/packages/http) to download images from the internet.

### Example app

The [example](https://github.com/7mada123/disposable_cached_images/tree/main/example) directory has a sample application that uses this plugin.

### Roadmap

Improve package documentation

Further improvements
