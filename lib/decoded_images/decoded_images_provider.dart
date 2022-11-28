// ignore_for_file: curly_braces_in_flow_control_structures, library_private_types_in_public_api

part of disposable_cached_images;

class _DecodedImages {
  final int? _capacity;

  _DecodedImages(this._capacity);

  final LinkedHashMap<String, _DecodedImage> _decodedImages = LinkedHashMap();

  /// decode local images
  ///
  /// can throw an error
  Future<void> addLocal(String path) async {
    final String key = path.key;

    if (_decodedImages.containsKey(key)) return;

    final bytes = await _imageStorage.getLocalBytes(path);

    return _addImage(
      bytes,
      key,
    );
  }

  /// decode assets images
  ///
  /// can throw an error
  Future<void> addAssets(String path) async {
    final String key = path.key;

    if (_decodedImages.containsKey(key)) return;

    final bytes = await _imageStorage.getAssetBytes(path);

    return _addImage(
      bytes,
      key,
    );
  }

  /// decode network images
  ///
  /// can throw an error
  Future<void> addNetwork(String url, {Map<String, String>? headers}) async {
    final String key = url.key;

    if (_decodedImages.containsKey(key)) return;

    bool isSaved = true;

    Uint8List? bytes = await _imageStorage.getBytes(key);

    if (bytes == null) {
      bytes = await getImageBytesFromUrl(url, headers: headers);
      isSaved = false;
    }

    await _addImage(
      bytes,
      key,
    );

    if (!isSaved) _imageStorage.add(_decodedImages[key]!.imageInfoData);
  }

  /// dispose an image by key
  ///
  /// the key is path if the image is local or assets, if it's a network image the key is the url
  void dispose(String key) {
    final selected = _decodedImages.remove(key.key);

    selected?.imageResolverResult.image.dispose();
    selected?.imageResolverResult.codec?.dispose();
  }

  /// dispose all images
  void disposeAll() {
    for (String key in _decodedImages.keys) {
      _decodedImages[key]!.imageResolverResult.image.dispose();
      _decodedImages[key]!.imageResolverResult.codec?.dispose();
    }

    _decodedImages.clear();
  }

  Future<void> _addImage(final Uint8List bytes, final String key) async {
    final completer = Completer<_ImageResolverResult?>();

    _ImageDecoder.schedule(
      bytes: bytes,
      completer: completer,
    );

    final res = await completer.future;

    _decodedImages[key] = _DecodedImage(
      ImageInfoData(
        height: res!.image.height,
        width: res.image.width,
        imageBytes: bytes,
        key: key,
      ),
      res,
    );

    // removing the oldest inserted/used images
    if (_capacity != null && _decodedImages.length > _capacity!) {
      final _DecodedImage? oldest = _decodedImages.remove(
        _decodedImages.keys.first,
      );

      oldest?.imageResolverResult.image.dispose();
    }
  }

  _DecodedImage? _get(String image) {
    final String key = image.key;

    late final _DecodedImage? selected;

    if (_capacity == null) {
      selected = _decodedImages[key];
    } else {
      // removing and adding to maintain the usage frequently
      selected = _decodedImages.remove(key);

      if (selected != null) _decodedImages[key] = selected;
    }

    if (selected == null) return null;

    return _DecodedImage(
      selected.imageInfoData,
      _ImageResolverResult(
        image: selected.imageResolverResult.image.clone(),
        codec: selected.imageResolverResult.codec,
        isAnimated: selected.imageResolverResult.isAnimated,
      ),
    );
  }
}

class _DecodedImage {
  final ImageInfoData imageInfoData;
  final _ImageResolverResult imageResolverResult;

  const _DecodedImage(this.imageInfoData, this.imageResolverResult);
}
