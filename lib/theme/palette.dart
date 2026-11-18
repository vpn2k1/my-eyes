import 'dart:ui' show Color;

/// Brand colors for surfaces the Material [ColorScheme] does not cover: the
/// hero card, the full-screen camera chrome and the eye-test result card.
///
/// Rule for this app: never carry meaning in hue alone. Every colored element
/// pairs its color with an icon, a label, or a lightness difference. Navy and
/// amber are the signal pair because they differ in lightness (relative
/// luminance 0.013 vs 0.42) as well as hue — a tritan viewer confuses blue with
/// yellow by hue, so the lightness gap is what actually carries the signal.
const brandSeed = Color(0xff2563eb);
const brandNavy = Color(0xff141e35);
const brandNavyLift = Color(0xff253c62);
const brandInk = Color(0xfff5f7fd);
const brandAmber = Color(0xffe0a32e);
