import 'dart:typed_data';
import 'dart:ui' as ui;

import 'image_metadata_stripper.dart';

/// Thrown when an image's metadata could not be removed. Callers must not
/// upload or share the original bytes in that case.
class ImageMetadataRemovalException implements Exception {
  const ImageMetadataRemovalException(this.message);
  final String message;
  @override
  String toString() => 'ImageMetadataRemovalException: $message';
}

/// Returns [bytes] with all embedded metadata (GPS location, camera/device
/// info, XMP/IPTC, comments) removed. Call this on every image before it
/// leaves the device (upload or broadcast).
///
/// JPEG/PNG/WebP/GIF are cleaned losslessly (pixels untouched, orientation
/// kept). Any other format, or a file that can't be parsed, is re-encoded to
/// PNG by the platform decoder, which writes no metadata. If that also
/// fails, throws [ImageMetadataRemovalException] — never returns the
/// original bytes.
Future<Uint8List> removeImageMetadata(Uint8List bytes) async {
  try {
    final stripped = ImageMetadataStripper.strip(bytes);
    if (stripped != null) return stripped;
  } on FormatException {
    // Malformed container: fall through to a full re-encode below.
  }
  return _reencodeAsPng(bytes);
}

Future<Uint8List> _reencodeAsPng(Uint8List bytes) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const ImageMetadataRemovalException('PNG encoding returned null');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } on ImageMetadataRemovalException {
    rethrow;
  } catch (e) {
    throw ImageMetadataRemovalException('could not decode image: $e');
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}
