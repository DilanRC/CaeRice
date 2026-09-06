import QtQuick
import Quickshell
import "../services"

Scope {
    Component.onCompleted: {
        CortetsuAudio;
        Audio;
        Brightness;
        Players;
        Time;
        CortetsuNotifications;
        CortetsuSpectrum;
    }
}
