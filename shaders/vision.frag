#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec3 uRed;
uniform vec3 uGreen;
uniform vec3 uBlue;
uniform sampler2D uSource;
out vec4 fragColor;

vec3 linearRGB(vec3 encoded) {
  return mix(encoded / 12.92, pow((encoded + .055) / 1.055, vec3(2.4)),
             step(vec3(.04045), encoded));
}

vec3 encodedRGB(vec3 linear) {
  return mix(linear * 12.92, 1.055 * pow(linear, vec3(1.0 / 2.4)) - .055,
             step(vec3(.0031308), linear));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  vec4 source = texture(uSource, uv);
  vec3 rgb = linearRGB(clamp(source.rgb / max(source.a, 0.000001), 0.0, 1.0));
  vec3 result = clamp(vec3(dot(uRed, rgb), dot(uGreen, rgb), dot(uBlue, rgb)), 0.0, 1.0);
  fragColor = vec4(encodedRGB(result) * source.a, source.a);
}
