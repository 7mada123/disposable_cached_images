## 0.0.6

Added new provider to keep track of the alrady yeild `MemoryImage`
This will help reduce the time required to display the previously viewed image.

Using a `map` instead of a `list` of cached images to find keys faster

## 0.0.5

Add maxCacheWidth and maxCacheHeight to resize images

Update documentation and example

- breaking changes:

Integrate the asset image with the network image to use one Widget for both

Improved error handling


## 0.0.3

Support assets images.

Remove Dio in favor of http.

