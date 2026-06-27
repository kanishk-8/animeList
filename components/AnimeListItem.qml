import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "../services" as Services

Rectangle {
    id: root

    property var anime: ({})
    property string title: anime.english || anime.romaji || anime.title || anime.route || "Unknown"
    property string episodeNumber: anime.episodeNumber ? "Ep " + anime.episodeNumber : ""
    property string airTime: ""
    property string timeUntil: ""
    property string imageUrl: ""
    property bool isInWatchlist: false
    property bool showWatchlistButton: true

    signal watchlistToggled(var anime)

    width: parent ? parent.width : 200
    height: 96
    color: mouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
    radius: Theme.cornerRadius

    property real infoWidth: Math.max(0, root.width - (Theme.spacingS * 2 + Theme.spacingM * 3 + 72 + 32 + 80))

    Connections {
        target: Services.AnimeScheduleService
        function onWatchlistModified() {
            root.updateWatchlistStatus();
        }
    }

    onAnimeChanged: updateWatchlistStatus()
    Component.onCompleted: updateWatchlistStatus()

    function updateWatchlistStatus() {
        if (root.anime && root.anime.route) {
            var wl = Services.AnimeScheduleService.watchlist;
            root.isInWatchlist = wl.indexOf(root.anime.route) !== -1;
        } else {
            root.isInWatchlist = false;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingM

        // Anime thumbnail
        Rectangle {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 80
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHighest
            clip: true

            Image {
                anchors.fill: parent
                source: root.imageUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: parent.parent.radius
                    border.width: 1
                    border.color: Theme.outline
                    opacity: 0.2
                }
            }

            DankIcon {
                anchors.centerIn: parent
                name: "movie"
                size: 24
                color: Theme.surfaceVariantText
                visible: parent.children[0].status !== Image.Ready
            }
        }

        // Info column
        ColumnLayout {
            Layout.preferredWidth: root.infoWidth
            Layout.maximumWidth: root.infoWidth
            Layout.fillHeight: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                Layout.fillWidth: true
                text: root.episodeNumber
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primary
                visible: text !== ""
            }

            StyledText {
                Layout.fillWidth: true
                text: root.airTime
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                visible: text !== ""
            }
        }

        // Watchlist button
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.cornerRadiusSmall
            color: starMouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
            visible: root.showWatchlistButton

            DankIcon {
                anchors.centerIn: parent
                name: root.isInWatchlist ? "favorite" : "add_circle"
                size: 20
                color: root.isInWatchlist ? Theme.primary : Theme.surfaceVariantText
            }

            MouseArea {
                id: starMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.watchlistToggled(root.anime)
            }
        }

        // Time until column
        ColumnLayout {
            Layout.preferredWidth: 80
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 2

            Rectangle {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: 76
                Layout.preferredHeight: 24
                radius: height / 2
                color: Theme.primary
                visible: root.timeUntil !== "" && root.timeUntil !== "Aired"

                StyledText {
                    id: timeUntilText
                    anchors.centerIn: parent
                    text: root.timeUntil
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.onPrimary
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: 76
                Layout.preferredHeight: 24
                radius: height / 2
                color: Theme.surfaceContainerHigh
                visible: root.timeUntil === "Aired"

                StyledText {
                    anchors.centerIn: parent
                    text: "Aired"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.surfaceVariantText
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: {
            // Open anime page in browser
            if (anime.route) {
                Qt.openUrlExternally("https://animeschedule.net/anime/" + anime.route);
            }
        }
    }
}
