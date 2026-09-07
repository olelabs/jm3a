import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../di/service_locator.dart';
import '../utils/app_logger.dart';

/// Uploads ToD proof photos/videos to storage instead of embedding raw
/// bytes in the realtime game-state broadcast/snapshot — videos in
/// particular are far too large to put in a JSONB column or broadcast
/// payload, and even photos are better as a short-lived URL than base64
/// bloating every state sync.
class MediaUploadService {
  MediaUploadService._();
  static final MediaUploadService instance = MediaUploadService._();

  /// Returns the uploaded file's public URL, or null on failure.
  Future<String?> uploadProofMedia({
    required Uint8List bytes,
    required bool isVideo,
    required String contentType,
  }) => _upload(
    fileType: isVideo ? 'proof_video' : 'proof_image',
    bytes: bytes,
    contentType: contentType,
  );

  /// Optional supporting evidence attached to an item-8 creator-recovery
  /// complaint (e.g. a screenshot of a failed renewal payment).
  Future<String?> uploadCreatorRecoveryEvidence({
    required Uint8List bytes,
    required String contentType,
  }) => _upload(
    fileType: 'creator_recovery_evidence',
    bytes: bytes,
    contentType: contentType,
  );

  Future<String?> _upload({
    required String fileType,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final res = await sl.apiClient.post<Map<String, dynamic>>(
        '/v1/storage/upload-url',
        data: {'file_type': fileType, 'content_type': contentType},
      );

      final data = res.data?['data'] as Map<String, dynamic>?;
      final uploadUrl = data?['upload_url'] as String?;
      final publicUrl = data?['public_url'] as String?;
      if (uploadUrl == null || publicUrl == null) {
        AppLogger.warning('MediaUploadService: missing upload/public url');
        return null;
      }

      // Direct PUT to the presigned Wasabi URL — bypasses the Node API for
      // the actual bytes, same pattern used for pack covers/avatars.
      final putDio = Dio();
      await putDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );

      return publicUrl;
    } catch (e, st) {
      AppLogger.error(
        'MediaUploadService: upload failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
