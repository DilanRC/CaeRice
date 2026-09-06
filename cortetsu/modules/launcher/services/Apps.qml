pragma Singleton

import Quickshell
import "../.."
import qs.utils

// First-party desktop-entry search. The old AppDb type came from the
// Caelestia plugin and was only used for frequency ranking.
QtObject {
    id: root

    readonly property bool useFuzzyApps: CortetsuConfig.useFuzzyApps

    function entries(): var {
        return DesktopEntries.applications.values.filter(entry =>
            !Strings.testRegexList(CortetsuConfig.hiddenApps, entry.id));
    }

    function scopeUnitName(entry): string {
        const identity = String(entry.id || entry.name || "app")
            .replace(/[^A-Za-z0-9_.@-]/g, "-").slice(0, 160);
        return `cortetsu-app-${identity}-${Date.now()}`;
    }

    function launch(entry): void {
        if (!entry)
            return;
        let command = entry.command;
        if (entry.runInTerminal)
            command = [...CortetsuConfig.terminalCommand,
                       `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...command];
        const steam = command.some(token => token === "steam" || token.endsWith("/steam"));
        if (steam) {
            Quickshell.execDetached({ command, workingDirectory: entry.workingDirectory });
            return;
        }
        const scoped = ["systemd-run", "--user", "--scope", "--collect", "--quiet",
                        "--unit", scopeUnitName(entry)];
        if (entry.workingDirectory)
            scoped.push("--working-directory", entry.workingDirectory);
        scoped.push("--", ...command);
        Quickshell.execDetached({ command: scoped, workingDirectory: entry.workingDirectory });
    }

    function search(text: string): var {
        const prefix = CortetsuConfig.specialPrefix;
        let query = text;
        let field = "name";
        const selectors = { i: "id", c: "categories", d: "comment", e: "execString",
                            w: "startupClass", g: "genericName", k: "keywords" };
        if (text.startsWith(`${prefix}t `))
            query = text.slice(prefix.length + 2);
        else if (text.startsWith(prefix) && text.length > 2 && text[1] in selectors) {
            field = selectors[text[1]];
            query = text.slice(prefix.length + 2);
        }
        const needle = query.toLowerCase();
        return entries().filter(entry => {
            if (text.startsWith(`${prefix}t `) && !entry.runInTerminal)
                return false;
            return String(entry[field] ?? "").toLowerCase().includes(needle);
        });
    }
}
