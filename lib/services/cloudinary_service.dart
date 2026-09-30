import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._();
  CloudinaryService._();

  // Cloudinary credentials provided by user
  String apiKey = '399642892931915';
  String apiSecret = 'hrVuS2NKSi309VgGp_RJ2rwwjug';
  String cloudName = 'imamhossenbu';
  String uploadPreset = 'flutter_upload';

  void configure({String? newCloudName, String? newApiKey, String? newApiSecret, String? newPreset}) {
    if (newCloudName != null && newCloudName.isNotEmpty) cloudName = newCloudName.trim();
    if (newApiKey != null && newApiKey.isNotEmpty) apiKey = newApiKey.trim();
    if (newApiSecret != null && newApiSecret.isNotEmpty) apiSecret = newApiSecret.trim();
    if (newPreset != null && newPreset.isNotEmpty) uploadPreset = newPreset.trim();
  }

  /// Picks an image from Gallery or Camera and returns XFile
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      return picked;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Uploads raw image bytes to Cloudinary using signed authentication
  Future<String?> uploadImageBytes(Uint8List bytes, {String filename = 'product.jpg'}) async {
    if (cloudName.isEmpty) {
      throw Exception('Cloudinary Cloud Name is required.');
    }

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // 1. Try Signed Upload with API Key & Secret
    try {
      // Cloudinary signature formula: SHA1(sorted_params + api_secret)
      final signaturePayload = 'timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(signaturePayload)).toString();

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint('Cloudinary upload success: $secureUrl');
          return secureUrl;
        }
      }

      debugPrint('Signed upload response [${response.statusCode}]: ${response.body}');

      // If signed upload failed (e.g. signature error or preset needed), try unsigned as fallback
      if (uploadPreset.isNotEmpty) {
        return await _uploadUnsigned(bytes, filename: filename);
      } else {
        final data = json.decode(response.body);
        final errorMsg = data['error']?['message'] ?? 'Cloudinary upload failed: ${response.statusCode}';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      rethrow;
    }
  }

  Future<String?> _uploadUnsigned(Uint8List bytes, {required String filename}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    }
    final data = json.decode(response.body);
    final errorMsg = data['error']?['message'] ?? 'Upload failed with code ${response.statusCode}';
    throw Exception(errorMsg);
  }
}
