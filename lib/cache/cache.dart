import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

import './interface.dart';
import '../image_info_data.dart';

// TODO
// Improve raster cache by using 2 providers at the same time
// and a thrid one that detects new value + changine KEY TO resulation

ImageCacheManger getInstance() => const _ImageDataBase();

class _ImageDataBase extends ImageCacheManger {
  static const keysFile = "cache_keys.json";

  static late final Map<String, Map<String, dynamic>> fileContent;

  static late String cachePath;

  static late final SendPort fileWriterPort;
  static late final SendPort fileReadePrort;
  static late final SendPort networkImagePrort;

  // static late final Isolate isolate;

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

    // await clearCache();

    final ReceivePort _port = ReceivePort();

    /// Isolate for writing images to device storage
    await Isolate.spawn<List<dynamic>>(
      dataWriterIoslate,
      [_port.sendPort, cachePath],
    );

    fileWriterPort = await _port.first;

    /// Isolate for reading images from device storage
    await Isolate.spawn<List<dynamic>>(
      dataReaderIoslate,
      [_port.sendPort, cachePath],
    );

    fileReadePrort = await _port.first;

    /// Isolate for getting images bytes data from url
    await Isolate.spawn<SendPort>(runHttpIoslate, _port.sendPort);

    networkImagePrort = await _port.first;

    _port.close();

    // ioSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);
  }

  @override
  void addNew(final ImageInfoData imageInfo) {
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

    fileReadePrort.send([key, fileReadePrort]);

    final bytes = await fileReceivePort.first;

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
    // TODO

    // await ioSink.close();

    await File(cachePath).delete(recursive: true);

    final cacheKeysFile = File(cachePath + keysFile);

    await cacheKeysFile.create(recursive: true);

    fileContent.clear();

    // ioSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);
  }

  static bool isContainKey(final String key) => fileContent.containsKey(key);

  @override
  Future getImageFromUrl(
    final http.Client httpClient,
    final String url,
    final Map<String, String>? headers,
  ) async {
    final imageReciverPort = ReceivePort();

    networkImagePrort.send(
      [httpClient, url, imageReciverPort.sendPort, headers],
    );

    final response = await imageReciverPort.first;

    imageReciverPort.close();

    return response;
  }
}

void dataWriterIoslate(final List<dynamic> values) {
  final ReceivePort port = ReceivePort();

  final SendPort sendPort = values[0];

  sendPort.send(port.sendPort);

  final cacheKeysFile = File(values[1] + "cache_keys.json");
  final ioSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);

  port.listen((final message) {
    // TODO
    /// broken
    final http.Client httpClien = message[0];
    final String url = message[1];
    final Map<String, String>? headers = message[2];

    final imageInfo = message as ImageInfoData;

    final imageBytesFile = File(values[1] + imageInfo.key);

    imageBytesFile.createSync();

    imageBytesFile.writeAsBytesSync(
      imageInfo.imageBytes!,
      mode: FileMode.writeOnly,
    );

    cacheKeysFile.writeAsString(
      json.encode({imageInfo.key: imageInfo.sizeToMap()}),
    );

    ioSink.write(json.encode({imageInfo.key: imageInfo.sizeToMap()}));
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

void runHttpIoslate(final SendPort receivePort) {
  final ReceivePort port = ReceivePort();

  receivePort.send(port.sendPort);

  port.listen((final message) async {
    final http.Client client = message[0];

    final String url = message[1];

    final SendPort imageSendPort = message[2];

    final Map<String, String>? headers = message[3];

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 404) {
        imageSendPort.send('Image not found');
        return;
      }

      client.close();

      imageSendPort.send(response.bodyBytes);
    } catch (e) {
      imageSendPort.send(e);
      print('error from isolate $e');
    }
  });
}
