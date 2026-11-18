import 'package:material_ui/material_ui.dart';

/// Brand colors for surfaces the Material [ColorScheme] does not cover: the
/// hero card, the full-screen camera chrome and the eye-test result card.
///
/// Rule for this app: never carry meaning in hue alone. Every colored element
/// pairs its color with an icon, a label, or a lightness difference. Navy and
/// amber are the signal pair because they differ in lightness (relative
/// luminance 0.013 vs 0.42) as well as hue — a tritan viewer confuses blue with
/// yellow by hue, so the lightness gap is what actually carries the signal.
const brandSeed = Color(0xff3366ff);
const brandNavy = Color(0xff141e35);
const brandNavyLift = Color(0xff253c62);
const brandInk = Color(0xfff5f7fd);
const brandAmber = Color(0xffe0a32e);

/// Fixed feature pigments are also separated by luminance, not hue alone.
typedef FeatureAccent = ({Color accent, Color onAccent});

class AppAccents extends ThemeExtension<AppAccents> {
  const AppAccents({
    required this.experience,
    required this.correction,
    required this.photo,
    required this.explore,
    required this.screening,
  });

  final FeatureAccent experience, correction, photo, explore, screening;

  static const light = AppAccents(
    // L=.072; next (teal) is .074 lighter.
    experience: (accent: Color(0xff1d43ab), onAccent: brandInk),
    // L=.146; next (coral) is .186 lighter.
    correction: (accent: Color(0xff267767), onAccent: brandInk),
    // L=.332; next (amber) is .090 lighter.
    photo: (accent: Color(0xffd18b70), onAccent: brandNavy),
    // L=.716; .294 lighter than the neighboring amber.
    explore: (accent: Color(0xffe3d6ff), onAccent: brandNavy),
    // L=.422; .090 lighter than coral, .294 darker than violet.
    screening: (accent: brandAmber, onAccent: brandNavy),
  );

  static const dark = AppAccents(
    // L=.052; next (teal) is .066 lighter.
    experience: (accent: Color(0xff173992), onAccent: brandInk),
    // L=.118; next (coral) is .170 lighter.
    correction: (accent: Color(0xff206c5d), onAccent: brandInk),
    // L=.288; next (amber) is .134 lighter.
    photo: (accent: Color(0xffc98065), onAccent: brandNavy),
    // L=.627; .205 lighter than the neighboring amber.
    explore: (accent: Color(0xffd9c8f5), onAccent: brandNavy),
    // L=.422; .134 lighter than coral, .205 darker than violet.
    screening: (accent: brandAmber, onAccent: brandNavy),
  );

  static AppAccents of(BuildContext context) =>
      Theme.of(context).extension<AppAccents>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  AppAccents copyWith({
    FeatureAccent? experience,
    FeatureAccent? correction,
    FeatureAccent? photo,
    FeatureAccent? explore,
    FeatureAccent? screening,
  }) => AppAccents(
    experience: experience ?? this.experience,
    correction: correction ?? this.correction,
    photo: photo ?? this.photo,
    explore: explore ?? this.explore,
    screening: screening ?? this.screening,
  );

  @override
  AppAccents lerp(AppAccents? other, double t) {
    if (other == null) return this;
    FeatureAccent mix(FeatureAccent a, FeatureAccent b) => (
      accent: Color.lerp(a.accent, b.accent, t)!,
      onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
    );
    return AppAccents(
      experience: mix(experience, other.experience),
      correction: mix(correction, other.correction),
      photo: mix(photo, other.photo),
      explore: mix(explore, other.explore),
      screening: mix(screening, other.screening),
    );
  }
}
