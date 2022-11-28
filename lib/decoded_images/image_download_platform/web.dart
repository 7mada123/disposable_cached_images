import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<Uint8List> getImageBytesFromUrl(String url,
    {Map<String, String>? headers}) async {
  final client = http.Client();

  final response = await client.get(Uri.parse(url), headers: headers);

  client.close();

  if (response.statusCode == 404) throw Exception('Image not found');

  return response.bodyBytes;
}
