part of disposable_cached_images;

final _imageDataBaseProvider = Provider.autoDispose<_ImageDataBase>(
  (final ref) => throw UnimplementedError(),
);

class _ImageDataBase {
  static const keysFile = "cache_keys.txt";

  static late final String cachePath;

  static late final List<String> fileContent;

  final String _path;

  _ImageDataBase(this._path) {
    cachePath = '$_path/image_cache/';

    final jsonFile = File(cachePath + keysFile);

    final fileExists = jsonFile.existsSync();

    if (fileExists) {
      fileContent = jsonFile.readAsStringSync().split(',');
    } else {
      jsonFile.createSync(recursive: true);
      fileContent = [];
    }
  }

  Future<void> addNew({
    required final String key,
    required final Uint8List bytes,
  }) async {
    final imageBytesFile = File(cachePath + key);

    await imageBytesFile.create();

    await imageBytesFile.writeAsBytes(bytes);

    final isContain = await isContainKeyCompute(key);

    if (!isContain) {
      fileContent.add(key);

      final imageFile = File(cachePath + keysFile);

      imageFile.writeAsString(fileContent.join(','));
    }
  }

  Future<Uint8List?> getBytes(final String key) async {
    final isContain = await isContainKeyCompute(key);

    if (!isContain) return null;

    try {
      final imageBytesFile = File(cachePath + key);
      return imageBytesFile.readAsBytes();
    } catch (e) {
      throw Exception(
        """Exception has occurred. Unable to load image from cache
        Error : ${e.toString()}""",
      );
    }
  }

  Future<Uint8List> getBytesFormAssets(final String imagePath) async {
    try {
      final imageBytesFile = File(imagePath);
      return imageBytesFile.readAsBytes();
    } catch (e) {
      throw Exception(
        """Exception has occurred. Unable to load asset image
        path : $imagePath
        Error : ${e.toString()}""",
      );
    }
  }

  static Future<void> _clearCache() async {
    await File(cachePath).delete(recursive: true);

    await File(cachePath + keysFile).create(recursive: true);

    fileContent.clear();
  }

  static Future<bool> isContainKeyCompute(final String key) async {
    return compute<_KeyCheckClass, bool>(
      isContainKey,
      _KeyCheckClass(keys: fileContent, key: key),
    );
  }

  static bool isContainKey(final _KeyCheckClass argument) {
    return argument.keys.contains(argument.key);
  }
}

class _KeyCheckClass {
  final List<String> keys;
  final String key;

  const _KeyCheckClass({
    required final this.keys,
    required final this.key,
  });

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is _KeyCheckClass &&
        listEquals(other.keys, keys) &&
        other.key == key;
  }

  @override
  int get hashCode => keys.hashCode ^ key.hashCode;
}
