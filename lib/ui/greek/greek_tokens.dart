import 'package:flutter/material.dart';

enum GreekActionVariant { primary, secondary, destructive, quiet }

enum GreekPanelVariant { stone, active, success, warning }

enum GreekNoticeKind { info, success, warning, error }

abstract final class GreekColors {
  static const marble = Color(0xFFF3EBDD);
  static const marbleLight = Color(0xFFFFFCF4);
  static const limestone = Color(0xFFDED2BE);
  static const limestoneDark = Color(0xFFC8B99F);
  static const aegean = Color(0xFF103F56);
  static const aegeanDeep = Color(0xFF082B3A);
  static const aegeanPale = Color(0xFFD9E4E5);
  static const bronze = Color(0xFFB78A3A);
  static const bronzeDeep = Color(0xFF7A5822);
  static const terracotta = Color(0xFFA94F35);
  static const terracottaPale = Color(0xFFF0D8CE);
  static const olive = Color(0xFF66704A);
  static const olivePale = Color(0xFFDDE2CF);
  static const ink = Color(0xFF25251F);
  static const inkMuted = Color(0xFF69655B);
  static const danger = Color(0xFF923A32);
  static const white = Color(0xFFFFFFFF);
}

abstract final class GreekSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class GreekMotion {
  static const quick = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 200);

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

ThemeData buildGreekTheme() {
  const scheme = ColorScheme.light(
    primary: GreekColors.aegean,
    onPrimary: GreekColors.marbleLight,
    primaryContainer: GreekColors.aegeanPale,
    onPrimaryContainer: GreekColors.aegeanDeep,
    secondary: GreekColors.terracotta,
    onSecondary: GreekColors.marbleLight,
    secondaryContainer: GreekColors.terracottaPale,
    onSecondaryContainer: GreekColors.ink,
    tertiary: GreekColors.bronze,
    onTertiary: GreekColors.ink,
    tertiaryContainer: Color(0xFFF0E1B8),
    onTertiaryContainer: GreekColors.ink,
    error: GreekColors.danger,
    onError: GreekColors.white,
    surface: GreekColors.marbleLight,
    onSurface: GreekColors.ink,
    outline: GreekColors.limestoneDark,
    outlineVariant: GreekColors.limestone,
  );
  final base = ThemeData(
    useMaterial3: false,
    colorScheme: scheme,
    fontFamily: 'NotoSans',
    scaffoldBackgroundColor: Colors.transparent,
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
  );
  final text = base.textTheme.apply(
    fontFamily: 'NotoSans',
    bodyColor: GreekColors.ink,
    displayColor: GreekColors.ink,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(
        fontFamily: 'NotoSerif',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontFamily: 'NotoSerif',
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontFamily: 'NotoSerif',
        fontWeight: FontWeight.w700,
        letterSpacing: .8,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontFamily: 'NotoSerif',
        fontWeight: FontWeight.w700,
        letterSpacing: .6,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.35),
    ),
    iconTheme: const IconThemeData(color: GreekColors.aegeanDeep),
    dividerTheme: const DividerThemeData(
      color: GreekColors.limestone,
      thickness: 1,
      space: 1,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: GreekColors.aegean,
      selectionColor: GreekColors.aegeanPale,
      selectionHandleColor: GreekColors.bronze,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _GreekPageTransitionBuilder(),
        TargetPlatform.iOS: _GreekPageTransitionBuilder(),
        TargetPlatform.windows: _GreekPageTransitionBuilder(),
      },
    ),
  );
}

class _GreekPageTransitionBuilder extends PageTransitionsBuilder {
  const _GreekPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(.025, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

const tabularFigures = [FontFeature.tabularFigures()];
