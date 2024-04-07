part of disposable_cached_images_io;

HelperBase getInstance() => _HelperIO();

class _HelperIO extends HelperBase {
  static const keysFile = "cache_keys.json";

  static late final Map<String, Map<String, dynamic>> fileContent;

  _HelperIO();

  @override
  late final _ThreadOperationIsolate threadOperation;

  @override
  Future<void> init(int maximumDownload) async {
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

    threadOperation = _ThreadOperationIsolate(cachePath, maximumDownload);

    await threadOperation.init();
  }

  @override
  void add(final ImageInfoData imageInfo) {
    if (isContainKey(imageInfo.key)) return;

    fileContent.putIfAbsent(imageInfo.key, () => imageInfo.sizeToMap());

    threadOperation.addToCache(
      key: imageInfo.key,
      width: imageInfo.width!,
      height: imageInfo.height!,
      bytes: imageInfo.imageBytes!,
    );
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

    return threadOperation.getBytes(key);
  }

  @override
  Future<Uint8List> getLocalBytes(final String imagePath) async {
    try {
      return threadOperation.getLocalFile(imagePath);
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
    await threadOperation.clearData();

    fileContent.clear();
  }

  static bool isContainKey(final String key) => fileContent.containsKey(key);
}

// @GenerateIsolate()
class _ThreadOperationIO extends ThreadOperationBase {
  final String cachePath;
  final int maximumDownload;

  _ThreadOperationIO(this.cachePath, this.maximumDownload);

  static const keysFile = 'cache_keys.json';

  late final cacheKeysFile = File(cachePath + keysFile);

  late IOSink keysIoSink = cacheKeysFile.openWrite(
    mode: FileMode.writeOnlyAppend,
  );

  final Map<String, HttpClientRequest> connections = {};
  final Set<String> runningRequests = HashSet();

  final HttpClient _client = HttpClient()..autoUncompress = false;

  final Queue<Future<void> Function()> _requtesQueue = Queue();

  int _runningCount = 0;

  Future<void> _runDownloads() async {
    while (_requtesQueue.isNotEmpty && _runningCount < maximumDownload) {
      _runningCount++;
      _requtesQueue.removeFirst()().then((value) {
        _runningCount--;

        _runDownloads();
      });
    }
  }

  @override
  Stream<dynamic> getNetworkBytes(
    final String url,
    final Map<String, String>? headers,
  ) {
    runningRequests.add(url);

    final StreamController streamController = StreamController();

    _requtesQueue.add(() => _downloadTask(streamController, url, headers));

    _runDownloads();

    return streamController.stream;
  }

  Future<void> _downloadTask(
    StreamController<dynamic> streamController,
    final String url,
    final Map<String, String>? headers,
  ) async {
    if (!runningRequests.contains(url)) {
      streamController.addError(Exception("canceled"));
      return;
    }

    try {
      final clientRequest = await _client.getUrl(Uri.base.resolve(url));

      if (!runningRequests.contains(url)) {
        clientRequest.abort();
        streamController.addError(Exception("canceled"));
        return;
      }

      headers?.forEach((String name, String value) {
        clientRequest.headers.add(name, value);
      });

      final clientResponse = await clientRequest.close();

      if (clientResponse.statusCode == 404) {
        await clientResponse.drain(Exception('Image not found'));

        clientRequest.abort();

        streamController.addError(Exception('Image not found'));

        return;
      }

      if (!runningRequests.contains(url)) {
        await clientResponse.drain(Exception("canceled"));

        streamController.addError(Exception("canceled"));

        clientRequest.abort();

        return;
      }

      connections[url] = clientRequest;

      final List<int> bytesList = [];
      final int fullLength = math.max(clientResponse.contentLength, 1);

      late final StreamSubscription<List<int>> subscription;

      final Completer<void> responseCompleter = Completer();

      subscription = clientResponse.listen(
        (List<int> chunk) {
          bytesList.addAll(chunk);
          streamController.add((bytesList.length / fullLength).clamp(0.0, 1.0));
        },
        onDone: () {
          subscription.cancel();
          responseCompleter.complete();
          streamController.add(Uint8List.fromList(bytesList));
          streamController.close();
        },
        onError: (e, s) {
          subscription.cancel();
          responseCompleter.complete();
          streamController.addError(e, s);
        },
        cancelOnError: true,
      );

      return responseCompleter.future;
    } catch (e, s) {
      streamController.addError(e, s);
    }
  }

  @override
  void cancelDownload(final String url) {
    runningRequests.remove(url);
    connections.remove(url)?.abort();
  }

  @override
  Future<Uint8List?> getBytes(final String key) async {
    final file = File(cachePath + key);

    if (!file.existsSync()) return null;

    return file.readAsBytesSync();
  }

  Uint8List getLocalFile(final String path) => File(path).readAsBytesSync();

  @override
  Future<void> clearData() async {
    await keysIoSink.close();

    await File(cachePath).delete(recursive: true);

    await cacheKeysFile.create(recursive: true);

    keysIoSink = cacheKeysFile.openWrite(mode: FileMode.writeOnlyAppend);
  }

  @override
  Future<void> addToCache({
    required String key,
    required int width,
    required int height,
    required Uint8List bytes,
  }) async {
    final imageBytesFile = File(cachePath + key);

    imageBytesFile.createSync();

    await imageBytesFile.writeAsBytes(
      bytes,
      mode: FileMode.writeOnly,
    );

    keysIoSink.write(json.encode(
      {
        key: {
          'height': height,
          'width': width,
        },
      },
    ));
  }
}
