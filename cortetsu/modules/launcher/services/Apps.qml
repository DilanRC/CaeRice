pragma Singleton

import Quickshell
import "../.."
import qs.utils

Searcher {
    id: root

    function scopeUnitName(entry: DesktopEntry): string {
        const identity = String(entry.id || entry.name || "app")
            .replace(/[^A-Za-z0-9_.@-]/g, "-")
            .slice(0, 160);
        return `cortetsu-app-${identity}-${Date.now()}`;
    }

    function isSteamCommand(command: list<string>): bool {
        return command.some(token => token === "steam" || token.endsWith("/steam"));
    }

    function launchDetached(entry: DesktopEntry, command: list<string>): void {
        Quickshell.execDetached({
            command: command,
            workingDirectory: entry.workingDirectory
        });
    }

    function launchInScope(entry: DesktopEntry, command: list<string>): void {
        if (root.isSteamCommand(command)) {
            root.launchDetached(entry, command);
            return;
        }
        const scopedCommand = [
            "systemd-run",
            "--user",
            "--scope",
            "--collect",
            "--quiet",
            "--unit",
            root.scopeUnitName(entry)
        ];
        if (entry.workingDirectory)
            scopedCommand.push("--working-directory", entry.workingDirectory);
        scopedCommand.push("--", ...command);
        Quickshell.execDetached({
            command: scopedCommand,
            workingDirectory: entry.workingDirectory
        });
    }

    function launch(entry: DesktopEntry): void {
        appDb.incrementFrequency(entry.id);

        if (entry.runInTerminal)
            root.launchInScope(entry, [...CortetsuConfig.terminalCommand, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command]);
        else
            root.launchInScope(entry, entry.command);
    }

    function search(search: string): var {
        const prefix = CortetsuConfig.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: CortetsuConfig.useFuzzyApps

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: CortetsuConfig.favouriteApps
        entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(CortetsuConfig.hiddenApps, a.id))
    }
}
