import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'greek_tokens.dart';

class GreekMarbleBackground extends StatelessWidget {
  const GreekMarbleBackground({super.key});

  @override
  Widget build(BuildContext context) => const Positioned.fill(
    child: IgnorePointer(child: CustomPaint(painter: _MarblePainter())),
  );
}

class _MarblePainter extends CustomPainter {
  const _MarblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = GreekColors.marble);
    final pale = Paint()
      ..color = GreekColors.white.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final vein = Paint()
      ..color = GreekColors.limestoneDark.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final softVein = Paint()
      ..color = GreekColors.aegean.withValues(alpha: .035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = -1; i < 6; i++) {
      final y = size.height * (i / 5);
      final path = Path()
        ..moveTo(-30, y + 20)
        ..cubicTo(
          size.width * .2,
          y - 42,
          size.width * .48,
          y + 66,
          size.width + 30,
          y - 18,
        );
      canvas.drawPath(path, i.isEven ? pale : softVein);
      canvas.drawPath(path, vein);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GreekKeyBorder extends StatelessWidget {
  const GreekKeyBorder({this.height = 10, this.color, super.key});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _GreekKeyPainter(color ?? GreekColors.bronze),
      ),
    ),
  );
}

class _GreekKeyPainter extends CustomPainter {
  const _GreekKeyPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.miter;
    final unit = size.height;
    final path = Path();
    for (double x = -unit; x < size.width + unit; x += unit * 2) {
      path
        ..moveTo(x, unit * .8)
        ..lineTo(x + unit * 1.55, unit * .8)
        ..lineTo(x + unit * 1.55, unit * .2)
        ..lineTo(x + unit * .42, unit * .2)
        ..lineTo(x + unit * .42, unit * .6)
        ..lineTo(x + unit * 1.1, unit * .6)
        ..lineTo(x + unit * 1.1, unit * .4)
        ..lineTo(x + unit * .78, unit * .4);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GreekKeyPainter oldDelegate) =>
      oldDelegate.color != color;
}

class GreekTempleMark extends StatelessWidget {
  const GreekTempleMark({this.size = 36, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _TemplePainter(color ?? GreekColors.bronze)),
  );
}

class _TemplePainter extends CustomPainter {
  const _TemplePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.width * .052)
      ..strokeJoin = StrokeJoin.miter;
    final path = Path()
      ..moveTo(size.width * .06, size.height * .3)
      ..lineTo(size.width * .5, size.height * .05)
      ..lineTo(size.width * .94, size.height * .3)
      ..close()
      ..moveTo(size.width * .1, size.height * .36)
      ..lineTo(size.width * .9, size.height * .36)
      ..moveTo(size.width * .12, size.height * .84)
      ..lineTo(size.width * .88, size.height * .84)
      ..moveTo(size.width * .06, size.height * .94)
      ..lineTo(size.width * .94, size.height * .94);
    for (final x in [.22, .4, .6, .78]) {
      path
        ..moveTo(size.width * x, size.height * .42)
        ..lineTo(size.width * x, size.height * .8);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TemplePainter oldDelegate) =>
      oldDelegate.color != color;
}

class GreekCutCornerClipper extends CustomClipper<Path> {
  const GreekCutCornerClipper({this.cut = 7});
  final double cut;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(cut, 0)
    ..lineTo(size.width - cut, 0)
    ..lineTo(size.width, cut)
    ..lineTo(size.width, size.height - cut)
    ..lineTo(size.width - cut, size.height)
    ..lineTo(cut, size.height)
    ..lineTo(0, size.height - cut)
    ..lineTo(0, cut)
    ..close();

  @override
  bool shouldReclip(covariant GreekCutCornerClipper oldClipper) =>
      oldClipper.cut != cut;
}
