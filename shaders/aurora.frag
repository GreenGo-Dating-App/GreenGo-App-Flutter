#version 460 core

// Calm aurora background for the auth screens (login / waiting).
// A few very large, soft colour fields drift on closed Lissajous paths so the
// whole image loops seamlessly every uPeriod seconds. Everything stays dark:
// the brightest pixel is a deep green, so white text on top keeps WCAG AA.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;   // seconds
uniform float uPeriod; // loop length in seconds

out vec4 fragColor;

const float TAU = 6.28318530718;

// Brand palette (linear-ish sRGB, pre-darkened).
const vec3 BASE   = vec3(0.016, 0.027, 0.024); // near-black, green-tinted
const vec3 GREEN  = vec3(0.043, 0.239, 0.180); // #0B3D2E
const vec3 EMER   = vec3(0.035, 0.180, 0.150); // deeper emerald
const vec3 TEAL   = vec3(0.040, 0.200, 0.215); // faint teal hint
const vec3 GOLD   = vec3(0.831, 0.686, 0.216); // #D4AF37 (used at ~4%)

float blob(vec2 p, vec2 c, float r) {
  float d = length(p - c) / r;
  return exp(-d * d * 1.6);
}

// Cheap hash for dithering (kills 8-bit banding on large gradients).
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float aspect = uSize.x / max(uSize.y, 1.0);
  vec2 uv = frag / uSize;              // 0..1
  vec2 p = vec2(uv.x * aspect, uv.y);  // aspect-corrected

  float a = TAU * uTime / uPeriod;     // one full turn per loop

  vec2 c1 = vec2((0.20 + 0.10 * sin(a)) * aspect,        0.18 + 0.08 * cos(a));
  vec2 c2 = vec2((0.85 + 0.08 * cos(a + 1.7)) * aspect,  0.40 + 0.10 * sin(2.0 * a + 0.6));
  vec2 c3 = vec2((0.35 + 0.12 * sin(2.0 * a + 2.4)) * aspect, 0.92 + 0.06 * cos(a + 0.3));
  vec2 c4 = vec2((0.70 + 0.10 * cos(a + 4.1)) * aspect,  0.08 + 0.05 * sin(a + 2.0));

  float r = 0.55 * max(aspect, 1.0);

  vec3 col = BASE;
  // Vertical base: slightly greener at the top, black at the bottom.
  col = mix(col, GREEN * 0.45, (1.0 - uv.y) * 0.55);
  col += GREEN * 0.55 * blob(p, c1, r);
  col += TEAL  * 0.40 * blob(p, c2, r * 0.9);
  col += EMER  * 0.45 * blob(p, c3, r * 1.1);
  col += GOLD  * 0.035 * blob(p, c4, r * 0.7);

  // Soft vignette keeps the edges deep and the centre calm.
  float v = length(uv - vec2(0.5, 0.45));
  col *= mix(1.0, 0.55, smoothstep(0.35, 0.95, v));

  // +-0.5/255 dither.
  col += (hash(frag) - 0.5) / 255.0;

  fragColor = vec4(col, 1.0);
}
