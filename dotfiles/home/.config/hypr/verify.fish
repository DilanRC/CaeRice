#!/usr/bin/env fish
set -l root "$HOME/.config/hypr"

set -l required \
    hyprland.lua \
    variables.lua \
    utils/functions.lua \
    utils/json.lua \
    scheme/current.lua \
    scheme/default.lua \
    hyprland/env.lua \
    hyprland/general.lua \
    hyprland/input.lua \
    hyprland/misc.lua \
    hyprland/animations.lua \
    hyprland/decoration.lua \
    hyprland/group.lua \
    hyprland/execs.lua \
    hyprland/rules.lua \
    hyprland/gestures.lua \
    hyprland/keybinds.lua

set -l failed 0
for f in $required
    if not test -f "$root/$f"
        echo "ERROR missing: $root/$f"
        set failed 1
    else
        echo "PASS  $f"
    end
end

if rg -n '\.config/caelestia/\?\.lua|package\.path.*caelestia' "$root/hyprland.lua" >/dev/null
    echo "ERROR hyprland.lua still uses Caelestia as a Lua module root"
    set failed 1
else
    echo "PASS  no Caelestia Lua module root in hyprland.lua"
end

for mod in variables utils.functions utils.json scheme.current
    set -l pat (string escape --style=regex "require(\"$mod\")")
    if rg -q "$pat" "$root"
        echo "PASS  dependency referenced: $mod"
    end
end

if test $failed -ne 0
    echo
    echo "VERIFY: ERROR"
    exit 1
end

echo
echo "VERIFY: PASS"
echo "Next:"
echo "  hyprctl reload"
echo "  hyprctl configerrors"
echo "  hyprctl binds -j | jq 'length'"
