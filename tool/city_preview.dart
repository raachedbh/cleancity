import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/world_art.dart';
import 'package:greenhaven/game/navigation.dart';
import 'package:greenhaven/game/people_art.dart';

void main() {
  testWidgets('export all six city plans and street views', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'Nunito',
      )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
      final dir = Directory('docs/screenshots/v16')
        ..createSync(recursive: true);
      for (final d in districts) {
        final art = WorldArt(d);
        final nav = CityNavigation(d);
        for (final overview in [true, false]) {
          final width = overview ? 1000 : 540,
              height = overview
                  ? (d.worldSize.height / d.worldSize.width * 1000).ceil()
                  : 960;
          final r = ui.PictureRecorder(), c = Canvas(r);
          c.clipRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
          if (overview) {
            c.scale(1000 / d.worldSize.width);
          } else {
            c.translate(270, d.id == 2 ? 750 : 550);
            c.translate(-d.layout.reviewPoint.dx, -d.layout.reviewPoint.dy);
          }
          c.drawPicture(art.ground);
          final draws = <({double depth, void Function() draw})>[
            for (var i = 0; i < art.lots.length; i++)
              (
                depth: d.blocks[i].bottom,
                draw: () => c.drawPicture(art.lots[i]),
              ),
            for (final prop in art.props)
              (
                depth: prop.position.dy,
                draw: () => c.drawPicture(prop.picture),
              ),
            for (var i = 0; i < 8; i++)
              (
                depth: d.layout.reviewPoint.dy + 90 - i * 37,
                draw: () => PeopleArt.draw(
                  c,
                  id: i,
                  position: nav.nearestWalkable(
                    d.layout.reviewPoint + Offset(-220 + i * 58, 90 - i * 37),
                  ),
                  facing: i % 4,
                  walking: true,
                  time: i * .2,
                  throwing: i == 3,
                  night: d.night,
                ),
              ),
          ]..sort((a, b) => a.depth.compareTo(b.depth));
          for (final draw in draws) {
            draw.draw();
          }
          for (final station in d.stations) {
            WorldArt.rect(
              c,
              Rect.fromCenter(center: station, width: 130, height: 34),
              const Color(0xFF528779),
              radius: 6,
            );
            WorldArt.label(
              c,
              'RECYCLE',
              station - const Offset(0, 12),
              12,
              Colors.white,
            );
          }
          final pic = r.endRecording(),
              image = await pic.toImage(width, height),
              bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${dir.path}/city-${d.id}-${overview ? 'plan' : 'street'}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
          pic.dispose();
        }
        art.dispose();
      }
    });
  });
}
