import QtQuick
import Quickshell.Networking

QtObject {
    id: root

    function handleConnect(network, session, onPasswordNeeded): void {
        if (!network)
            return;
        if (network.security === WifiSecurityType.None || network.known)
            network.connect();
        else if (onPasswordNeeded)
            onPasswordNeeded(network);
        else if (session?.network) {
            session.network.pendingNetwork = network;
            session.network.showPasswordDialog = true;
        }
    }

    function connectToNetwork(network, session, onPasswordNeeded): void {
        handleConnect(network, session, onPasswordNeeded);
    }

    function connectWithPassword(network, password, onResult): void {
        if (!network)
            return;
        network.connectWithPsk(password || "");
        if (onResult)
            onResult({ success: true });
    }
}
