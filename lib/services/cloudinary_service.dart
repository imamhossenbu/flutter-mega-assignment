import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._();
  CloudinaryService._();

  String? _cloudNameOverride;
  String? _uploadPresetOverride;

  String get cloudName => _cloudNameOverride ?? dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String get uploadPreset => _uploadPresetOverride ?? dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  void configure({String? newCloudName, String? newPreset}) {
    if (newCloudName != null && newCloudName.isNotEmpty) _cloudNameOverride = newCloudName.trim();
    if (newPreset != null && newPreset.isNotEmpty) _uploadPresetOverride = newPreset.trim();
  }

  /// Injects Cloudinary optimization transformations into URL.
  /// Defaults to w_400 for thumbnails, w_800 for details.
  static String transformUrl(String? url, {String transformation = 'w_400,q_auto,f_auto'}) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (!trimmed.contains('cloudinary.com') || !trimmed.contains('/upload/')) {
      return trimmed;
    }
    if (trimmed.contains('/upload/$transformation/')) {
      return trimmed;
    }
    return trimmed.replaceFirst('/upload/', '/upload/$transformation/');
  }

  static String thumbnail(String? url) => transformUrl(url, transformation: 'w_400,q_auto,f_auto');
  static String detail(String? url) => transformUrl(url, transformation: 'w_800,q_auto,f_auto');

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

  /// Uploads raw image bytes to Cloudinary using Unsigned Upload with preset
  Future<String?> uploadImageBytes(Uint8List bytes, {String filename = 'product.jpg'}) async {
    final cName = cloudName;
    final preset = uploadPreset;

    if (cName.isEmpty || preset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured. Please ensure CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET are set in your .env file.',
      );
    }

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          debugPrint('Cloudinary unsigned upload success: $secureUrl');
          return secureUrl;
        }
      }

      final data = json.decode(response.body);
      final errorMsg = data['error']?['message'] ?? 'Upload failed with HTTP ${response.statusCode}';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      rethrow;
    }
  }
}
