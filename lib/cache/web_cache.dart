// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/services.dart';

import './interface.dart';
import '../image_info_data.dart';

ImageCacheManger getInstance() => const _WebImageDataBase();

class _WebImageDataBase extends ImageCacheManger {
  static final html.Storage caches = html.window.localStorage;

  static late final Map<String, Map<String, dynamic>> fileContent;

  static late final bool _disableWebCache;

  const _WebImageDataBase();

  @override
  Future<void> init(final bool enableWebCache) async {
    if (!enableWebCache) {
      _disableWebCache = true;
      fileContent = {};
      return;
    }

    _disableWebCache = false;

    if (caches.keys.isEmpty) {
      fileContent = {};
      return;
    }

    for (final key in caches.keys)
      if (_webKeyReg.hasMatch(key)) _sortedWebKeys.add(key);

    fileContent = Map.from(
      json.decode(_sortedWebKeys.join().replaceAll('}{', ',')),
    );

    _sortedWebKeys.sort((final a, final b) {
      return (json.decode(caches[a]!)['time']).compareTo(
        json.decode(caches[b]!)['time'],
      );
    });
  }

  @override
  void add(final ImageInfoData imageInfo) {
    if (_disableWebCache || fileContent.containsKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    try {
      _add(imageInfo);
    } on html.DomException catch (e) {
      if (e.message?.contains('exceeded the quota') ?? false) {
        _removeOld5();
        _add(imageInfo);
      }
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

    return Uint8List.fromList(
      List<int>.from(json.decode(caches[imageInfo.webKey()]!)['bytes']),
    );
  }

  @override
  Future<Uint8List> getLocalBytes(final String imagePath) async {
    final byteData = await rootBundle.load(imagePath);
    return byteData.buffer.asUint8List();
  }

  @override
  Future<void> clearCache() async {
    fileContent.clear();

    for (final key in _sortedWebKeys) {
      caches.remove(key);
      _sortedWebKeys.remove(key);
    }
  }

  /// Using RegEx for the key so that we don't accidentally use or remove
  /// other values not associated with this package
  static final _webKeyReg = RegExp(
    r'{"http(s{0,1}).*?(width":\d+,"height":\d+})}',
  );

  static void _add(final ImageInfoData imageInfo) {
    try {
      final key = imageInfo.webKey();

      caches.putIfAbsent(
        key,
        () => json.encode({
          'bytes': imageInfo.imageBytes!.toList(),
          'time': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      _sortedWebKeys.add(key);
    } catch (e) {
      rethrow;
    }
  }

  /// used to remove the old images
  static final List<String> _sortedWebKeys = [];

  /// Remove the old five images when the local storage reaches the limit
  static void _removeOld5() {
    final old5 = _sortedWebKeys.sublist(
      0,
      _sortedWebKeys.length > 5 ? 5 : _sortedWebKeys.length,
    );

    for (final key in old5) {
      caches.remove(key);
      _sortedWebKeys.remove(key);
    }
  }
}

extension on ImageInfoData {
  String webKey() => json.encode({key: sizeToMap()});
}
