import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../game/recycling_game.dart';
import '../game/player_art.dart';
import '../game/walk_cycle.dart';

class CharacterPreview extends StatelessWidget {
  const CharacterPreview({
    super.key,
    required this.image,
    required this.outfit,
    this.height = 130,
  });
  final ui.Image? image;
  final int outfit;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: height * .72,
    child: CustomPaint(painter: _CharacterPainter(image, outfit)),
  );
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter(this.image, this.outfit);
  final ui.Image? image;
  final int outfit;
  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    final src = RecyclingGame.sourceForOutfit(outfit, 0);
    if (outfit >= 6) {
      canvas.save();
      canvas.translate(size.width / 2, size.height - 4);
      canvas.scale((size.height - 5) / 127);
      PlayerArt.draw(
        canvas,
        atlas: image!,
        source: src,
        outfit: outfit,
        facing: 0,
        position: Offset.zero,
        gait: WalkCycle(),
        time: 0,
        lean: 0,
      );
      canvas.restore();
      return;
    }
    final width = size.height * src.width / src.height;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 3),
        width: width * .8,
        height: 6,
      ),
      Paint()..color = const Color(0x20243F35),
    );
    canvas.drawImageRect(
      image!,
      src,
      Rect.fromLTWH((size.width - width) / 2, 0, width, size.height - 3),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_CharacterPainter old) =>
      old.image != image || old.outfit != outfit;
}
