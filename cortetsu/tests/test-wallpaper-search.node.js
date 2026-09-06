#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const modulePath = path.join(__dirname, "..", "modules", "CortetsuWallpaperSearch.js");
const source = fs.readFileSync(modulePath, "utf8");
if (!source.startsWith(".pragma library\n"))
    throw new Error("CortetsuWallpaperSearch.js must start with .pragma library");

const context = {};
vm.createContext(context);
vm.runInContext(
    source.replace(/^\.pragma library\r?\n/, "") +
        "\nglobalThis.__EXPORTS__ = { fuzzyMatch, matches };",
    context,
    { filename: "CortetsuWallpaperSearch.js" }
);
const search = context.__EXPORTS__;

function check(label, actual, expected) {
    if (actual !== expected)
        throw new Error(`${label}: expected ${expected}, got ${actual}`);
}

check("fuzzy subsequence", search.fuzzyMatch("Sunset Mountains", "smt"), true);
check("fuzzy rejects missing character", search.fuzzyMatch("Sunset Mountains", "sz"), false);
check("fuzzy is case-insensitive", search.matches("Bosque_Nublado.webp", "bnw", true), true);
check("substring mode keeps exact contract", search.matches("Bosque_Nublado.webp", "nublado", false), true);
check("substring mode rejects non-contiguous query", search.matches("Bosque_Nublado.webp", "bnw", false), false);
check("empty query matches", search.matches("anything", "", true), true);

console.log("test-wallpaper-search.node: OK (exact and fuzzy wallpaper search contracts)");
