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

  static late final SendPort imageIsolateSender;

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

    /// Isolate for handeling network and io oprations
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn<List<dynamic>>(
      imagesIsolate,
      [receivePort.sendPort, cachePath],
    );
    imageIsolateSender = await receivePort.first;
    receivePort.close();
  }

  @override
  void add(final ImageInfoData imageInfo) {
    if (isContainKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    imageIsolateSender.send([_IsolateOprations.write, imageInfo]);
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

    imageIsolateSender
        .send([_IsolateOprations.read, key, fileReceivePort.sendPort]);

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

    imageIsolateSender.send(
      [_IsolateOprations.download, url, imageReciverPort.sendPort, headers],
    );

    final response = await imageReciverPort.first;

    imageReciverPort.close();

    return response;
  }

  @override
  void cancleImageDownload(final String url) {
    imageIsolateSender.send([_IsolateOprations.cancleDownload, url]);
  }

  static bool isContainKey(final String key) => fileContent.containsKey(key);
}

void imagesIsolate(final List<dynamic> arg) {
  final ReceivePort port = ReceivePort();

  final Map<String, http.Client> connectios = {};

  final SendPort sendPort = arg[0];

  final String path = arg[1];

  sendPort.send(port.sendPort);

  final cacheKeysFile = File(path + "cache_keys.json");

  final keysIoSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);

  port.listen((final message) async {
    final _IsolateOprations opration = message[0];

    switch (opration) {
      case _IsolateOprations.write:
        final ImageInfoData imageInfo = message[1];

        final imageBytesFile = File(path + imageInfo.key);

        imageBytesFile.createSync();

        await imageBytesFile.writeAsBytes(
          imageInfo.imageBytes!,
          mode: FileMode.writeOnly,
        );

        keysIoSink.write(json.encode({imageInfo.key: imageInfo.sizeToMap()}));

        break;
      case _IsolateOprations.read:
        final String fileName = message[1];

        final SendPort fileSendPort = message[2];

        final data = File(path + fileName).readAsBytesSync();

        fileSendPort.send(data);

        break;
      case _IsolateOprations.cancleDownload:
        final client = connectios[message[1]];

        if (client == null) return;

        client.close();
        connectios.remove(message[1]);

        break;
      case _IsolateOprations.download:
        final client = http.Client();

        final String url = message[1];

        final SendPort sendPort = message[2];

        final Map<String, String>? headers = message[3];

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

        break;
      default:
    }
  });
}

enum _IsolateOprations {
  read,
  write,
  download,
  cancleDownload,
}
