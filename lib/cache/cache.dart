import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import './interface.dart';

ImageCacheManger getInstance() => const _ImageDataBase();

class _ImageDataBase extends ImageCacheManger {
  static const keysFile = "cache_keys.json";

  static late final String cachePath;

  static late final Map<String, String> fileContent;

  const _ImageDataBase();

  @override
  Future<void> init() async {
    final path = (await getTemporaryDirectory()).path;

    cachePath = '$path/image_cache/';

    final jsonFile = File(cachePath + keysFile);

    final fileExists = jsonFile.existsSync();

    if (fileExists) {
      fileContent = Map.from(json.decode(jsonFile.readAsStringSync()));
    } else {
      jsonFile.createSync(recursive: true);
      fileContent = {};
    }
  }

  @override
  Future<void> addNew({
    required final String key,
    required final Uint8List bytes,
  }) async {
    final imageBytesFile = File(cachePath + key);

    await imageBytesFile.create();

    await imageBytesFile.writeAsBytes(bytes);

    final isContain = isContainKey(key);

    if (!isContain) {
      fileContent.putIfAbsent(key, () => '');

      final imageFile = File(cachePath + keysFile);

      imageFile.writeAsString(json.encode(fileContent));
    }
  }

  @override
  Future<Uint8List?> getBytes(final String key) async {
    if (!isContainKey(key)) return null;

    try {
      return File(cachePath + key).readAsBytes();
    } catch (e) {
      throw Exception(
        """Exception has occurred. Unable to load image from cache
        Error : ${e.toString()}""",
      );
    }
  }

  @override
  Future<Uint8List> getBytesFormAssets(final String imagePath) async {
    try {
      return File(imagePath).readAsBytes();
    } catch (e) {
      throw Exception(
        """Exception has occurred. Unable to load asset image
        path : $imagePath
        Error : ${e.toString()}""",
      );
    }
  }

  @override
  Future<void> clearCache() async {
    await File(cachePath).delete(recursive: true);

    await File(cachePath + keysFile).create(recursive: true);

    fileContent.clear();
  }

  static bool isContainKey(final String key) {
    return fileContent[key] != null;
  }
}
