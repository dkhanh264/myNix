import QtQuick
import Quickshell

ShellRoot {
    readonly property bool performanceMode: !!(Config.getSetting("general", {}).performance)
    readonly property bool quickactionsEnabled: Config.getSetting("general", {}).quickactions !== false

    readonly property bool _initAppMeta: {
        Qt.application.name = "serpantinum";
        Qt.application.organizationName = "serpantinum";
        Qt.application.organizationDomain = "serpantinum.org";
        return true;
    }

    Component.onCompleted: {
        Qt.application.name = "serpantinum";
        Qt.application.organizationName = "serpantinum";
        Qt.application.organizationDomain = "serpantinum.org";
    }

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup() }
    }

    ScreenshotOverlay {}
    Main {}
    Bar {}
    Lock {}

    Launcher {}
    Clipboard {}	

    Polkit {}
    PopoutManager {}


    Loader {
        active: !performanceMode
        sourceComponent: Idle {}
    }
    Variants {
        model: performanceMode ? [] : Quickshell.screens
        delegate: WidgetLoader {
            required property var modelData
            screen: modelData
            monitorName: modelData.name
        }
    }
    Loader {
        active: !performanceMode
        sourceComponent: WallpaperEngine {}
    }
    Loader {
        active: !performanceMode && quickactionsEnabled
        sourceComponent: Floating {}
    }
}
