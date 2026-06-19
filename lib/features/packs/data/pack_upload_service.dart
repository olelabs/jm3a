import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/utils/app_logger.dart';
import '../data/pack_repository.dart';

class PackUploadService {
  PackUploadService._();
  static final PackUploadService _instance = PackUploadService._();
  static PackUploadService get instance => _instance;

  final _repo = PackRepository.instance;

  Future<String> uploadCoverImage(File imageFile) =>
      _upload(imageFile, 'cover', 'image/jpeg');

  Future<String> uploadCardImage(File imageFile) =>
      _upload(imageFile, 'card_image', 'image/jpeg');

  Future<String> _upload(File file, String fileType, String contentType) async {
    final size = await file.length();

    // 1. Get presigned URL from our API
    final urls = await _repo.getUploadUrl(
      contentType: contentType,
      fileType: fileType,
      fileSizeBytes: size,
    );

    AppLogger.debug('PackUploadService: uploading $fileType (${size}b)');

    // 2. Read file bytes
    final bytes = await file.readAsBytes();

    // 3. PUT to Wasabi — must send Content-Type to match the presigned signature
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
        validateStatus: (_) => true,
      ),
    );

    final response = await dio.put<String>(
      urls.uploadUrl,
      data: bytes,
      options: Options(
        contentType: contentType,
        headers: {'Content-Length': bytes.length},
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      AppLogger.error(
        'Wasabi upload failed: ${response.statusCode}\n${response.data}',
      );
      throw Exception(
        'Upload failed (${response.statusCode}): ${response.data}',
      );
    }

    AppLogger.info(
      'PackUploadService: ✅ $fileType uploaded → ${urls.publicUrl}',
    );
    return urls.publicUrl;
  }
}
