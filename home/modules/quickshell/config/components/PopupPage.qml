import QtQuick
import "../theme"

// Geometry and focus contract for content hosted by the shared morphing popup.
Item {
    property string popupKind: ""
    property real preferredWidth: 400
    property real preferredHeight: 400
    property real preferredX: Theme.popupEdgeInset
    property real preferredY: Theme.barHeight + Theme.space3
    property bool frameless: false
    property Item initialFocusItem: null
}
