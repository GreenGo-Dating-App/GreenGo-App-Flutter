#!/usr/bin/env python3
"""Fail if the app repo exports a Cloud Function that the web repo owns.

Both GreenGo repos deploy Cloud Functions to the same project and codebase
("default"). A name exported by both means whichever repo deploys last wins,
silently replacing the other repo's code (P1-9). The web repo is not available
in CI, so the names it owns are listed in web_owned_functions.txt.

Usage:  python tools/security/check_function_ownership.py [index.ts] [owned.txt]
Exit:   0 = no collision, 1 = collision, 2 = parse/usage error.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DEFAULT_INDEX = ROOT / "functions" / "src" / "index.ts"
DEFAULT_OWNED = pathlib.Path(__file__).resolve().parent / "web_owned_functions.txt"

IDENT = r"[A-Za-z_$][\w$]*"


def strip_comments(src: str) -> str:
    """Remove // and /* */ comments, leaving string literals intact."""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c in "'\"`":
            j = i + 1
            while j < n and src[j] != c:
                j += 2 if src[j] == "\\" else 1
            out.append(src[i:j + 1])
            i = j + 1
        elif src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def exported_names(src: str) -> set:
    code = strip_comments(src)
    names = set()
    # export { a, b as c, default as d } [from '...'];
    for block in re.findall(r"\bexport\s+(?:type\s+)?\{([^}]*)\}", code):
        for part in block.split(","):
            part = part.strip()
            if not part:
                continue
            m = re.fullmatch(rf"(?:type\s+)?({IDENT})(?:\s+as\s+({IDENT}))?", part)
            if not m:
                raise ValueError(f"cannot parse export specifier: {part!r}")
            names.add(m.group(2) or m.group(1))
    # export const|let|var|function|async function|class NAME
    for m in re.finditer(
        rf"\bexport\s+(?:async\s+)?(?:const|let|var|function\*?|class)\s+({IDENT})", code
    ):
        names.add(m.group(1))
    # export * as ns from '...'
    for m in re.finditer(rf"\bexport\s+\*\s+as\s+({IDENT})", code):
        names.add(m.group(1))
    # A bare `export * from '...'` re-exports names we can't see without
    # resolving the module: refuse rather than silently pass.
    bare = re.findall(r"\bexport\s+\*\s+from\s+(['\"][^'\"]+['\"])", code)
    if bare:
        raise ValueError("bare `export * from` is not supported by this check "
                         f"(list the names explicitly): {', '.join(bare)}")
    return names


def owned_names(text: str) -> set:
    return {ln.split("#", 1)[0].strip() for ln in text.splitlines()} - {""}


def main(argv) -> int:
    index = pathlib.Path(argv[1]) if len(argv) > 1 else DEFAULT_INDEX
    owned_file = pathlib.Path(argv[2]) if len(argv) > 2 else DEFAULT_OWNED
    try:
        exported = exported_names(index.read_text(encoding="utf-8"))
        owned = owned_names(owned_file.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        print(f"::error::check_function_ownership: {e}")
        return 2
    if not owned:
        print("::error::web_owned_functions.txt is empty: the check would be meaningless")
        return 2
    if len(exported) < 50:
        # functions/src/index.ts exports ~300 names; a tiny count means the
        # parser broke, and a broken parser must not turn into a green check.
        print(f"::error::only {len(exported)} exports parsed from {index}: parser problem?")
        return 2
    clash = sorted(exported & owned)
    print(f"{len(exported)} functions exported by {index.name}; "
          f"{len(owned)} names owned by the web repo.")
    if clash:
        for name in clash:
            print(f"::error file=functions/src/index.ts::'{name}' is owned by the web repo "
                  "(greengo-app-flutter-web). Exporting it here would overwrite the live "
                  "version on the next app deploy. Comment it out, or move ownership "
                  "deliberately and update tools/security/web_owned_functions.txt.")
        return 1
    print("OK: no function-name collision with the web repo.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
