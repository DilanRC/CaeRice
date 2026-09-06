pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

// First-party HTTP boundary for services that need small JSON requests.
// Each request is an isolated curl process with a bounded timeout and no
// shared mutable response state. Callers receive the upstream-compatible
// success/error callback contract and never own process lifecycle.
Singleton {
    id: root

    property list<QtObject> pending: []

    function commandFor(url: string, headers: var): list<string> {
        const command = ["curl", "--fail", "--silent", "--show-error", "--location", "--max-time", "20"];
        for (const [name, value] of Object.entries(headers || {}))
            command.push("--header", `${name}: ${value}`);
        command.push(url);
        return command;
    }

    function get(url, onSuccess, onError, headers = {}) {
        const request = requestComponent.createObject(root, {
            url,
            headers,
            successCallback: onSuccess,
            errorCallback: onError
        });
        pending = [...pending, request];
        request.start();
    }

    function finish(request: QtObject, code: int, output: string, errorOutput: string): void {
        const ok = code === 0;
        const metadata = { statusCode: ok ? 200 : 0, headers: {} };
        if (ok)
            request.successCallback?.(output, metadata);
        else
            request.errorCallback?.(errorOutput || qsTr("HTTP request failed"), metadata);
        pending = pending.filter(item => item !== request);
        request.destroy();
    }

    Component {
        id: requestComponent

        QtObject {
            id: request
            property string url: ""
            property var headers: ({})
            property var successCallback
            property var errorCallback

            property StdioCollector stdoutCollector: StdioCollector {}
            property StdioCollector stderrCollector: StdioCollector {}
            property Process process: Process {
                command: root.commandFor(request.url, request.headers)
                stdout: request.stdoutCollector
                stderr: request.stderrCollector
                onExited: code => root.finish(request, code, request.stdoutCollector.text, request.stderrCollector.text)
            }

            function start(): void { process.running = true; }
        }
    }
}
