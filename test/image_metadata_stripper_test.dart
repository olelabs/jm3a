// Privacy: images must not leave the device with GPS/EXIF/XMP metadata.
//
// Fixtures in test/fixtures/image_metadata/ were generated with Pillow and
// geotagged with exiftool (GPS IFD + XMP GPS + IPTC City + Make/Model +
// comments; JPEG orientation 6, PNG orientation 8, WebP orientation 6;
// gps_trailer.jpg has a second geotagged JPEG appended after EOI, like an
// MPF/HDR secondary image). They are real files, independent of the
// stripper under test.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:jma3a/core/utils/image_metadata_stripper.dart';
import 'package:jma3a/core/utils/image_privacy.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/image_metadata/$name').readAsBytesSync();

bool _containsAscii(Uint8List haystack, String needle) {
  final n = needle.codeUnits;
  outer:
  for (var i = 0; i + n.length <= haystack.length; i++) {
    for (var j = 0; j < n.length; j++) {
      if (haystack[i + j] != n[j]) continue outer;
    }
    return true;
  }
  return false;
}

/// Strings planted by exiftool that must all be gone after stripping.
const _leakMarkers = [
  'GPSLatitude',
  'GPSLongitude',
  'xmpmeta',
  'XMP',
  'TestMake',
  'TestPhone',
  'Nouakchott',
  'home',
];

/// Independent JPEG header walk: returns (marker, payload) for every
/// segment before the first SOS.
List<(int, Uint8List)> _jpegHeaderSegments(Uint8List b) {
  final out = <(int, Uint8List)>[];
  var pos = 2;
  while (pos + 4 <= b.length) {
    final marker = b[pos + 1];
    final len = (b[pos + 2] << 8) | b[pos + 3];
    out.add((marker, Uint8List.sublistView(b, pos + 4, pos + 2 + len)));
    if (marker == 0xDA) break;
    pos += 2 + len;
  }
  return out;
}

class _Decoded {
  _Decoded(this.width, this.height, this.frames, this.rgba);
  final int width;
  final int height;
  final int frames;
  final List<Uint8List> rgba;
}

Future<_Decoded> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frames = <Uint8List>[];
  int? w;
  int? h;
  for (var i = 0; i < codec.frameCount; i++) {
    final image = (await codec.getNextFrame()).image;
    w ??= image.width;
    h ??= image.height;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frames.add(data!.buffer.asUint8List());
    image.dispose();
  }
  final frameCount = codec.frameCount;
  codec.dispose();
  return _Decoded(w!, h!, frameCount, frames);
}

void main() {
  const geotagged = [
    'gps_orient6.jpg',
    'gps_progressive.jpg',
    'gps_trailer.jpg',
    'gps_orient8.png',
    'gps.webp',
    'gps.gif',
  ];

  group('ImageMetadataStripper (lossless)', () {
    for (final name in geotagged) {
      test('$name: fixture really carries location, output does not', () {
        final input = _fixture(name);
        expect(
          _leakMarkers.any((m) => _containsAscii(input, m)),
          isTrue,
          reason: 'fixture sanity: metadata must be present before stripping',
        );
        final output = ImageMetadataStripper.strip(input)!;
        for (final m in _leakMarkers) {
          expect(_containsAscii(output, m), isFalse, reason: '"$m" leaked');
        }
        expect(output.length, lessThan(input.length));
        // Idempotent: a second pass changes nothing.
        expect(ImageMetadataStripper.strip(output), equals(output));
      });
    }

    test('JPEG: only a one-tag orientation EXIF block remains; ICC kept', () {
      final out = ImageMetadataStripper.strip(_fixture('gps_orient6.jpg'))!;
      final segs = _jpegHeaderSegments(out);
      final app1 = segs.where((s) => s.$1 == 0xE1).toList();
      expect(app1, hasLength(1));
      final exif = app1.single.$2;
      expect(exif.length, 32); // "Exif\0\0" + 26-byte single-entry TIFF
      final bd = ByteData.sublistView(exif, 6);
      expect(bd.getUint16(8), 1); // one IFD entry
      expect(bd.getUint16(10), 0x0112); // Orientation
      expect(bd.getUint16(18), 6);
      expect(segs.any((s) => s.$1 == 0xED), isFalse); // APP13 IPTC
      expect(segs.any((s) => s.$1 == 0xFE), isFalse); // COM
      expect(segs.any((s) => s.$1 == 0xE2), isTrue); // ICC_PROFILE kept
      expect(segs.first.$1, 0xE0); // JFIF still first
    });

    test('JPEG without orientation gets no EXIF block at all', () {
      final out = ImageMetadataStripper.strip(_fixture('gps_progressive.jpg'))!;
      expect(_jpegHeaderSegments(out).any((s) => s.$1 == 0xE1), isFalse);
    });

    test('JPEG: data appended after EOI (secondary image) is dropped', () {
      final out = ImageMetadataStripper.strip(_fixture('gps_trailer.jpg'))!;
      expect(out[out.length - 2], 0xFF);
      expect(out[out.length - 1], 0xD9);
      expect(out, equals(ImageMetadataStripper.strip(_fixture('gps_orient6.jpg'))));
    });

    test('unknown formats are not handled by the lossless path', () {
      expect(ImageMetadataStripper.strip(_fixture('plain.bmp')), isNull);
    });

    test('malformed JPEG throws FormatException', () {
      final truncated = Uint8List.sublistView(_fixture('gps_orient6.jpg'), 0, 300);
      expect(
        () => ImageMetadataStripper.strip(truncated),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('stripped images still decode identically', () {
    for (final name in geotagged) {
      testWidgets('$name: same size, frames and pixels', (tester) async {
        await tester.runAsync(() async {
          final input = _fixture(name);
          final output = await removeImageMetadata(input);
          final a = await _decode(input);
          final b = await _decode(output);
          expect(b.width, a.width);
          expect(b.height, a.height);
          expect(b.frames, a.frames);
          for (var i = 0; i < a.frames; i++) {
            expect(b.rgba[i], equals(a.rgba[i]), reason: 'frame $i pixels');
          }
        });
      });
    }

    testWidgets('PNG transparency survives', (tester) async {
      await tester.runAsync(() async {
        final out = await removeImageMetadata(_fixture('gps_orient8.png'));
        final d = await _decode(out);
        // Pixel (0,0) is outside both drawn shapes: fully transparent.
        expect(d.rgba.first[3], 0);
      });
    });
  });

  group('removeImageMetadata fallback', () {
    testWidgets('unknown format is re-encoded to a metadata-free PNG', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final input = _fixture('plain.bmp');
        final out = await removeImageMetadata(input);
        expect(
          ImageMetadataStripper.detectFormat(out),
          ImageContainerFormat.png,
        );
        final a = await _decode(input);
        final b = await _decode(out);
        expect([b.width, b.height], [a.width, a.height]);
      });
    });

    testWidgets('undecodable bytes throw instead of returning the original', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final truncated = Uint8List.sublistView(
          _fixture('gps_orient6.jpg'),
          0,
          300,
        );
        await expectLater(
          removeImageMetadata(truncated),
          throwsA(isA<ImageMetadataRemovalException>()),
        );
      });
    });
  });
}
