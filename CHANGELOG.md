## 1.0.3

Big performance improvement using [dart:isolate](https://api.dart.dev/stable/2.16.2/dart-isolate/dart-isolate-library.html)

## 1.0.2

Resize the image, animated images will not be resized

404 Exception

Improved animated images handling

Remove cache check for local images

### Breaking change

rename `targetWidth`, `targetHeight` to `maxCacheWidth`, `maxCacheHeight`


## 1.0.1 stable release

Using `RawImage` with `ui.Image` directly instaded of `MemoryImage`, this improves the overall performance and fixed the issue where sometimes `evcit()` doesn't release the images from memory and some of the images are suddenly removed

Fixed an issue where animated images loss animations when resizing

Fixed an issue where dynamic height images wouldn't resize correctly when providing dynamic width

---

### Breaking change

Removed the need for `scaffoldMessengerKey`

Removed `ImageType` in favor of [Named constructors](https://dart.dev/guides/language/language-tour#named-constructors)

`onError` provide `StackTrace`

`onImage` provide the image `Widget` and size. `MemoryImage` provider is removed

---

Update documentation
Update example

## 0.1.0

Faster data writing using [IOSink](https://api.flutter.dev/flutter/dart-io/IOSink-class.html) and [FileMode](https://api.flutter.dev/flutter/dart-io/FileMode-class.html)

Saving image height and width to avoid UI jumping when loading dynamic sized images

option to enable or disable web local storage cache

Fix local storage initialization issue on web

Update documentation

## 0.0.9

Added web support

> Caching images with local storage

Update dependencies

Fix cache file initialization issue

## 0.0.7

Added initial web support

> web image caching and assets are still not supported

Added `ImageType` to determine if an image is from the Internet or an asset

Update documentation

## 0.0.6

A new provider has been added to keep track of the `MemoryImage` that has already been used and this will help reduce the time required to display the previously viewed image.

Using a `map` instead of a `list` of cached images to find keys faster

## 0.0.5

Add `maxCacheWidth` and `maxCacheHeight` to resize images

Update documentation and example

- breaking changes:

Integrate the asset image with the network image to use one Widget for both

Improved error handling

## 0.0.3

Support assets images.

Remove Dio in favor of http.
