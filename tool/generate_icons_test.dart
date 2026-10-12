// Renders the TrackPro mark into launcher icons for Android, iOS and web.
// Run:  flutter test tool/generate_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/widgets/trackpro_logo.dart';

Future<void> _render(String path, int size, {bool rounded = true, double padding = 0}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (padding > 0) {
    // Maskable icons: full-bleed brand background, mark inset in the safe zone.
    const TrackProMarkPainter(rounded: false).paint(canvas, Size(s, s));
    canvas.save();
    canvas.translate(s * padding, s * padding);
    const TrackProMarkPainter(rounded: false).paint(canvas, Size(s * (1 - 2 * padding), s * (1 - 2 * padding)));
    canvas.restore();
  } else {
    TrackProMarkPainter(rounded: rounded).paint(canvas, Size(s, s));
  }
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('generate launcher icons', () async {
    const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final e in android.entries) {
      await _render('android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', e.value);
    }

    const ios = {
      '20x20@1x': 20, '20x20@2x': 40, '20x20@3x': 60,
      '29x29@1x': 29, '29x29@2x': 58, '29x29@3x': 87,
      '40x40@1x': 40, '40x40@2x': 80, '40x40@3x': 120,
      '60x60@2x': 120, '60x60@3x': 180,
      '76x76@1x': 76, '76x76@2x': 152,
      '83.5x83.5@2x': 167, '1024x1024@1x': 1024,
    };
    for (final e in ios.entries) {
      // iOS applies its own mask; icons must be opaque squares.
      await _render('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-${e.key}.png', e.value, rounded: false);
    }

    await _render('web/favicon.png', 64);
    await _render('web/icons/Icon-192.png', 192);
    await _render('web/icons/Icon-512.png', 512);
    await _render('web/icons/Icon-maskable-192.png', 192, padding: 0.1);
    await _render('web/icons/Icon-maskable-512.png', 512, padding: 0.1);
  });
}
