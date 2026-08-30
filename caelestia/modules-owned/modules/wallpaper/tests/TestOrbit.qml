import QtQuick
import QtTest
import "../OrbitModel.js" as Orbit

TestCase {
    name: "OrbitModel"
    function paths(count) {
        const result = [];
        for (let i = 0; i < count; ++i)
            result.push({path: `/walls/cat/${i}.webp`});
        return result;
    }
    function test_bounded_windows_data() {
        return [
            {tag: "empty", count: 0, expected: 0}, {tag: "one", count: 1, expected: 1},
            {tag: "two", count: 2, expected: 2}, {tag: "twelve", count: 12, expected: 12},
            {tag: "thirteen", count: 13, expected: 12}, {tag: "hundreds", count: 300, expected: 12}
        ];
    }
    function test_bounded_windows(data) { compare(Orbit.visible(paths(data.count), 0, 12).length, data.expected); }
    function test_wrap_and_unicode() {
        compare(Orbit.move(0, -1, 13), 12);
        compare(Orbit.move(12, 1, 13), 0);
        const entries = [{path: "/walls/日本/星 空.webp"}, {path: "/walls/night/luna.png"}];
        compare(Orbit.filtered(entries, "日本", entry => entry.path.split("/")[2])[0].path, "/walls/日本/星 空.webp");
    }
    function test_rotation_contract() {
        compare(Orbit.angularStep(12), Math.PI / 6);
        compare(Orbit.shortestSteps(0, 12, 13), -1);
        compare(Orbit.shortestSteps(0, 7, 12), -5);
        compare(Orbit.satelliteTarget(6, 0, 12, 20), 0);
        verify(Orbit.satelliteAngle(0, 12, 0) !== Orbit.satelliteAngle(0, 12, -Orbit.angularStep(12)));
    }
    function test_categories() {
        const entries = [{kind: "fog"}, {kind: "night"}, {kind: "fog"}];
        compare(Orbit.categories(entries, entry => entry.kind).join(","), "ALL,fog,night");
    }
}
