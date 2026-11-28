import 'dart:typed_data';

/// Lossless removal of embedded metadata (EXIF incl. GPS coordinates, XMP,
/// IPTC, comments, text chunks, trailing data) from image bytes, without
/// re-encoding pixels — quality, transparency and animation are untouched.
///
/// Pure Dart (no Flutter imports) so it can run anywhere. App code should
/// call `removeImageMetadata` (image_privacy.dart), which also handles
/// formats this file doesn't parse.
///
/// The only metadata kept is the EXIF Orientation value (written back as a
/// minimal one-tag EXIF block), because image_picker leaves rotation in that
/// tag rather than in the pixels — dropping it would display photos rotated.
/// Colour data needed to render correctly (JPEG JFIF/ICC/Adobe, PNG colour
/// chunks) is kept.
abstract final class ImageMetadataStripper {
  /// Returns the stripped bytes, or null when [bytes] is not a JPEG, PNG,
  /// WebP or GIF. Throws [FormatException] for a malformed file of one of
  /// those formats.
  static Uint8List? strip(Uint8List bytes) {
    switch (detectFormat(bytes)) {
      case ImageContainerFormat.jpeg:
        return _stripJpeg(bytes);
      case ImageContainerFormat.png:
        return _stripPng(bytes);
      case ImageContainerFormat.webp:
        return _stripWebp(bytes);
      case ImageContainerFormat.gif:
        return _stripGif(bytes);
      case ImageContainerFormat.unknown:
        return null;
    }
  }

  static ImageContainerFormat detectFormat(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return ImageContainerFormat.jpeg;
    }
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47 &&
        b[4] == 0x0D &&
        b[5] == 0x0A &&
        b[6] == 0x1A &&
        b[7] == 0x0A) {
      return ImageContainerFormat.png;
    }
    if (b.length >= 12 &&
        _ascii(b, 0, 'RIFF') &&
        _ascii(b, 8, 'WEBP')) {
      return ImageContainerFormat.webp;
    }
    if (b.length >= 6 && (_ascii(b, 0, 'GIF87a') || _ascii(b, 0, 'GIF89a'))) {
      return ImageContainerFormat.gif;
    }
    return ImageContainerFormat.unknown;
  }

  // ── JPEG ────────────────────────────────────────────────────────────────

  static Uint8List _stripJpeg(Uint8List b) {
    final n = b.length;
    // Kept segments after SOI, with their marker so the orientation block
    // can be placed after any leading APP0 (JFIF must stay first).
    final kept = <(int, Uint8List)>[];
    int? orientation;
    var pos = 2;
    var sawEoi = false;

    while (pos < n) {
      if (b[pos] != 0xFF) {
        throw const FormatException('JPEG: expected marker');
      }
      var p = pos + 1;
      while (p < n && b[p] == 0xFF) {
        p++; // fill bytes
      }
      if (p >= n) throw const FormatException('JPEG: truncated marker');
      final m = b[p];
      final afterMarker = p + 1;

      if (m == 0xD9) {
        kept.add((m, Uint8List.fromList(const [0xFF, 0xD9])));
        sawEoi = true;
        break; // anything after EOI (MPF/secondary images, trailers) is dropped
      }
      if (m == 0x01 || (m >= 0xD0 && m <= 0xD7)) {
        kept.add((m, Uint8List.fromList([0xFF, m])));
        pos = afterMarker;
        continue;
      }
      if (afterMarker + 2 > n) throw const FormatException('JPEG: truncated');
      final len = (b[afterMarker] << 8) | b[afterMarker + 1];
      final end = afterMarker + len;
      if (len < 2 || end > n) throw const FormatException('JPEG: bad length');
      final payload = Uint8List.sublistView(b, afterMarker + 2, end);

      var keep = true;
      if (m == 0xE1) {
        // APP1: EXIF (GPS lives here) or XMP — always dropped.
        if (_ascii(payload, 0, 'Exif\u0000\u0000')) {
          orientation ??= _readTiffOrientation(payload, 6);
        }
        keep = false;
      } else if (m == 0xE0) {
        keep = _ascii(payload, 0, 'JFIF\u0000') || _ascii(payload, 0, 'JFXX\u0000');
      } else if (m == 0xE2) {
        keep = _ascii(payload, 0, 'ICC_PROFILE\u0000');
      } else if (m == 0xEE) {
        keep = _ascii(payload, 0, 'Adobe');
      } else if ((m >= 0xE3 && m <= 0xEF) || m == 0xFE) {
        keep = false; // other APPn (incl. APP13 IPTC/Photoshop) and comments
      }
      if (keep) {
        final seg = Uint8List(2 + len)
          ..[0] = 0xFF
          ..[1] = m
          ..setRange(2, 2 + len, b, afterMarker);
        kept.add((m, seg));
      }
      pos = end;

      if (m == 0xDA) {
        // Start of scan: copy entropy-coded data up to the next real marker.
        var q = pos;
        while (true) {
          if (q + 1 >= n) throw const FormatException('JPEG: unterminated scan');
          if (b[q] == 0xFF) {
            final next = b[q + 1];
            if (next == 0x00 || (next >= 0xD0 && next <= 0xD7)) {
              q += 2;
              continue;
            }
            break;
          }
          q++;
        }
        kept.add((-1, Uint8List.sublistView(b, pos, q)));
        pos = q;
      }
    }
    if (!sawEoi) throw const FormatException('JPEG: missing EOI');

    final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
    var orientationWritten = !_isRotated(orientation);
    for (final (marker, seg) in kept) {
      if (!orientationWritten && marker != 0xE0) {
        final tiff = _minimalOrientationTiff(orientation!);
        final len = 2 + 6 + tiff.length;
        out
          ..add([0xFF, 0xE1, len >> 8, len & 0xFF])
          ..add('Exif\u0000\u0000'.codeUnits)
          ..add(tiff);
        orientationWritten = true;
      }
      out.add(seg);
    }
    return out.toBytes();
  }

  // ── PNG ─────────────────────────────────────────────────────────────────

  static const _pngMetadataChunks = {'eXIf', 'tEXt', 'zTXt', 'iTXt', 'tIME'};

  static Uint8List _stripPng(Uint8List b) {
    final n = b.length;
    final chunks = <(String, Uint8List)>[];
    int? orientation;
    var pos = 8;
    var sawEnd = false;
    while (pos + 12 <= n) {
      final len = _u32be(b, pos);
      final type = String.fromCharCodes(b, pos + 4, pos + 8);
      final end = pos + 12 + len;
      if (len > n || end > n) throw const FormatException('PNG: bad chunk');
      if (type == 'eXIf') {
        final data = Uint8List.sublistView(b, pos + 8, pos + 8 + len);
        orientation ??= _ascii(data, 0, 'Exif\u0000\u0000')
            ? _readTiffOrientation(data, 6)
            : _readTiffOrientation(data, 0);
      }
      if (!_pngMetadataChunks.contains(type)) {
        chunks.add((type, Uint8List.sublistView(b, pos, end)));
      }
      pos = end;
      if (type == 'IEND') {
        sawEnd = true;
        break; // trailing data dropped
      }
    }
    if (!sawEnd) throw const FormatException('PNG: missing IEND');

    final out = BytesBuilder(copy: false)..add(Uint8List.sublistView(b, 0, 8));
    var orientationWritten = !_isRotated(orientation);
    for (final (type, chunk) in chunks) {
      if (!orientationWritten && type == 'IDAT') {
        out.add(_pngChunk('eXIf', _minimalOrientationTiff(orientation!)));
        orientationWritten = true;
      }
      out.add(chunk);
    }
    return out.toBytes();
  }

  static Uint8List _pngChunk(String type, Uint8List data) {
    final typeBytes = Uint8List.fromList(type.codeUnits);
    final crcInput = Uint8List(4 + data.length)
      ..setRange(0, 4, typeBytes)
      ..setRange(4, 4 + data.length, data);
    final out = ByteData(12 + data.length)
      ..setUint32(0, data.length)
      ..setUint32(8 + data.length, _crc32(crcInput));
    final bytes = out.buffer.asUint8List()
      ..setRange(4, 8, typeBytes)
      ..setRange(8, 8 + data.length, data);
    return bytes;
  }

  // ── WebP ────────────────────────────────────────────────────────────────

  static Uint8List _stripWebp(Uint8List b) {
    final riffEnd = 8 + _u32le(b, 4);
    if (riffEnd > b.length || riffEnd < 12) {
      throw const FormatException('WebP: bad RIFF size');
    }
    final chunks = <(String, Uint8List)>[];
    int? orientation;
    var pos = 12;
    while (pos + 8 <= riffEnd) {
      final fourcc = String.fromCharCodes(b, pos, pos + 4);
      final size = _u32le(b, pos + 4);
      final padded = size + (size & 1);
      final end = pos + 8 + padded;
      if (pos + 8 + size > riffEnd) throw const FormatException('WebP: bad chunk');
      if (fourcc == 'EXIF') {
        final data = Uint8List.sublistView(b, pos + 8, pos + 8 + size);
        orientation ??= _ascii(data, 0, 'Exif\u0000\u0000')
            ? _readTiffOrientation(data, 6)
            : _readTiffOrientation(data, 0);
      } else if (fourcc != 'XMP ') {
        chunks.add((
          fourcc,
          Uint8List.fromList(
            Uint8List.sublistView(b, pos, end > riffEnd ? riffEnd : end),
          ),
        ));
      }
      pos = end;
    }

    final hasVp8x = chunks.isNotEmpty && chunks.first.$1 == 'VP8X';
    final writeOrientation = hasVp8x && _isRotated(orientation);
    if (hasVp8x) {
      final vp8x = chunks.first.$2;
      vp8x[8] &= ~0x0C; // clear EXIF (0x08) and XMP (0x04) flags
      if (writeOrientation) vp8x[8] |= 0x08;
    }
    final body = BytesBuilder(copy: false);
    for (final (_, chunk) in chunks) {
      body.add(chunk);
    }
    if (writeOrientation) {
      final tiff = _minimalOrientationTiff(orientation!);
      final header = ByteData(8)..setUint32(4, tiff.length, Endian.little);
      final h = header.buffer.asUint8List()..setRange(0, 4, 'EXIF'.codeUnits);
      body
        ..add(h)
        ..add(tiff);
      if (tiff.length.isOdd) body.addByte(0);
    }
    final bodyBytes = body.toBytes();
    final head = ByteData(12)..setUint32(4, 4 + bodyBytes.length, Endian.little);
    final headBytes = head.buffer.asUint8List()
      ..setRange(0, 4, 'RIFF'.codeUnits)
      ..setRange(8, 12, 'WEBP'.codeUnits);
    return (BytesBuilder(copy: false)
          ..add(headBytes)
          ..add(bodyBytes))
        .toBytes();
  }

  // ── GIF ─────────────────────────────────────────────────────────────────

  static Uint8List _stripGif(Uint8List b) {
    final n = b.length;
    if (n < 13) throw const FormatException('GIF: truncated header');
    var pos = 13;
    final packed = b[10];
    if (packed & 0x80 != 0) pos += 3 * (1 << ((packed & 0x07) + 1));
    if (pos > n) throw const FormatException('GIF: truncated color table');
    final out = BytesBuilder(copy: false)..add(Uint8List.sublistView(b, 0, pos));

    int skipSubBlocks(int p) {
      while (true) {
        if (p >= n) throw const FormatException('GIF: truncated sub-blocks');
        final size = b[p];
        p += 1 + size;
        if (size == 0) return p;
      }
    }

    while (true) {
      if (pos >= n) throw const FormatException('GIF: missing trailer');
      final introducer = b[pos];
      if (introducer == 0x3B) {
        out.addByte(0x3B);
        break; // trailing data dropped
      } else if (introducer == 0x21) {
        if (pos + 2 > n) throw const FormatException('GIF: truncated extension');
        final label = b[pos + 1];
        final end = skipSubBlocks(pos + 2);
        var keep = label == 0xF9 || label == 0x01; // graphic control, plain text
        if (label == 0xFF) {
          // Application extension: keep only the animation loop blocks;
          // drop XMP ("XMP DataXMP") and anything else.
          final idLen = b[pos + 2];
          final id = idLen == 11 && pos + 14 <= n
              ? String.fromCharCodes(b, pos + 3, pos + 14)
              : '';
          keep = id == 'NETSCAPE2.0' || id == 'ANIMEXTS1.0';
        }
        // 0xFE comment and unknown extensions are dropped.
        if (keep) out.add(Uint8List.sublistView(b, pos, end));
        pos = end;
      } else if (introducer == 0x2C) {
        if (pos + 10 > n) throw const FormatException('GIF: truncated image');
        var p = pos + 10;
        final imgPacked = b[pos + 9];
        if (imgPacked & 0x80 != 0) p += 3 * (1 << ((imgPacked & 0x07) + 1));
        p += 1; // LZW minimum code size
        final end = skipSubBlocks(p);
        out.add(Uint8List.sublistView(b, pos, end));
        pos = end;
      } else {
        throw const FormatException('GIF: unknown block');
      }
    }
    return out.toBytes();
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  static bool _isRotated(int? orientation) =>
      orientation != null && orientation >= 2 && orientation <= 8;

  /// Reads IFD0 Orientation (0x0112) from a TIFF structure starting at
  /// [start] in [d]. Returns null if absent or unreadable.
  static int? _readTiffOrientation(Uint8List d, int start) {
    try {
      if (d.length < start + 8) return null;
      final bool little;
      if (d[start] == 0x49 && d[start + 1] == 0x49) {
        little = true;
      } else if (d[start] == 0x4D && d[start + 1] == 0x4D) {
        little = false;
      } else {
        return null;
      }
      final bd = ByteData.sublistView(d, start);
      final endian = little ? Endian.little : Endian.big;
      final ifd = bd.getUint32(4, endian);
      if (ifd + 2 > bd.lengthInBytes) return null;
      final count = bd.getUint16(ifd, endian);
      for (var i = 0; i < count; i++) {
        final e = ifd + 2 + i * 12;
        if (e + 12 > bd.lengthInBytes) return null;
        if (bd.getUint16(e, endian) == 0x0112 &&
            bd.getUint16(e + 2, endian) == 3) {
          return bd.getUint16(e + 8, endian);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Big-endian TIFF with a single IFD0 entry: Orientation = [value].
  static Uint8List _minimalOrientationTiff(int value) {
    final d = ByteData(26)
      ..setUint8(0, 0x4D)
      ..setUint8(1, 0x4D)
      ..setUint16(2, 42)
      ..setUint32(4, 8)
      ..setUint16(8, 1) // one entry
      ..setUint16(10, 0x0112) // Orientation
      ..setUint16(12, 3) // SHORT
      ..setUint32(14, 1) // count
      ..setUint16(18, value)
      ..setUint32(22, 0); // no next IFD
    return d.buffer.asUint8List();
  }

  static bool _ascii(Uint8List d, int at, String s) {
    if (d.length < at + s.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (d[at + i] != s.codeUnitAt(i)) return false;
    }
    return true;
  }

  static int _u32be(Uint8List d, int at) =>
      (d[at] << 24) | (d[at + 1] << 16) | (d[at + 2] << 8) | d[at + 3];

  static int _u32le(Uint8List d, int at) =>
      d[at] | (d[at + 1] << 8) | (d[at + 2] << 16) | (d[at + 3] << 24);

  static final List<int> _crcTable = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  static int _crc32(Uint8List data) {
    var c = 0xFFFFFFFF;
    for (final byte in data) {
      c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
    }
    return c ^ 0xFFFFFFFF;
  }
}

enum ImageContainerFormat { jpeg, png, webp, gif, unknown }
