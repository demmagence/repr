import 'package:flutter/material.dart';

enum AppActionVariant { primary, secondary, destructive, quiet }

ThemeData buildAppTheme() =>
    ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo);

const tabularFigures = [FontFeature.tabularFigures()];
