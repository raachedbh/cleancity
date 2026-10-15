import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/data/catalog.dart';
import 'package:greenhaven/game/people_art.dart';
import 'package:greenhaven/game/world_art.dart';

void main() {
  testWidgets('export Tunis interview and promenade views', (tester) async {
    await tester.runAsync(() async {
      final area = districts[2], art = WorldArt(districts[2]);
      final directory = Directory('docs/screenshots/v15')
        ..createSync(recursive: true);
      for (final view in [(false, 2.0), (false, 7.0), (true, 7.0)]) {
        final wide = view.$1, time = view.$2;
        final recorder = ui.PictureRecorder(), c = Canvas(recorder);
        const width = 1400, height = 800;
        c.clipRect(const Rect.fromLTWH(0, 0, 1400, 800));
        c.translate(700, 420);
        c.scale(wide ? .65 : 2.4);
        final anchor = wide
            ? const Offset(1870, 1390)
            : area.layout.interviewAnchor!;
        c.translate(-anchor.dx, -anchor.dy + 40);
        c.drawPicture(art.ground);
        final draws = <({double depth, void Function() paint})>[
          for (var i = 0; i < art.lots.length; i++)
            (
              depth: area.blocks[i].bottom,
              paint: () => c.drawPicture(art.lots[i]),
            ),
          for (final prop in art.props)
            (depth: prop.position.dy, paint: () => c.drawPicture(prop.picture)),
          for (var i = 0; i < area.layout.interviewSpots.length; i++)
            (
              depth: area.layout.interviewSpots[i].dy,
              paint: () => PeopleArt.draw(
                c,
                id: const [4, 0, 3][i],
                position: area.layout.interviewSpots[i],
                facing: i == 1 ? 3 : 1,
                walking: false,
                time: time,
                throwing: false,
                night: false,
                interviewRole: InterviewRole.values[i],
              ),
            ),
        ]..sort((a, b) => a.depth.compareTo(b.depth));
        for (final draw in draws) {
          draw.paint();
        }
        final picture = recorder.endRecording(),
            image = await picture.toImage(width, height);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${directory.path}/${wide ? 'promenade' : 'interview-${time.toInt()}'}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
      art.dispose();
    });
  });
}
