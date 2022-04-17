import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../disposable_cached_images.dart';

mixin NetworkImageProviderPlatformMixin on BaseImageProvider {
  final client = http.Client();

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  Future<Uint8List> getImageByetsFromUrl() async {
    final response = await client.get(
      Uri.parse(providerArguments.image),
      headers: providerArguments.headers,
    );

    client.close();

    if (response.statusCode == 404) throw Exception('Image not found');

    return response.bodyBytes;
  }
}
