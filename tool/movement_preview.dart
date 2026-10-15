import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenhaven/game/player_art.dart';
import 'package:greenhaven/game/recycling_game.dart';
import 'package:greenhaven/game/people_art.dart';
import 'package:greenhaven/game/walk_cycle.dart';

void main() {
  testWidgets('export movement poses for every outfit and resident', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final images = <ui.Image>[];
      for (final name in ['characters', 'special_skins_v2']) {
        final codec = await ui.instantiateImageCodec(
          File('assets/images/$name.png').readAsBytesSync(),
        );
        images.add((await codec.getNextFrame()).image);
        codec.dispose();
      }
      final recorder = ui.PictureRecorder(), c = Canvas(recorder);
      c.drawColor(const Color(0xFFE0E2D7), BlendMode.src);
      for (var outfit = 0; outfit < 12; outfit++) {
        for (var frame = 0; frame < 6; frame++) {
          final facing = frame < 2
              ? 0
              : frame == 5
              ? 2
              : frame == 4
              ? 3
              : 1;
          final gait = WalkCycle()
            ..phase = frame * pi * .55
            ..blend = frame == 0 ? 0 : 1;
          c.save();
          c.translate(frame * 190.0 + 90, outfit * 225.0 + 209);
          c.scale(1.6);
          PlayerArt.draw(
            c,
            atlas: images[outfit < 4 || outfit >= 6 ? 0 : 1],
            source: RecyclingGame.sourceForOutfit(outfit, facing),
            outfit: outfit,
            facing: facing,
            position: Offset.zero,
            gait: gait,
            time: 0,
            lean: frame == 0 ? 0 : .7,
          );
          c.restore();
        }
      }
      for (var id = 0; id < 8; id++) {
        c.save();
        c.translate(id * 142.0 + 70, 2840);
        c.scale(1.6);
        PeopleArt.draw(
          c,
          id: id,
          position: Offset.zero,
          facing: id % 4,
          walking: true,
          time: id * .15,
          throwing: false,
          night: false,
        );
        c.restore();
      }
      final picture = recorder.endRecording(),
          img = await picture.toImage(1140, 2860);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File(
        'docs/screenshots/v10/movement-review.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      picture.dispose();
      img.dispose();
      for (final image in images) {
        image.dispose();
      }
    });
  });
}
