import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff006e1c),
      surfaceTint: Color(0xff006e1c),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff4caf50),
      onPrimaryContainer: Color(0xff003c0b),
      secondary: Color(0xff42673f),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffc3eebb),
      onSecondaryContainer: Color(0xff486d45),
      tertiary: Color(0xff006492),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff00a4ec),
      onTertiaryContainer: Color(0xff003652),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fbef),
      onSurface: Color(0xff171d16),
      onSurfaceVariant: Color(0xff3f4a3c),
      outline: Color(0xff6f7a6b),
      outlineVariant: Color(0xffbecab9),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322a),
      inversePrimary: Color(0xff78dc77),
      primaryFixed: Color(0xff94f990),
      onPrimaryFixed: Color(0xff002204),
      primaryFixedDim: Color(0xff78dc77),
      onPrimaryFixedVariant: Color(0xff005313),
      secondaryFixed: Color(0xffc3eebb),
      onSecondaryFixed: Color(0xff002204),
      secondaryFixedDim: Color(0xffa8d1a1),
      onSecondaryFixedVariant: Color(0xff2b4f2a),
      tertiaryFixed: Color(0xffcae6ff),
      onTertiaryFixed: Color(0xff001e2f),
      tertiaryFixedDim: Color(0xff8cceff),
      onTertiaryFixedVariant: Color(0xff004b6f),
      surfaceDim: Color(0xffd6dcd0),
      surfaceBright: Color(0xfff5fbef),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff0f6ea),
      surfaceContainer: Color(0xffeaf0e4),
      surfaceContainerHigh: Color(0xffe4eade),
      surfaceContainerHighest: Color(0xffdee4d9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00400c),
      surfaceTint: Color(0xff006e1c),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff117e26),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1a3e1a),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff51764d),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003a57),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff0074a8),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbef),
      onSurface: Color(0xff0d130c),
      onSurfaceVariant: Color(0xff2f392c),
      outline: Color(0xff4b5548),
      outlineVariant: Color(0xff657061),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322a),
      inversePrimary: Color(0xff78dc77),
      primaryFixed: Color(0xff117e26),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff006318),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff51764d),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff395d37),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff0074a8),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff005a84),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2c8bd),
      surfaceBright: Color(0xfff5fbef),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff0f6ea),
      surfaceContainer: Color(0xffe4eade),
      surfaceContainerHigh: Color(0xffd9dfd3),
      surfaceContainerHighest: Color(0xffced4c8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003509),
      surfaceTint: Color(0xff006e1c),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff005614),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff0f3311),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff2d512c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff002f48),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff004e73),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fbef),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252f23),
      outlineVariant: Color(0xff414c3f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2c322a),
      inversePrimary: Color(0xff78dc77),
      primaryFixed: Color(0xff005614),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003c0b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff2d512c),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff173a17),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff004e73),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff003652),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb5bbb0),
      surfaceBright: Color(0xfff5fbef),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffedf3e7),
      surfaceContainer: Color(0xffdee4d9),
      surfaceContainerHigh: Color(0xffd0d6cb),
      surfaceContainerHighest: Color(0xffc2c8bd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff78dc77),
      surfaceTint: Color(0xff78dc77),
      onPrimary: Color(0xff00390a),
      primaryContainer: Color(0xff4caf50),
      onPrimaryContainer: Color(0xff003c0b),
      secondary: Color(0xffa8d1a1),
      onSecondary: Color(0xff143815),
      secondaryContainer: Color(0xff2b4f2a),
      onSecondaryContainer: Color(0xff97c091),
      tertiary: Color(0xff8cceff),
      onTertiary: Color(0xff00344e),
      tertiaryContainer: Color(0xff00a4ec),
      onTertiaryContainer: Color(0xff003652),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0f150e),
      onSurface: Color(0xffdee4d9),
      onSurfaceVariant: Color(0xffbecab9),
      outline: Color(0xff899484),
      outlineVariant: Color(0xff3f4a3c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4d9),
      inversePrimary: Color(0xff006e1c),
      primaryFixed: Color(0xff94f990),
      onPrimaryFixed: Color(0xff002204),
      primaryFixedDim: Color(0xff78dc77),
      onPrimaryFixedVariant: Color(0xff005313),
      secondaryFixed: Color(0xffc3eebb),
      onSecondaryFixed: Color(0xff002204),
      secondaryFixedDim: Color(0xffa8d1a1),
      onSecondaryFixedVariant: Color(0xff2b4f2a),
      tertiaryFixed: Color(0xffcae6ff),
      onTertiaryFixed: Color(0xff001e2f),
      tertiaryFixedDim: Color(0xff8cceff),
      onTertiaryFixedVariant: Color(0xff004b6f),
      surfaceDim: Color(0xff0f150e),
      surfaceBright: Color(0xff353b33),
      surfaceContainerLowest: Color(0xff0a1009),
      surfaceContainerLow: Color(0xff171d16),
      surfaceContainer: Color(0xff1b211a),
      surfaceContainerHigh: Color(0xff262c24),
      surfaceContainerHighest: Color(0xff30362e),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff8ef38b),
      surfaceTint: Color(0xff78dc77),
      onPrimary: Color(0xff002d06),
      primaryContainer: Color(0xff4caf50),
      onPrimaryContainer: Color(0xff000f01),
      secondary: Color(0xffbde8b6),
      onSecondary: Color(0xff082c0b),
      secondaryContainer: Color(0xff739b6e),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbde1ff),
      onTertiary: Color(0xff00283e),
      tertiaryContainer: Color(0xff00a4ec),
      onTertiaryContainer: Color(0xff000c17),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0f150e),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd4e0ce),
      outline: Color(0xffaab5a4),
      outlineVariant: Color(0xff889484),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4d9),
      inversePrimary: Color(0xff005413),
      primaryFixed: Color(0xff94f990),
      onPrimaryFixed: Color(0xff001602),
      primaryFixedDim: Color(0xff78dc77),
      onPrimaryFixedVariant: Color(0xff00400c),
      secondaryFixed: Color(0xffc3eebb),
      onSecondaryFixed: Color(0xff001602),
      secondaryFixedDim: Color(0xffa8d1a1),
      onSecondaryFixedVariant: Color(0xff1a3e1a),
      tertiaryFixed: Color(0xffcae6ff),
      onTertiaryFixed: Color(0xff001320),
      tertiaryFixedDim: Color(0xff8cceff),
      onTertiaryFixedVariant: Color(0xff003a57),
      surfaceDim: Color(0xff0f150e),
      surfaceBright: Color(0xff40463e),
      surfaceContainerLowest: Color(0xff040904),
      surfaceContainerLow: Color(0xff191f18),
      surfaceContainer: Color(0xff242922),
      surfaceContainerHigh: Color(0xff2e342c),
      surfaceContainerHighest: Color(0xff393f37),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc5ffbc),
      surfaceTint: Color(0xff78dc77),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff74d873),
      onPrimaryContainer: Color(0xff000f01),
      secondary: Color(0xffd1fcc8),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffa4cd9d),
      onSecondaryContainer: Color(0xff000f01),
      tertiary: Color(0xffe4f2ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff82caff),
      onTertiaryContainer: Color(0xff000d17),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0f150e),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f4e1),
      outlineVariant: Color(0xffbac6b5),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee4d9),
      inversePrimary: Color(0xff005413),
      primaryFixed: Color(0xff94f990),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff78dc77),
      onPrimaryFixedVariant: Color(0xff001602),
      secondaryFixed: Color(0xffc3eebb),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffa8d1a1),
      onSecondaryFixedVariant: Color(0xff001602),
      tertiaryFixed: Color(0xffcae6ff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xff8cceff),
      onTertiaryFixedVariant: Color(0xff001320),
      surfaceDim: Color(0xff0f150e),
      surfaceBright: Color(0xff4c5249),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b211a),
      surfaceContainer: Color(0xff2c322a),
      surfaceContainerHigh: Color(0xff373d35),
      surfaceContainerHighest: Color(0xff424840),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
