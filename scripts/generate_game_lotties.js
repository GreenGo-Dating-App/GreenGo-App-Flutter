#!/usr/bin/env node
/**
 * generate_game_lotties.js
 * Generates 8 Lottie (bodymovin) JSON files for the GreenGo games feature.
 */

const fs = require('fs');
const path = require('path');

const OUTPUT_DIR = path.join(__dirname, '..', 'assets', 'lottie', 'games');

// ── Helpers ──────────────────────────────────────────────────────────────────

function hexToRgb01(hex) {
  const h = hex.replace('#', '');
  return [
    parseInt(h.substring(0, 2), 16) / 255,
    parseInt(h.substring(2, 4), 16) / 255,
    parseInt(h.substring(4, 6), 16) / 255,
  ];
}

function makeLottie(op, layers) {
  return {
    v: '5.7.4',
    fr: 30,
    ip: 0,
    op,
    w: 512,
    h: 512,
    nm: 'Composition',
    ddd: 0,
    assets: [],
    layers,
  };
}

function staticVal(v) {
  if (Array.isArray(v)) return { a: 0, k: v };
  return { a: 0, k: v };
}

function animatedVal(keyframes) {
  return { a: 1, k: keyframes };
}

/** Simple two-value keyframe helper (linear) */
function kf(t1, v1, t2, v2) {
  return [
    { t: t1, s: Array.isArray(v1) ? v1 : [v1], e: Array.isArray(v2) ? v2 : [v2] },
    { t: t2, s: Array.isArray(v2) ? v2 : [v2] },
  ];
}

/** Multi-stop keyframes */
function kfMulti(stops) {
  const out = [];
  for (let i = 0; i < stops.length - 1; i++) {
    out.push({ t: stops[i][0], s: asArr(stops[i][1]), e: asArr(stops[i + 1][1]) });
  }
  out.push({ t: stops[stops.length - 1][0], s: asArr(stops[stops.length - 1][1]) });
  return out;
}

function asArr(v) { return Array.isArray(v) ? v : [v]; }

function makeTransform(opts = {}) {
  const o = opts.o !== undefined ? opts.o : staticVal(100);
  const r = opts.r !== undefined ? opts.r : staticVal(0);
  const p = opts.p !== undefined ? opts.p : staticVal([256, 256, 0]);
  const a = opts.a !== undefined ? opts.a : staticVal([0, 0, 0]);
  const s = opts.s !== undefined ? opts.s : staticVal([100, 100, 100]);
  return { o, r, p, a, s };
}

function rectShape(w, h, r) {
  return { ty: 'rc', d: 1, s: staticVal([w, h]), p: staticVal([0, 0]), r: staticVal(r || 0), nm: 'Rect' };
}

function ellipseShape(w, h) {
  return { ty: 'el', d: 1, s: staticVal([w, h || w]), p: staticVal([0, 0]), nm: 'Ellipse' };
}

function fillShape(color, opacity) {
  const rgb = typeof color === 'string' ? hexToRgb01(color) : color;
  const c = [...rgb, 1];
  return { ty: 'fl', c: staticVal(c), o: opacity !== undefined ? staticVal(opacity) : staticVal(100), r: 1, bm: 0, nm: 'Fill' };
}

function strokeShape(color, width, opacity) {
  const rgb = typeof color === 'string' ? hexToRgb01(color) : color;
  const c = [...rgb, 1];
  return { ty: 'st', c: staticVal(c), o: opacity !== undefined ? staticVal(opacity) : staticVal(100), w: staticVal(width || 2), lc: 2, lj: 2, nm: 'Stroke' };
}

function shapeGroup(name, items, transform) {
  return {
    ty: 'gr',
    it: [...items, { ty: 'tr', p: transform && transform.p ? transform.p : staticVal([0, 0]), a: staticVal([0, 0]), s: transform && transform.s ? transform.s : staticVal([100, 100]), r: transform && transform.r ? transform.r : staticVal(0), o: transform && transform.o ? transform.o : staticVal(100), nm: 'Transform' }],
    nm: name,
    bm: 0,
  };
}

function shapeLayer(name, shapes, transform, ind) {
  return {
    ddd: 0,
    ind: ind || 1,
    ty: 4,
    nm: name,
    sr: 1,
    ks: transform || makeTransform(),
    ao: 0,
    shapes,
    ip: 0,
    op: 9999,
    st: 0,
    bm: 0,
  };
}

// ── 1. Categories ────────────────────────────────────────────────────────────

function generateCategories() {
  const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#DDA0DD', '#F7DC6F', '#87CEEB', '#FFB347', '#98D8C8'];
  const layers = [];
  const tileSize = 90;
  const gap = 20;
  const gridStart = 256 - (tileSize + gap); // center the 3x3

  // 9 tiles
  for (let i = 0; i < 9; i++) {
    const row = Math.floor(i / 3);
    const col = i % 3;
    const x = gridStart + col * (tileSize + gap);
    const y = gridStart + row * (tileSize + gap);
    const startFrame = i * 15;
    const endFrame = startFrame + 20;

    const opacityAnim = animatedVal(kfMulti([
      [0, 0],
      [startFrame, 25],
      [endFrame, 100],
      [135, 100],
    ]));

    const group = shapeGroup('Tile' + i, [
      rectShape(tileSize, tileSize, 12),
      fillShape(colors[i]),
    ]);

    layers.push(shapeLayer('Tile_' + i, [group], makeTransform({
      p: staticVal([x, y, 0]),
      o: opacityAnim,
    }), i + 1));
  }

  // Gold scanning bar
  const barGroup = shapeGroup('Bar', [
    rectShape(300, 4, 2),
    fillShape('#FFD700'),
  ]);
  const barPosAnim = animatedVal(kfMulti([
    [0, [256, gridStart - 30, 0]],
    [120, [256, gridStart + 3 * (tileSize + gap) + 30, 0]],
    [135, [256, gridStart + 3 * (tileSize + gap) + 30, 0]],
  ]));
  layers.push(shapeLayer('ScanBar', [barGroup], makeTransform({
    p: barPosAnim,
    o: animatedVal(kfMulti([[0, 80], [120, 80], [135, 0]])),
  }), 10));

  return makeLottie(135, layers);
}

// ── 2. Grammar Duel ──────────────────────────────────────────────────────────

function generateGrammarDuel() {
  const layers = [];

  // Sword blade shape (tall narrow rect)
  function swordShapes(color) {
    return [
      shapeGroup('Blade', [
        rectShape(16, 160, 4),
        fillShape(color),
      ], { p: staticVal([0, -60]) }),
      shapeGroup('Guard', [
        rectShape(50, 10, 3),
        fillShape('#888888'),
      ], { p: staticVal([0, 20]) }),
      shapeGroup('Handle', [
        rectShape(12, 40, 2),
        fillShape('#5D4E37'),
      ], { p: staticVal([0, 45]) }),
    ];
  }

  // Left sword - red, wobbles around -40deg
  const leftRot = animatedVal(kfMulti([
    [0, -44], [15, -36], [30, -44], [45, -36], [60, -44], [75, -36], [90, -44],
  ]));
  layers.push(shapeLayer('LeftSword', swordShapes('#FF4444'), makeTransform({
    p: staticVal([220, 260, 0]),
    a: staticVal([0, 45, 0]),
    r: leftRot,
  }), 1));

  // Right sword - blue, wobbles around +40deg
  const rightRot = animatedVal(kfMulti([
    [0, 44], [15, 36], [30, 44], [45, 36], [60, 44], [75, 36], [90, 44],
  ]));
  layers.push(shapeLayer('RightSword', swordShapes('#4488FF'), makeTransform({
    p: staticVal([292, 260, 0]),
    a: staticVal([0, 45, 0]),
    r: rightRot,
  }), 2));

  // Center gold circle pulse
  const scaleAnim = animatedVal(kfMulti([
    [0, [50, 50, 100]], [22, [100, 100, 100]], [45, [50, 50, 100]], [67, [100, 100, 100]], [90, [50, 50, 100]],
  ]));
  const goldCircle = shapeGroup('GoldCircle', [
    ellipseShape(40, 40),
    fillShape('#FFD700'),
  ]);
  layers.push(shapeLayer('CenterPulse', [goldCircle], makeTransform({
    p: staticVal([256, 230, 0]),
    s: scaleAnim,
  }), 3));

  // Spark lines (4 lines radiating from center)
  for (let i = 0; i < 4; i++) {
    const angle = i * 90 + 45;
    const sparkGroup = shapeGroup('Spark' + i, [
      rectShape(3, 30, 1),
      fillShape('#FFD700', 80),
    ]);
    const sparkScale = animatedVal(kfMulti([
      [0, [100, 30, 100]], [22, [100, 100, 100]], [45, [100, 30, 100]], [67, [100, 100, 100]], [90, [100, 30, 100]],
    ]));
    layers.push(shapeLayer('Spark_' + i, [sparkGroup], makeTransform({
      p: staticVal([256, 230, 0]),
      r: staticVal(angle),
      s: sparkScale,
    }), 4 + i));
  }

  return makeLottie(90, layers);
}

// ── 3. Language Snap ─────────────────────────────────────────────────────────

function generateLanguageSnap() {
  const layers = [];

  // Left card (red) slides in from left
  const leftCard = shapeGroup('LeftCard', [
    rectShape(120, 170, 14),
    fillShape('#E74C3C'),
  ]);
  const leftPos = animatedVal(kfMulti([
    [0, [100, 256, 0]],
    [50, [210, 256, 0]],
    [120, [210, 256, 0]],
  ]));
  layers.push(shapeLayer('CardLeft', [leftCard], makeTransform({ p: leftPos }), 1));

  // Right card (blue) slides in from right
  const rightCard = shapeGroup('RightCard', [
    rectShape(120, 170, 14),
    fillShape('#3498DB'),
  ]);
  const rightPos = animatedVal(kfMulti([
    [0, [412, 256, 0]],
    [50, [302, 256, 0]],
    [120, [302, 256, 0]],
  ]));
  layers.push(shapeLayer('CardRight', [rightCard], makeTransform({ p: rightPos }), 2));

  // Gold flash circle at midpoint
  const flashScale = animatedVal(kfMulti([
    [0, [0, 0, 100]],
    [45, [0, 0, 100]],
    [55, [20, 20, 100]],
    [65, [110, 110, 100]],
    [75, [110, 110, 100]],
    [120, [110, 110, 100]],
  ]));
  const flashOpacity = animatedVal(kfMulti([
    [0, 0], [45, 0], [55, 90], [70, 90], [80, 0], [120, 0],
  ]));
  const flash = shapeGroup('Flash', [
    ellipseShape(100, 100),
    fillShape('#FFD700'),
  ]);
  layers.push(shapeLayer('GoldFlash', [flash], makeTransform({
    p: staticVal([256, 256, 0]),
    s: flashScale,
    o: flashOpacity,
  }), 3));

  // Green checkmark circle appears after flash
  const checkScale = animatedVal(kfMulti([
    [0, [0, 0, 100]], [70, [0, 0, 100]], [85, [100, 100, 100]], [120, [100, 100, 100]],
  ]));
  const checkOpacity = animatedVal(kfMulti([
    [0, 0], [70, 0], [80, 100], [120, 100],
  ]));
  const checkCircle = shapeGroup('CheckCircle', [
    ellipseShape(60, 60),
    fillShape('#27AE60'),
  ]);
  // Simple checkmark using a small rect as indicator
  const checkMark = shapeGroup('CheckMark', [
    rectShape(20, 6, 2),
    fillShape('#FFFFFF'),
  ], { p: staticVal([0, 0]), r: staticVal(-45) });

  layers.push(shapeLayer('Checkmark', [checkCircle, checkMark], makeTransform({
    p: staticVal([256, 256, 0]),
    s: checkScale,
    o: checkOpacity,
  }), 4));

  return makeLottie(120, layers);
}

// ── 4. Language Tapples ──────────────────────────────────────────────────────

function generateLanguageTapples() {
  const layers = [];

  // Main wheel - rotating circle
  const wheelRotation = animatedVal(kf(0, 0, 120, 360));
  const wheel = shapeGroup('Wheel', [
    ellipseShape(220, 220),
    fillShape('#6C3483'),
    strokeShape('#8E44AD', 6),
  ]);
  // Inner circle
  const inner = shapeGroup('Inner', [
    ellipseShape(180, 180),
    fillShape('#8E44AD'),
  ]);
  layers.push(shapeLayer('WheelBase', [wheel, inner], makeTransform({
    p: staticVal([256, 256, 0]),
    r: wheelRotation,
  }), 1));

  // 8 letter segments positioned around circumference
  const letters = 'ABCDEFGH';
  for (let i = 0; i < 8; i++) {
    const angle = (i * 45) * Math.PI / 180;
    const r = 80;
    const x = 256 + Math.cos(angle) * r;
    const y = 256 + Math.sin(angle) * r;

    // Small circle for each letter position
    const seg = shapeGroup('Seg' + i, [
      ellipseShape(30, 30),
      fillShape('#F1C40F'),
    ]);
    const segRotation = animatedVal(kf(0, 0, 120, 360));
    layers.push(shapeLayer('Letter_' + letters[i], [seg], makeTransform({
      p: staticVal([256, 256, 0]),
      a: staticVal([256 - x, 256 - y, 0]),
      r: segRotation,
    }), i + 2));
  }

  // 4 outer category badges pulsing
  const badgePositions = [[256, 80], [256, 432], [80, 256], [432, 256]];
  const badgeColors = ['#E74C3C', '#3498DB', '#27AE60', '#F39C12'];
  for (let i = 0; i < 4; i++) {
    const stagger = i * 15;
    const opAnim = animatedVal(kfMulti([
      [0 + stagger, 70], [30 + stagger, 100], [60 + stagger, 70], [90 + stagger, 100], [120, 70],
    ]));
    const badge = shapeGroup('Badge' + i, [
      rectShape(60, 24, 12),
      fillShape(badgeColors[i]),
    ]);
    layers.push(shapeLayer('Badge_' + i, [badge], makeTransform({
      p: staticVal([badgePositions[i][0], badgePositions[i][1], 0]),
      o: opAnim,
    }), 10 + i));
  }

  return makeLottie(120, layers);
}

// ── 5. Picture Guess ─────────────────────────────────────────────────────────

function generatePictureGuess() {
  const layers = [];

  // Golden frame border
  const frame = shapeGroup('Frame', [
    rectShape(240, 240, 8),
    strokeShape('#FFD700', 8),
    fillShape('#2C2C3E', 40),
  ]);
  layers.push(shapeLayer('GoldenFrame', [frame], makeTransform({
    p: staticVal([256, 256, 0]),
  }), 1));

  // Frosted overlay that fades in/out
  const overlayOpacity = animatedVal(kfMulti([
    [0, 40], [30, 10], [60, 40], [90, 40],
  ]));
  const overlay = shapeGroup('Overlay', [
    rectShape(224, 224, 4),
    fillShape('#FFFFFF'),
  ]);
  layers.push(shapeLayer('Frost', [overlay], makeTransform({
    p: staticVal([256, 256, 0]),
    o: overlayOpacity,
  }), 2));

  // Question mark - pulsing scale and wobble rotation
  const qScale = animatedVal(kfMulti([
    [0, [80, 80, 100]], [22, [120, 120, 100]], [45, [80, 80, 100]], [67, [120, 120, 100]], [90, [80, 80, 100]],
  ]));
  const qRot = animatedVal(kfMulti([
    [0, -10], [22, 10], [45, -10], [67, 10], [90, -10],
  ]));
  // Build "?" from shapes: a circle on top, vertical bar, and dot
  const qTop = shapeGroup('QTop', [
    ellipseShape(50, 50),
    strokeShape('#7D3C98', 10),
    fillShape('#7D3C98', 0),
  ], { p: staticVal([0, -25]) });
  const qBar = shapeGroup('QBar', [
    rectShape(10, 30, 3),
    fillShape('#7D3C98'),
  ], { p: staticVal([15, 10]) });
  const qDot = shapeGroup('QDot', [
    ellipseShape(14, 14),
    fillShape('#7D3C98'),
  ], { p: staticVal([15, 35]) });

  layers.push(shapeLayer('QuestionMark', [qTop, qBar, qDot], makeTransform({
    p: staticVal([246, 240, 0]),
    s: qScale,
    r: qRot,
  }), 3));

  return makeLottie(90, layers);
}

// ── 6. Translation Race ──────────────────────────────────────────────────────

function generateTranslationRace() {
  const layers = [];

  // Top track
  const topTrack = shapeGroup('TopTrack', [
    rectShape(380, 40, 20),
    fillShape('#333344'),
  ]);
  layers.push(shapeLayer('TrackTop', [topTrack], makeTransform({
    p: staticVal([256, 190, 0]),
  }), 1));

  // Bottom track
  const bottomTrack = shapeGroup('BottomTrack', [
    rectShape(380, 40, 20),
    fillShape('#333344'),
  ]);
  layers.push(shapeLayer('TrackBottom', [bottomTrack], makeTransform({
    p: staticVal([256, 310, 0]),
  }), 2));

  // Purple bubble racing on top track
  const purplePos = animatedVal(kfMulti([
    [0, [100, 190, 0]], [75, [420, 190, 0]], [90, [420, 190, 0]],
  ]));
  const purbleBubble = shapeGroup('PurpleBubble', [
    ellipseShape(30, 30),
    fillShape('#8E44AD'),
  ]);
  layers.push(shapeLayer('RacerPurple', [purbleBubble], makeTransform({
    p: purplePos,
  }), 3));

  // Orange bubble racing on bottom track (12 frame delay)
  const orangePos = animatedVal(kfMulti([
    [0, [100, 310, 0]], [12, [100, 310, 0]], [82, [390, 310, 0]], [90, [390, 310, 0]],
  ]));
  const orangeBubble = shapeGroup('OrangeBubble', [
    ellipseShape(30, 30),
    fillShape('#E67E22'),
  ]);
  layers.push(shapeLayer('RacerOrange', [orangeBubble], makeTransform({
    p: orangePos,
  }), 4));

  // Speed lines behind purple
  for (let i = 0; i < 3; i++) {
    const lineGroup = shapeGroup('SpeedLine' + i, [
      rectShape(20 + i * 8, 3, 1),
      fillShape('#8E44AD', 50 - i * 15),
    ]);
    const linePos = animatedVal(kfMulti([
      [0, [80, 185 + i * 5, 0]], [75, [400, 185 + i * 5, 0]], [90, [400, 185 + i * 5, 0]],
    ]));
    layers.push(shapeLayer('SpeedP_' + i, [lineGroup], makeTransform({
      p: linePos,
      o: staticVal(40 - i * 10),
    }), 5 + i));
  }

  // Checkered flag at right
  const flagPole = shapeGroup('FlagPole', [
    rectShape(4, 60, 1),
    fillShape('#AAAAAA'),
  ]);
  const flagTop = shapeGroup('FlagTop', [
    rectShape(35, 25, 2),
    fillShape('#FFFFFF'),
    strokeShape('#000000', 2),
  ], { p: staticVal([18, -20]) });
  // Flag wave rotation
  const flagRot = animatedVal(kfMulti([
    [0, -5], [15, 5], [30, -5], [45, 5], [60, -5], [75, 5], [90, -5],
  ]));
  layers.push(shapeLayer('Flag', [flagPole, flagTop], makeTransform({
    p: staticVal([450, 250, 0]),
    r: flagRot,
  }), 8));

  return makeLottie(90, layers);
}

// ── 7. Vocabulary Chain ──────────────────────────────────────────────────────

function generateVocabularyChain() {
  const colors = ['#E74C3C', '#F1C40F', '#27AE60', '#3498DB', '#8E44AD'];
  const layers = [];

  // 5 chain links assembling
  for (let i = 0; i < 5; i++) {
    const staggerFrame = i * 15; // 0.5s apart at 30fps
    const targetX = 130 + i * 65;
    const targetY = 256;

    // Different entry directions
    const startPositions = [
      [targetX, 50], [512, targetY], [targetX, 462], [0, targetY], [targetX, 50],
    ];

    const posAnim = animatedVal(kfMulti([
      [0, [startPositions[i][0], startPositions[i][1], 0]],
      [staggerFrame, [startPositions[i][0], startPositions[i][1], 0]],
      [staggerFrame + 20, [targetX, targetY, 0]],
      [120, [targetX, targetY, 0]],
    ]));

    const opacityAnim = animatedVal(kfMulti([
      [0, 0], [staggerFrame, 0], [staggerFrame + 10, 100], [120, 100],
    ]));

    // Oval chain link (ellipse with stroke, no fill)
    const link = shapeGroup('Link' + i, [
      ellipseShape(55, 35),
      strokeShape(colors[i], 8),
      fillShape(colors[i], 0),
    ]);

    layers.push(shapeLayer('ChainLink_' + i, [link], makeTransform({
      p: posAnim,
      o: opacityAnim,
      r: staticVal(i % 2 === 0 ? 0 : 90),
    }), i + 1));
  }

  // Energy pulse circles at connection points (between links)
  for (let i = 0; i < 4; i++) {
    const cx = 130 + i * 65 + 32;
    const appearFrame = (i + 1) * 15 + 20;

    const pulseScale = animatedVal(kfMulti([
      [0, [0, 0, 100]],
      [appearFrame, [0, 0, 100]],
      [appearFrame + 5, [120, 120, 100]],
      [appearFrame + 15, [180, 180, 100]],
      [120, [180, 180, 100]],
    ]));
    const pulseOpacity = animatedVal(kfMulti([
      [0, 0], [appearFrame, 0], [appearFrame + 5, 80], [appearFrame + 15, 0], [120, 0],
    ]));

    const pulse = shapeGroup('Pulse' + i, [
      ellipseShape(20, 20),
      strokeShape('#FFFFFF', 3),
      fillShape('#FFFFFF', 0),
    ]);

    layers.push(shapeLayer('Pulse_' + i, [pulse], makeTransform({
      p: staticVal([cx, 256, 0]),
      s: pulseScale,
      o: pulseOpacity,
    }), 6 + i));
  }

  return makeLottie(120, layers);
}

// ── 8. Word Bomb ─────────────────────────────────────────────────────────────

function generateWordBomb() {
  const layers = [];

  // Bomb body - dark circle with rapid shake
  // 8-step shake pattern cycling every ~18 frames (0.6s)
  const shakeOffsets = [
    [256, 280], [260, 278], [252, 282], [258, 276],
    [254, 284], [262, 278], [250, 280], [258, 282],
  ];
  const shakeStops = [];
  for (let cycle = 0; cycle < 5; cycle++) {
    for (let s = 0; s < 8; s++) {
      const frame = cycle * 18 + s * 2.25;
      shakeStops.push([Math.round(frame), [shakeOffsets[s][0], shakeOffsets[s][1], 0]]);
    }
  }
  // Trim to 90 frames
  const trimmedShake = shakeStops.filter(s => s[0] <= 90);
  if (trimmedShake[trimmedShake.length - 1][0] < 90) {
    trimmedShake.push([90, [256, 280, 0]]);
  }

  const bombPos = animatedVal(kfMulti(trimmedShake));

  const bombBody = shapeGroup('BombBody', [
    ellipseShape(100, 100),
    fillShape('#1E1E2E'),
  ]);
  // Fuse nub
  const fuseNub = shapeGroup('FuseNub', [
    rectShape(12, 20, 3),
    fillShape('#555555'),
  ], { p: staticVal([0, -55]) });

  layers.push(shapeLayer('Bomb', [bombBody, fuseNub], makeTransform({
    p: bombPos,
  }), 1));

  // Flame on top - flicker opacity
  const flameFlicker = animatedVal(kfMulti([
    [0, 100], [5, 60], [10, 100], [15, 70], [20, 100], [25, 55],
    [30, 100], [35, 65], [40, 100], [45, 60], [50, 100], [55, 70],
    [60, 100], [65, 55], [70, 100], [75, 65], [80, 100], [85, 60], [90, 100],
  ]));
  const flameOuter = shapeGroup('FlameOuter', [
    ellipseShape(22, 35),
    fillShape('#FF6B00'),
  ], { p: staticVal([0, -8]) });
  const flameInner = shapeGroup('FlameInner', [
    ellipseShape(12, 20),
    fillShape('#FFF7AE'),
  ], { p: staticVal([0, -12]) });

  // Flame follows bomb shake
  layers.push(shapeLayer('Flame', [flameOuter, flameInner], makeTransform({
    p: animatedVal(kfMulti(trimmedShake.map(s => [s[0], [s[1][0], s[1][1] - 70, 0]]))),
    o: flameFlicker,
  }), 2));

  // 6 letter shapes flying outward
  const letterColors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#F7DC6F', '#DDA0DD', '#FFB347'];
  const flyAngles = [0, 60, 120, 180, 240, 300];
  for (let i = 0; i < 6; i++) {
    const stagger = i * 9; // 0.3s apart
    const angle = flyAngles[i] * Math.PI / 180;
    const endX = 256 + Math.cos(angle) * 220;
    const endY = 280 + Math.sin(angle) * 220;

    const letterPos = animatedVal(kfMulti([
      [0, [256, 280, 0]],
      [stagger, [256, 280, 0]],
      [stagger + 25, [endX, endY, 0]],
      [90, [endX, endY, 0]],
    ]));
    const letterRot = animatedVal(kfMulti([
      [0, 0], [stagger, 0], [stagger + 25, 360], [90, 360],
    ]));
    const letterOpacity = animatedVal(kfMulti([
      [0, 0], [stagger, 0], [stagger + 2, 100], [stagger + 20, 100], [stagger + 30, 0], [90, 0],
    ]));

    const letterShape = shapeGroup('Letter' + i, [
      rectShape(24, 28, 5),
      fillShape(letterColors[i]),
    ]);

    layers.push(shapeLayer('Letter_' + String.fromCharCode(65 + i), [letterShape], makeTransform({
      p: letterPos,
      r: letterRot,
      o: letterOpacity,
    }), 3 + i));
  }

  return makeLottie(90, layers);
}

// ── Main ─────────────────────────────────────────────────────────────────────

function main() {
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  const generators = {
    'categories.json': generateCategories,
    'grammar_duel.json': generateGrammarDuel,
    'language_snap.json': generateLanguageSnap,
    'language_tapples.json': generateLanguageTapples,
    'picture_guess.json': generatePictureGuess,
    'translation_race.json': generateTranslationRace,
    'vocabulary_chain.json': generateVocabularyChain,
    'word_bomb.json': generateWordBomb,
  };

  for (const [filename, generator] of Object.entries(generators)) {
    const lottie = generator();
    const filePath = path.join(OUTPUT_DIR, filename);
    const json = JSON.stringify(lottie);
    const sizeKB = (Buffer.byteLength(json, 'utf8') / 1024).toFixed(1);
    fs.writeFileSync(filePath, json, 'utf8');
    console.log(`  ${filename} (${sizeKB} KB)`);
  }

  console.log(`\nAll 8 Lottie files written to ${OUTPUT_DIR}`);
}

main();
