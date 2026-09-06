pragma Singleton

import QtQuick

QtObject {
    function formatKib(value: real, total: real): var {
        const units = ["KiB", "MiB", "GiB", "TiB"];
        let amount = Math.max(0, value);
        let capacity = Math.max(0, total);
        let index = 0;
        while (amount >= 1024 && index < units.length - 1) {
            amount /= 1024;
            capacity /= 1024;
            index++;
        }
        return { value: amount, total: capacity, unit: units[index] };
    }
}
