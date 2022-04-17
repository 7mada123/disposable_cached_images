A flutter package for downloading, caching, displaying and releasing images from memory.

## Features

Display images from the Internet and/or local files (assets and device storage).

Caching images in the cache directory.

Cancel the download if the image widget has been disposed to reduce bandwidth usage.

Remove the image from memory if the image widget has been disposed to reduce device memory usage.

High performance due to the use of [dart:isolate](https://api.dart.dev/stable/2.16.2/dart-isolate/dart-isolate-library.html)

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

##### Obtaining a local image from assets or device storage using path

```dart
DisposableCachedImage.local(imagePath: 'assets/images/a_dot_burr.jpeg');
```

##### Display dynamic height images

If you are using dynamic height images, you should declare this as shown below to avoid UI jumping

```dart
DisposableCachedImage.network(
  imageUrl: imageUrl,
  isDynamicHeight: true,
  width: MediaQuery.of(context).size.width * 0.3,
),
```

> `width` required when displaying dynamic height images

---

You can display your custom widgets while the image is loading, has an error and when it is ready as shown below

```dart
DisposableCachedImage.network(
  imageUrl: 'https://picsum.photos/id/23/200/300',
  onLoading: (context) => const Center(
    child: Icon(Icons.downloading),
  ),
  onError: (context, error, stackTrace, retryCall) => Center(
    child: IconButton(
      onPressed: retryCall,
      icon: const Icon(Icons.download),
    ),
  ),
  onImage: (context, imageWidget, height, width) => Stack(
    children: [
      imageWidget,
      MyWidget(),
    ],
  ),
);
```

#### Resize images

You can change the image size to the provided `width` and \ or `height` by enabling `resizeImage` (disabled by default) to reduce raster thread usage when using high resolution images, if this option is enabled the same provider instance would be used for the number of images that share the same url \ path with a different image size for each widget to have a gallery like experience.

To change the size of the images in bytes before they are saved to the storage, provide `maxCacheWidth` and \ or `maxCacheHeight`.

```dart
DisposableCachedImage.network(
 imageUrl: imageUrl,
 maxCacheWidth: 300,
 width: 200,
 resizeImage: true,
),
```

#### Clipping

You can clip the image either with rounded corners by providing [`BorderRadius`](https://api.flutter.dev/flutter/painting/BorderRadius-class.html)

```dart
DisposableCachedImage.network(
  imageUrl: imageUrl,
  borderRadius: const BorderRadius.all(Radius.circular(20)),
),
```

Or by setting [`BoxShape`](https://api.flutter-io.cn/flutter/painting/BoxShape.html) to get oval image

```dart
DisposableCachedImage.network(
  imageUrl: imageUrl,
  shape: BoxShape.circle,
),
```

#### Keeping images alive

By default each image is removed from memory when it is not being used by any widget, however you can keep some images in memory for the entire application lifecycle as shown below

```dart
DisposableCachedImage.network(
  imageUrl: imageUrl,
  keepAlive: true,
),
```

---

> The other arguments are similar if not quite the same as [Image Widget](https://api.flutter.dev/flutter/widgets/Image-class.html)

---

#### Remove all cached images from the device storage

```dart
DisposableCachedImage.clearCache();
```

### Web

If you want to enable web caching, you must declare it in `runAppWithDisposableCachedImage` as shown below.

```dart
runAppWithDisposableCachedImage(
  const MyApp(),
  // enable Web cache, default false
  enableWebCache: true,
);
```

> In both cases the images will be saved in memory as variables, and the web local storage cache should not be enabled if your application uses many images because of the local storage size limit, prefer to use Cache-Control HTTP header.

## How it works

The package uses [RawImage](https://api.flutter.dev/flutter/widgets/RawImage-class.html) with [dart-ui-Image](https://api.flutter.dev/flutter/dart-ui/Image-class.html) directly without the need for [ImageProvider](https://api.flutter.dev/flutter/painting/ImageProvider-class.html)

Stores and retrieves files using [localStorage](https://api.flutter.dev/flutter/dart-html/Window/localStorage.html) on web and [dart:io](https://api.flutter.dev/flutter/dart-io/dart-io-library.html) on other platforms.

Disposing and changing image state using [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) with [state_notifier](https://pub.dev/packages/state_notifier).

Using [http](https://pub.dev/packages/http) to download images from the internet.

### Example app

The [example](https://github.com/7mada123/disposable_cached_images/tree/main/example) directory has a sample application that uses this plugin.

### Roadmap

Improve performance for web

Improve package documentation

Further improvements
