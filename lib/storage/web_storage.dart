// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';

import './interface.dart';
import '../image_info_data.dart';

ImageStorageManger getInstance() => const _WebImageDataBase();

class _WebImageDataBase extends ImageStorageManger {
  static late final Database _db;

  static late final Map<String, Map<String, dynamic>> fileContent;

  static late final bool _disableWebCache;

  static const String _storeName = "web_images";

  const _WebImageDataBase();

  @override
  Future<void> init(final bool enableWebCache) async {
    if (!enableWebCache) {
      _disableWebCache = true;
      fileContent = {};
      return;
    }

    _db = await idbFactoryBrowser.open("app_db.db", version: 1,
        onUpgradeNeeded: (VersionChangeEvent event) {
      Database db = event.database;
      db.createObjectStore(_storeName, autoIncrement: true);
    });

    _disableWebCache = false;

    var txn = _db.transaction(_storeName, "readonly");
    var store = txn.objectStore(_storeName);

    final res = await store.getAllKeys();

    await txn.completed;

    if (res.isEmpty) {
      fileContent = {};
      return;
    }

    final List<String> keys = [];

    for (Object key in res)
      if (key is String && _webKeyReg.hasMatch(key)) keys.add(key);

    if (keys.isEmpty) {
      fileContent = {};
      return;
    }

    fileContent = Map.from(
      json.decode(keys.join().replaceAll('}{', ',')),
    );
  }

  @override
  void add(final ImageInfoData imageInfo) {
    if (_disableWebCache || fileContent.containsKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    try {
      _add(imageInfo);
    } catch (e, s) {
      debugPrint(
          "disposable cached images : added web image to cache error\nerror :: ${e.toString()}");
      debugPrint(s.toString());
    }
  }

  @override
  ImageInfoData? getImageInfo(final String key) {
    final data = fileContent[key];

    if (data == null) return null;

    return ImageInfoData.fromMap(data, key);
  }

  @override
  Future<Uint8List?> getBytes(final String key) async {
    final imageInfo = getImageInfo(key);

    if (imageInfo == null) return null;

    var txn = _db.transaction(_storeName, "readonly");
    var store = txn.objectStore(_storeName);

    final res = await store.getObject(imageInfo.webKey()) as Uint8List?;

    await txn.completed;

    if (res == null) return null;

    return res;
  }

  @override
  Future<Uint8List> getLocalBytes(final String imagePath) async {
    return _loaclimageFileBytes(imagePath);
  }

  @override
  Future<Uint8List> getAssetBytes(String imagePath) async {
    return _loaclimageFileBytes(imagePath);
  }

  static Future<Uint8List> _loaclimageFileBytes(final String imagePath) async {
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
    fileContent.clear();

    var txn = _db.transaction(_storeName, "readwrite");
    var store = txn.objectStore(_storeName);

    await store.clear();

    await txn.completed;
  }

  /// Using RegEx for the key so that we don't accidentally use or remove
  /// other values not associated with this package
  static final _webKeyReg = RegExp(
    r'{"http(s{0,1}).*?(height":\d+,"width":\d+})}',
  );

  static void _add(final ImageInfoData imageInfo) async {
    try {
      final key = imageInfo.webKey();

      var txn = _db.transaction(_storeName, "readwrite");
      var store = txn.objectStore(_storeName);

      await store.put(
        imageInfo.imageBytes!,
        key,
      );

      await txn.completed;
    } catch (e) {
      rethrow;
    }
  }
}

extension on ImageInfoData {
  String webKey() => json.encode({key: sizeToMap()});
}
