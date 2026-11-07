import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/cloudinary_config.dart';

/// The only class that uploads photos. Uses an unsigned upload preset, so no
/// secret key is stored in the app.
class CloudinaryRepository {
  CloudinaryRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Uploads a photo and returns its public HTTPS URL.
  Future<String> uploadIncidentImage(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await _client.send(request);
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200) {
      throw Exception('Photo upload failed (${response.statusCode}). Check the Cloudinary settings.');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }
}
