#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PALETTES = REPO / 'caelestia/schemes/palettes.json'
OUT = REPO / 'caelestia/schemes/cortetsu-pack'


def rgb(h: str):
    h = h.strip().lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def hx(values) -> str:
    return ''.join(f'{max(0, min(255, round(x))):02X}' for x in values)


def mix(a: str, b: str, t: float) -> str:
    aa, bb = rgb(a), rgb(b)
    return hx(tuple(aa[i] * (1 - t) + bb[i] * t for i in range(3)))


def render(p: dict[str, str]) -> str:
    bg, surface, fg, muted = p['bg'], p['surface'], p['fg'], p['muted']
    pri, sec, ter = p['primary'], p['secondary'], p['tertiary']
    red, green, yellow = p['red'], p['green'], p['yellow']
    blue, mag, cyan, orange = p['blue'], p['magenta'], p['cyan'], p['orange']
    sl, sc = mix(bg, surface, .45), mix(bg, surface, .72)
    sh, shi = mix(surface, fg, .10), mix(surface, fg, .16)
    sb, sd, slo = mix(surface, fg, .22), mix(bg, '000000', .12), mix(bg, '000000', .28)
    outline, outline_var = mix(muted, bg, .18), mix(surface, muted, .35)
    pc, sec_c, tc = mix(pri, bg, .62), mix(sec, bg, .62), mix(ter, bg, .62)
    ec, success_c = mix(red, bg, .62), mix(green, bg, .62)
    rows = [
        ('primary_paletteKeyColor', pri), ('secondary_paletteKeyColor', sec), ('tertiary_paletteKeyColor', ter),
        ('neutral_paletteKeyColor', surface), ('neutral_variant_paletteKeyColor', outline_var),
        ('background', bg), ('onBackground', fg), ('surface', surface), ('surfaceDim', sd), ('surfaceBright', sb),
        ('surfaceContainerLowest', slo), ('surfaceContainerLow', sl), ('surfaceContainer', sc), ('surfaceContainerHigh', sh),
        ('surfaceContainerHighest', shi), ('onSurface', fg), ('surfaceVariant', sc), ('onSurfaceVariant', muted),
        ('inverseSurface', fg), ('inverseOnSurface', bg), ('outline', outline), ('outlineVariant', outline_var), ('shadow', '000000'), ('scrim', '000000'), ('surfaceTint', pri),
        ('primary', pri), ('onPrimary', bg), ('primaryContainer', pc), ('onPrimaryContainer', fg), ('inversePrimary', mix(pri, fg, .25)),
        ('secondary', sec), ('onSecondary', bg), ('secondaryContainer', sec_c), ('onSecondaryContainer', fg),
        ('tertiary', ter), ('onTertiary', bg), ('tertiaryContainer', tc), ('onTertiaryContainer', fg),
        ('error', red), ('onError', bg), ('errorContainer', ec), ('onErrorContainer', fg),
        ('primaryFixed', mix(pri, fg, .26)), ('primaryFixedDim', mix(pri, bg, .18)), ('onPrimaryFixed', bg), ('onPrimaryFixedVariant', pc),
        ('secondaryFixed', mix(sec, fg, .26)), ('secondaryFixedDim', mix(sec, bg, .18)), ('onSecondaryFixed', bg), ('onSecondaryFixedVariant', sec_c),
        ('tertiaryFixed', mix(ter, fg, .26)), ('tertiaryFixedDim', mix(ter, bg, .18)), ('onTertiaryFixed', bg), ('onTertiaryFixedVariant', tc),
        ('term0', bg), ('term1', red), ('term2', green), ('term3', yellow), ('term4', blue), ('term5', mag), ('term6', cyan), ('term7', fg),
        ('term8', muted), ('term9', mix(red, fg, .16)), ('term10', mix(green, fg, .16)), ('term11', mix(yellow, fg, .16)),
        ('term12', mix(blue, fg, .16)), ('term13', mix(mag, fg, .16)), ('term14', mix(cyan, fg, .16)), ('term15', fg),
        ('rosewater', mix(fg, red, .14)), ('flamingo', mix(red, fg, .30)), ('pink', mag), ('mauve', ter), ('red', red),
        ('maroon', mix(red, yellow, .35)), ('peach', orange), ('yellow', yellow), ('green', green), ('teal', mix(green, cyan, .5)),
        ('sky', mix(cyan, fg, .15)), ('sapphire', cyan), ('blue', blue), ('lavender', mix(blue, fg, .28)),
        ('klink', blue), ('klinkSelection', mix(blue, fg, .12)), ('kvisited', ter), ('kvisitedSelection', mix(ter, fg, .12)),
        ('knegative', red), ('knegativeSelection', mix(red, fg, .12)), ('kneutral', yellow), ('kneutralSelection', mix(yellow, fg, .12)),
        ('kpositive', green), ('kpositiveSelection', mix(green, fg, .12)),
        ('text', fg), ('subtext1', muted), ('subtext0', mix(muted, bg, .12)), ('overlay2', mix(muted, bg, .22)),
        ('overlay1', mix(muted, bg, .34)), ('overlay0', mix(muted, bg, .46)), ('surface2', shi), ('surface1', sh),
        ('surface0', sc), ('base', bg), ('mantle', sd), ('crust', slo),
        ('success', green), ('onSuccess', bg), ('successContainer', success_c), ('onSuccessContainer', fg),
    ]
    return '\n'.join(f'{k} {v}' for k, v in rows) + '\n'


def main() -> None:
    palettes = json.loads(PALETTES.read_text(encoding='utf-8'))
    for key, palette in palettes.items():
        family, flavour = key.split('/', 1)
        path = OUT / family / flavour / 'dark.txt'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(render(palette), encoding='utf-8')
        print(path.relative_to(REPO))


if __name__ == '__main__':
    main()
