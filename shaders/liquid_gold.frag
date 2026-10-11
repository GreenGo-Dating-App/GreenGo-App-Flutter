#version 460 core

// "Liquid Gold" background for the auth screens (login / waiting).
// Three large, soft, molten-gold glows over a warm near-black base. The glow
// positions/radii are animated on the Dart side (LiquidGoldBackground) and
// passed in as uniforms, so this shader only composites — it stays cheap and
// the Dart fallback painter shares exactly the same motion.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uGlowA; // centre.xy (px), core radius, blur (px)
uniform vec4 uGlowB;
uniform vec4 uGlowC;

out vec4 fragColor;

const vec3 BASE = vec3(0.027, 0.024, 0.016);   // #070604
const vec4 COL_A = vec4(0.914, 0.769, 0.416, 0.55); // rgba(233,196,106,.55)
const vec4 COL_B = vec4(0.788, 0.549, 0.157, 0.45); // rgba(201,140,40,.45)
const vec4 COL_C = vec4(0.627, 0.431, 0.118, 0.40); // rgba(160,110,30,.40)

// Linear radial ramp (CSS radial-gradient to transparent) softened as if it
// had been blurred: falls from ~0.92 at the centre to 0 at r + 0.9 * blur.
float glow(vec2 p, vec4 g) {
  float reach = g.z + 0.9 * g.w;
  float x = clamp(1.0 - length(p - g.xy) / reach, 0.0, 1.0);
  return 0.92 * x * x * (3.0 - 2.0 * x);
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec3 col = BASE;
  float a;
  a = COL_A.a * glow(p, uGlowA); col = mix(col, COL_A.rgb, a);
  a = COL_B.a * glow(p, uGlowB); col = mix(col, COL_B.rgb, a);
  a = COL_C.a * glow(p, uGlowC); col = mix(col, COL_C.rgb, a);
  // +-0.5/255 dither: no 8-bit banding on the huge soft gradients.
  col += (hash(p) - 0.5) / 255.0;
  fragColor = vec4(col, 1.0);
}
