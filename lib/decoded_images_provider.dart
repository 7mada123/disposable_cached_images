// ignore_for_file: curly_braces_in_flow_control_structures, library_private_types_in_public_api

part of disposable_cached_images;

// TODO doc

// TODO handeling network and asstes providers
class _DecodedImages {
  final int? capacity;

  _DecodedImages(this.capacity);

  final LinkedHashMap<String, DecodedImage> _decodedImages = LinkedHashMap();

  Future<void> addLocal(String path) async {
    try {
      final String key = path.key;

      if (_decodedImages.containsKey(key))
        throw Exception("image : $path\nis already decoded");

      final completer = Completer<_ImageResolverResult?>();

      ImageInfoData imageInfo = ImageInfoData.init(key);

      final bytes = await _imageStorage.getLocalBytes(path);

      imageInfo = imageInfo.copyWith(imageBytes: bytes);

      _ImageDecoder.schedule(
        bytes: bytes,
        completer: completer,
      );

      final res = await completer.future;

      imageInfo = imageInfo.copyWith(
        height: res!.image.height,
        width: res.image.width,
      );

      _decodedImages[key] = DecodedImage(
        ImageInfoData(
          height: res.image.height,
          width: res.image.width,
          imageBytes: bytes,
          key: key,
        ),
        res,
      );

      // removing the oldest inserted/used images
      if (capacity != null && _decodedImages.length > capacity!) {
        final DecodedImage? oldest = _decodedImages.remove(
          _decodedImages.keys.first,
        );

        oldest?.imageResolverResult.image.dispose();
      }
    } catch (e) {
      rethrow;
    }
  }

  void disposeImage(String path) {
    final selected = _decodedImages.remove(path.key);

    selected?.imageResolverResult.image.dispose();
    selected?.imageResolverResult.codec?.dispose();
  }

  DecodedImage? _get(String path) {
    final String key = path.key;

    late final DecodedImage? selected;

    if (capacity == null) {
      selected = _decodedImages[key];
    } else {
      // removing and adding to maintain the usage frequently
      selected = _decodedImages.remove(key);

      if (selected != null) _decodedImages[key] = selected;
    }

    if (selected == null) return null;

    return DecodedImage(
      selected.imageInfoData,
      _ImageResolverResult(
        image: selected.imageResolverResult.image.clone(),
        codec: selected.imageResolverResult.codec,
        isAnimated: selected.imageResolverResult.isAnimated,
      ),
    );
  }

  void disposeAll() {
    for (String key in _decodedImages.keys) {
      _decodedImages[key]!.imageResolverResult.image.dispose();
      _decodedImages[key]!.imageResolverResult.codec?.dispose();
    }

    _decodedImages.clear();
  }
}

class DecodedImage {
  final ImageInfoData imageInfoData;
  final _ImageResolverResult imageResolverResult;

  const DecodedImage(this.imageInfoData, this.imageResolverResult);
}
