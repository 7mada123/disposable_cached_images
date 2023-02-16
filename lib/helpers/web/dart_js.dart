// ignore_for_file: avoid_web_libraries_in_flutter

@JS()
library callable_function;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';

@JS()
external Future<dynamic> jsInvokeMethod(
    String method, dynamic param1, dynamic param2);

@JS()
external void jsInvokeDwonloadMethod(
    String method, String url, String? headers);

// JSIndexedDb
class JSIndexedDb {
  bool isOpen = false;

  Future<dynamic> open() async {
    final res = await promiseToFutureAsMap(jsInvokeMethod("init", null, null));

    if (res == null) throw Exception("no data recived from js");

    if (res["error"] != null) throw Exception(res["error"]);

    isOpen = true;

    return res["result"];
  }

  Future<List<dynamic>> getKeys() async {
    final res = await promiseToFutureAsMap(
      jsInvokeMethod("getAllKeys", null, null),
    );

    if (res == null) throw Exception("no data recived from js");

    if (res["error"] != null) throw Exception(res["error"]);

    return res["result"];
  }

  Future<Uint8List?> getImage(String key) async {
    final res = await promiseToFutureAsMap(
      jsInvokeMethod("getImage", key, null),
    );

    if (res == null) throw Exception("no data recived from js");

    if (res["error"] != null) throw Exception(res["error"]);

    return res["result"];
  }

  Future<void> addToCache(String key, Uint8List imageBytes) async {
    final res = await promiseToFutureAsMap(
      jsInvokeMethod("addToCache", imageBytes, key),
    );

    if (res == null) throw Exception("no data recived from js");

    if (res["error"] != null) throw Exception(res["error"]);
  }

  Future<void> clearCache() async {
    final res = await promiseToFutureAsMap(
      jsInvokeMethod("clearCache", null, null),
    );

    if (res == null) throw Exception("no data recived from js");

    if (res["error"] != null) throw Exception(res["error"]);
  }
}

// JSHttpClientHelper with fetch API

@JS('downloadStream')
external set _downloadStream(void Function(dynamic value, dynamic response) f);

final Map<String, StreamController> _downloadStreams = HashMap();

void _updateDownloadStream(dynamic value, dynamic response) {
  final map = json.decode(value);

  final String url = map["url"];

  final streamController = _downloadStreams[url];

  if (streamController == null) return;

  if (map["error"] != null) {
    streamController.addError(map["error"]);
    _downloadStreams.remove(url);
  } else {
    streamController.add(response);

    if (response is Uint8List) {
      streamController.close();
      _downloadStreams.remove(url);
    }
  }
}

class JSHttpClientHelper {
  JSHttpClientHelper() {
    _downloadStream = allowInterop(_updateDownloadStream);
  }

  Stream<dynamic> download(String url, {Map<String, String>? headers}) {
    final StreamController controller = StreamController();

    _downloadStreams[url] = controller;

    jsInvokeDwonloadMethod(
      "download",
      url,
      headers != null ? json.encode(headers) : null,
    );

    return controller.stream;
  }

  void cancelDownload(String url, {Map<String, String>? headers}) {
    jsInvokeMethod("cancel_download", url, null);

    _downloadStreams.remove(url)?.close();
  }
}
