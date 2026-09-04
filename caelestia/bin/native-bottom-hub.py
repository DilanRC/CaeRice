#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

DESIGN_IMPORT = 'import "CortetsuDesign.js" as CortetsuDesign'
SEGMENT_IDS = ("leftSegment", "appSegment", "traySegment", "statusSegment")

COLOUR_REPLACEMENTS = {
    "Colours.palette.m3secondaryContainer": "CortetsuDesign.colorIndigo",
    "Colours.palette.m3surfaceContainerHighest": "Qt.lighter(CortetsuDesign.colorTetsu, 1.16)",
    "Colours.palette.m3tertiary": "CortetsuDesign.colorMuted",
    "Colours.palette.m3primary": "CortetsuDesign.colorIndigo",
    "Colours.palette.m3secondary": "CortetsuDesign.colorMuted",
    "Colours.palette.m3outlineVariant": "Qt.darker(CortetsuDesign.colorMuted, 1.35)",
    "Colours.palette.m3onSurfaceVariant": "CortetsuDesign.colorMuted",
    "Colours.palette.m3errorContainer": "CortetsuDesign.colorVermillion",
    "Colours.palette.m3onErrorContainer": "CortetsuDesign.colorWashi",
    "Colours.palette.m3error": "CortetsuDesign.colorVermillion",
    "Colours.palette.m3onPrimary": "CortetsuDesign.colorWashi",
    "Colours.palette.m3onSurface": "CortetsuDesign.colorWashi",
    "Colours.tPalette.m3surfaceContainer": "CortetsuDesign.colorTetsu",
}

SEGMENT_STYLE_OLD = """                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer"""
SEGMENT_STYLE_NEW = """                        radiusValue: CortetsuDesign.radiusLarge
                        baseColor: CortetsuDesign.colorTetsu
                        outlined: true"""

WORKSPACE_PATTERN = re.compile(
    r"(?ms)^                            Row \{\n"
    r"                                id: workspaceDots\n"
    r".*?"
    r"^                                Item \{\n"
    r"                                    width: 7\n"
    r"                                    height: 1\n"
    r"                                \}\n"
    r"^                            \}"
)
WORKSPACE_COMPONENT = """                            CortetsuWorkspaceDots {
                                id: workspaceDots
                                anchors.verticalCenter: parent.verticalCenter
                                workspaceCount: win.workspaceCount
                                workspaceOffset: win.workspaceOffset
                                activeWsId: win.activeWsId
                            }"""


def fail(message: str) -> None:
    raise RuntimeError(message)


def validate(text: str) -> None:
    if DESIGN_IMPORT not in text:
        fail("BottomHub final no importa CortetsuDesign")
    if "Colours." in text:
        fail("BottomHub final todavía contiene Colours.*")
    if "m3surface" in text or "m3primary" in text or "m3secondary" in text:
        fail("BottomHub final todavía contiene nombres de paleta Material 3")
    if "appMouse.containsMouse ? 1.10 : 1" in text:
        fail("BottomHub final conserva hover 1.10 heredado")
    if "duration: 110" in text or "duration: 150" in text:
        fail("BottomHub final conserva motion hardcoded heredado")
    if "CortetsuDesign.hoverScale" not in text:
        fail("BottomHub final no usa hoverScale Cortetsu")
    if text.count("CortetsuSurface {") < 4:
        fail("BottomHub final no usa CortetsuSurface para los cuatro segmentos")
    if text.count("CortetsuWorkspaceDots {") != 1:
        fail("BottomHub final no delega workspaces al componente Cortetsu first-party")
    if "id: workspaceDot\n" in text:
        fail("BottomHub final todavía contiene el delegate visual de workspaces inline")

    for segment_id in SEGMENT_IDS:
        marker = f"id: {segment_id}"
        if marker not in text:
            fail(f"BottomHub final perdió {segment_id}")

    # Functional fingerprints: the visual compiler must never rewrite controllers.
    for fingerprint in (
        "function activateItem(item): void",
        "function cycleItem(item, direction): void",
        "SystemTray.items.values.filter(",
        "hubRoot.toggleLauncherFor(win.modelData)",
        "hubRoot.toggleSidebarFor(win.modelData)",
        "Hypr.dispatch(",
    ):
        if fingerprint not in text:
            fail(f"BottomHub final perdió controlador: {fingerprint}")


def extract_workspace_component(text: str) -> str:
    rendered, count = WORKSPACE_PATTERN.subn(WORKSPACE_COMPONENT, text, count=1)
    if count != 1:
        fail(f"se esperaba extraer 1 bloque workspaceDots; encontrados {count}")
    return rendered


def transform(text: str) -> str:
    try:
        validate(text)
    except RuntimeError:
        pass
    else:
        return text

    if DESIGN_IMPORT not in text:
        anchor = "import qs.modules.launcher.services\n"
        if text.count(anchor) != 1:
            fail("no se pudo ubicar el punto de import de BottomHub")
        text = text.replace(anchor, anchor + DESIGN_IMPORT + "\n", 1)

    if "CortetsuWorkspaceDots {" not in text:
        text = extract_workspace_component(text)

    style_count = text.count(SEGMENT_STYLE_OLD)
    if style_count != 4:
        fail(f"se esperaban 4 superficies Material del hub; encontradas {style_count}")
    text = text.replace(SEGMENT_STYLE_OLD, SEGMENT_STYLE_NEW)

    for segment_id in SEGMENT_IDS:
        old = f"                    StyledRect {{\n                        id: {segment_id}\n"
        new = f"                    CortetsuSurface {{\n                        id: {segment_id}\n"
        if text.count(old) != 1:
            fail(f"no se pudo migrar la superficie {segment_id}")
        text = text.replace(old, new, 1)

    for old, new in COLOUR_REPLACEMENTS.items():
        text = text.replace(old, new)

    text = text.replace(
        "scale: appMouse.containsMouse ? 1.10 : 1",
        "scale: appMouse.containsMouse ? CortetsuDesign.hoverScale : 1",
    )
    text = text.replace("duration: 110", "duration: CortetsuDesign.motionFastMs")
    text = text.replace("duration: 150", "duration: CortetsuDesign.motionStandardMs")

    validate(text)
    return text


def write_atomic(path: Path, text: str) -> None:
    temp = path.with_name(path.name + f".tmp.{os.getpid()}")
    temp.write_text(text, encoding="utf-8")
    os.replace(temp, path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Compile BottomHub presentation into Cortetsu first-party visual components and tokens")
    parser.add_argument("path", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    try:
        source = args.path.read_text(encoding="utf-8")
        if args.check:
            validate(source)
            print(f"PASS: native Bottom Hub component contract: {args.path}")
            return 0

        rendered = transform(source)
        if rendered == source:
            print(f"Cortetsu Bottom Hub visuals: already native: {args.path}")
            return 0
        write_atomic(args.path, rendered)
        print(f"Cortetsu Bottom Hub visuals: compiled with first-party components: {args.path}")
        return 0
    except (OSError, RuntimeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
