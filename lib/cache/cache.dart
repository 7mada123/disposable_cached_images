import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import './interface.dart';
import '../image_info_data.dart';

ImageCacheManger getInstance() => const _ImageDataBase();

class _ImageDataBase extends ImageCacheManger {
  static const keysFile = "cache_keys.json";

  static late final Map<String, Map<String, dynamic>> fileContent;

  static late String cachePath;

  static late final SendPort fileWriterPort;
  static late final SendPort fileReadePrort;
  static late final SendPort networkImagePrort;
  static late final SendPort networkImageCanclePrort;

  const _ImageDataBase();

  @override
  Future<void> init(final bool enableWebCache) async {
    final path = (await getTemporaryDirectory()).path;

    cachePath = '$path/images_cache/';

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

    /// Isolate for writing images to device storage
    final ReceivePort dataWriterIoslatePort = ReceivePort();
    await Isolate.spawn<List<dynamic>>(
      dataWriterIoslate,
      [dataWriterIoslatePort.sendPort, cachePath],
    );
    fileWriterPort = await dataWriterIoslatePort.first;
    dataWriterIoslatePort.close();

    /// Isolate for reading images from device storage
    final ReceivePort dataReaderIoslatePort = ReceivePort();
    await Isolate.spawn<List<dynamic>>(
      dataReaderIoslate,
      [dataReaderIoslatePort.sendPort, cachePath],
    );
    fileReadePrort = await dataReaderIoslatePort.first;
    dataReaderIoslatePort.close();

    /// Isolate for getting images bytes data from url
    final ReceivePort connectionPort = ReceivePort();
    final ReceivePort canclePort = ReceivePort();
    await Isolate.spawn<List<SendPort>>(
      httpIoslate,
      [connectionPort.sendPort, canclePort.sendPort],
    );
    networkImagePrort = await connectionPort.first;
    networkImageCanclePrort = await canclePort.first;
    connectionPort.close();
  }

  @override
  void add(final ImageInfoData imageInfo) {
    if (isContainKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    fileWriterPort.send(imageInfo);
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

    final fileReceivePort = ReceivePort();

    fileReadePrort.send([key, fileReceivePort.sendPort]);

    final bytes = await fileReceivePort.first;

    fileReceivePort.close();

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
  Future<void> clearCache() async {
    await File(cachePath).delete(recursive: true);

    final cacheKeysFile = File(cachePath + keysFile);

    await cacheKeysFile.create(recursive: true);

    fileContent.clear();
  }

  @override
  Future getImageFromUrl(
    final String url,
    final Map<String, String>? headers,
  ) async {
    final imageReciverPort = ReceivePort();

    networkImagePrort.send(
      [url, imageReciverPort.sendPort, headers],
    );

    final response = await imageReciverPort.first;

    imageReciverPort.close();

    return response;
  }

  @override
  void cancleImageDownload(final String url) {
    networkImageCanclePrort.send(url);
  }

  static bool isContainKey(final String key) => fileContent.containsKey(key);
}

void dataWriterIoslate(final List<dynamic> values) {
  final ReceivePort port = ReceivePort();

  final SendPort sendPort = values[0];

  final String path = values[1];

  sendPort.send(port.sendPort);

  final cacheKeysFile = File(path + "cache_keys.json");

  port.listen((final message) {
    final ImageInfoData imageInfo = message;

    final imageBytesFile = File(path + imageInfo.key);

    imageBytesFile.createSync();

    imageBytesFile.writeAsBytesSync(
      imageInfo.imageBytes!,
      mode: FileMode.writeOnly,
    );

    cacheKeysFile.writeAsStringSync(
      json.encode({imageInfo.key: imageInfo.sizeToMap()}),
      mode: FileMode.writeOnlyAppend,
    );
  });
}

void dataReaderIoslate(final List<dynamic> values) {
  final ReceivePort port = ReceivePort();

  final SendPort sendPort = values[0];

  final String cachePath = values[1];

  sendPort.send(port.sendPort);

  port.listen((final message) {
    final String fileName = message[0];

    final SendPort fileSendPort = message[1];

    final data = File(cachePath + fileName).readAsBytesSync();

    fileSendPort.send(data);
  });
}

void httpIoslate(final List<SendPort> receivePort) {
  final ReceivePort callPort = ReceivePort();
  final ReceivePort cancelPort = ReceivePort();

  receivePort[0].send(callPort.sendPort);
  receivePort[1].send(cancelPort.sendPort);

  final Map<String, http.Client> connectios = {};

  cancelPort.listen((final message) {
    final client = connectios[message];

    if (client == null) return;

    client.close();
    connectios.remove(message);
  });

  callPort.listen((final message) async {
    final client = http.Client();

    final String url = message[0];

    final SendPort sendPort = message[1];

    final Map<String, String>? headers = message[2];

    connectios.putIfAbsent(url, () => client);

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: headers,
      );

      client.close();
      connectios.remove(url);

      if (response.statusCode == 404) {
        sendPort.send(Exception('Image not found'));
        return;
      }

      sendPort.send(response.bodyBytes);
    } catch (e) {
      sendPort.send(e);
    }
  });
}
