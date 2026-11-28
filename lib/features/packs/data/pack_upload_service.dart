import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/image_privacy.dart';
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

  /// Meme sticker upload (task item 3 follow-up) — the backend's
  /// /v1/storage/upload-url already maps 'sticker' to its own Wasabi
  /// folder (storageRoutes.js FILE_TYPE_MAP), so this reuses the exact
  /// same presigned-URL + PUT flow as every other upload here, just with
  /// that file type. The resulting URL is used as CardDraft.imageUrl
  /// (the existing "pack-owned upload" sticker representation — see
  /// CardDraft.imageUrl's own doc comment) — sticker_library itself has
  /// no client-insert RLS policy and stays admin-curated only.
  Future<String> uploadStickerImage(File imageFile) =>
      _upload(imageFile, 'sticker', 'image/jpeg');

  Future<String> _upload(File file, String fileType, String contentType) async {
    // Privacy: strip GPS/EXIF metadata before the bytes leave the device.
    final bytes = await removeImageMetadata(await file.readAsBytes());
    final size = bytes.length;

    // 1. Get presigned URL from our API
    final urls = await _repo.getUploadUrl(
      contentType: contentType,
      fileType: fileType,
      fileSizeBytes: size,
    );

    AppLogger.debug('PackUploadService: uploading $fileType (${size}b)');

    // 2. PUT to Wasabi — must send Content-Type to match the presigned signature
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
