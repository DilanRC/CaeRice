import QtQml
import Quickshell.Io

QtObject {
    id: root

    property string path: ""
    property list<string> nameFilters: []
    property bool sortReverse: false
    property int generation: 0
    property ListModel entries: ListModel {}
    readonly property int count: entries.count

    function get(index: int): var {
        return entries.get(index);
    }

    function matches(name: string): bool {
        if (root.nameFilters.length === 0 || root.nameFilters.includes("*"))
            return true;
        return root.nameFilters.some(filter => {
            const escaped = String(filter).replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".");
            return new RegExp(`^${escaped}$`, "i").test(name);
        });
    }

    function reload(): void {
        root.generation += 1;
        scan.generation = root.generation;
        scan.command = ["sh", "-c", `find -- \"$1\" -mindepth 1 -maxdepth 1 -printf '%y\\t%p\\n' 2>/dev/null`, "cortetsu", root.path];
        scan.running = root.path.length > 0;
    }

    onPathChanged: reload()
    onNameFiltersChanged: reload()
    onSortReverseChanged: reload()

    property Process scan: Process {
        id: scanProcess

        property int generation: 0

        stdout: StdioCollector {
            onStreamFinished: {
                if (scanProcess.generation !== root.generation)
                    return;

                const results = text.split("\n").filter(Boolean).map(line => {
                    const tab = line.indexOf("\t");
                    const kind = tab >= 0 ? line.slice(0, tab) : "f";
                    const filePath = tab >= 0 ? line.slice(tab + 1) : line;
                    const slash = filePath.lastIndexOf("/");
                    const name = slash >= 0 ? filePath.slice(slash + 1) : filePath;
                    const dot = name.lastIndexOf(".");
                    const suffix = dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
                    return {
                        path: filePath,
                        name,
                        baseName: dot > 0 ? name.slice(0, dot) : name,
                        parentDir: slash >= 0 ? filePath.slice(0, slash) : "",
                        isDir: kind === "d",
                        isImage: ["jpg", "jpeg", "png", "webp", "gif", "bmp", "tif", "tiff"].includes(suffix),
                        mimeType: kind === "d" ? "inode/directory" : "application/octet-stream",
                        suffix,
                    };
                }).filter(entry => entry.isDir || root.matches(entry.name));

                results.sort((a, b) => a.name.localeCompare(b.name) || a.path.localeCompare(b.path));
                if (root.sortReverse)
                    results.reverse();

                entries.clear();
                for (const entry of results)
                    root.entries.append(entry);
            }
        }
    }
}
