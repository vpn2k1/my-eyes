/// Linear-sRGB 3x3 matrices approximating what a camera sees through real
/// color-blind-correction glasses, derived offline from published filter
/// characteristics (notch/cutoff center and width) by computing per-cone
/// (L/M/S) transmittance gain and converting back to RGB. See the project
/// plan for the derivation method and sources; these are approximations of
/// a proprietary optical product, not the manufacturer's exact formula.
library;

/// Narrow notch around the L/M cone overlap (~530-560nm) plus a shallow blue
/// stopband, the kind used by multi-notch red-green glasses.
const notchRedGreenMatrix = <double>[
  0.7718, 0.2044, 0.0453, //
  -0.0209, 0.6276, -0.0334, //
  0.0048, 0.0275, 0.8835,
];

/// Wider, shallower cutoff (~530-580nm) than a true notch - a broad tinted
/// lens, less selective than [notchRedGreenMatrix].
const broadTintRedGreenMatrix = <double>[
  0.7239, 0.0666, 0.0453, //
  -0.0070, 0.6752, -0.0413, //
  0.0059, 0.0354, 0.9727,
];

/// Red long-pass lens (~560-600nm cutoff) worn over one eye only; apply this
/// to one side of a split view and the identity matrix to the other - a
/// single flat image cannot reproduce the binocular comparison this design
/// actually relies on.
const monocularRedTintMatrix = <double>[
  0.5174, 0.6136, 0.0134, //
  -0.0617, 0.0917, 0.0219, //
  -0.0027, -0.0237, -0.0011,
];

/// Notch around the S/M overlap (~480-500nm) for blue-yellow support. Far
/// less public/commercial precedent than the red-green types above, so this
/// is the lowest-confidence matrix of the set.
const tritanTintMatrix = <double>[
  0.9790, 0.1419, 0.0074, //
  -0.0143, 0.8803, 0.0008, //
  -0.0000, -0.0018, 0.8891,
];
