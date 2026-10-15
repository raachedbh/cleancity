import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/world_art.dart';
import 'package:greenhaven/game/people_art.dart';

void main() {
  testWidgets('export architecture and resident review sheets', (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
      await font.load();
      final r = ui.PictureRecorder();
      // Separate canvas for the recording used in the export.
      final canvas = Canvas(r);
      canvas.drawColor(const Color(0xFFE7E6DD), BlendMode.src);
      for (final d in districts) {
        canvas.save();
        canvas.translate((d.id % 2) * 720.0, (d.id ~/ 2) * 460.0);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 720, 460),
          Paint()
            ..color = d.night
                ? const Color(0xFF535160)
                : const Color(0xFFD3D8C5),
        );
        WorldArt.label(
          canvas,
          d.name,
          const Offset(350, 16),
          22,
          d.night ? Colors.white : Colors.black87,
        );
        WorldArt.paintLot(canvas, d, const Rect.fromLTWH(32, 190, 310, 230), 0);
        WorldArt.paintLot(
          canvas,
          d,
          const Rect.fromLTWH(375, 190, 310, 230),
          1,
        );
        canvas.restore();
      }
      final picture = r.endRecording(),
          image = await picture.toImage(1440, 1380);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('docs/screenshots/v10')
        ..createSync(recursive: true);
      File(
        '${directory.path}/architecture-review.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      final heads = ui.PictureRecorder(), hc = Canvas(heads);
      hc.drawColor(const Color(0xFFF0ECE1), BlendMode.src);
      for (var id = 0; id < 8; id++) {
        for (var facing = 0; facing < 6; facing++) {
          hc.save();
          hc.translate(id * 165.0 + 80, facing * 200.0 + 192);
          hc.scale(1.6);
          PeopleArt.draw(
            hc,
            id: id,
            position: Offset.zero,
            facing: facing < 4 ? facing : (id.isEven ? 1 : 3),
            walking: facing == 4,
            time: id * .18,
            throwing: facing == 5,
            night: false,
          );
          hc.restore();
        }
      }
      final hp = heads.endRecording(), hi = await hp.toImage(1320, 1205);
      final hb = await hi.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${directory.path}/residents-review.png',
      ).writeAsBytesSync(hb!.buffer.asUint8List());
      hi.dispose();
      hp.dispose();
    });
  });
}
