// // // // // // // import 'dart:convert';
// // // // // // // import 'package:flutter/material.dart';
// // // // // // // import 'package:provider/provider.dart';
// // // // // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // // import '../../../core/extensions/context_ext.dart';
// // // // // // // import '../../../core/providers/auth_provider.dart';
// // // // // // // import '../../../core/router/route_names.dart';
// // // // // // // import '../../../core/router/app_router.dart';

// // // // // // // // ── Avatar data model ─────────────────────────────────────────────────────────

// // // // // // // class AvatarConfig {
// // // // // // //   const AvatarConfig({
// // // // // // //     this.skinTone = 0,
// // // // // // //     this.hairStyle = 0,
// // // // // // //     this.hairColor = 0,
// // // // // // //     this.eyeStyle = 0,
// // // // // // //     this.browStyle = 0,
// // // // // // //     this.mouthStyle = 0,
// // // // // // //     this.outfit = 0,
// // // // // // //     this.accessory = 0,
// // // // // // //     this.bgColor = 0,
// // // // // // //   });

// // // // // // //   final int skinTone,
// // // // // // //       hairStyle,
// // // // // // //       hairColor,
// // // // // // //       eyeStyle,
// // // // // // //       browStyle,
// // // // // // //       mouthStyle,
// // // // // // //       outfit,
// // // // // // //       accessory,
// // // // // // //       bgColor;

// // // // // // //   AvatarConfig copyWith({
// // // // // // //     int? skinTone,
// // // // // // //     int? hairStyle,
// // // // // // //     int? hairColor,
// // // // // // //     int? eyeStyle,
// // // // // // //     int? browStyle,
// // // // // // //     int? mouthStyle,
// // // // // // //     int? outfit,
// // // // // // //     int? accessory,
// // // // // // //     int? bgColor,
// // // // // // //   }) => AvatarConfig(
// // // // // // //     skinTone: skinTone ?? this.skinTone,
// // // // // // //     hairStyle: hairStyle ?? this.hairStyle,
// // // // // // //     hairColor: hairColor ?? this.hairColor,
// // // // // // //     eyeStyle: eyeStyle ?? this.eyeStyle,
// // // // // // //     browStyle: browStyle ?? this.browStyle,
// // // // // // //     mouthStyle: mouthStyle ?? this.mouthStyle,
// // // // // // //     outfit: outfit ?? this.outfit,
// // // // // // //     accessory: accessory ?? this.accessory,
// // // // // // //     bgColor: bgColor ?? this.bgColor,
// // // // // // //   );

// // // // // // //   Map<String, int> toMap() => {
// // // // // // //     'skinTone': skinTone,
// // // // // // //     'hairStyle': hairStyle,
// // // // // // //     'hairColor': hairColor,
// // // // // // //     'eyeStyle': eyeStyle,
// // // // // // //     'browStyle': browStyle,
// // // // // // //     'mouthStyle': mouthStyle,
// // // // // // //     'outfit': outfit,
// // // // // // //     'accessory': accessory,
// // // // // // //     'bgColor': bgColor,
// // // // // // //   };

// // // // // // //   factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
// // // // // // //     skinTone: m['skinTone'] as int? ?? 0,
// // // // // // //     hairStyle: m['hairStyle'] as int? ?? 0,
// // // // // // //     hairColor: m['hairColor'] as int? ?? 0,
// // // // // // //     eyeStyle: m['eyeStyle'] as int? ?? 0,
// // // // // // //     browStyle: m['browStyle'] as int? ?? 0,
// // // // // // //     mouthStyle: m['mouthStyle'] as int? ?? 0,
// // // // // // //     outfit: m['outfit'] as int? ?? 0,
// // // // // // //     accessory: m['accessory'] as int? ?? 0,
// // // // // // //     bgColor: m['bgColor'] as int? ?? 0,
// // // // // // //   );

// // // // // // //   static AvatarConfig get defaultConfig => const AvatarConfig();
// // // // // // // }

// // // // // // // // ── Avatar Service ────────────────────────────────────────────────────────────

// // // // // // // class AvatarService extends ChangeNotifier {
// // // // // // //   AvatarService._();
// // // // // // //   static final AvatarService instance = AvatarService._();

// // // // // // //   static const _prefKey = 'avatar_config_v1';

// // // // // // //   AvatarConfig _config = AvatarConfig.defaultConfig;
// // // // // // //   AvatarConfig get config => _config;

// // // // // // //   Future<void> load() async {
// // // // // // //     final prefs = await SharedPreferences.getInstance();
// // // // // // //     final raw = prefs.getString(_prefKey);
// // // // // // //     if (raw != null) {
// // // // // // //       try {
// // // // // // //         _config = AvatarConfig.fromMap(jsonDecode(raw) as Map<String, dynamic>);
// // // // // // //       } catch (_) {}
// // // // // // //     }
// // // // // // //     notifyListeners();
// // // // // // //   }

// // // // // // //   Future<void> save(AvatarConfig cfg) async {
// // // // // // //     _config = cfg;
// // // // // // //     final prefs = await SharedPreferences.getInstance();
// // // // // // //     await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
// // // // // // //     final uid = Supabase.instance.client.auth.currentUser?.id;
// // // // // // //     if (uid != null) {
// // // // // // //       await Supabase.instance.client
// // // // // // //           .from('profiles')
// // // // // // //           .update({'avatar_config': cfg.toMap()})
// // // // // // //           .eq('id', uid)
// // // // // // //           .catchError((_) {});
// // // // // // //     }
// // // // // // //     notifyListeners();
// // // // // // //   }
// // // // // // // }

// // // // // // // // ── Avatar Painter ────────────────────────────────────────────────────────────

// // // // // // // class AvatarPainter extends CustomPainter {
// // // // // // //   const AvatarPainter(this.config, {this.small = false});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final bool small;

// // // // // // //   static const _skinTones = [
// // // // // // //     Color(0xFFFFDBAC),
// // // // // // //     Color(0xFFF5CBA7),
// // // // // // //     Color(0xFFE8A87C),
// // // // // // //     Color(0xFFD4845A),
// // // // // // //     Color(0xFFA0522D),
// // // // // // //     Color(0xFF6F3A24),
// // // // // // //   ];
// // // // // // //   static const _hairColors = [
// // // // // // //     Color(0xFF2C1B0E),
// // // // // // //     Color(0xFF5C3317),
// // // // // // //     Color(0xFFA0522D),
// // // // // // //     Color(0xFFDAA520),
// // // // // // //     Color(0xFFFF4500),
// // // // // // //     Color(0xFF808080),
// // // // // // //     Color(0xFFFFFFFF),
// // // // // // //     Color(0xFF4B0082),
// // // // // // //     Color(0xFF00CED1),
// // // // // // //   ];
// // // // // // //   static const _bgColors = [
// // // // // // //     Color(0xFF6C63FF),
// // // // // // //     Color(0xFFF5A623),
// // // // // // //     Color(0xFF2ECC71),
// // // // // // //     Color(0xFFE91E63),
// // // // // // //     Color(0xFF00BCD4),
// // // // // // //     Color(0xFFFF5722),
// // // // // // //     Color(0xFF9C27B0),
// // // // // // //     Color(0xFF607D8B),
// // // // // // //     Color(0xFF1A1A2E),
// // // // // // //   ];

// // // // // // //   @override
// // // // // // //   void paint(Canvas canvas, Size size) {
// // // // // // //     final cx = size.width / 2;
// // // // // // //     final cy = size.height / 2;
// // // // // // //     final r = size.width * 0.45;

// // // // // // //     final bgPaint = Paint()
// // // // // // //       ..color = _bgColors[config.bgColor % _bgColors.length];
// // // // // // //     canvas.drawCircle(Offset(cx, cy), size.width / 2, bgPaint);

// // // // // // //     final skin = _skinTones[config.skinTone % _skinTones.length];
// // // // // // //     final skinPaint = Paint()..color = skin;

// // // // // // //     // Neck
// // // // // // //     canvas.drawRRect(
// // // // // // //       RRect.fromRectAndRadius(
// // // // // // //         Rect.fromCenter(
// // // // // // //           center: Offset(cx, cy + r * 0.7),
// // // // // // //           width: r * 0.38,
// // // // // // //           height: r * 0.35,
// // // // // // //         ),
// // // // // // //         const Radius.circular(6),
// // // // // // //       ),
// // // // // // //       skinPaint,
// // // // // // //     );

// // // // // // //     // Face
// // // // // // //     canvas.drawOval(
// // // // // // //       Rect.fromCenter(
// // // // // // //         center: Offset(cx, cy + r * 0.05),
// // // // // // //         width: r * 1.1,
// // // // // // //         height: r * 1.3,
// // // // // // //       ),
// // // // // // //       skinPaint,
// // // // // // //     );

// // // // // // //     // Hair base
// // // // // // //     final hairPaint = Paint()
// // // // // // //       ..color = _hairColors[config.hairColor % _hairColors.length];
// // // // // // //     _drawHair(canvas, cx, cy, r, hairPaint, config.hairStyle % 4);

// // // // // // //     // Eyes
// // // // // // //     _drawEyes(canvas, cx, cy, r, config.eyeStyle % 3);

// // // // // // //     // Eyebrows
// // // // // // //     _drawBrows(canvas, cx, cy, r, hairPaint, config.browStyle % 3);

// // // // // // //     // Mouth
// // // // // // //     _drawMouth(canvas, cx, cy, r, config.mouthStyle % 4);

// // // // // // //     // Nose
// // // // // // //     final nosePaint = Paint()
// // // // // // //       ..color = skin.withAlpha(180)
// // // // // // //       ..style = PaintingStyle.stroke
// // // // // // //       ..strokeWidth = 1.5
// // // // // // //       ..strokeCap = StrokeCap.round;
// // // // // // //     final nosePath = Path()
// // // // // // //       ..moveTo(cx - r * 0.04, cy + r * 0.15)
// // // // // // //       ..quadraticBezierTo(cx - r * 0.12, cy + r * 0.3, cx, cy + r * 0.32)
// // // // // // //       ..quadraticBezierTo(
// // // // // // //         cx + r * 0.12,
// // // // // // //         cy + r * 0.3,
// // // // // // //         cx + r * 0.04,
// // // // // // //         cy + r * 0.15,
// // // // // // //       );
// // // // // // //     canvas.drawPath(nosePath, nosePaint);

// // // // // // //     // Outfit
// // // // // // //     _drawOutfit(canvas, cx, cy, r, size, config.outfit % 4);

// // // // // // //     // Accessory
// // // // // // //     if (config.accessory > 0) {
// // // // // // //       _drawAccessory(canvas, cx, cy, r, config.accessory % 4);
// // // // // // //     }

// // // // // // //     // Clip to circle
// // // // // // //     final clipPaint = Paint()
// // // // // // //       ..color = Colors.transparent
// // // // // // //       ..blendMode = BlendMode.clear;
// // // // // // //     final clipPath = Path()
// // // // // // //       ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
// // // // // // //       ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: size.width / 2))
// // // // // // //       ..fillType = PathFillType.evenOdd;
// // // // // // //     canvas.drawPath(clipPath, clipPaint);
// // // // // // //   }

// // // // // // //   void _drawHair(
// // // // // // //     Canvas canvas,
// // // // // // //     double cx,
// // // // // // //     double cy,
// // // // // // //     double r,
// // // // // // //     Paint p,
// // // // // // //     int style,
// // // // // // //   ) {
// // // // // // //     switch (style) {
// // // // // // //       case 0: // Short round
// // // // // // //         canvas.drawOval(
// // // // // // //           Rect.fromCenter(
// // // // // // //             center: Offset(cx, cy - r * 0.35),
// // // // // // //             width: r * 1.15,
// // // // // // //             height: r * 0.85,
// // // // // // //           ),
// // // // // // //           p,
// // // // // // //         );
// // // // // // //       case 1: // Long
// // // // // // //         canvas.drawOval(
// // // // // // //           Rect.fromCenter(
// // // // // // //             center: Offset(cx, cy - r * 0.35),
// // // // // // //             width: r * 1.15,
// // // // // // //             height: r * 0.85,
// // // // // // //           ),
// // // // // // //           p,
// // // // // // //         );
// // // // // // //         canvas.drawRRect(
// // // // // // //           RRect.fromRectAndRadius(
// // // // // // //             Rect.fromCenter(
// // // // // // //               center: Offset(cx - r * 0.5, cy + r * 0.3),
// // // // // // //               width: r * 0.16,
// // // // // // //               height: r * 0.9,
// // // // // // //             ),
// // // // // // //             const Radius.circular(8),
// // // // // // //           ),
// // // // // // //           p,
// // // // // // //         );
// // // // // // //         canvas.drawRRect(
// // // // // // //           RRect.fromRectAndRadius(
// // // // // // //             Rect.fromCenter(
// // // // // // //               center: Offset(cx + r * 0.5, cy + r * 0.3),
// // // // // // //               width: r * 0.16,
// // // // // // //               height: r * 0.9,
// // // // // // //             ),
// // // // // // //             const Radius.circular(8),
// // // // // // //           ),
// // // // // // //           p,
// // // // // // //         );
// // // // // // //       case 2: // Spiky
// // // // // // //         for (var i = 0; i < 5; i++) {
// // // // // // //           final x = cx - r * 0.5 + i * r * 0.25;
// // // // // // //           final path = Path()
// // // // // // //             ..moveTo(x, cy - r * 0.25)
// // // // // // //             ..lineTo(x + r * 0.12, cy - r * 0.7)
// // // // // // //             ..lineTo(x + r * 0.24, cy - r * 0.25)
// // // // // // //             ..close();
// // // // // // //           canvas.drawPath(path, p);
// // // // // // //         }
// // // // // // //         canvas.drawOval(
// // // // // // //           Rect.fromCenter(
// // // // // // //             center: Offset(cx, cy - r * 0.2),
// // // // // // //             width: r * 1.1,
// // // // // // //             height: r * 0.5,
// // // // // // //           ),
// // // // // // //           p,
// // // // // // //         );
// // // // // // //       default: // Curly
// // // // // // //         for (var i = 0; i < 7; i++) {
// // // // // // //           final angle = (i / 7) * 3.14159;
// // // // // // //           final bx = cx + r * 0.55 * (i % 2 == 0 ? -1 : 1) * (0.5 + (i / 14));
// // // // // // //           canvas.drawCircle(
// // // // // // //             Offset(cx - r * 0.5 + i * r * 0.17, cy - r * 0.45),
// // // // // // //             r * 0.22,
// // // // // // //             p,
// // // // // // //           );
// // // // // // //         }
// // // // // // //     }
// // // // // // //   }

// // // // // // //   void _drawEyes(Canvas canvas, double cx, double cy, double r, int style) {
// // // // // // //     final white = Paint()..color = Colors.white;
// // // // // // //     final dark = Paint()..color = const Color(0xFF2C1B0E);
// // // // // // //     final highlight = Paint()..color = Colors.white;
// // // // // // //     for (final side in [-1, 1]) {
// // // // // // //       final ex = cx + side * r * 0.27;
// // // // // // //       final ey = cy - r * 0.05;
// // // // // // //       canvas.drawOval(
// // // // // // //         Rect.fromCenter(
// // // // // // //           center: Offset(ex, ey),
// // // // // // //           width: r * 0.28,
// // // // // // //           height: r * 0.22,
// // // // // // //         ),
// // // // // // //         white,
// // // // // // //       );
// // // // // // //       switch (style) {
// // // // // // //         case 0:
// // // // // // //           canvas.drawCircle(Offset(ex, ey), r * 0.1, dark);
// // // // // // //           canvas.drawCircle(
// // // // // // //             Offset(ex + r * 0.03, ey - r * 0.03),
// // // // // // //             r * 0.03,
// // // // // // //             highlight,
// // // // // // //           );
// // // // // // //         case 1: // Happy squint
// // // // // // //           final p = Paint()
// // // // // // //             ..color = const Color(0xFF2C1B0E)
// // // // // // //             ..style = PaintingStyle.stroke
// // // // // // //             ..strokeWidth = 2.5
// // // // // // //             ..strokeCap = StrokeCap.round;
// // // // // // //           canvas.drawArc(
// // // // // // //             Rect.fromCenter(
// // // // // // //               center: Offset(ex, ey + r * 0.04),
// // // // // // //               width: r * 0.22,
// // // // // // //               height: r * 0.18,
// // // // // // //             ),
// // // // // // //             3.14,
// // // // // // //             3.14,
// // // // // // //             false,
// // // // // // //             p,
// // // // // // //           );
// // // // // // //         default:
// // // // // // //           canvas.drawOval(
// // // // // // //             Rect.fromCenter(
// // // // // // //               center: Offset(ex, ey),
// // // // // // //               width: r * 0.12,
// // // // // // //               height: r * 0.16,
// // // // // // //             ),
// // // // // // //             dark,
// // // // // // //           );
// // // // // // //           canvas.drawCircle(
// // // // // // //             Offset(ex + r * 0.03, ey - r * 0.04),
// // // // // // //             r * 0.03,
// // // // // // //             highlight,
// // // // // // //           );
// // // // // // //       }
// // // // // // //     }
// // // // // // //   }

// // // // // // //   void _drawBrows(
// // // // // // //     Canvas canvas,
// // // // // // //     double cx,
// // // // // // //     double cy,
// // // // // // //     double r,
// // // // // // //     Paint p,
// // // // // // //     int style,
// // // // // // //   ) {
// // // // // // //     final bp = Paint()
// // // // // // //       ..color = p.color
// // // // // // //       ..style = PaintingStyle.stroke
// // // // // // //       ..strokeWidth = 3
// // // // // // //       ..strokeCap = StrokeCap.round;
// // // // // // //     for (final side in [-1, 1]) {
// // // // // // //       final bx = cx + side * r * 0.27;
// // // // // // //       final by = cy - r * 0.22;
// // // // // // //       switch (style) {
// // // // // // //         case 0:
// // // // // // //           canvas.drawLine(
// // // // // // //             Offset(bx - r * 0.1, by),
// // // // // // //             Offset(bx + r * 0.1, by),
// // // // // // //             bp,
// // // // // // //           );
// // // // // // //         case 1:
// // // // // // //           canvas.drawLine(
// // // // // // //             Offset(bx - r * 0.1, by + r * 0.03 * side),
// // // // // // //             Offset(bx + r * 0.1, by - r * 0.03 * side),
// // // // // // //             bp,
// // // // // // //           );
// // // // // // //         default:
// // // // // // //           final path = Path()
// // // // // // //             ..moveTo(bx - r * 0.1, by + r * 0.03)
// // // // // // //             ..quadraticBezierTo(bx, by - r * 0.05, bx + r * 0.1, by + r * 0.03);
// // // // // // //           canvas.drawPath(path, bp);
// // // // // // //       }
// // // // // // //     }
// // // // // // //   }

// // // // // // //   void _drawMouth(Canvas canvas, double cx, double cy, double r, int style) {
// // // // // // //     final mp = Paint()
// // // // // // //       ..color = const Color(0xFFCC4444)
// // // // // // //       ..style = PaintingStyle.stroke
// // // // // // //       ..strokeWidth = 2.5
// // // // // // //       ..strokeCap = StrokeCap.round;
// // // // // // //     switch (style) {
// // // // // // //       case 0: // Smile
// // // // // // //         canvas.drawArc(
// // // // // // //           Rect.fromCenter(
// // // // // // //             center: Offset(cx, cy + r * 0.36),
// // // // // // //             width: r * 0.42,
// // // // // // //             height: r * 0.25,
// // // // // // //           ),
// // // // // // //           0,
// // // // // // //           3.14,
// // // // // // //           false,
// // // // // // //           mp,
// // // // // // //         );
// // // // // // //       case 1: // Big smile with teeth
// // // // // // //         final tp = Paint()..color = Colors.white;
// // // // // // //         canvas.drawOval(
// // // // // // //           Rect.fromCenter(
// // // // // // //             center: Offset(cx, cy + r * 0.42),
// // // // // // //             width: r * 0.42,
// // // // // // //             height: r * 0.18,
// // // // // // //           ),
// // // // // // //           tp,
// // // // // // //         );
// // // // // // //         canvas.drawArc(
// // // // // // //           Rect.fromCenter(
// // // // // // //             center: Offset(cx, cy + r * 0.36),
// // // // // // //             width: r * 0.5,
// // // // // // //             height: r * 0.3,
// // // // // // //           ),
// // // // // // //           0,
// // // // // // //           3.14,
// // // // // // //           false,
// // // // // // //           mp
// // // // // // //             ..color = const Color(0xFF8B2020)
// // // // // // //             ..strokeWidth = 3,
// // // // // // //         );
// // // // // // //       case 2: // Neutral
// // // // // // //         canvas.drawLine(
// // // // // // //           Offset(cx - r * 0.15, cy + r * 0.42),
// // // // // // //           Offset(cx + r * 0.15, cy + r * 0.42),
// // // // // // //           mp,
// // // // // // //         );
// // // // // // //       default: // Smirk
// // // // // // //         canvas.drawArc(
// // // // // // //           Rect.fromCenter(
// // // // // // //             center: Offset(cx + r * 0.08, cy + r * 0.4),
// // // // // // //             width: r * 0.28,
// // // // // // //             height: r * 0.18,
// // // // // // //           ),
// // // // // // //           0,
// // // // // // //           3.14,
// // // // // // //           false,
// // // // // // //           mp,
// // // // // // //         );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   void _drawOutfit(
// // // // // // //     Canvas canvas,
// // // // // // //     double cx,
// // // // // // //     double cy,
// // // // // // //     double r,
// // // // // // //     Size size,
// // // // // // //     int style,
// // // // // // //   ) {
// // // // // // //     final colors = [
// // // // // // //       const Color(0xFF3498DB),
// // // // // // //       const Color(0xFFE74C3C),
// // // // // // //       const Color(0xFF2ECC71),
// // // // // // //       const Color(0xFF9B59B6),
// // // // // // //     ];
// // // // // // //     final op = Paint()..color = colors[style % colors.length];
// // // // // // //     final neckBottom = cy + r * 0.65;
// // // // // // //     canvas.drawRRect(
// // // // // // //       RRect.fromRectAndRadius(
// // // // // // //         Rect.fromLTWH(
// // // // // // //           cx - r * 0.7,
// // // // // // //           neckBottom,
// // // // // // //           r * 1.4,
// // // // // // //           size.height - neckBottom + 4,
// // // // // // //         ),
// // // // // // //         const Radius.circular(4),
// // // // // // //       ),
// // // // // // //       op,
// // // // // // //     );
// // // // // // //   }

// // // // // // //   void _drawAccessory(
// // // // // // //     Canvas canvas,
// // // // // // //     double cx,
// // // // // // //     double cy,
// // // // // // //     double r,
// // // // // // //     int style,
// // // // // // //   ) {
// // // // // // //     switch (style) {
// // // // // // //       case 1: // Glasses
// // // // // // //         final gp = Paint()
// // // // // // //           ..color = const Color(0xFF333333)
// // // // // // //           ..style = PaintingStyle.stroke
// // // // // // //           ..strokeWidth = 2;
// // // // // // //         canvas.drawCircle(Offset(cx - r * 0.27, cy - r * 0.05), r * 0.15, gp);
// // // // // // //         canvas.drawCircle(Offset(cx + r * 0.27, cy - r * 0.05), r * 0.15, gp);
// // // // // // //         canvas.drawLine(
// // // // // // //           Offset(cx - r * 0.12, cy - r * 0.05),
// // // // // // //           Offset(cx + r * 0.12, cy - r * 0.05),
// // // // // // //           gp,
// // // // // // //         );
// // // // // // //       case 2: // Crown
// // // // // // //         final cp = Paint()..color = const Color(0xFFFFD700);
// // // // // // //         final path = Path()
// // // // // // //           ..moveTo(cx - r * 0.3, cy - r * 0.7)
// // // // // // //           ..lineTo(cx - r * 0.3, cy - r * 0.55)
// // // // // // //           ..lineTo(cx, cy - r * 0.65)
// // // // // // //           ..lineTo(cx + r * 0.3, cy - r * 0.55)
// // // // // // //           ..lineTo(cx + r * 0.3, cy - r * 0.7)
// // // // // // //           ..close();
// // // // // // //         canvas.drawPath(path, cp);
// // // // // // //       default: // Hat
// // // // // // //         final hp = Paint()..color = const Color(0xFF1A1A2E);
// // // // // // //         canvas.drawRRect(
// // // // // // //           RRect.fromRectAndRadius(
// // // // // // //             Rect.fromCenter(
// // // // // // //               center: Offset(cx, cy - r * 0.7),
// // // // // // //               width: r * 0.7,
// // // // // // //               height: r * 0.5,
// // // // // // //             ),
// // // // // // //             const Radius.circular(4),
// // // // // // //           ),
// // // // // // //           hp,
// // // // // // //         );
// // // // // // //         canvas.drawRRect(
// // // // // // //           RRect.fromRectAndRadius(
// // // // // // //             Rect.fromCenter(
// // // // // // //               center: Offset(cx, cy - r * 0.5),
// // // // // // //               width: r * 1.1,
// // // // // // //               height: r * 0.12,
// // // // // // //             ),
// // // // // // //             const Radius.circular(4),
// // // // // // //           ),
// // // // // // //           hp,
// // // // // // //         );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   bool shouldRepaint(AvatarPainter old) => old.config != config;
// // // // // // // }

// // // // // // // // ── Avatar Widget ─────────────────────────────────────────────────────────────

// // // // // // // class AvatarWidget extends StatelessWidget {
// // // // // // //   const AvatarWidget({super.key, required this.config, this.size = 80});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final double size;

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => ClipOval(
// // // // // // //     child: CustomPaint(size: Size(size, size), painter: AvatarPainter(config)),
// // // // // // //   );
// // // // // // // }

// // // // // // // // ── Avatar Creator Screen ─────────────────────────────────────────────────────

// // // // // // // class AvatarCreatorScreen extends StatefulWidget {
// // // // // // //   const AvatarCreatorScreen({super.key});
// // // // // // //   @override
// // // // // // //   State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
// // // // // // // }

// // // // // // // class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
// // // // // // //   late AvatarConfig _config;
// // // // // // //   bool _saving = false;

// // // // // // //   static const _tabs = ['Face', 'Hair', 'Eyes', 'Mouth', 'Outfit', 'Extra'];

// // // // // // //   @override
// // // // // // //   void initState() {
// // // // // // //     super.initState();
// // // // // // //     _config = AvatarService.instance.config;
// // // // // // //   }

// // // // // // //   Future<void> _save() async {
// // // // // // //     setState(() => _saving = true);
// // // // // // //     await AvatarService.instance.save(_config);
// // // // // // //     if (mounted) {
// // // // // // //       setState(() => _saving = false);
// // // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // // //         const SnackBar(
// // // // // // //           content: Text('Avatar saved! ✦'),
// // // // // // //           behavior: SnackBarBehavior.fixed,
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }
// // // // // // //   }

// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) {
// // // // // // //     final isPremium =
// // // // // // //         context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
// // // // // // //     final theme = context.theme;

// // // // // // //     if (!isPremium) {
// // // // // // //       return Scaffold(
// // // // // // //         appBar: AppBar(title: const Text('Avatar Creator')),
// // // // // // //         body: Center(
// // // // // // //           child: Padding(
// // // // // // //             padding: const EdgeInsets.all(32),
// // // // // // //             child: Column(
// // // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // // //               children: [
// // // // // // //                 const Text('🎨', style: TextStyle(fontSize: 64)),
// // // // // // //                 const SizedBox(height: 16),
// // // // // // //                 Text(
// // // // // // //                   'Custom Avatars',
// // // // // // //                   style: theme.textTheme.headlineSmall?.copyWith(
// // // // // // //                     fontWeight: FontWeight.w800,
// // // // // // //                   ),
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 8),
// // // // // // //                 Text(
// // // // // // //                   'Create your own unique Bitmoji-style avatar with Premium.',
// // // // // // //                   textAlign: TextAlign.center,
// // // // // // //                   style: theme.textTheme.bodyMedium,
// // // // // // //                 ),
// // // // // // //                 const SizedBox(height: 24),
// // // // // // //                 FilledButton(
// // // // // // //                   onPressed: () => AppRouter.router.push(RouteNames.premium),
// // // // // // //                   child: const Text('Upgrade to Premium ✦'),
// // // // // // //                 ),
// // // // // // //               ],
// // // // // // //             ),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //       );
// // // // // // //     }

// // // // // // //     return DefaultTabController(
// // // // // // //       length: _tabs.length,
// // // // // // //       child: Scaffold(
// // // // // // //         appBar: AppBar(
// // // // // // //           title: const Text('My Avatar'),
// // // // // // //           actions: [
// // // // // // //             _saving
// // // // // // //                 ? const Padding(
// // // // // // //                     padding: EdgeInsets.all(16),
// // // // // // //                     child: SizedBox(
// // // // // // //                       width: 20,
// // // // // // //                       height: 20,
// // // // // // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // // // // // //                     ),
// // // // // // //                   )
// // // // // // //                 : TextButton.icon(
// // // // // // //                     onPressed: _save,
// // // // // // //                     icon: const Icon(Icons.check_rounded),
// // // // // // //                     label: const Text('Save'),
// // // // // // //                   ),
// // // // // // //           ],
// // // // // // //           bottom: TabBar(
// // // // // // //             isScrollable: true,
// // // // // // //             tabAlignment: TabAlignment.start,
// // // // // // //             tabs: _tabs.map((t) => Tab(text: t)).toList(),
// // // // // // //           ),
// // // // // // //         ),
// // // // // // //         body: Column(
// // // // // // //           children: [
// // // // // // //             Container(
// // // // // // //               padding: const EdgeInsets.all(20),
// // // // // // //               color: theme.colorScheme.surfaceContainerHighest,
// // // // // // //               child: Row(
// // // // // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // // // // //                 children: [
// // // // // // //                   AvatarWidget(config: _config, size: 100),
// // // // // // //                   const SizedBox(width: 20),
// // // // // // //                   Column(
// // // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //                     children: [
// // // // // // //                       Text(
// // // // // // //                         'Preview',
// // // // // // //                         style: theme.textTheme.labelSmall?.copyWith(
// // // // // // //                           color: theme.colorScheme.onSurfaceVariant,
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                       const SizedBox(height: 4),
// // // // // // //                       Text(
// // // // // // //                         context
// // // // // // //                                 .watch<AuthProvider>()
// // // // // // //                                 .currentUser
// // // // // // //                                 ?.displayName ??
// // // // // // //                             '',
// // // // // // //                         style: theme.textTheme.titleMedium?.copyWith(
// // // // // // //                           fontWeight: FontWeight.w700,
// // // // // // //                         ),
// // // // // // //                       ),
// // // // // // //                       const SizedBox(height: 8),
// // // // // // //                       OutlinedButton.icon(
// // // // // // //                         onPressed: () => setState(
// // // // // // //                           () => _config = AvatarConfig.defaultConfig,
// // // // // // //                         ),
// // // // // // //                         icon: const Icon(Icons.refresh_rounded, size: 16),
// // // // // // //                         label: const Text('Reset'),
// // // // // // //                       ),
// // // // // // //                     ],
// // // // // // //                   ),
// // // // // // //                 ],
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //             Expanded(
// // // // // // //               child: TabBarView(
// // // // // // //                 children: [
// // // // // // //                   _FaceTab(
// // // // // // //                     config: _config,
// // // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // // //                   ),
// // // // // // //                   _HairTab(
// // // // // // //                     config: _config,
// // // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // // //                   ),
// // // // // // //                   _EyesTab(
// // // // // // //                     config: _config,
// // // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // // //                   ),
// // // // // // //                   _MouthTab(
// // // // // // //                     config: _config,
// // // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // // //                   ),
// // // // // // //                   _OutfitTab(
// // // // // // //                     config: _config,
// // // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // // //                   ),
// // // // // // //                   _ExtraTab(
// // // // // // //                     config: _config,
// // // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // // //                   ),
// // // // // // //                 ],
// // // // // // //               ),
// // // // // // //             ),
// // // // // // //           ],
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //     );
// // // // // // //   }
// // // // // // // }

// // // // // // // // ── Tab content helpers ───────────────────────────────────────────────────────

// // // // // // // typedef _OnChanged = void Function(AvatarConfig);

// // // // // // // class _FaceTab extends StatelessWidget {
// // // // // // //   const _FaceTab({required this.config, required this.onChanged});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final _OnChanged onChanged;
// // // // // // //   static const _skins = [
// // // // // // //     '☀️ Light',
// // // // // // //     '🌤 Medium-Light',
// // // // // // //     '🌥 Medium',
// // // // // // //     '🌦 Medium-Dark',
// // // // // // //     '🌧 Dark',
// // // // // // //     '🌑 Deep',
// // // // // // //   ];
// // // // // // //   static const _bgs = [
// // // // // // //     'Violet',
// // // // // // //     'Gold',
// // // // // // //     'Emerald',
// // // // // // //     'Pink',
// // // // // // //     'Cyan',
// // // // // // //     'Orange',
// // // // // // //     'Purple',
// // // // // // //     'Slate',
// // // // // // //     'Night',
// // // // // // //   ];
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // // //     children: [
// // // // // // //       _Section(
// // // // // // //         'Skin Tone',
// // // // // // //         _skins
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.skinTone == e.key,
// // // // // // //                 () => onChanged(config.copyWith(skinTone: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //       _Section(
// // // // // // //         'Background',
// // // // // // //         _bgs
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.bgColor == e.key,
// // // // // // //                 () => onChanged(config.copyWith(bgColor: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //     ],
// // // // // // //   );
// // // // // // // }

// // // // // // // class _HairTab extends StatelessWidget {
// // // // // // //   const _HairTab({required this.config, required this.onChanged});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final _OnChanged onChanged;
// // // // // // //   static const _styles = ['Short', 'Long', 'Spiky', 'Curly'];
// // // // // // //   static const _colors = [
// // // // // // //     'Black',
// // // // // // //     'Dark Brown',
// // // // // // //     'Brown',
// // // // // // //     'Blonde',
// // // // // // //     'Red',
// // // // // // //     'Gray',
// // // // // // //     'White',
// // // // // // //     'Purple',
// // // // // // //     'Teal',
// // // // // // //   ];
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // // //     children: [
// // // // // // //       _Section(
// // // // // // //         'Style',
// // // // // // //         _styles
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.hairStyle == e.key,
// // // // // // //                 () => onChanged(config.copyWith(hairStyle: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //       _Section(
// // // // // // //         'Color',
// // // // // // //         _colors
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.hairColor == e.key,
// // // // // // //                 () => onChanged(config.copyWith(hairColor: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //     ],
// // // // // // //   );
// // // // // // // }

// // // // // // // class _EyesTab extends StatelessWidget {
// // // // // // //   const _EyesTab({required this.config, required this.onChanged});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final _OnChanged onChanged;
// // // // // // //   static const _eyes = ['Round', 'Happy', 'Almond'];
// // // // // // //   static const _brows = ['Straight', 'Angled', 'Arched'];
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // // //     children: [
// // // // // // //       _Section(
// // // // // // //         'Eye Shape',
// // // // // // //         _eyes
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.eyeStyle == e.key,
// // // // // // //                 () => onChanged(config.copyWith(eyeStyle: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //       _Section(
// // // // // // //         'Eyebrows',
// // // // // // //         _brows
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.browStyle == e.key,
// // // // // // //                 () => onChanged(config.copyWith(browStyle: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //     ],
// // // // // // //   );
// // // // // // // }

// // // // // // // class _MouthTab extends StatelessWidget {
// // // // // // //   const _MouthTab({required this.config, required this.onChanged});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final _OnChanged onChanged;
// // // // // // //   static const _mouths = ['Smile', 'Big Smile', 'Neutral', 'Smirk'];
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // // //     children: [
// // // // // // //       _Section(
// // // // // // //         'Mouth',
// // // // // // //         _mouths
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.mouthStyle == e.key,
// // // // // // //                 () => onChanged(config.copyWith(mouthStyle: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //     ],
// // // // // // //   );
// // // // // // // }

// // // // // // // class _OutfitTab extends StatelessWidget {
// // // // // // //   const _OutfitTab({required this.config, required this.onChanged});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final _OnChanged onChanged;
// // // // // // //   static const _outfits = ['Blue', 'Red', 'Green', 'Purple'];
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // // //     children: [
// // // // // // //       _Section(
// // // // // // //         'Outfit Color',
// // // // // // //         _outfits
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.outfit == e.key,
// // // // // // //                 () => onChanged(config.copyWith(outfit: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //     ],
// // // // // // //   );
// // // // // // // }

// // // // // // // class _ExtraTab extends StatelessWidget {
// // // // // // //   const _ExtraTab({required this.config, required this.onChanged});
// // // // // // //   final AvatarConfig config;
// // // // // // //   final _OnChanged onChanged;
// // // // // // //   static const _accessories = ['None', 'Glasses', 'Crown', 'Hat'];
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // // //     children: [
// // // // // // //       _Section(
// // // // // // //         'Accessory',
// // // // // // //         _accessories
// // // // // // //             .asMap()
// // // // // // //             .entries
// // // // // // //             .map(
// // // // // // //               (e) => _Chip(
// // // // // // //                 e.value,
// // // // // // //                 config.accessory == e.key,
// // // // // // //                 () => onChanged(config.copyWith(accessory: e.key)),
// // // // // // //               ),
// // // // // // //             )
// // // // // // //             .toList(),
// // // // // // //       ),
// // // // // // //     ],
// // // // // // //   );
// // // // // // // }

// // // // // // // class _OptionList extends StatelessWidget {
// // // // // // //   const _OptionList({required this.children});
// // // // // // //   final List<Widget> children;
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) =>
// // // // // // //       ListView(padding: const EdgeInsets.all(16), children: children);
// // // // // // // }

// // // // // // // class _Section extends StatelessWidget {
// // // // // // //   const _Section(this.title, this.chips);
// // // // // // //   final String title;
// // // // // // //   final List<Widget> chips;
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => Column(
// // // // // // //     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // // //     children: [
// // // // // // //       Padding(
// // // // // // //         padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // // //         child: Text(
// // // // // // //           title,
// // // // // // //           style: Theme.of(
// // // // // // //             context,
// // // // // // //           ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
// // // // // // //         ),
// // // // // // //       ),
// // // // // // //       Wrap(spacing: 8, runSpacing: 8, children: chips),
// // // // // // //       const SizedBox(height: 8),
// // // // // // //     ],
// // // // // // //   );
// // // // // // // }

// // // // // // // class _Chip extends StatelessWidget {
// // // // // // //   const _Chip(this.label, this.selected, this.onTap);
// // // // // // //   final String label;
// // // // // // //   final bool selected;
// // // // // // //   final VoidCallback onTap;
// // // // // // //   @override
// // // // // // //   Widget build(BuildContext context) => FilterChip(
// // // // // // //     label: Text(label),
// // // // // // //     selected: selected,
// // // // // // //     onSelected: (_) => onTap(),
// // // // // // //     showCheckmark: true,
// // // // // // //   );
// // // // // // // }

// // // // // // import 'dart:convert';
// // // // // // import 'package:flutter/material.dart';
// // // // // // import 'package:provider/provider.dart';
// // // // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // // import '../../../core/extensions/context_ext.dart';
// // // // // // import '../../../core/providers/auth_provider.dart';
// // // // // // import '../../../core/router/route_names.dart';
// // // // // // import '../../../core/router/app_router.dart';

// // // // // // // ── Avatar data model ─────────────────────────────────────────────────────────

// // // // // // class AvatarConfig {
// // // // // //   const AvatarConfig({
// // // // // //     this.skinTone = 0,
// // // // // //     this.hairStyle = 0,
// // // // // //     this.hairColor = 0,
// // // // // //     this.eyeStyle = 0,
// // // // // //     this.browStyle = 0,
// // // // // //     this.mouthStyle = 0,
// // // // // //     this.outfit = 0,
// // // // // //     this.accessory = 0,
// // // // // //     this.bgColor = 0,
// // // // // //   });

// // // // // //   final int skinTone,
// // // // // //       hairStyle,
// // // // // //       hairColor,
// // // // // //       eyeStyle,
// // // // // //       browStyle,
// // // // // //       mouthStyle,
// // // // // //       outfit,
// // // // // //       accessory,
// // // // // //       bgColor;

// // // // // //   AvatarConfig copyWith({
// // // // // //     int? skinTone,
// // // // // //     int? hairStyle,
// // // // // //     int? hairColor,
// // // // // //     int? eyeStyle,
// // // // // //     int? browStyle,
// // // // // //     int? mouthStyle,
// // // // // //     int? outfit,
// // // // // //     int? accessory,
// // // // // //     int? bgColor,
// // // // // //   }) => AvatarConfig(
// // // // // //     skinTone: skinTone ?? this.skinTone,
// // // // // //     hairStyle: hairStyle ?? this.hairStyle,
// // // // // //     hairColor: hairColor ?? this.hairColor,
// // // // // //     eyeStyle: eyeStyle ?? this.eyeStyle,
// // // // // //     browStyle: browStyle ?? this.browStyle,
// // // // // //     mouthStyle: mouthStyle ?? this.mouthStyle,
// // // // // //     outfit: outfit ?? this.outfit,
// // // // // //     accessory: accessory ?? this.accessory,
// // // // // //     bgColor: bgColor ?? this.bgColor,
// // // // // //   );

// // // // // //   Map<String, int> toMap() => {
// // // // // //     'skinTone': skinTone,
// // // // // //     'hairStyle': hairStyle,
// // // // // //     'hairColor': hairColor,
// // // // // //     'eyeStyle': eyeStyle,
// // // // // //     'browStyle': browStyle,
// // // // // //     'mouthStyle': mouthStyle,
// // // // // //     'outfit': outfit,
// // // // // //     'accessory': accessory,
// // // // // //     'bgColor': bgColor,
// // // // // //   };

// // // // // //   factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
// // // // // //     skinTone: m['skinTone'] as int? ?? 0,
// // // // // //     hairStyle: m['hairStyle'] as int? ?? 0,
// // // // // //     hairColor: m['hairColor'] as int? ?? 0,
// // // // // //     eyeStyle: m['eyeStyle'] as int? ?? 0,
// // // // // //     browStyle: m['browStyle'] as int? ?? 0,
// // // // // //     mouthStyle: m['mouthStyle'] as int? ?? 0,
// // // // // //     outfit: m['outfit'] as int? ?? 0,
// // // // // //     accessory: m['accessory'] as int? ?? 0,
// // // // // //     bgColor: m['bgColor'] as int? ?? 0,
// // // // // //   );

// // // // // //   static AvatarConfig get defaultConfig => const AvatarConfig();
// // // // // // }

// // // // // // // ── Avatar Service ────────────────────────────────────────────────────────────

// // // // // // class AvatarService extends ChangeNotifier {
// // // // // //   AvatarService._();
// // // // // //   static final AvatarService instance = AvatarService._();

// // // // // //   static const _prefKey = 'avatar_config_v1';

// // // // // //   AvatarConfig _config = AvatarConfig.defaultConfig;
// // // // // //   AvatarConfig get config => _config;

// // // // // //   Future<void> load() async {
// // // // // //     final prefs = await SharedPreferences.getInstance();
// // // // // //     final raw = prefs.getString(_prefKey);
// // // // // //     if (raw != null) {
// // // // // //       try {
// // // // // //         _config = AvatarConfig.fromMap(jsonDecode(raw) as Map<String, dynamic>);
// // // // // //       } catch (_) {}
// // // // // //     }
// // // // // //     notifyListeners();
// // // // // //   }

// // // // // //   Future<void> save(AvatarConfig cfg) async {
// // // // // //     _config = cfg;
// // // // // //     final prefs = await SharedPreferences.getInstance();
// // // // // //     await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
// // // // // //     final uid = Supabase.instance.client.auth.currentUser?.id;
// // // // // //     if (uid != null) {
// // // // // //       await Supabase.instance.client
// // // // // //           .from('profiles')
// // // // // //           .update({'avatar_config': cfg.toMap()})
// // // // // //           .eq('id', uid)
// // // // // //           .catchError((_) {});
// // // // // //     }
// // // // // //     notifyListeners();
// // // // // //   }
// // // // // // }

// // // // // // // ── Avatar Painter ────────────────────────────────────────────────────────────

// // // // // // class AvatarPainter extends CustomPainter {
// // // // // //   const AvatarPainter(this.config, {this.small = false});
// // // // // //   final AvatarConfig config;
// // // // // //   final bool small;

// // // // // //   static const _skinTones = [
// // // // // //     Color(0xFFFFDBAC),
// // // // // //     Color(0xFFF5CBA7),
// // // // // //     Color(0xFFE8A87C),
// // // // // //     Color(0xFFD4845A),
// // // // // //     Color(0xFFA0522D),
// // // // // //     Color(0xFF6F3A24),
// // // // // //   ];
// // // // // //   static const _hairColors = [
// // // // // //     Color(0xFF2C1B0E),
// // // // // //     Color(0xFF5C3317),
// // // // // //     Color(0xFFA0522D),
// // // // // //     Color(0xFFDAA520),
// // // // // //     Color(0xFFFF4500),
// // // // // //     Color(0xFF808080),
// // // // // //     Color(0xFFFFFFFF),
// // // // // //     Color(0xFF4B0082),
// // // // // //     Color(0xFF00CED1),
// // // // // //   ];
// // // // // //   static const _bgColors = [
// // // // // //     Color(0xFF6C63FF),
// // // // // //     Color(0xFFF5A623),
// // // // // //     Color(0xFF2ECC71),
// // // // // //     Color(0xFFE91E63),
// // // // // //     Color(0xFF00BCD4),
// // // // // //     Color(0xFFFF5722),
// // // // // //     Color(0xFF9C27B0),
// // // // // //     Color(0xFF607D8B),
// // // // // //     Color(0xFF1A1A2E),
// // // // // //   ];

// // // // // //   @override
// // // // // //   void paint(Canvas canvas, Size size) {
// // // // // //     final cx = size.width / 2;
// // // // // //     final cy = size.height / 2;
// // // // // //     final r = size.width * 0.45;

// // // // // //     final bgPaint = Paint()
// // // // // //       ..color = _bgColors[config.bgColor % _bgColors.length];
// // // // // //     canvas.drawCircle(Offset(cx, cy), size.width / 2, bgPaint);

// // // // // //     final skin = _skinTones[config.skinTone % _skinTones.length];
// // // // // //     final skinPaint = Paint()..color = skin;

// // // // // //     // Neck
// // // // // //     canvas.drawRRect(
// // // // // //       RRect.fromRectAndRadius(
// // // // // //         Rect.fromCenter(
// // // // // //           center: Offset(cx, cy + r * 0.7),
// // // // // //           width: r * 0.38,
// // // // // //           height: r * 0.35,
// // // // // //         ),
// // // // // //         const Radius.circular(6),
// // // // // //       ),
// // // // // //       skinPaint,
// // // // // //     );

// // // // // //     // Face
// // // // // //     canvas.drawOval(
// // // // // //       Rect.fromCenter(
// // // // // //         center: Offset(cx, cy + r * 0.05),
// // // // // //         width: r * 1.1,
// // // // // //         height: r * 1.3,
// // // // // //       ),
// // // // // //       skinPaint,
// // // // // //     );

// // // // // //     // Hair base
// // // // // //     final hairPaint = Paint()
// // // // // //       ..color = _hairColors[config.hairColor % _hairColors.length];
// // // // // //     _drawHair(canvas, cx, cy, r, hairPaint, config.hairStyle % 4);

// // // // // //     // Eyes
// // // // // //     _drawEyes(canvas, cx, cy, r, config.eyeStyle % 3);

// // // // // //     // Eyebrows
// // // // // //     _drawBrows(canvas, cx, cy, r, hairPaint, config.browStyle % 3);

// // // // // //     // Mouth
// // // // // //     _drawMouth(canvas, cx, cy, r, config.mouthStyle % 4);

// // // // // //     // Nose
// // // // // //     final nosePaint = Paint()
// // // // // //       ..color = skin.withAlpha(180)
// // // // // //       ..style = PaintingStyle.stroke
// // // // // //       ..strokeWidth = 1.5
// // // // // //       ..strokeCap = StrokeCap.round;
// // // // // //     final nosePath = Path()
// // // // // //       ..moveTo(cx - r * 0.04, cy + r * 0.15)
// // // // // //       ..quadraticBezierTo(cx - r * 0.12, cy + r * 0.3, cx, cy + r * 0.32)
// // // // // //       ..quadraticBezierTo(
// // // // // //         cx + r * 0.12,
// // // // // //         cy + r * 0.3,
// // // // // //         cx + r * 0.04,
// // // // // //         cy + r * 0.15,
// // // // // //       );
// // // // // //     canvas.drawPath(nosePath, nosePaint);

// // // // // //     // Outfit
// // // // // //     _drawOutfit(canvas, cx, cy, r, size, config.outfit % 4);

// // // // // //     // Accessory
// // // // // //     if (config.accessory > 0) {
// // // // // //       _drawAccessory(canvas, cx, cy, r, config.accessory % 4);
// // // // // //     }

// // // // // //     // Clip to circle
// // // // // //     final clipPaint = Paint()
// // // // // //       ..color = Colors.transparent
// // // // // //       ..blendMode = BlendMode.clear;
// // // // // //     final clipPath = Path()
// // // // // //       ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
// // // // // //       ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: size.width / 2))
// // // // // //       ..fillType = PathFillType.evenOdd;
// // // // // //     canvas.drawPath(clipPath, clipPaint);
// // // // // //   }

// // // // // //   void _drawHair(
// // // // // //     Canvas canvas,
// // // // // //     double cx,
// // // // // //     double cy,
// // // // // //     double r,
// // // // // //     Paint p,
// // // // // //     int style,
// // // // // //   ) {
// // // // // //     switch (style) {
// // // // // //       case 0: // Short round
// // // // // //         canvas.drawOval(
// // // // // //           Rect.fromCenter(
// // // // // //             center: Offset(cx, cy - r * 0.35),
// // // // // //             width: r * 1.15,
// // // // // //             height: r * 0.85,
// // // // // //           ),
// // // // // //           p,
// // // // // //         );
// // // // // //       case 1: // Long
// // // // // //         canvas.drawOval(
// // // // // //           Rect.fromCenter(
// // // // // //             center: Offset(cx, cy - r * 0.35),
// // // // // //             width: r * 1.15,
// // // // // //             height: r * 0.85,
// // // // // //           ),
// // // // // //           p,
// // // // // //         );
// // // // // //         canvas.drawRRect(
// // // // // //           RRect.fromRectAndRadius(
// // // // // //             Rect.fromCenter(
// // // // // //               center: Offset(cx - r * 0.5, cy + r * 0.3),
// // // // // //               width: r * 0.16,
// // // // // //               height: r * 0.9,
// // // // // //             ),
// // // // // //             const Radius.circular(8),
// // // // // //           ),
// // // // // //           p,
// // // // // //         );
// // // // // //         canvas.drawRRect(
// // // // // //           RRect.fromRectAndRadius(
// // // // // //             Rect.fromCenter(
// // // // // //               center: Offset(cx + r * 0.5, cy + r * 0.3),
// // // // // //               width: r * 0.16,
// // // // // //               height: r * 0.9,
// // // // // //             ),
// // // // // //             const Radius.circular(8),
// // // // // //           ),
// // // // // //           p,
// // // // // //         );
// // // // // //       case 2: // Spiky
// // // // // //         for (var i = 0; i < 5; i++) {
// // // // // //           final x = cx - r * 0.5 + i * r * 0.25;
// // // // // //           final path = Path()
// // // // // //             ..moveTo(x, cy - r * 0.25)
// // // // // //             ..lineTo(x + r * 0.12, cy - r * 0.7)
// // // // // //             ..lineTo(x + r * 0.24, cy - r * 0.25)
// // // // // //             ..close();
// // // // // //           canvas.drawPath(path, p);
// // // // // //         }
// // // // // //         canvas.drawOval(
// // // // // //           Rect.fromCenter(
// // // // // //             center: Offset(cx, cy - r * 0.2),
// // // // // //             width: r * 1.1,
// // // // // //             height: r * 0.5,
// // // // // //           ),
// // // // // //           p,
// // // // // //         );
// // // // // //       default: // Curly
// // // // // //         for (var i = 0; i < 7; i++) {
// // // // // //           final angle = (i / 7) * 3.14159;
// // // // // //           final bx = cx + r * 0.55 * (i % 2 == 0 ? -1 : 1) * (0.5 + (i / 14));
// // // // // //           canvas.drawCircle(
// // // // // //             Offset(cx - r * 0.5 + i * r * 0.17, cy - r * 0.45),
// // // // // //             r * 0.22,
// // // // // //             p,
// // // // // //           );
// // // // // //         }
// // // // // //     }
// // // // // //   }

// // // // // //   void _drawEyes(Canvas canvas, double cx, double cy, double r, int style) {
// // // // // //     final white = Paint()..color = Colors.white;
// // // // // //     final dark = Paint()..color = const Color(0xFF2C1B0E);
// // // // // //     final highlight = Paint()..color = Colors.white;
// // // // // //     for (final side in [-1, 1]) {
// // // // // //       final ex = cx + side * r * 0.27;
// // // // // //       final ey = cy - r * 0.05;
// // // // // //       canvas.drawOval(
// // // // // //         Rect.fromCenter(
// // // // // //           center: Offset(ex, ey),
// // // // // //           width: r * 0.28,
// // // // // //           height: r * 0.22,
// // // // // //         ),
// // // // // //         white,
// // // // // //       );
// // // // // //       switch (style) {
// // // // // //         case 0:
// // // // // //           canvas.drawCircle(Offset(ex, ey), r * 0.1, dark);
// // // // // //           canvas.drawCircle(
// // // // // //             Offset(ex + r * 0.03, ey - r * 0.03),
// // // // // //             r * 0.03,
// // // // // //             highlight,
// // // // // //           );
// // // // // //         case 1: // Happy squint
// // // // // //           final p = Paint()
// // // // // //             ..color = const Color(0xFF2C1B0E)
// // // // // //             ..style = PaintingStyle.stroke
// // // // // //             ..strokeWidth = 2.5
// // // // // //             ..strokeCap = StrokeCap.round;
// // // // // //           canvas.drawArc(
// // // // // //             Rect.fromCenter(
// // // // // //               center: Offset(ex, ey + r * 0.04),
// // // // // //               width: r * 0.22,
// // // // // //               height: r * 0.18,
// // // // // //             ),
// // // // // //             3.14,
// // // // // //             3.14,
// // // // // //             false,
// // // // // //             p,
// // // // // //           );
// // // // // //         default:
// // // // // //           canvas.drawOval(
// // // // // //             Rect.fromCenter(
// // // // // //               center: Offset(ex, ey),
// // // // // //               width: r * 0.12,
// // // // // //               height: r * 0.16,
// // // // // //             ),
// // // // // //             dark,
// // // // // //           );
// // // // // //           canvas.drawCircle(
// // // // // //             Offset(ex + r * 0.03, ey - r * 0.04),
// // // // // //             r * 0.03,
// // // // // //             highlight,
// // // // // //           );
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   void _drawBrows(
// // // // // //     Canvas canvas,
// // // // // //     double cx,
// // // // // //     double cy,
// // // // // //     double r,
// // // // // //     Paint p,
// // // // // //     int style,
// // // // // //   ) {
// // // // // //     final bp = Paint()
// // // // // //       ..color = p.color
// // // // // //       ..style = PaintingStyle.stroke
// // // // // //       ..strokeWidth = 3
// // // // // //       ..strokeCap = StrokeCap.round;
// // // // // //     for (final side in [-1, 1]) {
// // // // // //       final bx = cx + side * r * 0.27;
// // // // // //       final by = cy - r * 0.22;
// // // // // //       switch (style) {
// // // // // //         case 0:
// // // // // //           canvas.drawLine(
// // // // // //             Offset(bx - r * 0.1, by),
// // // // // //             Offset(bx + r * 0.1, by),
// // // // // //             bp,
// // // // // //           );
// // // // // //         case 1:
// // // // // //           canvas.drawLine(
// // // // // //             Offset(bx - r * 0.1, by + r * 0.03 * side),
// // // // // //             Offset(bx + r * 0.1, by - r * 0.03 * side),
// // // // // //             bp,
// // // // // //           );
// // // // // //         default:
// // // // // //           final path = Path()
// // // // // //             ..moveTo(bx - r * 0.1, by + r * 0.03)
// // // // // //             ..quadraticBezierTo(bx, by - r * 0.05, bx + r * 0.1, by + r * 0.03);
// // // // // //           canvas.drawPath(path, bp);
// // // // // //       }
// // // // // //     }
// // // // // //   }

// // // // // //   void _drawMouth(Canvas canvas, double cx, double cy, double r, int style) {
// // // // // //     final mp = Paint()
// // // // // //       ..color = const Color(0xFFCC4444)
// // // // // //       ..style = PaintingStyle.stroke
// // // // // //       ..strokeWidth = 2.5
// // // // // //       ..strokeCap = StrokeCap.round;
// // // // // //     switch (style) {
// // // // // //       case 0: // Smile
// // // // // //         canvas.drawArc(
// // // // // //           Rect.fromCenter(
// // // // // //             center: Offset(cx, cy + r * 0.36),
// // // // // //             width: r * 0.42,
// // // // // //             height: r * 0.25,
// // // // // //           ),
// // // // // //           0,
// // // // // //           3.14,
// // // // // //           false,
// // // // // //           mp,
// // // // // //         );
// // // // // //       case 1: // Big smile with teeth
// // // // // //         final tp = Paint()..color = Colors.white;
// // // // // //         canvas.drawOval(
// // // // // //           Rect.fromCenter(
// // // // // //             center: Offset(cx, cy + r * 0.42),
// // // // // //             width: r * 0.42,
// // // // // //             height: r * 0.18,
// // // // // //           ),
// // // // // //           tp,
// // // // // //         );
// // // // // //         canvas.drawArc(
// // // // // //           Rect.fromCenter(
// // // // // //             center: Offset(cx, cy + r * 0.36),
// // // // // //             width: r * 0.5,
// // // // // //             height: r * 0.3,
// // // // // //           ),
// // // // // //           0,
// // // // // //           3.14,
// // // // // //           false,
// // // // // //           mp
// // // // // //             ..color = const Color(0xFF8B2020)
// // // // // //             ..strokeWidth = 3,
// // // // // //         );
// // // // // //       case 2: // Neutral
// // // // // //         canvas.drawLine(
// // // // // //           Offset(cx - r * 0.15, cy + r * 0.42),
// // // // // //           Offset(cx + r * 0.15, cy + r * 0.42),
// // // // // //           mp,
// // // // // //         );
// // // // // //       default: // Smirk
// // // // // //         canvas.drawArc(
// // // // // //           Rect.fromCenter(
// // // // // //             center: Offset(cx + r * 0.08, cy + r * 0.4),
// // // // // //             width: r * 0.28,
// // // // // //             height: r * 0.18,
// // // // // //           ),
// // // // // //           0,
// // // // // //           3.14,
// // // // // //           false,
// // // // // //           mp,
// // // // // //         );
// // // // // //     }
// // // // // //   }

// // // // // //   void _drawOutfit(
// // // // // //     Canvas canvas,
// // // // // //     double cx,
// // // // // //     double cy,
// // // // // //     double r,
// // // // // //     Size size,
// // // // // //     int style,
// // // // // //   ) {
// // // // // //     final colors = [
// // // // // //       const Color(0xFF3498DB),
// // // // // //       const Color(0xFFE74C3C),
// // // // // //       const Color(0xFF2ECC71),
// // // // // //       const Color(0xFF9B59B6),
// // // // // //     ];
// // // // // //     final op = Paint()..color = colors[style % colors.length];
// // // // // //     final neckBottom = cy + r * 0.65;
// // // // // //     canvas.drawRRect(
// // // // // //       RRect.fromRectAndRadius(
// // // // // //         Rect.fromLTWH(
// // // // // //           cx - r * 0.7,
// // // // // //           neckBottom,
// // // // // //           r * 1.4,
// // // // // //           size.height - neckBottom + 4,
// // // // // //         ),
// // // // // //         const Radius.circular(4),
// // // // // //       ),
// // // // // //       op,
// // // // // //     );
// // // // // //   }

// // // // // //   void _drawAccessory(
// // // // // //     Canvas canvas,
// // // // // //     double cx,
// // // // // //     double cy,
// // // // // //     double r,
// // // // // //     int style,
// // // // // //   ) {
// // // // // //     switch (style) {
// // // // // //       case 1: // Glasses
// // // // // //         final gp = Paint()
// // // // // //           ..color = const Color(0xFF333333)
// // // // // //           ..style = PaintingStyle.stroke
// // // // // //           ..strokeWidth = 2;
// // // // // //         canvas.drawCircle(Offset(cx - r * 0.27, cy - r * 0.05), r * 0.15, gp);
// // // // // //         canvas.drawCircle(Offset(cx + r * 0.27, cy - r * 0.05), r * 0.15, gp);
// // // // // //         canvas.drawLine(
// // // // // //           Offset(cx - r * 0.12, cy - r * 0.05),
// // // // // //           Offset(cx + r * 0.12, cy - r * 0.05),
// // // // // //           gp,
// // // // // //         );
// // // // // //       case 2: // Crown
// // // // // //         final cp = Paint()..color = const Color(0xFFFFD700);
// // // // // //         final path = Path()
// // // // // //           ..moveTo(cx - r * 0.3, cy - r * 0.7)
// // // // // //           ..lineTo(cx - r * 0.3, cy - r * 0.55)
// // // // // //           ..lineTo(cx, cy - r * 0.65)
// // // // // //           ..lineTo(cx + r * 0.3, cy - r * 0.55)
// // // // // //           ..lineTo(cx + r * 0.3, cy - r * 0.7)
// // // // // //           ..close();
// // // // // //         canvas.drawPath(path, cp);
// // // // // //       default: // Hat
// // // // // //         final hp = Paint()..color = const Color(0xFF1A1A2E);
// // // // // //         canvas.drawRRect(
// // // // // //           RRect.fromRectAndRadius(
// // // // // //             Rect.fromCenter(
// // // // // //               center: Offset(cx, cy - r * 0.7),
// // // // // //               width: r * 0.7,
// // // // // //               height: r * 0.5,
// // // // // //             ),
// // // // // //             const Radius.circular(4),
// // // // // //           ),
// // // // // //           hp,
// // // // // //         );
// // // // // //         canvas.drawRRect(
// // // // // //           RRect.fromRectAndRadius(
// // // // // //             Rect.fromCenter(
// // // // // //               center: Offset(cx, cy - r * 0.5),
// // // // // //               width: r * 1.1,
// // // // // //               height: r * 0.12,
// // // // // //             ),
// // // // // //             const Radius.circular(4),
// // // // // //           ),
// // // // // //           hp,
// // // // // //         );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   bool shouldRepaint(AvatarPainter old) => old.config != config;
// // // // // // }

// // // // // // // ── Avatar Widget ─────────────────────────────────────────────────────────────

// // // // // // class AvatarWidget extends StatelessWidget {
// // // // // //   const AvatarWidget({super.key, required this.config, this.size = 80});
// // // // // //   final AvatarConfig config;
// // // // // //   final double size;

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => ClipOval(
// // // // // //     child: CustomPaint(size: Size(size, size), painter: AvatarPainter(config)),
// // // // // //   );
// // // // // // }

// // // // // // // ── Avatar Creator Screen ─────────────────────────────────────────────────────

// // // // // // class AvatarCreatorScreen extends StatefulWidget {
// // // // // //   const AvatarCreatorScreen({super.key});
// // // // // //   @override
// // // // // //   State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
// // // // // // }

// // // // // // class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
// // // // // //   late AvatarConfig _config;
// // // // // //   bool _saving = false;

// // // // // //   static const _tabs = ['Face', 'Hair', 'Eyes', 'Mouth', 'Outfit', 'Extra'];

// // // // // //   @override
// // // // // //   void initState() {
// // // // // //     super.initState();
// // // // // //     _config = AvatarService.instance.config;
// // // // // //   }

// // // // // //   Future<void> _save() async {
// // // // // //     setState(() => _saving = true);
// // // // // //     await AvatarService.instance.save(_config);
// // // // // //     if (mounted) {
// // // // // //       setState(() => _saving = false);
// // // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // // //         const SnackBar(
// // // // // //           content: Text('Avatar saved! ✦'),
// // // // // //           behavior: SnackBarBehavior.fixed,
// // // // // //         ),
// // // // // //       );
// // // // // //     }
// // // // // //   }

// // // // // //   @override
// // // // // //   Widget build(BuildContext context) {
// // // // // //     final isPremium =
// // // // // //         context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
// // // // // //     final theme = context.theme;

// // // // // //     if (!isPremium) {
// // // // // //       return Scaffold(
// // // // // //         appBar: AppBar(title: const Text('Avatar Creator')),
// // // // // //         body: Center(
// // // // // //           child: Padding(
// // // // // //             padding: const EdgeInsets.all(32),
// // // // // //             child: Column(
// // // // // //               mainAxisSize: MainAxisSize.min,
// // // // // //               children: [
// // // // // //                 const Text('🎨', style: TextStyle(fontSize: 64)),
// // // // // //                 const SizedBox(height: 16),
// // // // // //                 Text(
// // // // // //                   'Custom Avatars',
// // // // // //                   style: theme.textTheme.headlineSmall?.copyWith(
// // // // // //                     fontWeight: FontWeight.w800,
// // // // // //                   ),
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 8),
// // // // // //                 Text(
// // // // // //                   'Create your own unique Bitmoji-style avatar with Premium.',
// // // // // //                   textAlign: TextAlign.center,
// // // // // //                   style: theme.textTheme.bodyMedium,
// // // // // //                 ),
// // // // // //                 const SizedBox(height: 24),
// // // // // //                 FilledButton(
// // // // // //                   onPressed: () => AppRouter.router.push(RouteNames.premium),
// // // // // //                   child: const Text('Upgrade to Premium ✦'),
// // // // // //                 ),
// // // // // //               ],
// // // // // //             ),
// // // // // //           ),
// // // // // //         ),
// // // // // //       );
// // // // // //     }

// // // // // //     return DefaultTabController(
// // // // // //       length: _tabs.length,
// // // // // //       child: Scaffold(
// // // // // //         appBar: AppBar(
// // // // // //           title: const Text('My Avatar'),
// // // // // //           actions: [
// // // // // //             _saving
// // // // // //                 ? const Padding(
// // // // // //                     padding: EdgeInsets.all(16),
// // // // // //                     child: SizedBox(
// // // // // //                       width: 20,
// // // // // //                       height: 20,
// // // // // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // // // // //                     ),
// // // // // //                   )
// // // // // //                 : TextButton.icon(
// // // // // //                     onPressed: _save,
// // // // // //                     icon: const Icon(Icons.check_rounded),
// // // // // //                     label: const Text('Save'),
// // // // // //                   ),
// // // // // //           ],
// // // // // //           bottom: TabBar(
// // // // // //             isScrollable: true,
// // // // // //             tabAlignment: TabAlignment.start,
// // // // // //             tabs: _tabs.map((t) => Tab(text: t)).toList(),
// // // // // //           ),
// // // // // //         ),
// // // // // //         body: Column(
// // // // // //           children: [
// // // // // //             Container(
// // // // // //               padding: const EdgeInsets.all(20),
// // // // // //               color: theme.colorScheme.surfaceContainerHighest,
// // // // // //               child: Row(
// // // // // //                 mainAxisAlignment: MainAxisAlignment.center,
// // // // // //                 children: [
// // // // // //                   AvatarWidget(config: _config, size: 100),
// // // // // //                   const SizedBox(width: 20),
// // // // // //                   Column(
// // // // // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //                     children: [
// // // // // //                       Text(
// // // // // //                         'Preview',
// // // // // //                         style: theme.textTheme.labelSmall?.copyWith(
// // // // // //                           color: theme.colorScheme.onSurfaceVariant,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       const SizedBox(height: 4),
// // // // // //                       Text(
// // // // // //                         context
// // // // // //                                 .watch<AuthProvider>()
// // // // // //                                 .currentUser
// // // // // //                                 ?.displayName ??
// // // // // //                             '',
// // // // // //                         style: theme.textTheme.titleMedium?.copyWith(
// // // // // //                           fontWeight: FontWeight.w700,
// // // // // //                         ),
// // // // // //                       ),
// // // // // //                       const SizedBox(height: 8),
// // // // // //                       OutlinedButton.icon(
// // // // // //                         onPressed: () => setState(
// // // // // //                           () => _config = AvatarConfig.defaultConfig,
// // // // // //                         ),
// // // // // //                         icon: const Icon(Icons.refresh_rounded, size: 16),
// // // // // //                         label: const Text('Reset'),
// // // // // //                       ),
// // // // // //                     ],
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //             Expanded(
// // // // // //               child: TabBarView(
// // // // // //                 children: [
// // // // // //                   _FaceTab(
// // // // // //                     config: _config,
// // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // //                   ),
// // // // // //                   _HairTab(
// // // // // //                     config: _config,
// // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // //                   ),
// // // // // //                   _EyesTab(
// // // // // //                     config: _config,
// // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // //                   ),
// // // // // //                   _MouthTab(
// // // // // //                     config: _config,
// // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // //                   ),
// // // // // //                   _OutfitTab(
// // // // // //                     config: _config,
// // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // //                   ),
// // // // // //                   _ExtraTab(
// // // // // //                     config: _config,
// // // // // //                     onChanged: (c) => setState(() => _config = c),
// // // // // //                   ),
// // // // // //                 ],
// // // // // //               ),
// // // // // //             ),
// // // // // //           ],
// // // // // //         ),
// // // // // //       ),
// // // // // //     );
// // // // // //   }
// // // // // // }

// // // // // // // ── Tab content helpers ───────────────────────────────────────────────────────

// // // // // // typedef _OnChanged = void Function(AvatarConfig);

// // // // // // class _FaceTab extends StatelessWidget {
// // // // // //   const _FaceTab({required this.config, required this.onChanged});
// // // // // //   final AvatarConfig config;
// // // // // //   final _OnChanged onChanged;
// // // // // //   static const _skins = [
// // // // // //     '☀️ Light',
// // // // // //     '🌤 Medium-Light',
// // // // // //     '🌥 Medium',
// // // // // //     '🌦 Medium-Dark',
// // // // // //     '🌧 Dark',
// // // // // //     '🌑 Deep',
// // // // // //   ];
// // // // // //   static const _bgs = [
// // // // // //     'Violet',
// // // // // //     'Gold',
// // // // // //     'Emerald',
// // // // // //     'Pink',
// // // // // //     'Cyan',
// // // // // //     'Orange',
// // // // // //     'Purple',
// // // // // //     'Slate',
// // // // // //     'Night',
// // // // // //   ];
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // //     children: [
// // // // // //       _Section(
// // // // // //         'Skin Tone',
// // // // // //         _skins
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.skinTone == e.key,
// // // // // //                 () => onChanged(config.copyWith(skinTone: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //       _Section(
// // // // // //         'Background',
// // // // // //         _bgs
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.bgColor == e.key,
// // // // // //                 () => onChanged(config.copyWith(bgColor: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //     ],
// // // // // //   );
// // // // // // }

// // // // // // class _HairTab extends StatelessWidget {
// // // // // //   const _HairTab({required this.config, required this.onChanged});
// // // // // //   final AvatarConfig config;
// // // // // //   final _OnChanged onChanged;
// // // // // //   static const _styles = ['Short', 'Long', 'Spiky', 'Curly'];
// // // // // //   static const _colors = [
// // // // // //     'Black',
// // // // // //     'Dark Brown',
// // // // // //     'Brown',
// // // // // //     'Blonde',
// // // // // //     'Red',
// // // // // //     'Gray',
// // // // // //     'White',
// // // // // //     'Purple',
// // // // // //     'Teal',
// // // // // //   ];
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // //     children: [
// // // // // //       _Section(
// // // // // //         'Style',
// // // // // //         _styles
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.hairStyle == e.key,
// // // // // //                 () => onChanged(config.copyWith(hairStyle: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //       _Section(
// // // // // //         'Color',
// // // // // //         _colors
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.hairColor == e.key,
// // // // // //                 () => onChanged(config.copyWith(hairColor: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //     ],
// // // // // //   );
// // // // // // }

// // // // // // class _EyesTab extends StatelessWidget {
// // // // // //   const _EyesTab({required this.config, required this.onChanged});
// // // // // //   final AvatarConfig config;
// // // // // //   final _OnChanged onChanged;
// // // // // //   static const _eyes = ['Round', 'Happy', 'Almond'];
// // // // // //   static const _brows = ['Straight', 'Angled', 'Arched'];
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // //     children: [
// // // // // //       _Section(
// // // // // //         'Eye Shape',
// // // // // //         _eyes
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.eyeStyle == e.key,
// // // // // //                 () => onChanged(config.copyWith(eyeStyle: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //       _Section(
// // // // // //         'Eyebrows',
// // // // // //         _brows
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.browStyle == e.key,
// // // // // //                 () => onChanged(config.copyWith(browStyle: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //     ],
// // // // // //   );
// // // // // // }

// // // // // // class _MouthTab extends StatelessWidget {
// // // // // //   const _MouthTab({required this.config, required this.onChanged});
// // // // // //   final AvatarConfig config;
// // // // // //   final _OnChanged onChanged;
// // // // // //   static const _mouths = ['Smile', 'Big Smile', 'Neutral', 'Smirk'];
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // //     children: [
// // // // // //       _Section(
// // // // // //         'Mouth',
// // // // // //         _mouths
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.mouthStyle == e.key,
// // // // // //                 () => onChanged(config.copyWith(mouthStyle: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //     ],
// // // // // //   );
// // // // // // }

// // // // // // class _OutfitTab extends StatelessWidget {
// // // // // //   const _OutfitTab({required this.config, required this.onChanged});
// // // // // //   final AvatarConfig config;
// // // // // //   final _OnChanged onChanged;
// // // // // //   static const _outfits = ['Blue', 'Red', 'Green', 'Purple'];
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // //     children: [
// // // // // //       _Section(
// // // // // //         'Outfit Color',
// // // // // //         _outfits
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.outfit == e.key,
// // // // // //                 () => onChanged(config.copyWith(outfit: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //     ],
// // // // // //   );
// // // // // // }

// // // // // // class _ExtraTab extends StatelessWidget {
// // // // // //   const _ExtraTab({required this.config, required this.onChanged});
// // // // // //   final AvatarConfig config;
// // // // // //   final _OnChanged onChanged;
// // // // // //   static const _accessories = ['None', 'Glasses', 'Crown', 'Hat'];
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => _OptionList(
// // // // // //     children: [
// // // // // //       _Section(
// // // // // //         'Accessory',
// // // // // //         _accessories
// // // // // //             .asMap()
// // // // // //             .entries
// // // // // //             .map(
// // // // // //               (e) => _Chip(
// // // // // //                 e.value,
// // // // // //                 config.accessory == e.key,
// // // // // //                 () => onChanged(config.copyWith(accessory: e.key)),
// // // // // //               ),
// // // // // //             )
// // // // // //             .toList(),
// // // // // //       ),
// // // // // //     ],
// // // // // //   );
// // // // // // }

// // // // // // class _OptionList extends StatelessWidget {
// // // // // //   const _OptionList({required this.children});
// // // // // //   final List<Widget> children;
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) =>
// // // // // //       ListView(padding: const EdgeInsets.all(16), children: children);
// // // // // // }

// // // // // // class _Section extends StatelessWidget {
// // // // // //   const _Section(this.title, this.chips);
// // // // // //   final String title;
// // // // // //   final List<Widget> chips;
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => Column(
// // // // // //     crossAxisAlignment: CrossAxisAlignment.start,
// // // // // //     children: [
// // // // // //       Padding(
// // // // // //         padding: const EdgeInsets.symmetric(vertical: 10),
// // // // // //         child: Text(
// // // // // //           title,
// // // // // //           style: Theme.of(
// // // // // //             context,
// // // // // //           ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
// // // // // //         ),
// // // // // //       ),
// // // // // //       SizedBox(
// // // // // //         width: double.infinity,
// // // // // //         child: Wrap(spacing: 8, runSpacing: 8, children: chips),
// // // // // //       ),
// // // // // //       const SizedBox(height: 8),
// // // // // //     ],
// // // // // //   );
// // // // // // }

// // // // // // class _Chip extends StatelessWidget {
// // // // // //   const _Chip(this.label, this.selected, this.onTap);
// // // // // //   final String label;
// // // // // //   final bool selected;
// // // // // //   final VoidCallback onTap;
// // // // // //   @override
// // // // // //   Widget build(BuildContext context) => ChoiceChip(
// // // // // //     label: Text(label),
// // // // // //     selected: selected,
// // // // // //     onSelected: (_) => onTap(),
// // // // // //     showCheckmark: true,
// // // // // //   );
// // // // // // }

// // // // // import 'dart:convert';
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:flutter_svg/flutter_svg.dart';
// // // // // import 'package:provider/provider.dart';
// // // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // // import '../../../core/extensions/context_ext.dart';
// // // // // import '../../../core/providers/auth_provider.dart';
// // // // // import '../../../core/router/route_names.dart';
// // // // // import '../../../core/router/app_router.dart';

// // // // // class AvatarConfig {
// // // // //   const AvatarConfig({
// // // // //     this.topType = 'ShortHairShortFlat',
// // // // //     this.accessoriesType = 'Blank',
// // // // //     this.hairColor = 'BrownDark',
// // // // //     this.facialHairType = 'Blank',
// // // // //     this.facialHairColor = 'BrownDark',
// // // // //     this.clotheType = 'Hoodie',
// // // // //     this.clotheColor = 'Blue01',
// // // // //     this.eyeType = 'Default',
// // // // //     this.eyebrowType = 'Default',
// // // // //     this.mouthType = 'Smile',
// // // // //     this.skinColor = 'Light',
// // // // //   });

// // // // //   final String topType;
// // // // //   final String accessoriesType;
// // // // //   final String hairColor;
// // // // //   final String facialHairType;
// // // // //   final String facialHairColor;
// // // // //   final String clotheType;
// // // // //   final String clotheColor;
// // // // //   final String eyeType;
// // // // //   final String eyebrowType;
// // // // //   final String mouthType;
// // // // //   final String skinColor;

// // // // //   static AvatarConfig get defaults => const AvatarConfig();

// // // // //   String get avatarUrl =>
// // // // //       'https://avataaars.io/?avatarStyle=Circle'
// // // // //       '&topType=$topType'
// // // // //       '&accessoriesType=$accessoriesType'
// // // // //       '&hairColor=$hairColor'
// // // // //       '&facialHairType=$facialHairType'
// // // // //       '&facialHairColor=$facialHairColor'
// // // // //       '&clotheType=$clotheType'
// // // // //       '&clotheColor=$clotheColor'
// // // // //       '&eyeType=$eyeType'
// // // // //       '&eyebrowType=$eyebrowType'
// // // // //       '&mouthType=$mouthType'
// // // // //       '&skinColor=$skinColor';

// // // // //   Map<String, String> toMap() => {
// // // // //     'topType': topType,
// // // // //     'accessoriesType': accessoriesType,
// // // // //     'hairColor': hairColor,
// // // // //     'facialHairType': facialHairType,
// // // // //     'facialHairColor': facialHairColor,
// // // // //     'clotheType': clotheType,
// // // // //     'clotheColor': clotheColor,
// // // // //     'eyeType': eyeType,
// // // // //     'eyebrowType': eyebrowType,
// // // // //     'mouthType': mouthType,
// // // // //     'skinColor': skinColor,
// // // // //   };

// // // // //   factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
// // // // //     topType: m['topType'] as String? ?? 'ShortHairShortFlat',
// // // // //     accessoriesType: m['accessoriesType'] as String? ?? 'Blank',
// // // // //     hairColor: m['hairColor'] as String? ?? 'BrownDark',
// // // // //     facialHairType: m['facialHairType'] as String? ?? 'Blank',
// // // // //     facialHairColor: m['facialHairColor'] as String? ?? 'BrownDark',
// // // // //     clotheType: m['clotheType'] as String? ?? 'Hoodie',
// // // // //     clotheColor: m['clotheColor'] as String? ?? 'Blue01',
// // // // //     eyeType: m['eyeType'] as String? ?? 'Default',
// // // // //     eyebrowType: m['eyebrowType'] as String? ?? 'Default',
// // // // //     mouthType: m['mouthType'] as String? ?? 'Smile',
// // // // //     skinColor: m['skinColor'] as String? ?? 'Light',
// // // // //   );

// // // // //   AvatarConfig copyWith({
// // // // //     String? topType,
// // // // //     String? accessoriesType,
// // // // //     String? hairColor,
// // // // //     String? facialHairType,
// // // // //     String? facialHairColor,
// // // // //     String? clotheType,
// // // // //     String? clotheColor,
// // // // //     String? eyeType,
// // // // //     String? eyebrowType,
// // // // //     String? mouthType,
// // // // //     String? skinColor,
// // // // //   }) => AvatarConfig(
// // // // //     topType: topType ?? this.topType,
// // // // //     accessoriesType: accessoriesType ?? this.accessoriesType,
// // // // //     hairColor: hairColor ?? this.hairColor,
// // // // //     facialHairType: facialHairType ?? this.facialHairType,
// // // // //     facialHairColor: facialHairColor ?? this.facialHairColor,
// // // // //     clotheType: clotheType ?? this.clotheType,
// // // // //     clotheColor: clotheColor ?? this.clotheColor,
// // // // //     eyeType: eyeType ?? this.eyeType,
// // // // //     eyebrowType: eyebrowType ?? this.eyebrowType,
// // // // //     mouthType: mouthType ?? this.mouthType,
// // // // //     skinColor: skinColor ?? this.skinColor,
// // // // //   );
// // // // // }

// // // // // class AvatarService extends ChangeNotifier {
// // // // //   AvatarService._();
// // // // //   static final AvatarService instance = AvatarService._();

// // // // //   static const _prefKey = 'avataaars_config_v1';
// // // // //   AvatarConfig _config = AvatarConfig.defaults;
// // // // //   AvatarConfig get config => _config;

// // // // //   Future<void> load() async {
// // // // //     final prefs = await SharedPreferences.getInstance();
// // // // //     final raw = prefs.getString(_prefKey);
// // // // //     if (raw != null) {
// // // // //       try {
// // // // //         _config = AvatarConfig.fromMap(
// // // // //           Map<String, dynamic>.from(jsonDecode(raw) as Map),
// // // // //         );
// // // // //       } catch (_) {}
// // // // //     }
// // // // //     notifyListeners();
// // // // //   }

// // // // //   Future<void> save(AvatarConfig cfg) async {
// // // // //     _config = cfg;
// // // // //     final prefs = await SharedPreferences.getInstance();
// // // // //     await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
// // // // //     final uid = Supabase.instance.client.auth.currentUser?.id;
// // // // //     if (uid != null) {
// // // // //       await Supabase.instance.client
// // // // //           .from('profiles')
// // // // //           .update({'avatar_config': cfg.toMap()})
// // // // //           .eq('id', uid)
// // // // //           .catchError((_) {});
// // // // //     }
// // // // //     notifyListeners();
// // // // //   }
// // // // // }

// // // // // class AvatarDisplay extends StatelessWidget {
// // // // //   const AvatarDisplay({super.key, required this.avatarUrl, required this.size});
// // // // //   final String avatarUrl;
// // // // //   final double size;

// // // // //   @override
// // // // //   Widget build(BuildContext context) => SvgPicture.network(
// // // // //     avatarUrl,
// // // // //     width: size,
// // // // //     height: size,
// // // // //     placeholderBuilder: (_) => SizedBox(
// // // // //       width: size,
// // // // //       height: size,
// // // // //       child: CircleAvatar(
// // // // //         radius: size / 2,
// // // // //         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
// // // // //         child: Icon(
// // // // //           Icons.person,
// // // // //           size: size * 0.5,
// // // // //           color: Theme.of(context).colorScheme.onPrimaryContainer,
// // // // //         ),
// // // // //       ),
// // // // //     ),
// // // // //   );
// // // // // }

// // // // // class AvatarCreatorScreen extends StatefulWidget {
// // // // //   const AvatarCreatorScreen({super.key});
// // // // //   @override
// // // // //   State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
// // // // // }

// // // // // class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
// // // // //   late AvatarConfig _config;
// // // // //   bool _saving = false;

// // // // //   static const _skinColors = [
// // // // //     'Tanned',
// // // // //     'Yellow',
// // // // //     'Pale',
// // // // //     'Light',
// // // // //     'Brown',
// // // // //     'DarkBrown',
// // // // //     'Black',
// // // // //   ];
// // // // //   static const _hairColors = [
// // // // //     'Auburn',
// // // // //     'Black',
// // // // //     'Blonde',
// // // // //     'BlondeGolden',
// // // // //     'Brown',
// // // // //     'BrownDark',
// // // // //     'PastelPink',
// // // // //     'Platinum',
// // // // //     'Red',
// // // // //     'SilverGray',
// // // // //   ];
// // // // //   static const _topTypes = [
// // // // //     'NoHair',
// // // // //     'Eyepatch',
// // // // //     'Hat',
// // // // //     'Hijab',
// // // // //     'Turban',
// // // // //     'WinterHat1',
// // // // //     'WinterHat2',
// // // // //     'WinterHat3',
// // // // //     'WinterHat4',
// // // // //     'LongHairBigHair',
// // // // //     'LongHairBob',
// // // // //     'LongHairBun',
// // // // //     'LongHairCurly',
// // // // //     'LongHairCurvy',
// // // // //     'LongHairDreads',
// // // // //     'LongHairFrida',
// // // // //     'LongHairFro',
// // // // //     'LongHairFroBand',
// // // // //     'LongHairNotTooLong',
// // // // //     'LongHairShavedSides',
// // // // //     'LongHairMiaWallace',
// // // // //     'LongHairStraight',
// // // // //     'LongHairStraight2',
// // // // //     'LongHairStraightStrand',
// // // // //     'ShortHairDreads01',
// // // // //     'ShortHairDreads02',
// // // // //     'ShortHairFrizzle',
// // // // //     'ShortHairShaggyMullet',
// // // // //     'ShortHairShortCurly',
// // // // //     'ShortHairShortFlat',
// // // // //     'ShortHairShortRound',
// // // // //     'ShortHairShortWaved',
// // // // //     'ShortHairSides',
// // // // //     'ShortHairTheCaesar',
// // // // //     'ShortHairTheCaesarSidePart',
// // // // //   ];
// // // // //   static const _accessories = [
// // // // //     'Blank',
// // // // //     'Kurt',
// // // // //     'Prescription01',
// // // // //     'Prescription02',
// // // // //     'Round',
// // // // //     'Sunglasses',
// // // // //     'Wayfarers',
// // // // //   ];
// // // // //   static const _facialHair = [
// // // // //     'Blank',
// // // // //     'BeardMedium',
// // // // //     'BeardLight',
// // // // //     'BeardMagestic',
// // // // //     'MoustacheFancy',
// // // // //     'MoustacheMagnum',
// // // // //   ];
// // // // //   static const _clothes = [
// // // // //     'BlazerShirt',
// // // // //     'BlazerSweater',
// // // // //     'CollarSweater',
// // // // //     'GraphicShirt',
// // // // //     'Hoodie',
// // // // //     'Overall',
// // // // //     'ShirtCrewNeck',
// // // // //     'ShirtScoopNeck',
// // // // //     'ShirtVNeck',
// // // // //   ];
// // // // //   static const _clotheColors = [
// // // // //     'Black',
// // // // //     'Blue01',
// // // // //     'Blue02',
// // // // //     'Blue03',
// // // // //     'Gray01',
// // // // //     'Gray02',
// // // // //     'Heather',
// // // // //     'PastelBlue',
// // // // //     'PastelGreen',
// // // // //     'PastelOrange',
// // // // //     'PastelRed',
// // // // //     'PastelYellow',
// // // // //     'Pink',
// // // // //     'Red',
// // // // //     'White',
// // // // //   ];
// // // // //   static const _eyes = [
// // // // //     'Close',
// // // // //     'Cry',
// // // // //     'Default',
// // // // //     'Dizzy',
// // // // //     'EyeRoll',
// // // // //     'Happy',
// // // // //     'Hearts',
// // // // //     'Side',
// // // // //     'Squint',
// // // // //     'Surprised',
// // // // //     'Wink',
// // // // //     'WinkWacky',
// // // // //   ];
// // // // //   static const _eyebrows = [
// // // // //     'Angry',
// // // // //     'AngryNatural',
// // // // //     'Default',
// // // // //     'DefaultNatural',
// // // // //     'FlatNatural',
// // // // //     'RaisedExcited',
// // // // //     'RaisedExcitedNatural',
// // // // //     'SadConcerned',
// // // // //     'SadConcernedNatural',
// // // // //     'UnibrowNatural',
// // // // //     'UpDown',
// // // // //     'UpDownNatural',
// // // // //   ];
// // // // //   static const _mouths = [
// // // // //     'Concerned',
// // // // //     'Default',
// // // // //     'Disbelief',
// // // // //     'Eating',
// // // // //     'Grimace',
// // // // //     'Sad',
// // // // //     'ScreamOpen',
// // // // //     'Serious',
// // // // //     'Smile',
// // // // //     'Tongue',
// // // // //     'Twinkle',
// // // // //     'Vomit',
// // // // //   ];

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     _config = AvatarService.instance.config;
// // // // //   }

// // // // //   Future<void> _save() async {
// // // // //     setState(() => _saving = true);
// // // // //     await AvatarService.instance.save(_config);
// // // // //     if (mounted) {
// // // // //       setState(() => _saving = false);
// // // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // // //         const SnackBar(
// // // // //           content: Text('Avatar saved!'),
// // // // //           behavior: SnackBarBehavior.fixed,
// // // // //         ),
// // // // //       );
// // // // //     }
// // // // //   }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final isPremium =
// // // // //         context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
// // // // //     final theme = context.theme;

// // // // //     if (!isPremium) {
// // // // //       return Scaffold(
// // // // //         appBar: AppBar(title: const Text('My Avatar')),
// // // // //         body: Center(
// // // // //           child: Padding(
// // // // //             padding: const EdgeInsets.all(32),
// // // // //             child: Column(
// // // // //               mainAxisSize: MainAxisSize.min,
// // // // //               children: [
// // // // //                 AvatarDisplay(
// // // // //                   avatarUrl: AvatarConfig.defaults.avatarUrl,
// // // // //                   size: 120,
// // // // //                 ),
// // // // //                 const SizedBox(height: 20),
// // // // //                 Text(
// // // // //                   'Custom Avatars',
// // // // //                   style: theme.textTheme.headlineSmall?.copyWith(
// // // // //                     fontWeight: FontWeight.w800,
// // // // //                   ),
// // // // //                 ),
// // // // //                 const SizedBox(height: 8),
// // // // //                 const Text(
// // // // //                   'Create your own Bitmoji-style avatar and show it across the app with Premium.',
// // // // //                   textAlign: TextAlign.center,
// // // // //                 ),
// // // // //                 const SizedBox(height: 24),
// // // // //                 FilledButton(
// // // // //                   onPressed: () => AppRouter.router.push(RouteNames.premium),
// // // // //                   child: const Text('Upgrade to Premium ✦'),
// // // // //                 ),
// // // // //               ],
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //       );
// // // // //     }

// // // // //     return DefaultTabController(
// // // // //       length: 6,
// // // // //       child: Scaffold(
// // // // //         appBar: AppBar(
// // // // //           title: const Text('My Avatar'),
// // // // //           actions: [
// // // // //             _saving
// // // // //                 ? const Padding(
// // // // //                     padding: EdgeInsets.all(16),
// // // // //                     child: SizedBox(
// // // // //                       width: 20,
// // // // //                       height: 20,
// // // // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // // // //                     ),
// // // // //                   )
// // // // //                 : FilledButton.icon(
// // // // //                     onPressed: _save,
// // // // //                     icon: const Icon(Icons.check_rounded, size: 18),
// // // // //                     label: const Text('Save'),
// // // // //                   ),
// // // // //             const SizedBox(width: 8),
// // // // //           ],
// // // // //           bottom: const TabBar(
// // // // //             isScrollable: true,
// // // // //             tabAlignment: TabAlignment.start,
// // // // //             tabs: [
// // // // //               Tab(text: 'Hair'),
// // // // //               Tab(text: 'Face'),
// // // // //               Tab(text: 'Eyes'),
// // // // //               Tab(text: 'Mouth'),
// // // // //               Tab(text: 'Outfit'),
// // // // //               Tab(text: 'Extras'),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //         body: Column(
// // // // //           children: [
// // // // //             Container(
// // // // //               color: theme.colorScheme.surfaceContainerHighest,
// // // // //               padding: const EdgeInsets.symmetric(vertical: 20),
// // // // //               child: Center(
// // // // //                 child: ClipOval(
// // // // //                   child: AvatarDisplay(avatarUrl: _config.avatarUrl, size: 120),
// // // // //                 ),
// // // // //               ),
// // // // //             ),
// // // // //             Expanded(
// // // // //               child: TabBarView(
// // // // //                 children: [
// // // // //                   _TraitTab(
// // // // //                     children: [
// // // // //                       _OptionRow(
// // // // //                         'Hair Style',
// // // // //                         _topTypes,
// // // // //                         _config.topType,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(topType: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                       _OptionRow(
// // // // //                         'Hair Color',
// // // // //                         _hairColors,
// // // // //                         _config.hairColor,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(hairColor: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   _TraitTab(
// // // // //                     children: [
// // // // //                       _OptionRow(
// // // // //                         'Skin Tone',
// // // // //                         _skinColors,
// // // // //                         _config.skinColor,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(skinColor: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                       _OptionRow(
// // // // //                         'Facial Hair',
// // // // //                         _facialHair,
// // // // //                         _config.facialHairType,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(facialHairType: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                       _OptionRow(
// // // // //                         'Facial Hair Color',
// // // // //                         _hairColors,
// // // // //                         _config.facialHairColor,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(facialHairColor: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   _TraitTab(
// // // // //                     children: [
// // // // //                       _OptionRow(
// // // // //                         'Eyes',
// // // // //                         _eyes,
// // // // //                         _config.eyeType,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(eyeType: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                       _OptionRow(
// // // // //                         'Eyebrows',
// // // // //                         _eyebrows,
// // // // //                         _config.eyebrowType,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(eyebrowType: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                       _OptionRow(
// // // // //                         'Accessories',
// // // // //                         _accessories,
// // // // //                         _config.accessoriesType,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(accessoriesType: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   _TraitTab(
// // // // //                     children: [
// // // // //                       _OptionRow(
// // // // //                         'Mouth',
// // // // //                         _mouths,
// // // // //                         _config.mouthType,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(mouthType: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   _TraitTab(
// // // // //                     children: [
// // // // //                       _OptionRow(
// // // // //                         'Outfit',
// // // // //                         _clothes,
// // // // //                         _config.clotheType,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(clotheType: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                       _OptionRow(
// // // // //                         'Outfit Color',
// // // // //                         _clotheColors,
// // // // //                         _config.clotheColor,
// // // // //                         (v) => setState(
// // // // //                           () => _config = _config.copyWith(clotheColor: v),
// // // // //                         ),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                   _TraitTab(
// // // // //                     children: [
// // // // //                       _RandomRow(
// // // // //                         onRandom: () =>
// // // // //                             setState(() => _config = _randomConfig()),
// // // // //                       ),
// // // // //                     ],
// // // // //                   ),
// // // // //                 ],
// // // // //               ),
// // // // //             ),
// // // // //           ],
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }

// // // // //   AvatarConfig _randomConfig() {
// // // // //     final r = DateTime.now().millisecondsSinceEpoch;
// // // // //     T pick<T>(List<T> list) => list[r % list.length];
// // // // //     return AvatarConfig(
// // // // //       topType: pick(_topTypes),
// // // // //       accessoriesType: pick(_accessories),
// // // // //       hairColor: pick(_hairColors),
// // // // //       facialHairType: pick(_facialHair),
// // // // //       facialHairColor: pick(_hairColors),
// // // // //       clotheType: pick(_clothes),
// // // // //       clotheColor: pick(_clotheColors),
// // // // //       eyeType: pick(_eyes),
// // // // //       eyebrowType: pick(_eyebrows),
// // // // //       mouthType: pick(_mouths),
// // // // //       skinColor: pick(_skinColors),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _TraitTab extends StatelessWidget {
// // // // //   const _TraitTab({required this.children});
// // // // //   final List<Widget> children;
// // // // //   @override
// // // // //   Widget build(BuildContext context) =>
// // // // //       ListView(padding: const EdgeInsets.all(16), children: children);
// // // // // }

// // // // // class _OptionRow extends StatelessWidget {
// // // // //   const _OptionRow(this.label, this.options, this.selected, this.onSelect);
// // // // //   final String label;
// // // // //   final List<String> options;
// // // // //   final String selected;
// // // // //   final void Function(String) onSelect;

// // // // //   // String _humanize(String s) => s
// // // // //   //     .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
// // // // //   //     .replaceAll(RegExp(r'\d+'), (m) => ' $m')
// // // // //   //     .trim();
// // // // //   String _humanize(String s) => s
// // // // //       .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
// // // // //       .replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m[0]}')
// // // // //       .trim();

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     final theme = Theme.of(context);
// // // // //     return Column(
// // // // //       crossAxisAlignment: CrossAxisAlignment.start,
// // // // //       children: [
// // // // //         Padding(
// // // // //           padding: const EdgeInsets.only(top: 14, bottom: 8),
// // // // //           child: Text(
// // // // //             label,
// // // // //             style: theme.textTheme.titleSmall?.copyWith(
// // // // //               fontWeight: FontWeight.w800,
// // // // //             ),
// // // // //           ),
// // // // //         ),
// // // // //         SizedBox(
// // // // //           width: double.infinity,
// // // // //           child: Wrap(
// // // // //             spacing: 8,
// // // // //             runSpacing: 8,
// // // // //             children: options
// // // // //                 .map(
// // // // //                   (opt) => ChoiceChip(
// // // // //                     label: Text(
// // // // //                       _humanize(opt),
// // // // //                       style: const TextStyle(fontSize: 12),
// // // // //                     ),
// // // // //                     selected: selected == opt,
// // // // //                     onSelected: (_) => onSelect(opt),
// // // // //                     visualDensity: VisualDensity.compact,
// // // // //                   ),
// // // // //                 )
// // // // //                 .toList(),
// // // // //           ),
// // // // //         ),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class _RandomRow extends StatelessWidget {
// // // // //   const _RandomRow({required this.onRandom});
// // // // //   final VoidCallback onRandom;
// // // // //   @override
// // // // //   Widget build(BuildContext context) => Center(
// // // // //     child: Padding(
// // // // //       padding: const EdgeInsets.all(32),
// // // // //       child: Column(
// // // // //         children: [
// // // // //           const Text('🎲', style: TextStyle(fontSize: 48)),
// // // // //           const SizedBox(height: 12),
// // // // //           const Text(
// // // // //             'Feeling lucky?',
// // // // //             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
// // // // //           ),
// // // // //           const SizedBox(height: 8),
// // // // //           const Text(
// // // // //             'Generate a random avatar instantly.',
// // // // //             textAlign: TextAlign.center,
// // // // //           ),
// // // // //           const SizedBox(height: 20),
// // // // //           FilledButton.icon(
// // // // //             onPressed: onRandom,
// // // // //             icon: const Icon(Icons.shuffle_rounded),
// // // // //             label: const Text('Randomize Avatar'),
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //     ),
// // // // //   );
// // // // // }

// // // // import 'dart:convert';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter_svg/flutter_svg.dart';
// // // // import 'package:provider/provider.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // // import '../../../core/extensions/context_ext.dart';
// // // // import '../../../core/providers/auth_provider.dart';
// // // // import '../../../core/router/route_names.dart';
// // // // import '../../../core/router/app_router.dart';

// // // // class AvatarConfig {
// // // //   const AvatarConfig({
// // // //     this.topType = 'ShortHairShortFlat',
// // // //     this.accessoriesType = 'Blank',
// // // //     this.hairColor = 'BrownDark',
// // // //     this.facialHairType = 'Blank',
// // // //     this.facialHairColor = 'BrownDark',
// // // //     this.clotheType = 'Hoodie',
// // // //     this.clotheColor = 'Blue01',
// // // //     this.eyeType = 'Default',
// // // //     this.eyebrowType = 'Default',
// // // //     this.mouthType = 'Smile',
// // // //     this.skinColor = 'Light',
// // // //   });

// // // //   final String topType;
// // // //   final String accessoriesType;
// // // //   final String hairColor;
// // // //   final String facialHairType;
// // // //   final String facialHairColor;
// // // //   final String clotheType;
// // // //   final String clotheColor;
// // // //   final String eyeType;
// // // //   final String eyebrowType;
// // // //   final String mouthType;
// // // //   final String skinColor;

// // // //   static AvatarConfig get defaults => const AvatarConfig();

// // // //   String get avatarUrl =>
// // // //       'https://avataaars.io/?avatarStyle=Circle'
// // // //       '&topType=$topType'
// // // //       '&accessoriesType=$accessoriesType'
// // // //       '&hairColor=$hairColor'
// // // //       '&facialHairType=$facialHairType'
// // // //       '&facialHairColor=$facialHairColor'
// // // //       '&clotheType=$clotheType'
// // // //       '&clotheColor=$clotheColor'
// // // //       '&eyeType=$eyeType'
// // // //       '&eyebrowType=$eyebrowType'
// // // //       '&mouthType=$mouthType'
// // // //       '&skinColor=$skinColor';

// // // //   Map<String, String> toMap() => {
// // // //     'topType': topType,
// // // //     'accessoriesType': accessoriesType,
// // // //     'hairColor': hairColor,
// // // //     'facialHairType': facialHairType,
// // // //     'facialHairColor': facialHairColor,
// // // //     'clotheType': clotheType,
// // // //     'clotheColor': clotheColor,
// // // //     'eyeType': eyeType,
// // // //     'eyebrowType': eyebrowType,
// // // //     'mouthType': mouthType,
// // // //     'skinColor': skinColor,
// // // //   };

// // // //   factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
// // // //     topType: m['topType'] as String? ?? 'ShortHairShortFlat',
// // // //     accessoriesType: m['accessoriesType'] as String? ?? 'Blank',
// // // //     hairColor: m['hairColor'] as String? ?? 'BrownDark',
// // // //     facialHairType: m['facialHairType'] as String? ?? 'Blank',
// // // //     facialHairColor: m['facialHairColor'] as String? ?? 'BrownDark',
// // // //     clotheType: m['clotheType'] as String? ?? 'Hoodie',
// // // //     clotheColor: m['clotheColor'] as String? ?? 'Blue01',
// // // //     eyeType: m['eyeType'] as String? ?? 'Default',
// // // //     eyebrowType: m['eyebrowType'] as String? ?? 'Default',
// // // //     mouthType: m['mouthType'] as String? ?? 'Smile',
// // // //     skinColor: m['skinColor'] as String? ?? 'Light',
// // // //   );

// // // //   AvatarConfig copyWith({
// // // //     String? topType,
// // // //     String? accessoriesType,
// // // //     String? hairColor,
// // // //     String? facialHairType,
// // // //     String? facialHairColor,
// // // //     String? clotheType,
// // // //     String? clotheColor,
// // // //     String? eyeType,
// // // //     String? eyebrowType,
// // // //     String? mouthType,
// // // //     String? skinColor,
// // // //   }) => AvatarConfig(
// // // //     topType: topType ?? this.topType,
// // // //     accessoriesType: accessoriesType ?? this.accessoriesType,
// // // //     hairColor: hairColor ?? this.hairColor,
// // // //     facialHairType: facialHairType ?? this.facialHairType,
// // // //     facialHairColor: facialHairColor ?? this.facialHairColor,
// // // //     clotheType: clotheType ?? this.clotheType,
// // // //     clotheColor: clotheColor ?? this.clotheColor,
// // // //     eyeType: eyeType ?? this.eyeType,
// // // //     eyebrowType: eyebrowType ?? this.eyebrowType,
// // // //     mouthType: mouthType ?? this.mouthType,
// // // //     skinColor: skinColor ?? this.skinColor,
// // // //   );
// // // // }

// // // // class AvatarService extends ChangeNotifier {
// // // //   AvatarService._();
// // // //   static final AvatarService instance = AvatarService._();

// // // //   static const _prefKey = 'avataaars_config_v1';
// // // //   AvatarConfig _config = AvatarConfig.defaults;
// // // //   AvatarConfig get config => _config;

// // // //   Future<void> load() async {
// // // //     final prefs = await SharedPreferences.getInstance();
// // // //     final raw = prefs.getString(_prefKey);
// // // //     if (raw != null) {
// // // //       try {
// // // //         _config = AvatarConfig.fromMap(
// // // //           Map<String, dynamic>.from(jsonDecode(raw) as Map),
// // // //         );
// // // //       } catch (_) {}
// // // //     }
// // // //     notifyListeners();
// // // //   }

// // // //   Future<void> save(AvatarConfig cfg) async {
// // // //     _config = cfg;
// // // //     final prefs = await SharedPreferences.getInstance();
// // // //     await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
// // // //     final uid = Supabase.instance.client.auth.currentUser?.id;
// // // //     if (uid != null) {
// // // //       await Supabase.instance.client
// // // //           .from('profiles')
// // // //           .update({'avatar_config': cfg.toMap()})
// // // //           .eq('id', uid)
// // // //           .catchError((_) {});
// // // //     }
// // // //     notifyListeners();
// // // //   }
// // // // }

// // // // class AvatarDisplay extends StatelessWidget {
// // // //   const AvatarDisplay({super.key, required this.avatarUrl, required this.size});
// // // //   final String avatarUrl;
// // // //   final double size;

// // // //   @override
// // // //   Widget build(BuildContext context) => SvgPicture.network(
// // // //     avatarUrl,
// // // //     width: size,
// // // //     height: size,
// // // //     placeholderBuilder: (_) => SizedBox(
// // // //       width: size,
// // // //       height: size,
// // // //       child: CircleAvatar(
// // // //         radius: size / 2,
// // // //         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
// // // //         child: Icon(
// // // //           Icons.person,
// // // //           size: size * 0.5,
// // // //           color: Theme.of(context).colorScheme.onPrimaryContainer,
// // // //         ),
// // // //       ),
// // // //     ),
// // // //   );
// // // // }

// // // // class AvatarCreatorScreen extends StatefulWidget {
// // // //   const AvatarCreatorScreen({super.key});
// // // //   @override
// // // //   State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
// // // // }

// // // // class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
// // // //   late AvatarConfig _config;
// // // //   bool _saving = false;

// // // //   static const _skinColors = [
// // // //     'Tanned',
// // // //     'Yellow',
// // // //     'Pale',
// // // //     'Light',
// // // //     'Brown',
// // // //     'DarkBrown',
// // // //     'Black',
// // // //   ];
// // // //   static const _hairColors = [
// // // //     'Auburn',
// // // //     'Black',
// // // //     'Blonde',
// // // //     'BlondeGolden',
// // // //     'Brown',
// // // //     'BrownDark',
// // // //     'PastelPink',
// // // //     'Platinum',
// // // //     'Red',
// // // //     'SilverGray',
// // // //   ];
// // // //   static const _topTypes = [
// // // //     'NoHair',
// // // //     'Eyepatch',
// // // //     'Hat',
// // // //     'Hijab',
// // // //     'Turban',
// // // //     'WinterHat1',
// // // //     'WinterHat2',
// // // //     'WinterHat3',
// // // //     'WinterHat4',
// // // //     'LongHairBigHair',
// // // //     'LongHairBob',
// // // //     'LongHairBun',
// // // //     'LongHairCurly',
// // // //     'LongHairCurvy',
// // // //     'LongHairDreads',
// // // //     'LongHairFrida',
// // // //     'LongHairFro',
// // // //     'LongHairFroBand',
// // // //     'LongHairNotTooLong',
// // // //     'LongHairShavedSides',
// // // //     'LongHairMiaWallace',
// // // //     'LongHairStraight',
// // // //     'LongHairStraight2',
// // // //     'LongHairStraightStrand',
// // // //     'ShortHairDreads01',
// // // //     'ShortHairDreads02',
// // // //     'ShortHairFrizzle',
// // // //     'ShortHairShaggyMullet',
// // // //     'ShortHairShortCurly',
// // // //     'ShortHairShortFlat',
// // // //     'ShortHairShortRound',
// // // //     'ShortHairShortWaved',
// // // //     'ShortHairSides',
// // // //     'ShortHairTheCaesar',
// // // //     'ShortHairTheCaesarSidePart',
// // // //   ];
// // // //   static const _accessories = [
// // // //     'Blank',
// // // //     'Kurt',
// // // //     'Prescription01',
// // // //     'Prescription02',
// // // //     'Round',
// // // //     'Sunglasses',
// // // //     'Wayfarers',
// // // //   ];
// // // //   static const _facialHair = [
// // // //     'Blank',
// // // //     'BeardMedium',
// // // //     'BeardLight',
// // // //     'BeardMagestic',
// // // //     'MoustacheFancy',
// // // //     'MoustacheMagnum',
// // // //   ];
// // // //   static const _clothes = [
// // // //     'BlazerShirt',
// // // //     'BlazerSweater',
// // // //     'CollarSweater',
// // // //     'GraphicShirt',
// // // //     'Hoodie',
// // // //     'Overall',
// // // //     'ShirtCrewNeck',
// // // //     'ShirtScoopNeck',
// // // //     'ShirtVNeck',
// // // //   ];
// // // //   static const _clotheColors = [
// // // //     'Black',
// // // //     'Blue01',
// // // //     'Blue02',
// // // //     'Blue03',
// // // //     'Gray01',
// // // //     'Gray02',
// // // //     'Heather',
// // // //     'PastelBlue',
// // // //     'PastelGreen',
// // // //     'PastelOrange',
// // // //     'PastelRed',
// // // //     'PastelYellow',
// // // //     'Pink',
// // // //     'Red',
// // // //     'White',
// // // //   ];
// // // //   static const _eyes = [
// // // //     'Close',
// // // //     'Cry',
// // // //     'Default',
// // // //     'Dizzy',
// // // //     'EyeRoll',
// // // //     'Happy',
// // // //     'Hearts',
// // // //     'Side',
// // // //     'Squint',
// // // //     'Surprised',
// // // //     'Wink',
// // // //     'WinkWacky',
// // // //   ];
// // // //   static const _eyebrows = [
// // // //     'Angry',
// // // //     'AngryNatural',
// // // //     'Default',
// // // //     'DefaultNatural',
// // // //     'FlatNatural',
// // // //     'RaisedExcited',
// // // //     'RaisedExcitedNatural',
// // // //     'SadConcerned',
// // // //     'SadConcernedNatural',
// // // //     'UnibrowNatural',
// // // //     'UpDown',
// // // //     'UpDownNatural',
// // // //   ];
// // // //   static const _mouths = [
// // // //     'Concerned',
// // // //     'Default',
// // // //     'Disbelief',
// // // //     'Eating',
// // // //     'Grimace',
// // // //     'Sad',
// // // //     'ScreamOpen',
// // // //     'Serious',
// // // //     'Smile',
// // // //     'Tongue',
// // // //     'Twinkle',
// // // //     'Vomit',
// // // //   ];

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     _config = AvatarService.instance.config;
// // // //   }

// // // //   Future<void> _save() async {
// // // //     setState(() => _saving = true);
// // // //     await AvatarService.instance.save(_config);
// // // //     if (mounted) {
// // // //       setState(() => _saving = false);
// // // //       ScaffoldMessenger.of(context).showSnackBar(
// // // //         const SnackBar(
// // // //           content: Text('Avatar saved!'),
// // // //           behavior: SnackBarBehavior.fixed,
// // // //         ),
// // // //       );
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final isPremium =
// // // //         context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
// // // //     final theme = context.theme;

// // // //     if (!isPremium) {
// // // //       return Scaffold(
// // // //         appBar: AppBar(title: const Text('My Avatar')),
// // // //         body: Center(
// // // //           child: Padding(
// // // //             padding: const EdgeInsets.all(32),
// // // //             child: Column(
// // // //               mainAxisSize: MainAxisSize.min,
// // // //               children: [
// // // //                 AvatarDisplay(
// // // //                   avatarUrl: AvatarConfig.defaults.avatarUrl,
// // // //                   size: 120,
// // // //                 ),
// // // //                 const SizedBox(height: 20),
// // // //                 Text(
// // // //                   'Custom Avatars',
// // // //                   style: theme.textTheme.headlineSmall?.copyWith(
// // // //                     fontWeight: FontWeight.w800,
// // // //                   ),
// // // //                 ),
// // // //                 const SizedBox(height: 8),
// // // //                 const Text(
// // // //                   'Create your own Bitmoji-style avatar and show it across the app with Premium.',
// // // //                   textAlign: TextAlign.center,
// // // //                 ),
// // // //                 const SizedBox(height: 24),
// // // //                 FilledButton(
// // // //                   onPressed: () => AppRouter.router.push(RouteNames.premium),
// // // //                   child: const Text('Upgrade to Premium ✦'),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       );
// // // //     }

// // // //     return DefaultTabController(
// // // //       length: 6,
// // // //       child: Scaffold(
// // // //         appBar: AppBar(
// // // //           title: const Text('My Avatar'),
// // // //           actions: [
// // // //             _saving
// // // //                 ? const Padding(
// // // //                     padding: EdgeInsets.all(16),
// // // //                     child: SizedBox(
// // // //                       width: 20,
// // // //                       height: 20,
// // // //                       child: CircularProgressIndicator(strokeWidth: 2),
// // // //                     ),
// // // //                   )
// // // //                 : FilledButton.icon(
// // // //                     onPressed: _save,
// // // //                     icon: const Icon(Icons.check_rounded, size: 18),
// // // //                     label: const Text('Save'),
// // // //                   ),
// // // //             const SizedBox(width: 8),
// // // //           ],
// // // //           bottom: const TabBar(
// // // //             isScrollable: true,
// // // //             tabAlignment: TabAlignment.start,
// // // //             tabs: [
// // // //               Tab(text: 'Hair'),
// // // //               Tab(text: 'Face'),
// // // //               Tab(text: 'Eyes'),
// // // //               Tab(text: 'Mouth'),
// // // //               Tab(text: 'Outfit'),
// // // //               Tab(text: 'Extras'),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //         body: Column(
// // // //           children: [
// // // //             Container(
// // // //               color: theme.colorScheme.surfaceContainerHighest,
// // // //               padding: const EdgeInsets.symmetric(vertical: 20),
// // // //               child: Center(
// // // //                 child: ClipOval(
// // // //                   child: AvatarDisplay(avatarUrl: _config.avatarUrl, size: 120),
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //             Expanded(
// // // //               child: TabBarView(
// // // //                 children: [
// // // //                   _TraitTab(
// // // //                     children: [
// // // //                       _OptionRow(
// // // //                         'Hair Style',
// // // //                         _topTypes,
// // // //                         _config.topType,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(topType: v),
// // // //                         ),
// // // //                       ),
// // // //                       _OptionRow(
// // // //                         'Hair Color',
// // // //                         _hairColors,
// // // //                         _config.hairColor,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(hairColor: v),
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   _TraitTab(
// // // //                     children: [
// // // //                       _OptionRow(
// // // //                         'Skin Tone',
// // // //                         _skinColors,
// // // //                         _config.skinColor,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(skinColor: v),
// // // //                         ),
// // // //                       ),
// // // //                       _OptionRow(
// // // //                         'Facial Hair',
// // // //                         _facialHair,
// // // //                         _config.facialHairType,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(facialHairType: v),
// // // //                         ),
// // // //                       ),
// // // //                       _OptionRow(
// // // //                         'Facial Hair Color',
// // // //                         _hairColors,
// // // //                         _config.facialHairColor,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(facialHairColor: v),
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   _TraitTab(
// // // //                     children: [
// // // //                       _OptionRow(
// // // //                         'Eyes',
// // // //                         _eyes,
// // // //                         _config.eyeType,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(eyeType: v),
// // // //                         ),
// // // //                       ),
// // // //                       _OptionRow(
// // // //                         'Eyebrows',
// // // //                         _eyebrows,
// // // //                         _config.eyebrowType,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(eyebrowType: v),
// // // //                         ),
// // // //                       ),
// // // //                       _OptionRow(
// // // //                         'Accessories',
// // // //                         _accessories,
// // // //                         _config.accessoriesType,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(accessoriesType: v),
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   _TraitTab(
// // // //                     children: [
// // // //                       _OptionRow(
// // // //                         'Mouth',
// // // //                         _mouths,
// // // //                         _config.mouthType,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(mouthType: v),
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   _TraitTab(
// // // //                     children: [
// // // //                       _OptionRow(
// // // //                         'Outfit',
// // // //                         _clothes,
// // // //                         _config.clotheType,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(clotheType: v),
// // // //                         ),
// // // //                       ),
// // // //                       _OptionRow(
// // // //                         'Outfit Color',
// // // //                         _clotheColors,
// // // //                         _config.clotheColor,
// // // //                         (v) => setState(
// // // //                           () => _config = _config.copyWith(clotheColor: v),
// // // //                         ),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                   _TraitTab(
// // // //                     children: [
// // // //                       _RandomRow(
// // // //                         onRandom: () =>
// // // //                             setState(() => _config = _randomConfig()),
// // // //                       ),
// // // //                     ],
// // // //                   ),
// // // //                 ],
// // // //               ),
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }

// // // //   AvatarConfig _randomConfig() {
// // // //     final r = DateTime.now().millisecondsSinceEpoch;
// // // //     T pick<T>(List<T> list) => list[r % list.length];
// // // //     return AvatarConfig(
// // // //       topType: pick(_topTypes),
// // // //       accessoriesType: pick(_accessories),
// // // //       hairColor: pick(_hairColors),
// // // //       facialHairType: pick(_facialHair),
// // // //       facialHairColor: pick(_hairColors),
// // // //       clotheType: pick(_clothes),
// // // //       clotheColor: pick(_clotheColors),
// // // //       eyeType: pick(_eyes),
// // // //       eyebrowType: pick(_eyebrows),
// // // //       mouthType: pick(_mouths),
// // // //       skinColor: pick(_skinColors),
// // // //     );
// // // //   }
// // // // }

// // // // class _TraitTab extends StatelessWidget {
// // // //   const _TraitTab({required this.children});
// // // //   final List<Widget> children;
// // // //   @override
// // // //   Widget build(BuildContext context) =>
// // // //       ListView(padding: const EdgeInsets.all(16), children: children);
// // // // }

// // // // class _OptionRow extends StatelessWidget {
// // // //   const _OptionRow(this.label, this.options, this.selected, this.onSelect);
// // // //   final String label;
// // // //   final List<String> options;
// // // //   final String selected;
// // // //   final void Function(String) onSelect;

// // // //   // String _humanize(String s) => s
// // // //   //     .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
// // // //   //     .replaceAll(RegExp(r'\d+'), (m) => ' $m')
// // // //   //     .trim();

// // // //   String _humanize(String s) => s
// // // //       .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
// // // //       .replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m[0]}')
// // // //       .trim();

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     final theme = Theme.of(context);
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(top: 14, bottom: 4),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.stretch,
// // // //         children: [
// // // //           Text(
// // // //             label,
// // // //             style: theme.textTheme.titleSmall?.copyWith(
// // // //               fontWeight: FontWeight.w800,
// // // //             ),
// // // //           ),
// // // //           const SizedBox(height: 8),
// // // //           Wrap(
// // // //             spacing: 8,
// // // //             runSpacing: 8,
// // // //             children: options
// // // //                 .map(
// // // //                   (opt) => ChoiceChip(
// // // //                     label: Text(
// // // //                       _humanize(opt),
// // // //                       style: const TextStyle(fontSize: 12),
// // // //                     ),
// // // //                     selected: selected == opt,
// // // //                     onSelected: (_) => onSelect(opt),
// // // //                     visualDensity: VisualDensity.compact,
// // // //                   ),
// // // //                 )
// // // //                 .toList(),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class _RandomRow extends StatelessWidget {
// // // //   const _RandomRow({required this.onRandom});
// // // //   final VoidCallback onRandom;
// // // //   @override
// // // //   Widget build(BuildContext context) => Center(
// // // //     child: Padding(
// // // //       padding: const EdgeInsets.all(32),
// // // //       child: Column(
// // // //         children: [
// // // //           const Text('🎲', style: TextStyle(fontSize: 48)),
// // // //           const SizedBox(height: 12),
// // // //           const Text(
// // // //             'Feeling lucky?',
// // // //             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
// // // //           ),
// // // //           const SizedBox(height: 8),
// // // //           const Text(
// // // //             'Generate a random avatar instantly.',
// // // //             textAlign: TextAlign.center,
// // // //           ),
// // // //           const SizedBox(height: 20),
// // // //           FilledButton.icon(
// // // //             onPressed: onRandom,
// // // //             icon: const Icon(Icons.shuffle_rounded),
// // // //             label: const Text('Randomize Avatar'),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     ),
// // // //   );
// // // // }

// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_svg/flutter_svg.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:supabase_flutter/supabase_flutter.dart';

// // // import '../../../core/extensions/context_ext.dart';
// // // import '../../../core/providers/auth_provider.dart';
// // // import '../../../core/router/route_names.dart';
// // // import '../../../core/router/app_router.dart';

// // // class AvatarConfig {
// // //   const AvatarConfig({
// // //     this.topType = 'ShortHairShortFlat',
// // //     this.accessoriesType = 'Blank',
// // //     this.hairColor = 'BrownDark',
// // //     this.facialHairType = 'Blank',
// // //     this.facialHairColor = 'BrownDark',
// // //     this.clotheType = 'Hoodie',
// // //     this.clotheColor = 'Blue01',
// // //     this.eyeType = 'Default',
// // //     this.eyebrowType = 'Default',
// // //     this.mouthType = 'Smile',
// // //     this.skinColor = 'Light',
// // //   });

// // //   final String topType;
// // //   final String accessoriesType;
// // //   final String hairColor;
// // //   final String facialHairType;
// // //   final String facialHairColor;
// // //   final String clotheType;
// // //   final String clotheColor;
// // //   final String eyeType;
// // //   final String eyebrowType;
// // //   final String mouthType;
// // //   final String skinColor;

// // //   static AvatarConfig get defaults => const AvatarConfig();

// // //   String get avatarUrl =>
// // //       'https://avataaars.io/?avatarStyle=Circle'
// // //       '&topType=$topType'
// // //       '&accessoriesType=$accessoriesType'
// // //       '&hairColor=$hairColor'
// // //       '&facialHairType=$facialHairType'
// // //       '&facialHairColor=$facialHairColor'
// // //       '&clotheType=$clotheType'
// // //       '&clotheColor=$clotheColor'
// // //       '&eyeType=$eyeType'
// // //       '&eyebrowType=$eyebrowType'
// // //       '&mouthType=$mouthType'
// // //       '&skinColor=$skinColor';

// // //   Map<String, String> toMap() => {
// // //     'topType': topType,
// // //     'accessoriesType': accessoriesType,
// // //     'hairColor': hairColor,
// // //     'facialHairType': facialHairType,
// // //     'facialHairColor': facialHairColor,
// // //     'clotheType': clotheType,
// // //     'clotheColor': clotheColor,
// // //     'eyeType': eyeType,
// // //     'eyebrowType': eyebrowType,
// // //     'mouthType': mouthType,
// // //     'skinColor': skinColor,
// // //   };

// // //   factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
// // //     topType: m['topType'] as String? ?? 'ShortHairShortFlat',
// // //     accessoriesType: m['accessoriesType'] as String? ?? 'Blank',
// // //     hairColor: m['hairColor'] as String? ?? 'BrownDark',
// // //     facialHairType: m['facialHairType'] as String? ?? 'Blank',
// // //     facialHairColor: m['facialHairColor'] as String? ?? 'BrownDark',
// // //     clotheType: m['clotheType'] as String? ?? 'Hoodie',
// // //     clotheColor: m['clotheColor'] as String? ?? 'Blue01',
// // //     eyeType: m['eyeType'] as String? ?? 'Default',
// // //     eyebrowType: m['eyebrowType'] as String? ?? 'Default',
// // //     mouthType: m['mouthType'] as String? ?? 'Smile',
// // //     skinColor: m['skinColor'] as String? ?? 'Light',
// // //   );

// // //   AvatarConfig copyWith({
// // //     String? topType,
// // //     String? accessoriesType,
// // //     String? hairColor,
// // //     String? facialHairType,
// // //     String? facialHairColor,
// // //     String? clotheType,
// // //     String? clotheColor,
// // //     String? eyeType,
// // //     String? eyebrowType,
// // //     String? mouthType,
// // //     String? skinColor,
// // //   }) => AvatarConfig(
// // //     topType: topType ?? this.topType,
// // //     accessoriesType: accessoriesType ?? this.accessoriesType,
// // //     hairColor: hairColor ?? this.hairColor,
// // //     facialHairType: facialHairType ?? this.facialHairType,
// // //     facialHairColor: facialHairColor ?? this.facialHairColor,
// // //     clotheType: clotheType ?? this.clotheType,
// // //     clotheColor: clotheColor ?? this.clotheColor,
// // //     eyeType: eyeType ?? this.eyeType,
// // //     eyebrowType: eyebrowType ?? this.eyebrowType,
// // //     mouthType: mouthType ?? this.mouthType,
// // //     skinColor: skinColor ?? this.skinColor,
// // //   );
// // // }

// // // class AvatarService extends ChangeNotifier {
// // //   AvatarService._();
// // //   static final AvatarService instance = AvatarService._();

// // //   static const _prefKey = 'avataaars_config_v1';
// // //   AvatarConfig _config = AvatarConfig.defaults;
// // //   AvatarConfig get config => _config;

// // //   Future<void> load() async {
// // //     final prefs = await SharedPreferences.getInstance();
// // //     final raw = prefs.getString(_prefKey);
// // //     if (raw != null) {
// // //       try {
// // //         _config = AvatarConfig.fromMap(
// // //           Map<String, dynamic>.from(jsonDecode(raw) as Map),
// // //         );
// // //       } catch (_) {}
// // //     }
// // //     notifyListeners();
// // //   }

// // //   Future<void> save(AvatarConfig cfg) async {
// // //     _config = cfg;
// // //     final prefs = await SharedPreferences.getInstance();
// // //     await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
// // //     final uid = Supabase.instance.client.auth.currentUser?.id;
// // //     if (uid != null) {
// // //       await Supabase.instance.client
// // //           .from('profiles')
// // //           .update({'avatar_config': cfg.toMap()})
// // //           .eq('id', uid)
// // //           .catchError((_) {});
// // //     }
// // //     notifyListeners();
// // //   }
// // // }

// // // class AvatarDisplay extends StatelessWidget {
// // //   const AvatarDisplay({super.key, required this.avatarUrl, required this.size});
// // //   final String avatarUrl;
// // //   final double size;

// // //   @override
// // //   Widget build(BuildContext context) => SvgPicture.network(
// // //     avatarUrl,
// // //     width: size,
// // //     height: size,
// // //     placeholderBuilder: (_) => SizedBox(
// // //       width: size,
// // //       height: size,
// // //       child: CircleAvatar(
// // //         radius: size / 2,
// // //         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
// // //         child: Icon(
// // //           Icons.person,
// // //           size: size * 0.5,
// // //           color: Theme.of(context).colorScheme.onPrimaryContainer,
// // //         ),
// // //       ),
// // //     ),
// // //   );
// // // }

// // // class AvatarCreatorScreen extends StatefulWidget {
// // //   const AvatarCreatorScreen({super.key});
// // //   @override
// // //   State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
// // // }

// // // class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
// // //   late AvatarConfig _config;
// // //   bool _saving = false;

// // //   static const _skinColors = [
// // //     'Tanned',
// // //     'Yellow',
// // //     'Pale',
// // //     'Light',
// // //     'Brown',
// // //     'DarkBrown',
// // //     'Black',
// // //   ];
// // //   static const _hairColors = [
// // //     'Auburn',
// // //     'Black',
// // //     'Blonde',
// // //     'BlondeGolden',
// // //     'Brown',
// // //     'BrownDark',
// // //     'PastelPink',
// // //     'Platinum',
// // //     'Red',
// // //     'SilverGray',
// // //   ];
// // //   static const _topTypes = [
// // //     'NoHair',
// // //     'Eyepatch',
// // //     'Hat',
// // //     'Hijab',
// // //     'Turban',
// // //     'WinterHat1',
// // //     'WinterHat2',
// // //     'WinterHat3',
// // //     'WinterHat4',
// // //     'LongHairBigHair',
// // //     'LongHairBob',
// // //     'LongHairBun',
// // //     'LongHairCurly',
// // //     'LongHairCurvy',
// // //     'LongHairDreads',
// // //     'LongHairFrida',
// // //     'LongHairFro',
// // //     'LongHairFroBand',
// // //     'LongHairNotTooLong',
// // //     'LongHairShavedSides',
// // //     'LongHairMiaWallace',
// // //     'LongHairStraight',
// // //     'LongHairStraight2',
// // //     'LongHairStraightStrand',
// // //     'ShortHairDreads01',
// // //     'ShortHairDreads02',
// // //     'ShortHairFrizzle',
// // //     'ShortHairShaggyMullet',
// // //     'ShortHairShortCurly',
// // //     'ShortHairShortFlat',
// // //     'ShortHairShortRound',
// // //     'ShortHairShortWaved',
// // //     'ShortHairSides',
// // //     'ShortHairTheCaesar',
// // //     'ShortHairTheCaesarSidePart',
// // //   ];
// // //   static const _accessories = [
// // //     'Blank',
// // //     'Kurt',
// // //     'Prescription01',
// // //     'Prescription02',
// // //     'Round',
// // //     'Sunglasses',
// // //     'Wayfarers',
// // //   ];
// // //   static const _facialHair = [
// // //     'Blank',
// // //     'BeardMedium',
// // //     'BeardLight',
// // //     'BeardMagestic',
// // //     'MoustacheFancy',
// // //     'MoustacheMagnum',
// // //   ];
// // //   static const _clothes = [
// // //     'BlazerShirt',
// // //     'BlazerSweater',
// // //     'CollarSweater',
// // //     'GraphicShirt',
// // //     'Hoodie',
// // //     'Overall',
// // //     'ShirtCrewNeck',
// // //     'ShirtScoopNeck',
// // //     'ShirtVNeck',
// // //   ];
// // //   static const _clotheColors = [
// // //     'Black',
// // //     'Blue01',
// // //     'Blue02',
// // //     'Blue03',
// // //     'Gray01',
// // //     'Gray02',
// // //     'Heather',
// // //     'PastelBlue',
// // //     'PastelGreen',
// // //     'PastelOrange',
// // //     'PastelRed',
// // //     'PastelYellow',
// // //     'Pink',
// // //     'Red',
// // //     'White',
// // //   ];
// // //   static const _eyes = [
// // //     'Close',
// // //     'Cry',
// // //     'Default',
// // //     'Dizzy',
// // //     'EyeRoll',
// // //     'Happy',
// // //     'Hearts',
// // //     'Side',
// // //     'Squint',
// // //     'Surprised',
// // //     'Wink',
// // //     'WinkWacky',
// // //   ];
// // //   static const _eyebrows = [
// // //     'Angry',
// // //     'AngryNatural',
// // //     'Default',
// // //     'DefaultNatural',
// // //     'FlatNatural',
// // //     'RaisedExcited',
// // //     'RaisedExcitedNatural',
// // //     'SadConcerned',
// // //     'SadConcernedNatural',
// // //     'UnibrowNatural',
// // //     'UpDown',
// // //     'UpDownNatural',
// // //   ];
// // //   static const _mouths = [
// // //     'Concerned',
// // //     'Default',
// // //     'Disbelief',
// // //     'Eating',
// // //     'Grimace',
// // //     'Sad',
// // //     'ScreamOpen',
// // //     'Serious',
// // //     'Smile',
// // //     'Tongue',
// // //     'Twinkle',
// // //     'Vomit',
// // //   ];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _config = AvatarService.instance.config;
// // //   }

// // //   Future<void> _save() async {
// // //     setState(() => _saving = true);
// // //     await AvatarService.instance.save(_config);
// // //     if (mounted) {
// // //       setState(() => _saving = false);
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         const SnackBar(
// // //           content: Text('Avatar saved! ✦'),
// // //           behavior: SnackBarBehavior.fixed,
// // //           duration: Duration(seconds: 2),
// // //         ),
// // //       );
// // //     }
// // //   }

// // //   void _updateConfig(AvatarConfig cfg) => setState(() => _config = cfg);

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final isPremium =
// // //         context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
// // //     final theme = context.theme;

// // //     if (!isPremium) {
// // //       return Scaffold(
// // //         appBar: AppBar(title: const Text('My Avatar')),
// // //         body: Center(
// // //           child: Padding(
// // //             padding: const EdgeInsets.all(32),
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 AvatarDisplay(
// // //                   avatarUrl: AvatarConfig.defaults.avatarUrl,
// // //                   size: 120,
// // //                 ),
// // //                 const SizedBox(height: 20),
// // //                 Text(
// // //                   'Custom Avatars',
// // //                   style: theme.textTheme.headlineSmall?.copyWith(
// // //                     fontWeight: FontWeight.w800,
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 const Text(
// // //                   'Create your own Bitmoji-style avatar and show it across the app with Premium.',
// // //                   textAlign: TextAlign.center,
// // //                 ),
// // //                 const SizedBox(height: 24),
// // //                 FilledButton(
// // //                   onPressed: () => AppRouter.router.push(RouteNames.premium),
// // //                   child: const Text('Upgrade to Premium ✦'),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //       );
// // //     }

// // //     return DefaultTabController(
// // //       length: 6,
// // //       child: Scaffold(
// // //         appBar: AppBar(
// // //           title: const Text('My Avatar'),
// // //           bottom: const TabBar(
// // //             isScrollable: true,
// // //             tabAlignment: TabAlignment.start,
// // //             tabs: [
// // //               Tab(text: 'Hair'),
// // //               Tab(text: 'Face'),
// // //               Tab(text: 'Eyes'),
// // //               Tab(text: 'Mouth'),
// // //               Tab(text: 'Outfit'),
// // //               Tab(text: 'Extras'),
// // //             ],
// // //           ),
// // //         ),
// // //         floatingActionButton: FloatingActionButton.extended(
// // //           onPressed: _saving ? null : _save,
// // //           icon: _saving
// // //               ? const SizedBox(
// // //                   width: 18,
// // //                   height: 18,
// // //                   child: CircularProgressIndicator(
// // //                     strokeWidth: 2,
// // //                     color: Colors.white,
// // //                   ),
// // //                 )
// // //               : const Icon(Icons.check_rounded),
// // //           label: Text(_saving ? 'Saving…' : 'Save Avatar'),
// // //         ),
// // //         body: Column(
// // //           children: [
// // //             Container(
// // //               color: theme.colorScheme.surfaceContainerHighest,
// // //               padding: const EdgeInsets.symmetric(vertical: 20),
// // //               child: Center(
// // //                 child: ClipOval(
// // //                   child: AvatarDisplay(avatarUrl: _config.avatarUrl, size: 120),
// // //                 ),
// // //               ),
// // //             ),
// // //             Expanded(
// // //               child: TabBarView(
// // //                 children: [
// // //                   _TraitTab(
// // //                     children: [
// // //                       _OptionRow(
// // //                         'Hair Style',
// // //                         _topTypes,
// // //                         _config.topType,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(topType: v),
// // //                         ),
// // //                       ),
// // //                       _OptionRow(
// // //                         'Hair Color',
// // //                         _hairColors,
// // //                         _config.hairColor,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(hairColor: v),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   _TraitTab(
// // //                     children: [
// // //                       _OptionRow(
// // //                         'Skin Tone',
// // //                         _skinColors,
// // //                         _config.skinColor,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(skinColor: v),
// // //                         ),
// // //                       ),
// // //                       _OptionRow(
// // //                         'Facial Hair',
// // //                         _facialHair,
// // //                         _config.facialHairType,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(facialHairType: v),
// // //                         ),
// // //                       ),
// // //                       _OptionRow(
// // //                         'Facial Hair Color',
// // //                         _hairColors,
// // //                         _config.facialHairColor,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(facialHairColor: v),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   _TraitTab(
// // //                     children: [
// // //                       _OptionRow(
// // //                         'Eyes',
// // //                         _eyes,
// // //                         _config.eyeType,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(eyeType: v),
// // //                         ),
// // //                       ),
// // //                       _OptionRow(
// // //                         'Eyebrows',
// // //                         _eyebrows,
// // //                         _config.eyebrowType,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(eyebrowType: v),
// // //                         ),
// // //                       ),
// // //                       _OptionRow(
// // //                         'Accessories',
// // //                         _accessories,
// // //                         _config.accessoriesType,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(accessoriesType: v),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   _TraitTab(
// // //                     children: [
// // //                       _OptionRow(
// // //                         'Mouth',
// // //                         _mouths,
// // //                         _config.mouthType,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(mouthType: v),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   _TraitTab(
// // //                     children: [
// // //                       _OptionRow(
// // //                         'Outfit',
// // //                         _clothes,
// // //                         _config.clotheType,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(clotheType: v),
// // //                         ),
// // //                       ),
// // //                       _OptionRow(
// // //                         'Outfit Color',
// // //                         _clotheColors,
// // //                         _config.clotheColor,
// // //                         (v) => setState(
// // //                           () => _config = _config.copyWith(clotheColor: v),
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   _TraitTab(
// // //                     children: [
// // //                       _RandomRow(
// // //                         onRandom: () =>
// // //                             setState(() => _config = _randomConfig()),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   AvatarConfig _randomConfig() {
// // //     final r = DateTime.now().millisecondsSinceEpoch;
// // //     T pick<T>(List<T> list) => list[r % list.length];
// // //     return AvatarConfig(
// // //       topType: pick(_topTypes),
// // //       accessoriesType: pick(_accessories),
// // //       hairColor: pick(_hairColors),
// // //       facialHairType: pick(_facialHair),
// // //       facialHairColor: pick(_hairColors),
// // //       clotheType: pick(_clothes),
// // //       clotheColor: pick(_clotheColors),
// // //       eyeType: pick(_eyes),
// // //       eyebrowType: pick(_eyebrows),
// // //       mouthType: pick(_mouths),
// // //       skinColor: pick(_skinColors),
// // //     );
// // //   }
// // // }

// // // class _TraitTab extends StatelessWidget {
// // //   const _TraitTab({required this.children});
// // //   final List<Widget> children;
// // //   @override
// // //   Widget build(BuildContext context) =>
// // //       ListView(padding: const EdgeInsets.all(16), children: children);
// // // }

// // // class _OptionRow extends StatelessWidget {
// // //   const _OptionRow(this.label, this.options, this.selected, this.onSelect);
// // //   final String label;
// // //   final List<String> options;
// // //   final String selected;
// // //   final void Function(String) onSelect;

// // //   String _humanize(String s) => s
// // //       .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
// // //       .replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m[0]}')
// // //       .trim();

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final theme = Theme.of(context);
// // //     return Padding(
// // //       padding: const EdgeInsets.only(top: 14, bottom: 4),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.stretch,
// // //         children: [
// // //           Text(
// // //             label,
// // //             style: theme.textTheme.titleSmall?.copyWith(
// // //               fontWeight: FontWeight.w800,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           Wrap(
// // //             spacing: 8,
// // //             runSpacing: 8,
// // //             children: options
// // //                 .map(
// // //                   (opt) => ChoiceChip(
// // //                     label: Text(
// // //                       _humanize(opt),
// // //                       style: const TextStyle(fontSize: 12),
// // //                     ),
// // //                     selected: selected == opt,
// // //                     onSelected: (_) => onSelect(opt),
// // //                     visualDensity: VisualDensity.compact,
// // //                   ),
// // //                 )
// // //                 .toList(),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }

// // // class _RandomRow extends StatelessWidget {
// // //   const _RandomRow({required this.onRandom});
// // //   final VoidCallback onRandom;
// // //   @override
// // //   Widget build(BuildContext context) => Center(
// // //     child: Padding(
// // //       padding: const EdgeInsets.all(32),
// // //       child: Column(
// // //         children: [
// // //           const Text('🎲', style: TextStyle(fontSize: 48)),
// // //           const SizedBox(height: 12),
// // //           const Text(
// // //             'Feeling lucky?',
// // //             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
// // //           ),
// // //           const SizedBox(height: 8),
// // //           const Text(
// // //             'Generate a random avatar instantly.',
// // //             textAlign: TextAlign.center,
// // //           ),
// // //           const SizedBox(height: 20),
// // //           FilledButton.icon(
// // //             onPressed: onRandom,
// // //             icon: const Icon(Icons.shuffle_rounded),
// // //             label: const Text('Randomize Avatar'),
// // //           ),
// // //         ],
// // //       ),
// // //     ),
// // //   );
// // // }

// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_svg/flutter_svg.dart';
// // import 'package:provider/provider.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import '../../../core/extensions/context_ext.dart';
// // import '../../../core/providers/auth_provider.dart';
// // import '../../../core/router/route_names.dart';
// // import '../../../core/router/app_router.dart';

// // class AvatarConfig {
// //   const AvatarConfig({
// //     this.topType = 'ShortHairShortFlat',
// //     this.accessoriesType = 'Blank',
// //     this.hairColor = 'BrownDark',
// //     this.facialHairType = 'Blank',
// //     this.facialHairColor = 'BrownDark',
// //     this.clotheType = 'Hoodie',
// //     this.clotheColor = 'Blue01',
// //     this.eyeType = 'Default',
// //     this.eyebrowType = 'Default',
// //     this.mouthType = 'Smile',
// //     this.skinColor = 'Light',
// //   });

// //   final String topType;
// //   final String accessoriesType;
// //   final String hairColor;
// //   final String facialHairType;
// //   final String facialHairColor;
// //   final String clotheType;
// //   final String clotheColor;
// //   final String eyeType;
// //   final String eyebrowType;
// //   final String mouthType;
// //   final String skinColor;

// //   static AvatarConfig get defaults => const AvatarConfig();

// //   String get avatarUrl =>
// //       'https://avataaars.io/?avatarStyle=Circle'
// //       '&topType=$topType'
// //       '&accessoriesType=$accessoriesType'
// //       '&hairColor=$hairColor'
// //       '&facialHairType=$facialHairType'
// //       '&facialHairColor=$facialHairColor'
// //       '&clotheType=$clotheType'
// //       '&clotheColor=$clotheColor'
// //       '&eyeType=$eyeType'
// //       '&eyebrowType=$eyebrowType'
// //       '&mouthType=$mouthType'
// //       '&skinColor=$skinColor';

// //   Map<String, String> toMap() => {
// //     'topType': topType,
// //     'accessoriesType': accessoriesType,
// //     'hairColor': hairColor,
// //     'facialHairType': facialHairType,
// //     'facialHairColor': facialHairColor,
// //     'clotheType': clotheType,
// //     'clotheColor': clotheColor,
// //     'eyeType': eyeType,
// //     'eyebrowType': eyebrowType,
// //     'mouthType': mouthType,
// //     'skinColor': skinColor,
// //   };

// //   factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
// //     topType: m['topType'] as String? ?? 'ShortHairShortFlat',
// //     accessoriesType: m['accessoriesType'] as String? ?? 'Blank',
// //     hairColor: m['hairColor'] as String? ?? 'BrownDark',
// //     facialHairType: m['facialHairType'] as String? ?? 'Blank',
// //     facialHairColor: m['facialHairColor'] as String? ?? 'BrownDark',
// //     clotheType: m['clotheType'] as String? ?? 'Hoodie',
// //     clotheColor: m['clotheColor'] as String? ?? 'Blue01',
// //     eyeType: m['eyeType'] as String? ?? 'Default',
// //     eyebrowType: m['eyebrowType'] as String? ?? 'Default',
// //     mouthType: m['mouthType'] as String? ?? 'Smile',
// //     skinColor: m['skinColor'] as String? ?? 'Light',
// //   );

// //   AvatarConfig copyWith({
// //     String? topType,
// //     String? accessoriesType,
// //     String? hairColor,
// //     String? facialHairType,
// //     String? facialHairColor,
// //     String? clotheType,
// //     String? clotheColor,
// //     String? eyeType,
// //     String? eyebrowType,
// //     String? mouthType,
// //     String? skinColor,
// //   }) => AvatarConfig(
// //     topType: topType ?? this.topType,
// //     accessoriesType: accessoriesType ?? this.accessoriesType,
// //     hairColor: hairColor ?? this.hairColor,
// //     facialHairType: facialHairType ?? this.facialHairType,
// //     facialHairColor: facialHairColor ?? this.facialHairColor,
// //     clotheType: clotheType ?? this.clotheType,
// //     clotheColor: clotheColor ?? this.clotheColor,
// //     eyeType: eyeType ?? this.eyeType,
// //     eyebrowType: eyebrowType ?? this.eyebrowType,
// //     mouthType: mouthType ?? this.mouthType,
// //     skinColor: skinColor ?? this.skinColor,
// //   );
// // }

// // class AvatarService extends ChangeNotifier {
// //   AvatarService._();
// //   static final AvatarService instance = AvatarService._();

// //   static const _prefKey = 'avataaars_config_v1';
// //   static const _lastSavedKey = 'avataaars_last_saved_v1';
// //   static const cooldown = Duration(hours: 24);

// //   AvatarConfig _config = AvatarConfig.defaults;
// //   DateTime? _lastSavedAt;
// //   AvatarConfig get config => _config;

// //   Duration? get cooldownRemaining {
// //     if (_lastSavedAt == null) return null;
// //     final elapsed = DateTime.now().difference(_lastSavedAt!);
// //     if (elapsed >= cooldown) return null;
// //     return cooldown - elapsed;
// //   }

// //   bool get canSave => cooldownRemaining == null;

// //   Future<void> load() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final raw = prefs.getString(_prefKey);
// //     if (raw != null) {
// //       try {
// //         _config = AvatarConfig.fromMap(
// //           Map<String, dynamic>.from(jsonDecode(raw) as Map),
// //         );
// //       } catch (_) {}
// //     }
// //     final lastSavedMs = prefs.getInt(_lastSavedKey);
// //     if (lastSavedMs != null) {
// //       _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(lastSavedMs);
// //     }
// //     notifyListeners();
// //   }

// //   Future<bool> save(AvatarConfig cfg) async {
// //     if (!canSave) return false;
// //     _config = cfg;
// //     _lastSavedAt = DateTime.now();
// //     final prefs = await SharedPreferences.getInstance();
// //     await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
// //     await prefs.setInt(_lastSavedKey, _lastSavedAt!.millisecondsSinceEpoch);
// //     final uid = Supabase.instance.client.auth.currentUser?.id;
// //     if (uid != null) {
// //       await Supabase.instance.client
// //           .from('profiles')
// //           .update({'avatar_config': cfg.toMap()})
// //           .eq('id', uid)
// //           .catchError((_) {});
// //     }
// //     notifyListeners();
// //     return true;
// //   }
// // }

// // class AvatarDisplay extends StatelessWidget {
// //   const AvatarDisplay({super.key, required this.avatarUrl, required this.size});
// //   final String avatarUrl;
// //   final double size;

// //   @override
// //   Widget build(BuildContext context) => SvgPicture.network(
// //     avatarUrl,
// //     width: size,
// //     height: size,
// //     placeholderBuilder: (_) => SizedBox(
// //       width: size,
// //       height: size,
// //       child: CircleAvatar(
// //         radius: size / 2,
// //         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
// //         child: Icon(
// //           Icons.person,
// //           size: size * 0.5,
// //           color: Theme.of(context).colorScheme.onPrimaryContainer,
// //         ),
// //       ),
// //     ),
// //   );
// // }

// // class AvatarCreatorScreen extends StatefulWidget {
// //   const AvatarCreatorScreen({super.key});
// //   @override
// //   State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
// // }

// // class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
// //   late AvatarConfig _config;
// //   bool _saving = false;

// //   static const _skinColors = [
// //     'Tanned',
// //     'Yellow',
// //     'Pale',
// //     'Light',
// //     'Brown',
// //     'DarkBrown',
// //     'Black',
// //   ];
// //   static const _hairColors = [
// //     'Auburn',
// //     'Black',
// //     'Blonde',
// //     'BlondeGolden',
// //     'Brown',
// //     'BrownDark',
// //     'PastelPink',
// //     'Platinum',
// //     'Red',
// //     'SilverGray',
// //   ];
// //   static const _topTypes = [
// //     'NoHair',
// //     'Eyepatch',
// //     'Hat',
// //     'Hijab',
// //     'Turban',
// //     'WinterHat1',
// //     'WinterHat2',
// //     'WinterHat3',
// //     'WinterHat4',
// //     'LongHairBigHair',
// //     'LongHairBob',
// //     'LongHairBun',
// //     'LongHairCurly',
// //     'LongHairCurvy',
// //     'LongHairDreads',
// //     'LongHairFrida',
// //     'LongHairFro',
// //     'LongHairFroBand',
// //     'LongHairNotTooLong',
// //     'LongHairShavedSides',
// //     'LongHairMiaWallace',
// //     'LongHairStraight',
// //     'LongHairStraight2',
// //     'LongHairStraightStrand',
// //     'ShortHairDreads01',
// //     'ShortHairDreads02',
// //     'ShortHairFrizzle',
// //     'ShortHairShaggyMullet',
// //     'ShortHairShortCurly',
// //     'ShortHairShortFlat',
// //     'ShortHairShortRound',
// //     'ShortHairShortWaved',
// //     'ShortHairSides',
// //     'ShortHairTheCaesar',
// //     'ShortHairTheCaesarSidePart',
// //   ];
// //   static const _accessories = [
// //     'Blank',
// //     'Kurt',
// //     'Prescription01',
// //     'Prescription02',
// //     'Round',
// //     'Sunglasses',
// //     'Wayfarers',
// //   ];
// //   static const _facialHair = [
// //     'Blank',
// //     'BeardMedium',
// //     'BeardLight',
// //     'BeardMagestic',
// //     'MoustacheFancy',
// //     'MoustacheMagnum',
// //   ];
// //   static const _clothes = [
// //     'BlazerShirt',
// //     'BlazerSweater',
// //     'CollarSweater',
// //     'GraphicShirt',
// //     'Hoodie',
// //     'Overall',
// //     'ShirtCrewNeck',
// //     'ShirtScoopNeck',
// //     'ShirtVNeck',
// //   ];
// //   static const _clotheColors = [
// //     'Black',
// //     'Blue01',
// //     'Blue02',
// //     'Blue03',
// //     'Gray01',
// //     'Gray02',
// //     'Heather',
// //     'PastelBlue',
// //     'PastelGreen',
// //     'PastelOrange',
// //     'PastelRed',
// //     'PastelYellow',
// //     'Pink',
// //     'Red',
// //     'White',
// //   ];
// //   static const _eyes = [
// //     'Close',
// //     'Cry',
// //     'Default',
// //     'Dizzy',
// //     'EyeRoll',
// //     'Happy',
// //     'Hearts',
// //     'Side',
// //     'Squint',
// //     'Surprised',
// //     'Wink',
// //     'WinkWacky',
// //   ];
// //   static const _eyebrows = [
// //     'Angry',
// //     'AngryNatural',
// //     'Default',
// //     'DefaultNatural',
// //     'FlatNatural',
// //     'RaisedExcited',
// //     'RaisedExcitedNatural',
// //     'SadConcerned',
// //     'SadConcernedNatural',
// //     'UnibrowNatural',
// //     'UpDown',
// //     'UpDownNatural',
// //   ];
// //   static const _mouths = [
// //     'Concerned',
// //     'Default',
// //     'Disbelief',
// //     'Eating',
// //     'Grimace',
// //     'Sad',
// //     'ScreamOpen',
// //     'Serious',
// //     'Smile',
// //     'Tongue',
// //     'Twinkle',
// //     'Vomit',
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _config = AvatarService.instance.config;
// //   }

// //   Future<void> _save() async {
// //     final remaining = AvatarService.instance.cooldownRemaining;
// //     if (remaining != null) {
// //       final hours = remaining.inHours;
// //       final mins = remaining.inMinutes % 60;
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             'You can update your avatar again in ${hours}h ${mins}m.',
// //           ),
// //           behavior: SnackBarBehavior.fixed,
// //         ),
// //       );
// //       return;
// //     }
// //     setState(() => _saving = true);
// //     final ok = await AvatarService.instance.save(_config);
// //     if (mounted) {
// //       setState(() => _saving = false);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(ok ? 'Avatar saved! ✦' : 'Could not save right now.'),
// //           behavior: SnackBarBehavior.fixed,
// //           duration: const Duration(seconds: 2),
// //         ),
// //       );
// //     }
// //   }

// //   void _updateConfig(AvatarConfig cfg) => setState(() => _config = cfg);

// //   @override
// //   Widget build(BuildContext context) {
// //     final isPremium =
// //         context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
// //     final theme = context.theme;

// //     if (!isPremium) {
// //       return Scaffold(
// //         appBar: AppBar(title: const Text('My Avatar')),
// //         body: Center(
// //           child: Padding(
// //             padding: const EdgeInsets.all(32),
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 AvatarDisplay(
// //                   avatarUrl: AvatarConfig.defaults.avatarUrl,
// //                   size: 120,
// //                 ),
// //                 const SizedBox(height: 20),
// //                 Text(
// //                   'Custom Avatars',
// //                   style: theme.textTheme.headlineSmall?.copyWith(
// //                     fontWeight: FontWeight.w800,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 const Text(
// //                   'Create your own Bitmoji-style avatar and show it across the app with Premium.',
// //                   textAlign: TextAlign.center,
// //                 ),
// //                 const SizedBox(height: 24),
// //                 FilledButton(
// //                   onPressed: () => AppRouter.router.push(RouteNames.premium),
// //                   child: const Text('Upgrade to Premium ✦'),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       );
// //     }

// //     final remaining = context.watch<AvatarService>().cooldownRemaining;

// //     return DefaultTabController(
// //       length: 6,
// //       child: Scaffold(
// //         appBar: AppBar(
// //           title: const Text('My Avatar'),
// //           bottom: const TabBar(
// //             isScrollable: true,
// //             tabAlignment: TabAlignment.start,
// //             tabs: [
// //               Tab(text: 'Hair'),
// //               Tab(text: 'Face'),
// //               Tab(text: 'Eyes'),
// //               Tab(text: 'Mouth'),
// //               Tab(text: 'Outfit'),
// //               Tab(text: 'Extras'),
// //             ],
// //           ),
// //         ),
// //         floatingActionButton: FloatingActionButton.extended(
// //           onPressed: _saving ? null : _save,
// //           backgroundColor: remaining != null ? Colors.grey : null,
// //           icon: _saving
// //               ? const SizedBox(
// //                   width: 18,
// //                   height: 18,
// //                   child: CircularProgressIndicator(
// //                     strokeWidth: 2,
// //                     color: Colors.white,
// //                   ),
// //                 )
// //               : Icon(
// //                   remaining != null
// //                       ? Icons.lock_clock_rounded
// //                       : Icons.check_rounded,
// //                 ),
// //           label: Text(
// //             _saving
// //                 ? 'Saving…'
// //                 : remaining != null
// //                 ? 'On Cooldown'
// //                 : 'Save Avatar',
// //           ),
// //         ),
// //         body: Column(
// //           children: [
// //             Container(
// //               color: theme.colorScheme.surfaceContainerHighest,
// //               padding: const EdgeInsets.symmetric(vertical: 20),
// //               child: Center(
// //                 child: ClipOval(
// //                   child: AvatarDisplay(avatarUrl: _config.avatarUrl, size: 120),
// //                 ),
// //               ),
// //             ),
// //             if (remaining != null)
// //               Container(
// //                 width: double.infinity,
// //                 color: theme.colorScheme.errorContainer,
// //                 padding: const EdgeInsets.symmetric(
// //                   vertical: 10,
// //                   horizontal: 16,
// //                 ),
// //                 child: Row(
// //                   children: [
// //                     Icon(
// //                       Icons.lock_clock_rounded,
// //                       size: 16,
// //                       color: theme.colorScheme.onErrorContainer,
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Expanded(
// //                       child: Text(
// //                         'You already updated your avatar. Try again in ${remaining.inHours}h ${remaining.inMinutes % 60}m.',
// //                         style: theme.textTheme.bodySmall?.copyWith(
// //                           color: theme.colorScheme.onErrorContainer,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             Expanded(
// //               child: TabBarView(
// //                 children: [
// //                   _TraitTab(
// //                     children: [
// //                       _OptionRow(
// //                         'Hair Style',
// //                         _topTypes,
// //                         _config.topType,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(topType: v),
// //                         ),
// //                       ),
// //                       _OptionRow(
// //                         'Hair Color',
// //                         _hairColors,
// //                         _config.hairColor,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(hairColor: v),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   _TraitTab(
// //                     children: [
// //                       _OptionRow(
// //                         'Skin Tone',
// //                         _skinColors,
// //                         _config.skinColor,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(skinColor: v),
// //                         ),
// //                       ),
// //                       _OptionRow(
// //                         'Facial Hair',
// //                         _facialHair,
// //                         _config.facialHairType,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(facialHairType: v),
// //                         ),
// //                       ),
// //                       _OptionRow(
// //                         'Facial Hair Color',
// //                         _hairColors,
// //                         _config.facialHairColor,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(facialHairColor: v),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   _TraitTab(
// //                     children: [
// //                       _OptionRow(
// //                         'Eyes',
// //                         _eyes,
// //                         _config.eyeType,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(eyeType: v),
// //                         ),
// //                       ),
// //                       _OptionRow(
// //                         'Eyebrows',
// //                         _eyebrows,
// //                         _config.eyebrowType,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(eyebrowType: v),
// //                         ),
// //                       ),
// //                       _OptionRow(
// //                         'Accessories',
// //                         _accessories,
// //                         _config.accessoriesType,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(accessoriesType: v),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   _TraitTab(
// //                     children: [
// //                       _OptionRow(
// //                         'Mouth',
// //                         _mouths,
// //                         _config.mouthType,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(mouthType: v),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   _TraitTab(
// //                     children: [
// //                       _OptionRow(
// //                         'Outfit',
// //                         _clothes,
// //                         _config.clotheType,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(clotheType: v),
// //                         ),
// //                       ),
// //                       _OptionRow(
// //                         'Outfit Color',
// //                         _clotheColors,
// //                         _config.clotheColor,
// //                         (v) => setState(
// //                           () => _config = _config.copyWith(clotheColor: v),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   _TraitTab(
// //                     children: [
// //                       _RandomRow(
// //                         onRandom: () =>
// //                             setState(() => _config = _randomConfig()),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   AvatarConfig _randomConfig() {
// //     final r = DateTime.now().millisecondsSinceEpoch;
// //     T pick<T>(List<T> list) => list[r % list.length];
// //     return AvatarConfig(
// //       topType: pick(_topTypes),
// //       accessoriesType: pick(_accessories),
// //       hairColor: pick(_hairColors),
// //       facialHairType: pick(_facialHair),
// //       facialHairColor: pick(_hairColors),
// //       clotheType: pick(_clothes),
// //       clotheColor: pick(_clotheColors),
// //       eyeType: pick(_eyes),
// //       eyebrowType: pick(_eyebrows),
// //       mouthType: pick(_mouths),
// //       skinColor: pick(_skinColors),
// //     );
// //   }
// // }

// // class _TraitTab extends StatelessWidget {
// //   const _TraitTab({required this.children});
// //   final List<Widget> children;
// //   @override
// //   Widget build(BuildContext context) =>
// //       ListView(padding: const EdgeInsets.all(16), children: children);
// // }

// // class _OptionRow extends StatelessWidget {
// //   const _OptionRow(this.label, this.options, this.selected, this.onSelect);
// //   final String label;
// //   final List<String> options;
// //   final String selected;
// //   final void Function(String) onSelect;

// //   String _humanize(String s) => s
// //       .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
// //       .replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m[0]}')
// //       .trim();
// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);
// //     return Padding(
// //       padding: const EdgeInsets.only(top: 14, bottom: 4),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.stretch,
// //         children: [
// //           Text(
// //             label,
// //             style: theme.textTheme.titleSmall?.copyWith(
// //               fontWeight: FontWeight.w800,
// //             ),
// //           ),
// //           const SizedBox(height: 8),
// //           Wrap(
// //             spacing: 8,
// //             runSpacing: 8,
// //             children: options
// //                 .map(
// //                   (opt) => ChoiceChip(
// //                     label: Text(
// //                       _humanize(opt),
// //                       style: const TextStyle(fontSize: 12),
// //                     ),
// //                     selected: selected == opt,
// //                     onSelected: (_) => onSelect(opt),
// //                     visualDensity: VisualDensity.compact,
// //                   ),
// //                 )
// //                 .toList(),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // class _RandomRow extends StatelessWidget {
// //   const _RandomRow({required this.onRandom});
// //   final VoidCallback onRandom;
// //   @override
// //   Widget build(BuildContext context) => Center(
// //     child: Padding(
// //       padding: const EdgeInsets.all(32),
// //       child: Column(
// //         children: [
// //           const Text('🎲', style: TextStyle(fontSize: 48)),
// //           const SizedBox(height: 12),
// //           const Text(
// //             'Feeling lucky?',
// //             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
// //           ),
// //           const SizedBox(height: 8),
// //           const Text(
// //             'Generate a random avatar instantly.',
// //             textAlign: TextAlign.center,
// //           ),
// //           const SizedBox(height: 20),
// //           FilledButton.icon(
// //             onPressed: onRandom,
// //             icon: const Icon(Icons.shuffle_rounded),
// //             label: const Text('Randomize Avatar'),
// //           ),
// //         ],
// //       ),
// //     ),
// //   );
// // }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../core/extensions/context_ext.dart';
// import '../../../core/providers/auth_provider.dart';
// import '../../../core/router/route_names.dart';
// import '../../../core/router/app_router.dart';

// class AvatarConfig {
//   const AvatarConfig({
//     this.topType = 'ShortHairShortFlat',
//     this.accessoriesType = 'Blank',
//     this.hairColor = 'BrownDark',
//     this.facialHairType = 'Blank',
//     this.facialHairColor = 'BrownDark',
//     this.clotheType = 'Hoodie',
//     this.clotheColor = 'Blue01',
//     this.eyeType = 'Default',
//     this.eyebrowType = 'Default',
//     this.mouthType = 'Smile',
//     this.skinColor = 'Light',
//   });

//   final String topType;
//   final String accessoriesType;
//   final String hairColor;
//   final String facialHairType;
//   final String facialHairColor;
//   final String clotheType;
//   final String clotheColor;
//   final String eyeType;
//   final String eyebrowType;
//   final String mouthType;
//   final String skinColor;

//   static AvatarConfig get defaults => const AvatarConfig();

//   String get avatarUrl =>
//       'https://avataaars.io/?avatarStyle=Circle'
//       '&topType=$topType'
//       '&accessoriesType=$accessoriesType'
//       '&hairColor=$hairColor'
//       '&facialHairType=$facialHairType'
//       '&facialHairColor=$facialHairColor'
//       '&clotheType=$clotheType'
//       '&clotheColor=$clotheColor'
//       '&eyeType=$eyeType'
//       '&eyebrowType=$eyebrowType'
//       '&mouthType=$mouthType'
//       '&skinColor=$skinColor';

//   Map<String, String> toMap() => {
//     'topType': topType,
//     'accessoriesType': accessoriesType,
//     'hairColor': hairColor,
//     'facialHairType': facialHairType,
//     'facialHairColor': facialHairColor,
//     'clotheType': clotheType,
//     'clotheColor': clotheColor,
//     'eyeType': eyeType,
//     'eyebrowType': eyebrowType,
//     'mouthType': mouthType,
//     'skinColor': skinColor,
//   };

//   factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
//     topType: m['topType'] as String? ?? 'ShortHairShortFlat',
//     accessoriesType: m['accessoriesType'] as String? ?? 'Blank',
//     hairColor: m['hairColor'] as String? ?? 'BrownDark',
//     facialHairType: m['facialHairType'] as String? ?? 'Blank',
//     facialHairColor: m['facialHairColor'] as String? ?? 'BrownDark',
//     clotheType: m['clotheType'] as String? ?? 'Hoodie',
//     clotheColor: m['clotheColor'] as String? ?? 'Blue01',
//     eyeType: m['eyeType'] as String? ?? 'Default',
//     eyebrowType: m['eyebrowType'] as String? ?? 'Default',
//     mouthType: m['mouthType'] as String? ?? 'Smile',
//     skinColor: m['skinColor'] as String? ?? 'Light',
//   );

//   static const Map<
//     String,
//     ({String eyeType, String mouthType, String eyebrowType, String emoji})
//   >
//   reactionExpressions = {
//     'laugh': (
//       eyeType: 'Squint',
//       mouthType: 'Twinkle',
//       eyebrowType: 'Default',
//       emoji: '😂',
//     ),
//     'fire': (
//       eyeType: 'Default',
//       mouthType: 'Serious',
//       eyebrowType: 'RaisedExcited',
//       emoji: '🔥',
//     ),
//     'dead': (
//       eyeType: 'Close',
//       mouthType: 'Disbelief',
//       eyebrowType: 'Default',
//       emoji: '💀',
//     ),
//     'clap': (
//       eyeType: 'Happy',
//       mouthType: 'Default',
//       eyebrowType: 'RaisedExcitedNatural',
//       emoji: '👏',
//     ),
//     'rofl': (
//       eyeType: 'Squint',
//       mouthType: 'ScreamOpen',
//       eyebrowType: 'Default',
//       emoji: '🤣',
//     ),
//     'cry': (
//       eyeType: 'Cry',
//       mouthType: 'Sad',
//       eyebrowType: 'SadConcerned',
//       emoji: '😭',
//     ),
//     'salute': (
//       eyeType: 'Default',
//       mouthType: 'Serious',
//       eyebrowType: 'UpDown',
//       emoji: '🫡',
//     ),
//     'hundred': (
//       eyeType: 'Default',
//       mouthType: 'Smile',
//       eyebrowType: 'RaisedExcited',
//       emoji: '💯',
//     ),
//     'mindblown': (
//       eyeType: 'Surprised',
//       mouthType: 'ScreamOpen',
//       eyebrowType: 'UpDown',
//       emoji: '🤯',
//     ),
//     'crown': (
//       eyeType: 'Default',
//       mouthType: 'Twinkle',
//       eyebrowType: 'Default',
//       emoji: '👑',
//     ),
//     'annoyed': (
//       eyeType: 'Default',
//       mouthType: 'Grimace',
//       eyebrowType: 'Angry',
//       emoji: '😤',
//     ),
//     'touched': (
//       eyeType: 'Happy',
//       mouthType: 'Concerned',
//       eyebrowType: 'SadConcernedNatural',
//       emoji: '🥹',
//     ),
//   };

//   static const String reactionPrefix = 'avatar:';

//   static bool isAvatarReaction(String value) =>
//       value.startsWith(reactionPrefix);

//   static String avatarReactionKey(String value) =>
//       value.substring(reactionPrefix.length);

//   String reactionUrl(String expressionKey) {
//     final preset = reactionExpressions[expressionKey];
//     if (preset == null) return avatarUrl;
//     return copyWith(
//       eyeType: preset.eyeType,
//       mouthType: preset.mouthType,
//       eyebrowType: preset.eyebrowType,
//     ).avatarUrl;
//   }

//   AvatarConfig copyWith({
//     String? topType,
//     String? accessoriesType,
//     String? hairColor,
//     String? facialHairType,
//     String? facialHairColor,
//     String? clotheType,
//     String? clotheColor,
//     String? eyeType,
//     String? eyebrowType,
//     String? mouthType,
//     String? skinColor,
//   }) => AvatarConfig(
//     topType: topType ?? this.topType,
//     accessoriesType: accessoriesType ?? this.accessoriesType,
//     hairColor: hairColor ?? this.hairColor,
//     facialHairType: facialHairType ?? this.facialHairType,
//     facialHairColor: facialHairColor ?? this.facialHairColor,
//     clotheType: clotheType ?? this.clotheType,
//     clotheColor: clotheColor ?? this.clotheColor,
//     eyeType: eyeType ?? this.eyeType,
//     eyebrowType: eyebrowType ?? this.eyebrowType,
//     mouthType: mouthType ?? this.mouthType,
//     skinColor: skinColor ?? this.skinColor,
//   );
// }

// class AvatarService extends ChangeNotifier {
//   AvatarService._();
//   static final AvatarService instance = AvatarService._();

//   static const _prefKey = 'avataaars_config_v1';
//   static const _lastSavedKey = 'avataaars_last_saved_v1';
//   static const _reactionStyleKey = 'reaction_style_v1';
//   static const cooldown = Duration(hours: 24);

//   AvatarConfig _config = AvatarConfig.defaults;
//   DateTime? _lastSavedAt;
//   String _reactionStyle = 'emoji';
//   AvatarConfig get config => _config;
//   String get reactionStyle => _reactionStyle;
//   bool get reactionStyleIsAvatar => _reactionStyle == 'avatar';

//   Future<void> setReactionStyle(String style) async {
//     _reactionStyle = style == 'avatar' ? 'avatar' : 'emoji';
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_reactionStyleKey, _reactionStyle);
//     notifyListeners();
//   }

//   Duration? get cooldownRemaining {
//     if (_lastSavedAt == null) return null;
//     final elapsed = DateTime.now().difference(_lastSavedAt!);
//     if (elapsed >= cooldown) return null;
//     return cooldown - elapsed;
//   }

//   bool get canSave => cooldownRemaining == null;

//   Future<void> load() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_prefKey);
//     if (raw != null) {
//       try {
//         _config = AvatarConfig.fromMap(
//           Map<String, dynamic>.from(jsonDecode(raw) as Map),
//         );
//       } catch (_) {}
//     }
//     final lastSavedMs = prefs.getInt(_lastSavedKey);
//     if (lastSavedMs != null) {
//       _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(lastSavedMs);
//     }
//     _reactionStyle = prefs.getString(_reactionStyleKey) ?? 'emoji';
//     notifyListeners();
//   }

//   Future<bool> save(AvatarConfig cfg) async {
//     if (!canSave) return false;
//     _config = cfg;
//     _lastSavedAt = DateTime.now();
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
//     await prefs.setInt(_lastSavedKey, _lastSavedAt!.millisecondsSinceEpoch);
//     final uid = Supabase.instance.client.auth.currentUser?.id;
//     if (uid != null) {
//       await Supabase.instance.client
//           .from('profiles')
//           .update({'avatar_config': cfg.toMap()})
//           .eq('id', uid)
//           .catchError((_) {});
//     }
//     notifyListeners();
//     return true;
//   }
// }

// class AvatarDisplay extends StatelessWidget {
//   const AvatarDisplay({super.key, required this.avatarUrl, required this.size});
//   final String avatarUrl;
//   final double size;

//   @override
//   Widget build(BuildContext context) => SvgPicture.network(
//     avatarUrl,
//     width: size,
//     height: size,
//     placeholderBuilder: (_) => SizedBox(
//       width: size,
//       height: size,
//       child: CircleAvatar(
//         radius: size / 2,
//         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
//         child: Icon(
//           Icons.person,
//           size: size * 0.5,
//           color: Theme.of(context).colorScheme.onPrimaryContainer,
//         ),
//       ),
//     ),
//   );
// }

// class AvatarCreatorScreen extends StatefulWidget {
//   const AvatarCreatorScreen({super.key});
//   @override
//   State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
// }

// class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
//   late AvatarConfig _config;
//   bool _saving = false;

//   static const _skinColors = [
//     'Tanned',
//     'Yellow',
//     'Pale',
//     'Light',
//     'Brown',
//     'DarkBrown',
//     'Black',
//   ];
//   static const _hairColors = [
//     'Auburn',
//     'Black',
//     'Blonde',
//     'BlondeGolden',
//     'Brown',
//     'BrownDark',
//     'PastelPink',
//     'Platinum',
//     'Red',
//     'SilverGray',
//   ];
//   static const _topTypes = [
//     'NoHair',
//     'Eyepatch',
//     'Hat',
//     'Hijab',
//     'Turban',
//     'WinterHat1',
//     'WinterHat2',
//     'WinterHat3',
//     'WinterHat4',
//     'LongHairBigHair',
//     'LongHairBob',
//     'LongHairBun',
//     'LongHairCurly',
//     'LongHairCurvy',
//     'LongHairDreads',
//     'LongHairFrida',
//     'LongHairFro',
//     'LongHairFroBand',
//     'LongHairNotTooLong',
//     'LongHairShavedSides',
//     'LongHairMiaWallace',
//     'LongHairStraight',
//     'LongHairStraight2',
//     'LongHairStraightStrand',
//     'ShortHairDreads01',
//     'ShortHairDreads02',
//     'ShortHairFrizzle',
//     'ShortHairShaggyMullet',
//     'ShortHairShortCurly',
//     'ShortHairShortFlat',
//     'ShortHairShortRound',
//     'ShortHairShortWaved',
//     'ShortHairSides',
//     'ShortHairTheCaesar',
//     'ShortHairTheCaesarSidePart',
//   ];
//   static const _accessories = [
//     'Blank',
//     'Kurt',
//     'Prescription01',
//     'Prescription02',
//     'Round',
//     'Sunglasses',
//     'Wayfarers',
//   ];
//   static const _facialHair = [
//     'Blank',
//     'BeardMedium',
//     'BeardLight',
//     'BeardMagestic',
//     'MoustacheFancy',
//     'MoustacheMagnum',
//   ];
//   static const _clothes = [
//     'BlazerShirt',
//     'BlazerSweater',
//     'CollarSweater',
//     'GraphicShirt',
//     'Hoodie',
//     'Overall',
//     'ShirtCrewNeck',
//     'ShirtScoopNeck',
//     'ShirtVNeck',
//   ];
//   static const _clotheColors = [
//     'Black',
//     'Blue01',
//     'Blue02',
//     'Blue03',
//     'Gray01',
//     'Gray02',
//     'Heather',
//     'PastelBlue',
//     'PastelGreen',
//     'PastelOrange',
//     'PastelRed',
//     'PastelYellow',
//     'Pink',
//     'Red',
//     'White',
//   ];
//   static const _eyes = [
//     'Close',
//     'Cry',
//     'Default',
//     'Dizzy',
//     'EyeRoll',
//     'Happy',
//     'Hearts',
//     'Side',
//     'Squint',
//     'Surprised',
//     'Wink',
//     'WinkWacky',
//   ];
//   static const _eyebrows = [
//     'Angry',
//     'AngryNatural',
//     'Default',
//     'DefaultNatural',
//     'FlatNatural',
//     'RaisedExcited',
//     'RaisedExcitedNatural',
//     'SadConcerned',
//     'SadConcernedNatural',
//     'UnibrowNatural',
//     'UpDown',
//     'UpDownNatural',
//   ];
//   static const _mouths = [
//     'Concerned',
//     'Default',
//     'Disbelief',
//     'Eating',
//     'Grimace',
//     'Sad',
//     'ScreamOpen',
//     'Serious',
//     'Smile',
//     'Tongue',
//     'Twinkle',
//     'Vomit',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _config = AvatarService.instance.config;
//   }

//   Future<void> _save() async {
//     final remaining = AvatarService.instance.cooldownRemaining;
//     if (remaining != null) {
//       final hours = remaining.inHours;
//       final mins = remaining.inMinutes % 60;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'You can update your avatar again in ${hours}h ${mins}m.',
//           ),
//           behavior: SnackBarBehavior.fixed,
//         ),
//       );
//       return;
//     }
//     setState(() => _saving = true);
//     final ok = await AvatarService.instance.save(_config);
//     if (mounted) {
//       setState(() => _saving = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(ok ? 'Avatar saved! ✦' : 'Could not save right now.'),
//           behavior: SnackBarBehavior.fixed,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   void _updateConfig(AvatarConfig cfg) => setState(() => _config = cfg);

//   @override
//   Widget build(BuildContext context) {
//     final isPremium =
//         context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
//     final theme = context.theme;

//     if (!isPremium) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('My Avatar')),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(32),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 AvatarDisplay(
//                   avatarUrl: AvatarConfig.defaults.avatarUrl,
//                   size: 120,
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Custom Avatars',
//                   style: theme.textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.w800,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'Create your own Bitmoji-style avatar and show it across the app with Premium.',
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 FilledButton(
//                   onPressed: () => AppRouter.router.push(RouteNames.premium),
//                   child: const Text('Upgrade to Premium ✦'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     final remaining = context.watch<AvatarService>().cooldownRemaining;

//     return DefaultTabController(
//       length: 6,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('My Avatar'),
//           bottom: const TabBar(
//             isScrollable: true,
//             tabAlignment: TabAlignment.start,
//             tabs: [
//               Tab(text: 'Hair'),
//               Tab(text: 'Face'),
//               Tab(text: 'Eyes'),
//               Tab(text: 'Mouth'),
//               Tab(text: 'Outfit'),
//               Tab(text: 'Extras'),
//             ],
//           ),
//         ),
//         floatingActionButton: FloatingActionButton.extended(
//           onPressed: _saving ? null : _save,
//           backgroundColor: remaining != null ? Colors.grey : null,
//           icon: _saving
//               ? const SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Icon(
//                   remaining != null
//                       ? Icons.lock_clock_rounded
//                       : Icons.check_rounded,
//                 ),
//           label: Text(
//             _saving
//                 ? 'Saving…'
//                 : remaining != null
//                 ? 'On Cooldown'
//                 : 'Save Avatar',
//           ),
//         ),
//         body: Column(
//           children: [
//             Container(
//               color: theme.colorScheme.surfaceContainerHighest,
//               padding: const EdgeInsets.symmetric(vertical: 20),
//               child: Center(
//                 child: ClipOval(
//                   child: AvatarDisplay(avatarUrl: _config.avatarUrl, size: 120),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Default reaction style in games',
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       ChoiceChip(
//                         label: const Text('Emoji'),
//                         selected: !context
//                             .watch<AvatarService>()
//                             .reactionStyleIsAvatar,
//                         onSelected: (_) => context
//                             .read<AvatarService>()
//                             .setReactionStyle('emoji'),
//                       ),
//                       const SizedBox(width: 8),
//                       ChoiceChip(
//                         label: const Text('Avatar ✦'),
//                         selected: context
//                             .watch<AvatarService>()
//                             .reactionStyleIsAvatar,
//                         onSelected: (_) => context
//                             .read<AvatarService>()
//                             .setReactionStyle('avatar'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             if (remaining != null)
//               Container(
//                 width: double.infinity,
//                 color: theme.colorScheme.errorContainer,
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 10,
//                   horizontal: 16,
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.lock_clock_rounded,
//                       size: 16,
//                       color: theme.colorScheme.onErrorContainer,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'You already updated your avatar. Try again in ${remaining.inHours}h ${remaining.inMinutes % 60}m.',
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: theme.colorScheme.onErrorContainer,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             Expanded(
//               child: TabBarView(
//                 children: [
//                   _TraitTab(
//                     children: [
//                       _OptionRow(
//                         'Hair Style',
//                         _topTypes,
//                         _config.topType,
//                         (v) => setState(
//                           () => _config = _config.copyWith(topType: v),
//                         ),
//                       ),
//                       _OptionRow(
//                         'Hair Color',
//                         _hairColors,
//                         _config.hairColor,
//                         (v) => setState(
//                           () => _config = _config.copyWith(hairColor: v),
//                         ),
//                       ),
//                     ],
//                   ),
//                   _TraitTab(
//                     children: [
//                       _OptionRow(
//                         'Skin Tone',
//                         _skinColors,
//                         _config.skinColor,
//                         (v) => setState(
//                           () => _config = _config.copyWith(skinColor: v),
//                         ),
//                       ),
//                       _OptionRow(
//                         'Facial Hair',
//                         _facialHair,
//                         _config.facialHairType,
//                         (v) => setState(
//                           () => _config = _config.copyWith(facialHairType: v),
//                         ),
//                       ),
//                       _OptionRow(
//                         'Facial Hair Color',
//                         _hairColors,
//                         _config.facialHairColor,
//                         (v) => setState(
//                           () => _config = _config.copyWith(facialHairColor: v),
//                         ),
//                       ),
//                     ],
//                   ),
//                   _TraitTab(
//                     children: [
//                       _OptionRow(
//                         'Eyes',
//                         _eyes,
//                         _config.eyeType,
//                         (v) => setState(
//                           () => _config = _config.copyWith(eyeType: v),
//                         ),
//                       ),
//                       _OptionRow(
//                         'Eyebrows',
//                         _eyebrows,
//                         _config.eyebrowType,
//                         (v) => setState(
//                           () => _config = _config.copyWith(eyebrowType: v),
//                         ),
//                       ),
//                       _OptionRow(
//                         'Accessories',
//                         _accessories,
//                         _config.accessoriesType,
//                         (v) => setState(
//                           () => _config = _config.copyWith(accessoriesType: v),
//                         ),
//                       ),
//                     ],
//                   ),
//                   _TraitTab(
//                     children: [
//                       _OptionRow(
//                         'Mouth',
//                         _mouths,
//                         _config.mouthType,
//                         (v) => setState(
//                           () => _config = _config.copyWith(mouthType: v),
//                         ),
//                       ),
//                     ],
//                   ),
//                   _TraitTab(
//                     children: [
//                       _OptionRow(
//                         'Outfit',
//                         _clothes,
//                         _config.clotheType,
//                         (v) => setState(
//                           () => _config = _config.copyWith(clotheType: v),
//                         ),
//                       ),
//                       _OptionRow(
//                         'Outfit Color',
//                         _clotheColors,
//                         _config.clotheColor,
//                         (v) => setState(
//                           () => _config = _config.copyWith(clotheColor: v),
//                         ),
//                       ),
//                     ],
//                   ),
//                   _TraitTab(
//                     children: [
//                       _RandomRow(
//                         onRandom: () =>
//                             setState(() => _config = _randomConfig()),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   AvatarConfig _randomConfig() {
//     final r = DateTime.now().millisecondsSinceEpoch;
//     T pick<T>(List<T> list) => list[r % list.length];
//     return AvatarConfig(
//       topType: pick(_topTypes),
//       accessoriesType: pick(_accessories),
//       hairColor: pick(_hairColors),
//       facialHairType: pick(_facialHair),
//       facialHairColor: pick(_hairColors),
//       clotheType: pick(_clothes),
//       clotheColor: pick(_clotheColors),
//       eyeType: pick(_eyes),
//       eyebrowType: pick(_eyebrows),
//       mouthType: pick(_mouths),
//       skinColor: pick(_skinColors),
//     );
//   }
// }

// class _TraitTab extends StatelessWidget {
//   const _TraitTab({required this.children});
//   final List<Widget> children;
//   @override
//   Widget build(BuildContext context) =>
//       ListView(padding: const EdgeInsets.all(16), children: children);
// }

// class _OptionRow extends StatelessWidget {
//   const _OptionRow(this.label, this.options, this.selected, this.onSelect);
//   final String label;
//   final List<String> options;
//   final String selected;
//   final void Function(String) onSelect;

//   String _humanize(String s) => s
//       .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
//       .replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m[0]}')
//       .trim();

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.only(top: 14, bottom: 4),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(
//             label,
//             style: theme.textTheme.titleSmall?.copyWith(
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: options
//                 .map(
//                   (opt) => ChoiceChip(
//                     label: Text(
//                       _humanize(opt),
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                     selected: selected == opt,
//                     onSelected: (_) => onSelect(opt),
//                     visualDensity: VisualDensity.compact,
//                   ),
//                 )
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _RandomRow extends StatelessWidget {
//   const _RandomRow({required this.onRandom});
//   final VoidCallback onRandom;
//   @override
//   Widget build(BuildContext context) => Center(
//     child: Padding(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         children: [
//           const Text('🎲', style: TextStyle(fontSize: 48)),
//           const SizedBox(height: 12),
//           const Text(
//             'Feeling lucky?',
//             style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Generate a random avatar instantly.',
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 20),
//           FilledButton.icon(
//             onPressed: onRandom,
//             icon: const Icon(Icons.shuffle_rounded),
//             label: const Text('Randomize Avatar'),
//           ),
//         ],
//       ),
//     ),
//   );
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/app_router.dart';

class AvatarConfig {
  const AvatarConfig({
    this.topType = 'ShortHairShortFlat',
    this.accessoriesType = 'Blank',
    this.hairColor = 'BrownDark',
    this.facialHairType = 'Blank',
    this.facialHairColor = 'BrownDark',
    this.clotheType = 'Hoodie',
    this.clotheColor = 'Blue01',
    this.eyeType = 'Default',
    this.eyebrowType = 'Default',
    this.mouthType = 'Smile',
    this.skinColor = 'Light',
  });

  final String topType;
  final String accessoriesType;
  final String hairColor;
  final String facialHairType;
  final String facialHairColor;
  final String clotheType;
  final String clotheColor;
  final String eyeType;
  final String eyebrowType;
  final String mouthType;
  final String skinColor;

  static AvatarConfig get defaults => const AvatarConfig();

  String get avatarUrl =>
      'https://avataaars.io/?avatarStyle=Circle'
      '&topType=$topType'
      '&accessoriesType=$accessoriesType'
      '&hairColor=$hairColor'
      '&facialHairType=$facialHairType'
      '&facialHairColor=$facialHairColor'
      '&clotheType=$clotheType'
      '&clotheColor=$clotheColor'
      '&eyeType=$eyeType'
      '&eyebrowType=$eyebrowType'
      '&mouthType=$mouthType'
      '&skinColor=$skinColor';

  Map<String, String> toMap() => {
    'topType': topType,
    'accessoriesType': accessoriesType,
    'hairColor': hairColor,
    'facialHairType': facialHairType,
    'facialHairColor': facialHairColor,
    'clotheType': clotheType,
    'clotheColor': clotheColor,
    'eyeType': eyeType,
    'eyebrowType': eyebrowType,
    'mouthType': mouthType,
    'skinColor': skinColor,
  };

  factory AvatarConfig.fromMap(Map<String, dynamic> m) => AvatarConfig(
    topType: m['topType'] as String? ?? 'ShortHairShortFlat',
    accessoriesType: m['accessoriesType'] as String? ?? 'Blank',
    hairColor: m['hairColor'] as String? ?? 'BrownDark',
    facialHairType: m['facialHairType'] as String? ?? 'Blank',
    facialHairColor: m['facialHairColor'] as String? ?? 'BrownDark',
    clotheType: m['clotheType'] as String? ?? 'Hoodie',
    clotheColor: m['clotheColor'] as String? ?? 'Blue01',
    eyeType: m['eyeType'] as String? ?? 'Default',
    eyebrowType: m['eyebrowType'] as String? ?? 'Default',
    mouthType: m['mouthType'] as String? ?? 'Smile',
    skinColor: m['skinColor'] as String? ?? 'Light',
  );

  static const Map<
    String,
    ({String eyeType, String mouthType, String eyebrowType, String emoji})
  >
  reactionExpressions = {
    'laugh': (
      eyeType: 'Squint',
      mouthType: 'Twinkle',
      eyebrowType: 'Default',
      emoji: '😂',
    ),
    'fire': (
      eyeType: 'Default',
      mouthType: 'Serious',
      eyebrowType: 'RaisedExcited',
      emoji: '🔥',
    ),
    'dead': (
      eyeType: 'Close',
      mouthType: 'Disbelief',
      eyebrowType: 'Default',
      emoji: '💀',
    ),
    'clap': (
      eyeType: 'Happy',
      mouthType: 'Default',
      eyebrowType: 'RaisedExcitedNatural',
      emoji: '👏',
    ),
    'rofl': (
      eyeType: 'Squint',
      mouthType: 'ScreamOpen',
      eyebrowType: 'Default',
      emoji: '🤣',
    ),
    'cry': (
      eyeType: 'Cry',
      mouthType: 'Sad',
      eyebrowType: 'SadConcerned',
      emoji: '😭',
    ),
    'salute': (
      eyeType: 'Default',
      mouthType: 'Serious',
      eyebrowType: 'UpDown',
      emoji: '🫡',
    ),
    'hundred': (
      eyeType: 'Default',
      mouthType: 'Smile',
      eyebrowType: 'RaisedExcited',
      emoji: '💯',
    ),
    'mindblown': (
      eyeType: 'Surprised',
      mouthType: 'ScreamOpen',
      eyebrowType: 'UpDown',
      emoji: '🤯',
    ),
    'crown': (
      eyeType: 'Default',
      mouthType: 'Twinkle',
      eyebrowType: 'Default',
      emoji: '👑',
    ),
    'annoyed': (
      eyeType: 'Default',
      mouthType: 'Grimace',
      eyebrowType: 'Angry',
      emoji: '😤',
    ),
    'touched': (
      eyeType: 'Happy',
      mouthType: 'Concerned',
      eyebrowType: 'SadConcernedNatural',
      emoji: '🥹',
    ),
  };

  static const String reactionPrefix = 'avatar:';

  static bool isAvatarReaction(String value) =>
      value.startsWith(reactionPrefix);

  static String avatarReactionKey(String value) =>
      value.substring(reactionPrefix.length);

  String reactionUrl(String expressionKey) {
    final preset = reactionExpressions[expressionKey];
    if (preset == null) return avatarUrl;
    return copyWith(
      eyeType: preset.eyeType,
      mouthType: preset.mouthType,
      eyebrowType: preset.eyebrowType,
    ).avatarUrl;
  }

  AvatarConfig copyWith({
    String? topType,
    String? accessoriesType,
    String? hairColor,
    String? facialHairType,
    String? facialHairColor,
    String? clotheType,
    String? clotheColor,
    String? eyeType,
    String? eyebrowType,
    String? mouthType,
    String? skinColor,
  }) => AvatarConfig(
    topType: topType ?? this.topType,
    accessoriesType: accessoriesType ?? this.accessoriesType,
    hairColor: hairColor ?? this.hairColor,
    facialHairType: facialHairType ?? this.facialHairType,
    facialHairColor: facialHairColor ?? this.facialHairColor,
    clotheType: clotheType ?? this.clotheType,
    clotheColor: clotheColor ?? this.clotheColor,
    eyeType: eyeType ?? this.eyeType,
    eyebrowType: eyebrowType ?? this.eyebrowType,
    mouthType: mouthType ?? this.mouthType,
    skinColor: skinColor ?? this.skinColor,
  );
}

class AvatarService extends ChangeNotifier {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  static const _prefKey = 'avataaars_config_v1';
  static const _lastSavedKey = 'avataaars_last_saved_v1';
  static const _reactionStyleKey = 'reaction_style_v1';
  static const cooldown = Duration(hours: 24);

  AvatarConfig _config = AvatarConfig.defaults;
  DateTime? _lastSavedAt;
  String _reactionStyle = 'emoji';
  AvatarConfig get config => _config;
  String get reactionStyle => _reactionStyle;
  bool get reactionStyleIsAvatar => _reactionStyle == 'avatar';

  Future<void> setReactionStyle(String style) async {
    _reactionStyle = style == 'avatar' ? 'avatar' : 'emoji';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reactionStyleKey, _reactionStyle);
    notifyListeners();
  }

  Duration? get cooldownRemaining {
    if (_lastSavedAt == null) return null;
    final elapsed = DateTime.now().difference(_lastSavedAt!);
    if (elapsed >= cooldown) return null;
    return cooldown - elapsed;
  }

  bool get canSave => cooldownRemaining == null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      try {
        _config = AvatarConfig.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }
    final lastSavedMs = prefs.getInt(_lastSavedKey);
    if (lastSavedMs != null) {
      _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(lastSavedMs);
    }
    _reactionStyle = prefs.getString(_reactionStyleKey) ?? 'emoji';
    notifyListeners();
  }

  Future<bool> save(AvatarConfig cfg) async {
    if (!canSave) return false;
    _config = cfg;
    _lastSavedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(cfg.toMap()));
    await prefs.setInt(_lastSavedKey, _lastSavedAt!.millisecondsSinceEpoch);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_config': cfg.toMap()})
          .eq('id', uid)
          .catchError((_) {});
    }
    notifyListeners();
    return true;
  }
}

class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({super.key, required this.avatarUrl, required this.size});
  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.network(
    avatarUrl,
    width: size,
    height: size,
    placeholderBuilder: (_) => SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    ),
  );
}

class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});
  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late AvatarConfig _config;
  bool _saving = false;

  static const _skinColors = [
    'Tanned',
    'Yellow',
    'Pale',
    'Light',
    'Brown',
    'DarkBrown',
    'Black',
  ];
  static const _hairColors = [
    'Auburn',
    'Black',
    'Blonde',
    'BlondeGolden',
    'Brown',
    'BrownDark',
    'PastelPink',
    'Platinum',
    'Red',
    'SilverGray',
  ];
  static const _topTypes = [
    'NoHair',
    'Eyepatch',
    'Hat',
    'Hijab',
    'Turban',
    'WinterHat1',
    'WinterHat2',
    'WinterHat3',
    'WinterHat4',
    'LongHairBigHair',
    'LongHairBob',
    'LongHairBun',
    'LongHairCurly',
    'LongHairCurvy',
    'LongHairDreads',
    'LongHairFrida',
    'LongHairFro',
    'LongHairFroBand',
    'LongHairNotTooLong',
    'LongHairShavedSides',
    'LongHairMiaWallace',
    'LongHairStraight',
    'LongHairStraight2',
    'LongHairStraightStrand',
    'ShortHairDreads01',
    'ShortHairDreads02',
    'ShortHairFrizzle',
    'ShortHairShaggyMullet',
    'ShortHairShortCurly',
    'ShortHairShortFlat',
    'ShortHairShortRound',
    'ShortHairShortWaved',
    'ShortHairSides',
    'ShortHairTheCaesar',
    'ShortHairTheCaesarSidePart',
  ];
  static const _accessories = [
    'Blank',
    'Kurt',
    'Prescription01',
    'Prescription02',
    'Round',
    'Sunglasses',
    'Wayfarers',
  ];
  static const _facialHair = [
    'Blank',
    'BeardMedium',
    'BeardLight',
    'BeardMagestic',
    'MoustacheFancy',
    'MoustacheMagnum',
  ];
  static const _clothes = [
    'BlazerShirt',
    'BlazerSweater',
    'CollarSweater',
    'GraphicShirt',
    'Hoodie',
    'Overall',
    'ShirtCrewNeck',
    'ShirtScoopNeck',
    'ShirtVNeck',
  ];
  static const _clotheColors = [
    'Black',
    'Blue01',
    'Blue02',
    'Blue03',
    'Gray01',
    'Gray02',
    'Heather',
    'PastelBlue',
    'PastelGreen',
    'PastelOrange',
    'PastelRed',
    'PastelYellow',
    'Pink',
    'Red',
    'White',
  ];
  static const _eyes = [
    'Close',
    'Cry',
    'Default',
    'Dizzy',
    'EyeRoll',
    'Happy',
    'Hearts',
    'Side',
    'Squint',
    'Surprised',
    'Wink',
    'WinkWacky',
  ];
  static const _eyebrows = [
    'Angry',
    'AngryNatural',
    'Default',
    'DefaultNatural',
    'FlatNatural',
    'RaisedExcited',
    'RaisedExcitedNatural',
    'SadConcerned',
    'SadConcernedNatural',
    'UnibrowNatural',
    'UpDown',
    'UpDownNatural',
  ];
  static const _mouths = [
    'Concerned',
    'Default',
    'Disbelief',
    'Eating',
    'Grimace',
    'Sad',
    'ScreamOpen',
    'Serious',
    'Smile',
    'Tongue',
    'Twinkle',
    'Vomit',
  ];

  @override
  void initState() {
    super.initState();
    _config = AvatarService.instance.config;
  }

  Future<void> _save() async {
    final remaining = AvatarService.instance.cooldownRemaining;
    if (remaining != null) {
      final hours = remaining.inHours;
      final mins = remaining.inMinutes % 60;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can update your avatar again in ${hours}h ${mins}m.',
          ),
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await AvatarService.instance.save(_config);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Avatar saved! ✦' : 'Could not save right now.'),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateConfig(AvatarConfig cfg) => setState(() => _config = cfg);

  @override
  Widget build(BuildContext context) {
    final isPremium =
        context.watch<AuthProvider>().currentUser?.isPremiumActive ?? false;
    final theme = context.theme;

    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Avatar')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarDisplay(
                  avatarUrl: AvatarConfig.defaults.avatarUrl,
                  size: 120,
                ),
                const SizedBox(height: 20),
                Text(
                  'Custom Avatars',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your own Bitmoji-style avatar and show it across the app with Premium.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => AppRouter.router.push(RouteNames.premium),
                  child: const Text('Upgrade to Premium ✦'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final remaining = context.watch<AvatarService>().cooldownRemaining;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Avatar'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Hair'),
              Tab(text: 'Face'),
              Tab(text: 'Eyes'),
              Tab(text: 'Mouth'),
              Tab(text: 'Outfit'),
              Tab(text: 'Extras'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saving ? null : _save,
          backgroundColor: remaining != null ? Colors.grey : null,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  remaining != null
                      ? Icons.lock_clock_rounded
                      : Icons.check_rounded,
                ),
          label: Text(
            _saving
                ? 'Saving…'
                : remaining != null
                ? 'On Cooldown'
                : 'Save Avatar',
          ),
        ),
        body: Column(
          children: [
            Container(
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: ClipOval(
                  child: AvatarDisplay(avatarUrl: _config.avatarUrl, size: 120),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Your avatar reactions (happy, laugh, cry & more) are '
                'available alongside emoji reactions in Truth or Dare and '
                'Never Have I Ever.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (remaining != null)
              Container(
                width: double.infinity,
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You already updated your avatar. Try again in ${remaining.inHours}h ${remaining.inMinutes % 60}m.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _TraitTab(
                    children: [
                      _OptionRow(
                        'Hair Style',
                        _topTypes,
                        _config.topType,
                        (v) => setState(
                          () => _config = _config.copyWith(topType: v),
                        ),
                      ),
                      _OptionRow(
                        'Hair Color',
                        _hairColors,
                        _config.hairColor,
                        (v) => setState(
                          () => _config = _config.copyWith(hairColor: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        'Skin Tone',
                        _skinColors,
                        _config.skinColor,
                        (v) => setState(
                          () => _config = _config.copyWith(skinColor: v),
                        ),
                      ),
                      _OptionRow(
                        'Facial Hair',
                        _facialHair,
                        _config.facialHairType,
                        (v) => setState(
                          () => _config = _config.copyWith(facialHairType: v),
                        ),
                      ),
                      _OptionRow(
                        'Facial Hair Color',
                        _hairColors,
                        _config.facialHairColor,
                        (v) => setState(
                          () => _config = _config.copyWith(facialHairColor: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        'Eyes',
                        _eyes,
                        _config.eyeType,
                        (v) => setState(
                          () => _config = _config.copyWith(eyeType: v),
                        ),
                      ),
                      _OptionRow(
                        'Eyebrows',
                        _eyebrows,
                        _config.eyebrowType,
                        (v) => setState(
                          () => _config = _config.copyWith(eyebrowType: v),
                        ),
                      ),
                      _OptionRow(
                        'Accessories',
                        _accessories,
                        _config.accessoriesType,
                        (v) => setState(
                          () => _config = _config.copyWith(accessoriesType: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        'Mouth',
                        _mouths,
                        _config.mouthType,
                        (v) => setState(
                          () => _config = _config.copyWith(mouthType: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _OptionRow(
                        'Outfit',
                        _clothes,
                        _config.clotheType,
                        (v) => setState(
                          () => _config = _config.copyWith(clotheType: v),
                        ),
                      ),
                      _OptionRow(
                        'Outfit Color',
                        _clotheColors,
                        _config.clotheColor,
                        (v) => setState(
                          () => _config = _config.copyWith(clotheColor: v),
                        ),
                      ),
                    ],
                  ),
                  _TraitTab(
                    children: [
                      _RandomRow(
                        onRandom: () =>
                            setState(() => _config = _randomConfig()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AvatarConfig _randomConfig() {
    final r = DateTime.now().millisecondsSinceEpoch;
    T pick<T>(List<T> list) => list[r % list.length];
    return AvatarConfig(
      topType: pick(_topTypes),
      accessoriesType: pick(_accessories),
      hairColor: pick(_hairColors),
      facialHairType: pick(_facialHair),
      facialHairColor: pick(_hairColors),
      clotheType: pick(_clothes),
      clotheColor: pick(_clotheColors),
      eyeType: pick(_eyes),
      eyebrowType: pick(_eyebrows),
      mouthType: pick(_mouths),
      skinColor: pick(_skinColors),
    );
  }
}

class _TraitTab extends StatelessWidget {
  const _TraitTab({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: children);
}

class _OptionRow extends StatelessWidget {
  const _OptionRow(this.label, this.options, this.selected, this.onSelect);
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSelect;

  String _humanize(String s) => s
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
      .replaceAllMapped(RegExp(r'\d+'), (m) => ' ${m[0]}')
      .trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (opt) => ChoiceChip(
                    label: Text(
                      _humanize(opt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: selected == opt,
                    onSelected: (_) => onSelect(opt),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RandomRow extends StatelessWidget {
  const _RandomRow({required this.onRandom});
  final VoidCallback onRandom;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('🎲', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Feeling lucky?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate a random avatar instantly.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRandom,
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('Randomize Avatar'),
          ),
        ],
      ),
    ),
  );
}
