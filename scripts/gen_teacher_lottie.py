"""Generate 6 consistent teacher character Lottie JSON files.
Same character body across all emotions, only face/arms/extras change."""

import json, os

W, H = 512, 512
FPS = 30
FRAMES = 90  # 3 seconds

# Consistent color palette
SKIN = [0.96, 0.82, 0.71]
HAIR = [0.25, 0.15, 0.1]
SHIRT = [0.2, 0.45, 0.75]
PANTS = [0.22, 0.22, 0.28]
SHOES = [0.18, 0.15, 0.13]
WHITE = [1, 1, 1]
BLACK = [0, 0, 0]


def rgb(r, g, b):
    return {"a": 0, "k": [r, g, b, 1]}

def pos(x, y):
    return {"a": 0, "k": [x, y]}

def sz(w, h):
    return {"a": 0, "k": [w, h]}

def sc(v):
    return {"a": 0, "k": v}

def anim_pos(kfs):
    if len(kfs) == 1:
        return {"a": 0, "k": kfs[0][1]}
    out = []
    for i, (f, v) in enumerate(kfs):
        kf = {"t": f, "s": v}
        if i < len(kfs) - 1:
            kf["i"] = {"x": [0.4], "y": [1]}
            kf["o"] = {"x": [0.6], "y": [0]}
        out.append(kf)
    return {"a": 1, "k": out}

def anim_sc(kfs):
    if len(kfs) == 1:
        return {"a": 0, "k": kfs[0][1]}
    out = []
    for i, (f, v) in enumerate(kfs):
        kf = {"t": f, "s": [v]}
        if i < len(kfs) - 1:
            kf["i"] = {"x": [0.4], "y": [1]}
            kf["o"] = {"x": [0.6], "y": [0]}
        out.append(kf)
    return {"a": 1, "k": out}

def ellipse(name, cx, cy, rx, ry, fill, stroke=None, sw=0):
    items = [
        {"ty": "el", "p": pos(cx, cy), "s": sz(rx*2, ry*2), "d": 1, "nm": "p"},
        {"ty": "fl", "c": rgb(*fill), "o": sc(100), "r": 1, "nm": "f"},
    ]
    if stroke:
        items.insert(1, {"ty": "st", "c": rgb(*stroke), "o": sc(100), "w": sc(sw), "lc": 2, "lj": 2, "nm": "s"})
    return {
        "ty": 4, "nm": name, "sr": 1,
        "ks": {"o": sc(100), "r": sc(0), "p": pos(0, 0), "a": pos(0, 0), "s": sz(100, 100)},
        "shapes": items, "ip": 0, "op": FRAMES, "st": 0
    }

def rect(name, cx, cy, w, h, fill, rx=0):
    items = [
        {"ty": "rc", "p": pos(cx, cy), "s": sz(w, h), "r": sc(rx), "d": 1, "nm": "p"},
        {"ty": "fl", "c": rgb(*fill), "o": sc(100), "r": 1, "nm": "f"},
    ]
    return {
        "ty": 4, "nm": name, "sr": 1,
        "ks": {"o": sc(100), "r": sc(0), "p": pos(0, 0), "a": pos(0, 0), "s": sz(100, 100)},
        "shapes": items, "ip": 0, "op": FRAMES, "st": 0
    }


def body_layers():
    return [
        ellipse("l_shoe", 230, 440, 22, 10, SHOES),
        ellipse("r_shoe", 282, 440, 22, 10, SHOES),
        rect("l_leg", 235, 400, 26, 65, PANTS, 8),
        rect("r_leg", 277, 400, 26, 65, PANTS, 8),
        rect("torso", 256, 320, 80, 100, SHIRT, 16),
        rect("neck", 256, 262, 24, 20, SKIN, 8),
    ]


def head_layers():
    return [
        ellipse("head", 256, 220, 52, 58, SKIN),
        ellipse("hair_top", 256, 188, 56, 38, HAIR),
        rect("hair_l", 206, 215, 12, 45, HAIR, 6),
        rect("hair_r", 306, 215, 12, 45, HAIR, 6),
        # Ears
        ellipse("ear_l", 205, 222, 8, 10, SKIN),
        ellipse("ear_r", 307, 222, 8, 10, SKIN),
        # Nose
        ellipse("nose", 256, 230, 4, 5, [0.9, 0.75, 0.65]),
        # Cheek blush (subtle)
        ellipse("blush_l", 235, 232, 8, 5, [1, 0.7, 0.7]),
        ellipse("blush_r", 277, 232, 8, 5, [1, 0.7, 0.7]),
    ]


def eyes(emo):
    layers = []
    if emo == "celebrating":
        # Happy squint arcs
        layers.append(ellipse("l_eye", 240, 218, 10, 3, BLACK))
        layers.append(ellipse("r_eye", 272, 218, 10, 3, BLACK))
    elif emo == "wrong":
        layers.append(ellipse("l_eye_w", 240, 218, 8, 10, WHITE, BLACK, 2))
        layers.append(ellipse("l_pup", 240, 220, 4, 5, BLACK))
        layers.append(ellipse("r_eye_w", 272, 218, 8, 10, WHITE, BLACK, 2))
        layers.append(ellipse("r_pup", 272, 220, 4, 5, BLACK))
        # Sad eyebrows
        l_brow = rect("l_brow", 240, 205, 18, 3, HAIR, 2)
        l_brow["ks"]["r"] = sc(8)
        layers.append(l_brow)
        r_brow = rect("r_brow", 272, 205, 18, 3, HAIR, 2)
        r_brow["ks"]["r"] = sc(-8)
        layers.append(r_brow)
    elif emo == "thinking":
        layers.append(ellipse("l_eye_w", 240, 216, 7, 8, WHITE, BLACK, 2))
        layers.append(ellipse("l_pup", 242, 213, 3, 4, BLACK))
        layers.append(ellipse("r_eye_w", 272, 216, 7, 8, WHITE, BLACK, 2))
        layers.append(ellipse("r_pup", 274, 213, 3, 4, BLACK))
        # Raised eyebrow
        r_brow = rect("r_brow", 272, 204, 18, 3, HAIR, 2)
        r_brow["ks"]["r"] = sc(-5)
        r_brow["ks"]["p"] = anim_pos([(0, [0, 0]), (30, [0, -2]), (60, [0, 0]), (FRAMES, [0, -2])])
        layers.append(r_brow)
    elif emo == "speaking":
        # Normal eyes with blink
        layers.append(ellipse("l_eye_w", 240, 218, 7, 8, WHITE, BLACK, 2))
        layers.append(ellipse("l_pup", 240, 219, 3, 4, BLACK))
        layers.append(ellipse("r_eye_w", 272, 218, 7, 8, WHITE, BLACK, 2))
        layers.append(ellipse("r_pup", 272, 219, 3, 4, BLACK))
        # Blink overlay
        blink = ellipse("blink", 256, 218, 40, 10, SKIN)
        blink["ks"]["o"] = anim_sc([(0, 0), (58, 0), (60, 100), (63, 0), (FRAMES, 0)])
        layers.append(blink)
    else:
        # Friendly open eyes
        layers.append(ellipse("l_eye_w", 240, 218, 7, 8, WHITE, BLACK, 2))
        layers.append(ellipse("l_pup", 240, 219, 3, 4, BLACK))
        layers.append(ellipse("r_eye_w", 272, 218, 7, 8, WHITE, BLACK, 2))
        layers.append(ellipse("r_pup", 272, 219, 3, 4, BLACK))
    return layers


def mouth(emo):
    if emo in ("correct", "celebrating"):
        return [ellipse("mouth", 256, 240, 16, 10, [0.85, 0.3, 0.3])]
    elif emo == "wrong":
        return [ellipse("mouth", 256, 243, 10, 4, [0.75, 0.35, 0.35])]
    elif emo == "speaking":
        m = ellipse("mouth", 256, 240, 10, 8, [0.8, 0.3, 0.3])
        m["ks"]["s"] = anim_pos([(0, [100, 100]), (10, [100, 60]), (20, [100, 110]),
                                  (30, [100, 50]), (40, [100, 100]), (50, [100, 60]),
                                  (60, [100, 110]), (70, [100, 50]), (80, [100, 100]), (FRAMES, [100, 80])])
        return [m]
    elif emo == "thinking":
        return [ellipse("mouth", 260, 240, 6, 6, [0.75, 0.35, 0.35])]
    else:
        return [ellipse("mouth", 256, 238, 14, 6, [0.85, 0.3, 0.3])]


def arms(emo):
    layers = []
    if emo == "greeting":
        # Waving right arm
        ra = rect("r_arm", 320, 280, 22, 70, SHIRT, 8)
        ra["ks"]["r"] = anim_sc([(0, -30), (15, -50), (30, -30), (45, -50), (60, -30), (75, -50), (FRAMES, -30)])
        layers.append(ra)
        rh = ellipse("r_hand", 335, 246, 14, 14, SKIN)
        rh["ks"]["p"] = anim_pos([(0, [0, 0]), (15, [5, -8]), (30, [0, 0]), (45, [5, -8]), (60, [0, 0]), (75, [5, -8]), (FRAMES, [0, 0])])
        layers.append(rh)
        layers.append(rect("l_arm", 192, 320, 22, 65, SHIRT, 8))
        layers.append(ellipse("l_hand", 192, 355, 14, 14, SKIN))
    elif emo == "correct":
        ra = rect("r_arm", 316, 290, 22, 60, SHIRT, 8)
        ra["ks"]["r"] = sc(-25)
        layers.append(ra)
        layers.append(ellipse("r_hand", 330, 258, 14, 14, SKIN))
        # Thumbs up indicator
        layers.append(ellipse("thumb", 332, 248, 5, 8, SKIN))
        layers.append(rect("l_arm", 196, 318, 22, 60, SHIRT, 8))
        layers.append(ellipse("l_hand", 196, 350, 14, 14, SKIN))
    elif emo == "wrong":
        la = rect("l_arm", 190, 305, 22, 60, SHIRT, 8)
        la["ks"]["r"] = sc(8)
        layers.append(la)
        layers.append(ellipse("l_hand", 182, 338, 14, 14, SKIN))
        ra = rect("r_arm", 322, 305, 22, 60, SHIRT, 8)
        ra["ks"]["r"] = sc(-8)
        layers.append(ra)
        layers.append(ellipse("r_hand", 330, 338, 14, 14, SKIN))
    elif emo == "thinking":
        ra = rect("r_arm", 300, 268, 22, 55, SHIRT, 8)
        ra["ks"]["r"] = sc(-50)
        layers.append(ra)
        layers.append(ellipse("r_hand", 275, 244, 14, 14, SKIN))
        layers.append(rect("l_arm", 196, 320, 22, 65, SHIRT, 8))
        layers.append(ellipse("l_hand", 196, 355, 14, 14, SKIN))
    elif emo == "celebrating":
        la = rect("l_arm", 190, 270, 22, 68, SHIRT, 8)
        la["ks"]["r"] = anim_sc([(0, 30), (15, 38), (30, 25), (45, 38), (60, 25), (75, 38), (FRAMES, 30)])
        layers.append(la)
        lh = ellipse("l_hand", 178, 240, 14, 14, SKIN)
        lh["ks"]["p"] = anim_pos([(0, [0, 0]), (15, [-3, -5]), (30, [0, 0]), (45, [-3, -5]), (60, [0, 0]), (75, [-3, -5]), (FRAMES, [0, 0])])
        layers.append(lh)
        ra = rect("r_arm", 322, 270, 22, 68, SHIRT, 8)
        ra["ks"]["r"] = anim_sc([(0, -30), (15, -38), (30, -25), (45, -38), (60, -25), (75, -38), (FRAMES, -30)])
        layers.append(ra)
        rh = ellipse("r_hand", 334, 240, 14, 14, SKIN)
        rh["ks"]["p"] = anim_pos([(0, [0, 0]), (15, [3, -5]), (30, [0, 0]), (45, [3, -5]), (60, [0, 0]), (75, [3, -5]), (FRAMES, [0, 0])])
        layers.append(rh)
    elif emo == "speaking":
        ra = rect("r_arm", 318, 290, 22, 60, SHIRT, 8)
        ra["ks"]["r"] = anim_sc([(0, -15), (22, -28), (45, -15), (67, -28), (FRAMES, -15)])
        layers.append(ra)
        rh = ellipse("r_hand", 328, 262, 14, 14, SKIN)
        rh["ks"]["p"] = anim_pos([(0, [0, 0]), (22, [3, -5]), (45, [0, 0]), (67, [3, -5]), (FRAMES, [0, 0])])
        layers.append(rh)
        layers.append(rect("l_arm", 196, 318, 22, 60, SHIRT, 8))
        layers.append(ellipse("l_hand", 196, 350, 14, 14, SKIN))
    return layers


def extras(emo):
    layers = []
    if emo == "correct":
        s1 = ellipse("spark1", 310, 178, 6, 6, [1, 0.85, 0.2])
        s1["ks"]["o"] = anim_sc([(0, 0), (10, 100), (30, 100), (45, 0), (60, 0), (70, 100), (FRAMES, 0)])
        layers.append(s1)
        s2 = ellipse("spark2", 198, 185, 4, 4, [1, 0.85, 0.2])
        s2["ks"]["o"] = anim_sc([(0, 0), (20, 0), (30, 100), (50, 100), (65, 0), (FRAMES, 0)])
        layers.append(s2)
    elif emo == "celebrating":
        colors = [[1, 0.3, 0.3], [0.3, 0.85, 0.3], [0.3, 0.4, 1], [1, 0.8, 0.2], [1, 0.5, 0.8],
                  [0.4, 0.9, 0.9], [0.9, 0.5, 0.2]]
        for i, c in enumerate(colors):
            x = 140 + i * 40
            y0 = 100 + (i % 3) * 15
            d = ellipse("conf_%d" % i, x, y0, 5, 5, c)
            d["ks"]["p"] = anim_pos([(0, [x, y0]), (FRAMES, [x + (i % 2 * 30 - 15), y0 + 60])])
            d["ks"]["o"] = anim_sc([(0, 100), (65, 100), (FRAMES, 0)])
            d["ks"]["r"] = anim_sc([(0, 0), (FRAMES, 360 if i % 2 == 0 else -360)])
            layers.append(d)
    elif emo == "thinking":
        for i, (bx, by, br) in enumerate([(298, 200, 5), (310, 182, 7), (324, 162, 10)]):
            b = ellipse("thought_%d" % i, bx, by, br, br, WHITE, [0.7, 0.7, 0.7], 1.5)
            b["ks"]["o"] = anim_sc([(0, 0), (10 + i * 12, 0), (22 + i * 12, 85), (FRAMES, 85)])
            layers.append(b)
    elif emo == "wrong":
        d = ellipse("sweat", 302, 200, 4, 6, [0.6, 0.85, 1])
        d["ks"]["p"] = anim_pos([(0, [302, 200]), (30, [303, 212]), (60, [302, 200]), (FRAMES, [303, 212])])
        layers.append(d)
    return layers


def idle_bounce(layers):
    """Subtle idle breathing/bounce on key body parts."""
    bounce_parts = {"head", "hair_top", "hair_l", "hair_r", "ear_l", "ear_r",
                    "nose", "blush_l", "blush_r", "neck"}
    for layer in layers:
        nm = layer.get("nm", "")
        if nm in bounce_parts:
            p = layer["ks"]["p"]
            if p.get("a", 0) == 0:
                bx, by = p["k"]
                layer["ks"]["p"] = anim_pos([
                    (0, [bx, by]), (22, [bx, by - 1.5]),
                    (45, [bx, by]), (67, [bx, by - 1.5]),
                    (FRAMES, [bx, by])
                ])


def generate(emo):
    all_layers = []
    all_layers.extend(extras(emo))
    all_layers.extend(eyes(emo))
    all_layers.extend(mouth(emo))
    all_layers.extend(head_layers())
    all_layers.extend(arms(emo))
    all_layers.extend(body_layers())
    all_layers.reverse()  # render body first, extras on top
    idle_bounce(all_layers)

    return {
        "v": "5.7.4", "fr": FPS, "ip": 0, "op": FRAMES,
        "w": W, "h": H, "nm": "teacher_%s" % emo, "ddd": 0,
        "assets": [], "layers": all_layers,
    }


if __name__ == "__main__":
    outdir = os.path.join(os.path.dirname(__file__), "..", "assets", "lottie", "teacher")
    os.makedirs(outdir, exist_ok=True)
    for emo in ["greeting", "correct", "wrong", "thinking", "celebrating", "speaking"]:
        data = generate(emo)
        fpath = os.path.join(outdir, "teacher_%s.json" % emo)
        with open(fpath, "w") as f:
            json.dump(data, f, separators=(",", ":"))
        kb = os.path.getsize(fpath) / 1024
        print("%s: %d layers, %.1f KB" % (emo, len(data["layers"]), kb))
    print("\nAll 6 consistent teacher animations generated!")
