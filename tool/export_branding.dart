import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Packaging only: preserves the generated artwork, exports platform sizes and
// places the original transparent pixels inside launcher masks' safe area.
void main() {
  testWidgets('export CleanCity platform icons and mask review', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File('assets/branding/cleancity-mark.png').readAsBytesSync(),
      );
      final mark = (await codec.getNextFrame()).image;
      codec.dispose();
      final pixels = (await mark.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var left = mark.width, top = mark.height, right = 0, bottom = 0;
      var transparent = 0;
      for (var y = 0; y < mark.height; y++) {
        for (var x = 0; x < mark.width; x++) {
          final alpha = pixels.getUint8((y * mark.width + x) * 4 + 3);
          if (alpha == 0) transparent++;
          if (alpha > 12) {
            left = min(left, x);
            right = max(right, x);
            top = min(top, y);
            bottom = max(bottom, y);
          }
        }
      }
      expect(transparent, greaterThan(mark.width * mark.height ~/ 3));
      final bounds = Rect.fromLTRB(
        max(0, left - 3).toDouble(),
        max(0, top - 3).toDouble(),
        min(mark.width, right + 4).toDouble(),
        min(mark.height, bottom + 4).toDouble(),
      );
      var radius = 0.0;
      for (var y = top; y <= bottom; y++) {
        for (var x = left; x <= right; x++) {
          if (pixels.getUint8((y * mark.width + x) * 4 + 3) > 12) {
            radius = max(
              radius,
              (Offset(x.toDouble(), y.toDouble()) - bounds.center).distance,
            );
          }
        }
      }
      const background = Color(0xFF123B32);
      // Actual nontransparent content is inside a 64dp circle on a 108dp layer.
      final adaptiveScale = (32 / 108) / radius;
      // Legacy/iOS masks show the full image rather than the adaptive layer inset.
      final iconScale = .425 / radius;
      void drawMark(Canvas c, double size, double scale) {
        c.drawImageRect(
          mark,
          bounds,
          Rect.fromCenter(
            center: Offset(size / 2, size / 2),
            width: bounds.width * size * scale,
            height: bounds.height * size * scale,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
      }

      Future<void> export(
        String path,
        int size, {
        bool transparent = false,
        bool adaptive = false,
      }) async {
        final rec = ui.PictureRecorder(), c = Canvas(rec);
        if (!transparent) c.drawColor(background, BlendMode.src);
        drawMark(c, size.toDouble(), adaptive ? adaptiveScale : iconScale);
        final picture = rec.endRecording(),
            image = await picture.toImage(size, size);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(path);
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(png!.buffer.asUint8List());
        picture.dispose();
        image.dispose();
      }

      await export('assets/branding/cleancity-icon.png', 1024);
      await export('assets/branding/cleancity-icon-ui.png', 192);
      const res = 'android/app/src/main/res';
      for (final (density, factor) in [
        ('mdpi', 1.0),
        ('hdpi', 1.5),
        ('xhdpi', 2.0),
        ('xxhdpi', 3.0),
        ('xxxhdpi', 4.0),
      ]) {
        await export(
          '$res/mipmap-$density/ic_launcher.png',
          (48 * factor).round(),
        );
        await export(
          '$res/mipmap-$density/ic_launcher_foreground.png',
          (108 * factor).round(),
          transparent: true,
          adaptive: true,
        );
        await export(
          '$res/drawable-$density/cleancity_splash.png',
          (160 * factor).round(),
          transparent: true,
        );
      }
      const ios = 'ios/Runner/Assets.xcassets';
      final catalog =
          jsonDecode(
                File(
                  '$ios/AppIcon.appiconset/Contents.json',
                ).readAsStringSync(),
              )
              as Map;
      for (final item in catalog['images'] as List) {
        final points = double.parse((item['size'] as String).split('x').first);
        final scale = double.parse(
          (item['scale'] as String).replaceAll('x', ''),
        );
        await export(
          '$ios/AppIcon.appiconset/${item['filename']}',
          (points * scale).round(),
        );
      }
      for (var scale = 1; scale <= 3; scale++) {
        await export(
          '$ios/LaunchImage.imageset/LaunchImage${scale == 1 ? '' : '@${scale}x'}.png',
          160 * scale,
          transparent: true,
        );
      }
      final rec = ui.PictureRecorder(), c = Canvas(rec);
      c.drawColor(const Color(0xFFF4F4EE), BlendMode.src);
      final iconFile = File('assets/branding/cleancity-icon.png');
      final iconCodec = await ui.instantiateImageCodec(
        iconFile.readAsBytesSync(),
      );
      final icon = (await iconCodec.getNextFrame()).image;
      iconCodec.dispose();
      for (var i = 0; i < 3; i++) {
        c.save();
        c.translate(24 + i * 296.0, 24);
        final box = const Rect.fromLTWH(0, 0, 248, 248);
        final mask = Path();
        if (i == 0) {
          mask.addOval(box);
        } else {
          mask.addRRect(
            RRect.fromRectAndRadius(box, Radius.circular(i == 1 ? 56 : 10)),
          );
        }
        c.clipPath(mask);
        c.drawColor(background, BlendMode.src);
        c.save();
        // The launcher's normal mask is 72dp of its 108dp foreground canvas.
        c.translate(-62, -62);
        drawMark(c, 372, adaptiveScale);
        c.restore();
        c.restore();
      }
      for (var i = 0; i < 3; i++) {
        final size = [48.0, 72.0, 120.0][i];
        c.save();
        c.translate(124 + i * 296 - size / 2, 307);
        c.clipRRect(
          RRect.fromRectAndRadius(
            Offset.zero & Size.square(size),
            Radius.circular(size * .22),
          ),
        );
        c.drawImageRect(
          icon,
          const Rect.fromLTWH(0, 0, 1024, 1024),
          Offset.zero & Size.square(size),
          Paint()..filterQuality = FilterQuality.high,
        );
        c.restore();
      }
      final picture = rec.endRecording(),
          review = await picture.toImage(912, 456);
      final bytes = await review.toByteData(format: ui.ImageByteFormat.png);
      File(
        'docs/screenshots/v7/icon-masks.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      File('docs/branding-export.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'sourceWidth': mark.width,
          'sourceHeight': mark.height,
          'transparentPixels': transparent,
          'contentBounds': [left, top, right, bottom],
          'adaptiveSafeDiameterDp': 64,
          'adaptiveCanvasDp': 108,
          'background': '#123B32',
          'source': 'assets/branding/cleancity-mark.png',
        }),
      );
      picture.dispose();
      review.dispose();
      icon.dispose();
      mark.dispose();
    });
  });
}
