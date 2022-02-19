import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/services.dart';

import './interface.dart';

ImageCacheManger getInstance() => const _WebImageDataBase();

class _WebImageDataBase extends ImageCacheManger {
  static final html.Storage caches = html.window.localStorage;

  static late final List<String> sortedKeys;

  const _WebImageDataBase();

  @override
  Future<void> init() async {
    sortedKeys = caches.keys.toList()
      ..sort((a, b) => (json.decode(caches[a]!)['time']).compareTo(
            json.decode(caches[b]!)['time'],
          ));
  }

  @override
  Future<void> addNew({required String key, required Uint8List bytes}) async {
    sortedKeys.add(key);

    try {
      _add(key, bytes);
    } on html.DomException catch (e) {
      if (e.message?.contains('exceeded the quota') ?? false) {
        _removeOld5();
        _add(key, bytes);
      }
    }
  }

  @override
  Future<Uint8List?> getBytes(String key) async {
    if (caches.containsKey(key)) {
      return Uint8List.fromList(
        List<int>.from(json.decode(caches[key]!)['bytes']),
      );
    } else {
      return null;
    }
  }

  @override
  Future<Uint8List> getBytesFormAssets(String imagePath) async {
    final byteData = await rootBundle.load('assets/$imagePath');
    return byteData.buffer.asUint8List();
  }

  @override
  Future<void> clearCache() async {
    sortedKeys.clear();
    caches.clear();
  }

  void _add(final String key, final Uint8List bytes) {
    try {
      caches.putIfAbsent(
        key,
        () => json.encode({
          'bytes': bytes.toList(),
          'time': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _removeOld5() {
    final last5 = sortedKeys.sublist(0, 5);
    caches.removeWhere((key, value) => last5.contains(key));
    sortedKeys.removeRange(0, 5);
  }
}
