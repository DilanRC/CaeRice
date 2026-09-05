local home = assert(os.getenv("HOME"), "HOME is not set")
local hypr = home .. "/.config/hypr"

-- Cortetsu-owned Lua module root.
--   require("variables")       -> ~/.config/hypr/variables.lua
--   require("utils.functions") -> ~/.config/hypr/utils/functions.lua
--   require("scheme.current")  -> ~/.config/hypr/scheme/current.lua
--   require("hyprland.env")    -> ~/.config/hypr/hyprland/env.lua
local cortetsu_path = table.concat({
    hypr .. "/?.lua",
    hypr .. "/?/init.lua",
}, ";")

package.path = cortetsu_path .. ";" .. package.path

local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function maybe_copy(src, dst)
    if file_exists(dst) then
        return
    end

    local input = io.open(src, "r")
    if not input then
        return
    end

    local output = io.open(dst, "w")
    if output then
        output:write(input:read("*a"))
        output:close()
    end
    input:close()
end

-- Ensure a live scheme exists.
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

-- Required modules must fail loudly. Silently skipping one of these can
-- remove entire groups of Hyprland configuration/keybinds after reload.
local required_modules = {
    "hyprland.env",
    "hyprland.general",
    "hyprland.input",
    "hyprland.misc",
    "hyprland.animations",
    "hyprland.decoration",
    "hyprland.group",
    "hyprland.execs",
    "hyprland.rules",
    "hyprland.gestures",
    "hyprland.keybinds",
}

local failures = {}
for _, mod in ipairs(required_modules) do
    local ok, err = pcall(require, mod)
    if not ok then
        failures[#failures + 1] = mod .. ": " .. tostring(err)
    end
end

if #failures > 0 then
    error("[Cortetsu Hyprland] required module load failure:\n  " ..
          table.concat(failures, "\n  "))
end

-- Optional per-machine overrides. These are allowed to be absent, but if a
-- present file is broken we surface the error instead of swallowing it.
for _, name in ipairs({ "variables", "env", "general", "execs", "rules", "keybinds" }) do
    local path = hypr .. "/custom/" .. name .. ".lua"
    if file_exists(path) then
        local ok, err = pcall(dofile, path)
        if not ok then
            error("[Cortetsu Hyprland] custom/" .. name .. ".lua failed: " .. tostring(err))
        end
    end
end

-- Transitional user overrides.
-- Keep legacy hypr-user.lua usable without putting ~/.config/caelestia back
-- into package.path. This prevents legacy files from becoming a module root.
local cortetsu_user = hypr .. "/hypr-user.lua"
local legacy_user = home .. "/.config/caelestia/hypr-user.lua"

if file_exists(cortetsu_user) then
    local ok, err = pcall(dofile, cortetsu_user)
    if not ok then
        error("[Cortetsu Hyprland] hypr-user.lua failed: " .. tostring(err))
    end
elseif file_exists(legacy_user) then
    local ok, err = pcall(dofile, legacy_user)
    if not ok then
        error("[Cortetsu Hyprland] legacy hypr-user.lua failed: " .. tostring(err))
    end
end
