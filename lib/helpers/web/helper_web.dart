// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './dart_js.dart';
import '../../image_info_data.dart';
import '../interfaces.dart';

HelperBase getInstance() => _HelperWeb();

class _HelperWeb extends HelperBase {
  static late final Map<String, Map<String, dynamic>> fileContent;

  static bool _disableWebCache = false;

  // TODO web html render
  // html.document.body?.getAttribute("flt-renderer")?.contains("html")

  @override
  final _ThreadOperationWeb threadOperation = _ThreadOperationWeb();

  _HelperWeb();

  @override
  Future<void> init(final bool enableWebCache, int maximumDownload) async {
    await threadOperation.init();

    if (!enableWebCache) {
      _disableWebCache = true;
      fileContent = {};
      return;
    }

    final res = await threadOperation.db.getKeys();

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
  void add(final ImageInfoData imageInfo) async {
    if (_disableWebCache || fileContent.containsKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    try {
      await threadOperation.addToCache(
        key: imageInfo.key,
        width: imageInfo.width!,
        height: imageInfo.height!,
        bytes: imageInfo.imageBytes!,
      );
    } catch (e, s) {
      debugPrint(
          "disposable cached images : added web image to cache error\nerror :: ${e.toString()} \n$s");
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

    return threadOperation.getBytes(imageInfo.webKey());
  }

  @override
  Future<Uint8List> getLocalBytes(final String imagePath) async {
    return _localImageFileBytes(imagePath);
  }

  @override
  Future<Uint8List> getAssetBytes(String imagePath) async {
    return _localImageFileBytes(imagePath);
  }

  static Future<Uint8List> _localImageFileBytes(final String imagePath) async {
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

    return threadOperation.clearData();
  }

  /// Using RegEx for the key so that we don't accidentally use or remove
  /// other values not associated with this package
  static final _webKeyReg = RegExp(
    r'{"http(s{0,1}).*?(height":\d+,"width":\d+})}',
  );
}

extension on ImageInfoData {
  String webKey() => json.encode({key: sizeToMap()});
}

class _ThreadOperationWeb extends ThreadOperationBase {
  final client = JSHttpClientHelper();
  final db = JSIndexedDb();
  final Queue<Future<void> Function(String url)> queue = Queue();

  Future<void> init() => db.open();

  @override
  Future<void> clearData() => db.clearCache();

  @override
  Future<Uint8List?> getBytes(String key) async => db.getImage(key);

  @override
  Future<void> addToCache({
    required String key,
    required int width,
    required int height,
    required Uint8List bytes,
  }) {
    return db.addToCache(
      json.encode({
        key: {
          'height': height,
          'width': width,
        }
      }),
      bytes,
    );
  }

  @override
  void cancelDownload(String url) {
    client.cancelDownload(url);
  }

  @override
  Stream getNetworkBytes(String url, Map<String, String>? headers) {
    return client.download(url, headers: headers);
  }
}
