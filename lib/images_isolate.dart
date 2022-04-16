import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'image_info_data.dart';

enum _IsolateOprations {
  read,
  write,
  download,
  cancleDownload,
  clearData,
  // TODO
  // decodeImage,
}

/// Isolate for handeling network and io oprations
class ImagesIsolate {
  const ImagesIsolate();

  static late final SendPort imageIsolateSender;

  static Future<void> init(final String cachePath) async {
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn<List<dynamic>>(
      _imagesIsolate,
      [receivePort.sendPort, cachePath],
    );
    imageIsolateSender = await receivePort.first;
    receivePort.close();
  }

  static void addToCache(final ImageInfoData imageInfo) {
    imageIsolateSender.send([_IsolateOprations.write, imageInfo]);
  }

  static Future<Uint8List?> getBytes(final String key) async {
    final fileReceivePort = ReceivePort();

    imageIsolateSender.send(
      [_IsolateOprations.read, key, fileReceivePort.sendPort],
    );

    final bytes = await fileReceivePort.first;

    fileReceivePort.close();

    return bytes;
  }

  static Future<void> clearData() async {
    final receivePort = ReceivePort();

    imageIsolateSender
        .send([_IsolateOprations.clearData, receivePort.sendPort]);

    final result = await receivePort.first;

    if (result is! String) throw result;
  }

  static Future<Uint8List> getImageFromUrl(
    final String url,
    final Map<String, String>? headers,
  ) async {
    final imageReciverPort = ReceivePort();

    imageIsolateSender.send(
      [_IsolateOprations.download, url, imageReciverPort.sendPort, headers],
    );

    final response = await imageReciverPort.first;

    imageReciverPort.close();

    if (response is! Uint8List) throw response;

    return response;
  }

  static void cancleDownload(final String url) {
    imageIsolateSender.send([_IsolateOprations.cancleDownload, url]);
  }
}

void _imagesIsolate(final List<dynamic> arg) {
  const keysFile = 'cache_keys.json';

  final ReceivePort port = ReceivePort();

  final Map<String, http.Client> connectios = {};

  final SendPort sendPort = arg[0];

  final String path = arg[1];

  sendPort.send(port.sendPort);

  final cacheKeysFile = File(path + keysFile);

  IOSink keysIoSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);

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

        final file = File(path + fileName);

        if (!file.existsSync()) {
          fileSendPort.send(null);
          return;
        }

        final data = file.readAsBytesSync();

        fileSendPort.send(data);

        break;
      case _IsolateOprations.clearData:
        final SendPort sendPort = message[1];
        try {
          await keysIoSink.close();

          await File(path).delete(recursive: true);

          await cacheKeysFile.create(recursive: true);

          keysIoSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);

          sendPort.send('');
        } catch (e) {
          sendPort.send(e);
        }

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
