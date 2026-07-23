pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string language: "vi"
    readonly property bool vietnamese: language !== "en"

    function tr(vietnameseText, englishText) {
        return vietnamese ? vietnameseText : englishText;
    }

    function setLanguage(value) {
        const normalized = value === "en" ? "en" : "vi";
        if (language === normalized)
            return;
        language = normalized;
        languageFile.setText(normalized + "\n");
    }

    function loadLanguage() {
        const value = languageFile.text().trim().toLowerCase();
        if (value === "en" || value === "vi")
            language = value;
    }

    FileView {
        id: languageFile
        path: Quickshell.env("HOME") + "/.config/m3-shell-language"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root.loadLanguage()
        onFileChanged: {
            reload();
            languageReload.restart();
        }
    }

    Timer {
        id: languageReload
        interval: 80
        onTriggered: root.loadLanguage()
    }
}
