.pragma library

function normalise(value) {
    return String(value ?? "").toLowerCase();
}

function fuzzyMatch(value, needle) {
    const haystack = normalise(value);
    const query = normalise(needle).trim();
    if (!query)
        return true;

    let offset = 0;
    for (const character of query) {
        offset = haystack.indexOf(character, offset);
        if (offset < 0)
            return false;
        offset += character.length;
    }
    return true;
}

function matches(value, needle, fuzzy) {
    const haystack = normalise(value);
    const query = normalise(needle).trim();
    return !query || (fuzzy ? fuzzyMatch(haystack, query) : haystack.includes(query));
}
