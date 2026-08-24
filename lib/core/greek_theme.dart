import 'package:flutter/material.dart';

abstract final class GreekPalette {
  static const marble = Color(0xFFF4EFE4);
  static const ivory = Color(0xFFFFFCF4);
  static const aegean = Color(0xFF164C63);
  static const aegeanDeep = Color(0xFF0C3446);
  static const terracotta = Color(0xFFAD593B);
  static const antiqueGold = Color(0xFFB58A3B);
  static const olive = Color(0xFF64704A);
  static const ink = Color(0xFF272821);
  static const limestone = Color(0xFFE4DAC7);
}

ThemeData buildGreekTheme() {
  const scheme = ColorScheme.light(
    primary: GreekPalette.aegean,
    onPrimary: GreekPalette.ivory,
    primaryContainer: Color(0xFFDCE8E8),
    onPrimaryContainer: GreekPalette.aegeanDeep,
    secondary: GreekPalette.terracotta,
    onSecondary: GreekPalette.ivory,
    secondaryContainer: Color(0xFFF2DCD1),
    onSecondaryContainer: Color(0xFF592718),
    tertiary: GreekPalette.antiqueGold,
    onTertiary: GreekPalette.ink,
    tertiaryContainer: Color(0xFFF2E4BC),
    onTertiaryContainer: Color(0xFF45330D),
    error: Color(0xFF9D382F),
    onError: Colors.white,
    surface: GreekPalette.ivory,
    onSurface: GreekPalette.ink,
    outline: Color(0xFF9D8B6E),
    outlineVariant: GreekPalette.limestone,
    shadow: Color(0x33272821),
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final serif = base.textTheme.apply(
    bodyColor: GreekPalette.ink,
    displayColor: GreekPalette.ink,
  );
  return base.copyWith(
    scaffoldBackgroundColor: GreekPalette.marble,
    textTheme: serif.copyWith(
      headlineLarge: serif.headlineLarge?.copyWith(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      headlineMedium: serif.headlineMedium?.copyWith(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
      titleLarge: serif.titleLarge?.copyWith(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
      titleMedium: serif.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: serif.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: .4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: GreekPalette.marble,
      foregroundColor: GreekPalette.aegeanDeep,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: GreekPalette.aegeanDeep,
        fontFamily: 'serif',
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 1,
      shadowColor: Color(0x25272821),
      color: GreekPalette.ivory,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: GreekPalette.limestone),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: GreekPalette.ivory,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: GreekPalette.limestone),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: GreekPalette.limestone),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: GreekPalette.aegean, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 0,
      backgroundColor: GreekPalette.ivory,
      surfaceTintColor: Colors.transparent,
      indicatorColor: GreekPalette.antiqueGold.withValues(alpha: .24),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? GreekPalette.aegeanDeep
              : const Color(0xFF6E695E),
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? GreekPalette.aegeanDeep
              : const Color(0xFF6E695E),
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : null,
          fontSize: 12,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: GreekPalette.aegean),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: GreekPalette.ivory,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: GreekPalette.antiqueGold),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: GreekPalette.ivory,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: GreekPalette.limestone,
      thickness: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: GreekPalette.ivory,
      selectedColor: const Color(0xFFDCE8E8),
      side: const BorderSide(color: GreekPalette.limestone),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
  );
}

class GreekKeyBorder extends StatelessWidget {
  const GreekKeyBorder({this.height = 12, this.color, super.key});

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _GreekKeyPainter(
          color: color ?? Theme.of(context).colorScheme.tertiary,
        ),
      ),
    ),
  );
}

class _GreekKeyPainter extends CustomPainter {
  const _GreekKeyPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final unit = size.height;
    final path = Path();
    for (double x = -unit; x < size.width + unit; x += unit * 2) {
      path
        ..moveTo(x, size.height * .78)
        ..lineTo(x + unit * 1.55, size.height * .78)
        ..lineTo(x + unit * 1.55, size.height * .22)
        ..lineTo(x + unit * .45, size.height * .22)
        ..lineTo(x + unit * .45, size.height * .58)
        ..lineTo(x + unit * 1.12, size.height * .58)
        ..lineTo(x + unit * 1.12, size.height * .4)
        ..lineTo(x + unit * .82, size.height * .4);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _GreekKeyPainter oldDelegate) =>
      oldDelegate.color != color;
}

class GreekBrandMark extends StatelessWidget {
  const GreekBrandMark({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(
        width: 34,
        height: 34,
        child: CustomPaint(painter: _TemplePainter()),
      ),
      const SizedBox(width: 10),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPR',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: GreekPalette.aegeanDeep,
              letterSpacing: 2.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'ARETĒ  •  TRACK EVERY REP',
            style: TextStyle(
              color: GreekPalette.terracotta,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    ],
  );
}

class GreekMottoBanner extends StatelessWidget {
  const GreekMottoBanner({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: GreekPalette.ivory,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: GreekPalette.antiqueGold),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            'ΑΡΕΤΗ',
            style: TextStyle(
              color: GreekPalette.aegeanDeep,
              fontFamily: 'serif',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          SizedBox(width: 14),
          SizedBox(
            height: 30,
            child: VerticalDivider(color: GreekPalette.antiqueGold),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Keunggulan dibangun satu repetisi demi satu repetisi.',
              style: TextStyle(
                color: GreekPalette.terracotta,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TemplePainter extends CustomPainter {
  const _TemplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GreekPalette.antiqueGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.miter;
    final path = Path()
      ..moveTo(2, 10)
      ..lineTo(size.width / 2, 2)
      ..lineTo(size.width - 2, 10)
      ..close()
      ..moveTo(4, 12)
      ..lineTo(size.width - 4, 12)
      ..moveTo(7, 29)
      ..lineTo(size.width - 7, 29)
      ..moveTo(4, 32)
      ..lineTo(size.width - 4, 32);
    for (final x in [9.0, 15.0, 21.0, 27.0]) {
      path
        ..moveTo(x, 14)
        ..lineTo(x, 28);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
