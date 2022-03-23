import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import './interface.dart';
import '../image_info_data.dart';

ImageCacheManger getInstance() => const _ImageDataBase();

class _ImageDataBase extends ImageCacheManger {
  static const keysFile = "cache_keys.json";

  static late final String cachePath;

  static late final Map<String, Map<String, dynamic>> fileContent;

  static late IOSink ioSink;

  const _ImageDataBase();

  @override
  Future<void> init(final bool enableWebCache) async {
    final path = (await getTemporaryDirectory()).path;

    cachePath = '$path/images_cache/';

    final cacheKeysFile = File(cachePath + keysFile);

    if (cacheKeysFile.existsSync()) {
      final fileStr = cacheKeysFile.readAsStringSync().replaceAll('}{', ',');

      fileContent = fileStr.isNotEmpty ? Map.from(json.decode(fileStr)) : {};
    } else {
      cacheKeysFile.createSync(recursive: true);
      fileContent = {};
    }

    ioSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);
  }

  @override
  Future<void> addNew(final ImageInfoData imageInfo) async {
    if (isContainKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    final imageBytesFile = File(cachePath + imageInfo.key);

    await imageBytesFile.create();

    await imageBytesFile.writeAsBytes(
      imageInfo.imageBytes!,
      mode: FileMode.writeOnly,
    );

    ioSink.write(json.encode({imageInfo.key: imageInfo.sizeToMap()}));
  }

  @override
  ImageInfoData? getImageInfo(String key) {
    final data = fileContent[key];

    if (data == null) return null;

    return ImageInfoData.fromMap(data, key);
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
  Future<Uint8List> getLocalBytes(final String imagePath) async {
    try {
      return File(imagePath).readAsBytes();
    } catch (e) {
      throw Exception(
        """Exception has occurred. Unable to load image file
        path : $imagePath
        Error : ${e.toString()}""",
      );
    }
  }

  @override
  Future<void> clearCache() async {
    await ioSink.close();

    await File(cachePath).delete(recursive: true);

    final cacheKeysFile = File(cachePath + keysFile);

    await cacheKeysFile.create(recursive: true);

    fileContent.clear();

    ioSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);
  }

  static bool isContainKey(final String key) => fileContent.containsKey(key);
}
