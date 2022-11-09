import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import './interface.dart';
import '../image_info_data.dart';
import '../images_isolate.dart';

ImageStorageManger getInstance() => const _ImageDataBase();

class _ImageDataBase extends ImageStorageManger {
  static const keysFile = "cache_keys.json";

  static late final Map<String, Map<String, dynamic>> fileContent;

  const _ImageDataBase();

  @override
  Future<void> init(final bool enableWebCache) async {
    final path = (await getTemporaryDirectory()).path;

    final cachePath = '$path/images_cache/';

    final cacheKeysFile = File(cachePath + keysFile);

    if (cacheKeysFile.existsSync()) {
      try {
        final fileStr = cacheKeysFile.readAsStringSync().replaceAll('}{', ',');

        fileContent = fileStr.isNotEmpty ? Map.from(json.decode(fileStr)) : {};
      } catch (e) {
        debugPrint(e.toString());
        cacheKeysFile.deleteSync();
        cacheKeysFile.createSync();
        fileContent = {};
      }
    } else {
      cacheKeysFile.createSync(recursive: true);
      fileContent = {};
    }

    await ImagesIsolate.init(cachePath);
  }

  @override
  void add(final ImageInfoData imageInfo) {
    if (isContainKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    ImagesIsolate.addToCache(imageInfo);
  }

  @override
  ImageInfoData? getImageInfo(final String key) {
    final data = fileContent[key];

    if (data == null) return null;

    return ImageInfoData.fromMap(data, key);
  }

  @override
  Future<Uint8List?> getBytes(final String key) async {
    if (!isContainKey(key)) return null;

    final bytes = await ImagesIsolate.getBytes(key);

    return bytes;
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
  Future<Uint8List> getAssetBytes(String imagePath) async {
    try {
      final byteData = await rootBundle.load(imagePath);
      return byteData.buffer.asUint8List();
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
    await ImagesIsolate.clearData();

    fileContent.clear();
  }

  static bool isContainKey(final String key) => fileContent.containsKey(key);
}
