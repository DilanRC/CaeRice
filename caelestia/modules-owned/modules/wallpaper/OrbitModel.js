.pragma library

function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value));
}

function categories(entries, categoryFor) {
    const values = ["ALL"];
    const seen = {};
    for (let i = 0; i < entries.length; ++i) {
        const category = categoryFor(entries[i]);
        if (category && !seen[category]) {
            seen[category] = true;
            values.push(category);
        }
    }
    return values;
}

function filtered(entries, category, categoryFor) {
    if (category === "ALL")
        return entries.slice();
    return entries.filter(entry => categoryFor(entry) === category);
}

function normalize(index, count) {
    if (count <= 0)
        return -1;
    return ((index % count) + count) % count;
}

function visible(entries, currentIndex, maximum) {
    const count = entries.length;
    if (count === 0)
        return [];
    const size = clamp(Math.floor(maximum), 1, Math.min(12, count));
    const start = normalize(currentIndex - Math.floor(size / 2), count);
    const result = [];
    for (let i = 0; i < size; ++i)
        result.push(entries[(start + i) % count]);
    return result;
}

function prefetch(entries, currentIndex, maximum) {
    const count = entries.length;
    if (count === 0)
        return [];
    const size = clamp(Math.floor(maximum), 1, Math.min(18, count));
    const start = normalize(currentIndex - Math.floor(size / 2), count);
    const result = [];
    for (let i = 0; i < size; ++i)
        result.push(entries[(start + i) % count]);
    return result;
}

function basename(path) {
    const slash = path.lastIndexOf("/");
    return slash >= 0 ? path.slice(slash + 1) : path;
}

function resolveCurrentIndex(entries, actualPath) {
    for (let i = 0; i < entries.length; ++i) {
        if (entries[i].path === actualPath)
            return i;
    }
    const name = basename(actualPath || "");
    if (!name)
        return -1;
    let match = -1;
    for (let i = 0; i < entries.length; ++i) {
        if (basename(entries[i].path) !== name)
            continue;
        if (match >= 0)
            return -1;
        match = i;
    }
    return match;
}

function satellites(entries, anchorIndex, selectedIndex, maximum) {
    const count = entries.length;
    if (count < 2 || selectedIndex < 0)
        return [];
    const windowSize = clamp(Math.floor(maximum), 1, Math.min(12, count));
    const start = normalize(anchorIndex - Math.floor(windowSize / 2), count);
    const result = [];
    for (let i = 0; i < windowSize; ++i) {
        const index = (start + i) % count;
        if (index !== selectedIndex)
            result.push({ entry: entries[index], index: index });
    }
    return result;
}

function move(index, direction, count) {
    return normalize(index + direction, count);
}

function angularStep(count) {
    return count > 0 ? Math.PI * 2 / count : 0;
}

function satelliteAngle(index, count, phase) {
    return index * angularStep(count) - Math.PI / 2 + phase;
}

function shortestSteps(from, to, count) {
    if (count <= 1)
        return 0;
    const forward = normalize(to - from, count);
    return forward > count / 2 ? forward - count : forward;
}

function satelliteTarget(center, slot, visibleCount, totalCount) {
    return normalize(center + slot - Math.floor(visibleCount / 2), totalCount);
}

function wheelIntent(accumulator, angleDelta, pixelDelta) {
    const delta = pixelDelta !== 0 ? pixelDelta : angleDelta;
    const threshold = pixelDelta !== 0 ? 40 : 120;
    const total = accumulator && delta && Math.sign(accumulator) !== Math.sign(delta)
        ? delta : accumulator + delta;
    if (!delta || Math.abs(total) < threshold)
        return { accumulator: total, direction: 0 };
    return {
        accumulator: Math.sign(total) * (Math.abs(total) % threshold),
        direction: total > 0 ? -1 : 1
    };
}

function previewEligible(pendingPath, currentPath, managerOpen, animating, queuedDirection) {
    return managerOpen && !animating && !queuedDirection && !!pendingPath && pendingPath === currentPath;
}
