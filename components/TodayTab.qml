import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "../services" as Services

Item {
    id: root
    anchors.fill: parent

    property bool isLoading: Services.AnimeScheduleService.isLoading
    property bool showAll: false
    property var todayList: showAll ? root.allWatchlistAnime : Services.AnimeScheduleService.watchlistTodayAnime

    // All watchlist anime (not just today)
    property var allWatchlistAnime: {
        var result = [];
        var timetable = Services.AnimeScheduleService.timetable;
        var watchlist = Services.AnimeScheduleService.watchlist;
        if (!timetable || !watchlist) return result;
        for (var i = 0; i < timetable.length; i++) {
            var anime = timetable[i];
            if (anime.route && watchlist.indexOf(anime.route) !== -1) {
                result.push(anime);
            }
        }
        return result;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Header with count and toggle
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            spacing: Theme.spacingS

            StyledText {
                text: root.showAll ? "My List - All" : "My List - Today"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: height / 2
                color: Theme.primary
                visible: todayList.length > 0

                StyledText {
                    id: countBadge
                    anchors.centerIn: parent
                    text: todayList.length.toString()
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: Theme.onPrimary
                }
            }

            Item { Layout.fillWidth: true }

            // Toggle buttons
            Row {
                spacing: 0

                Rectangle {
                    width: watchlistBtnText.width + Theme.spacingL
                    height: 26
                    radius: height / 2
                    color: !root.showAll ? Theme.primary : (watchlistMouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                    scale: !root.showAll ? 1.0 : 0.96
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                        }
                    }

                    StyledText {
                        id: watchlistBtnText
                        anchors.centerIn: parent
                        text: "Today"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: !root.showAll ? Font.Bold : Font.Medium
                        color: !root.showAll ? Theme.onPrimary : Theme.surfaceVariantText
                    }

                    MouseArea {
                        id: watchlistMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.showAll = false
                    }
                }

                Rectangle {
                    width: allBtnText.width + Theme.spacingL
                    height: 26
                    radius: height / 2
                    color: root.showAll ? Theme.primary : (allMouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                    scale: root.showAll ? 1.0 : 0.96
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                        }
                    }

                    StyledText {
                        id: allBtnText
                        anchors.centerIn: parent
                        text: "All"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: root.showAll ? Font.Bold : Font.Medium
                        color: root.showAll ? Theme.onPrimary : Theme.surfaceVariantText
                    }

                    MouseArea {
                        id: allMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.showAll = true
                    }
                }
            }

            // Refresh Button
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: height / 2
                color: todayRefreshMouseArea.containsMouse ? Theme.primaryContainer : Theme.surfaceContainerHigh

                DankIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    size: 16
                    color: todayRefreshMouseArea.containsMouse ? Theme.onPrimaryContainer : Theme.surfaceVariantText

                    RotationAnimation on rotation {
                        running: root.isLoading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: todayRefreshMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.isLoading) {
                            Services.AnimeScheduleService.forceRefresh();
                        }
                    }
                }
            }
        }

        // Content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading State
            LoadingState {
                anchors.centerIn: parent
                visible: root.isLoading && todayList.length === 0
            }

            // No Token State
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingM
                visible: Services.AnimeScheduleService.apiToken === ""

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "key"
                    size: 48
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "API Token Required"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }
            }

            // Empty State - no anime today
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingM
                visible: !root.isLoading && todayList.length === 0 && Services.AnimeScheduleService.apiToken !== "" && !Services.AnimeScheduleService.hasError

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "event_busy"
                    size: 48
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No anime in your list today"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Add anime from Season tab"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            // Today's Anime List
            ListView {
                id: todayListView
                anchors.fill: parent
                visible: todayList.length > 0
                clip: true
                spacing: Theme.spacingXS

                model: todayList

                delegate: AnimeListItem {
                    width: todayListView.width
                    anime: modelData
                    title: modelData.english ||modelData.title || modelData.route || "Unknown"
                    episodeNumber: modelData.episodeNumber ? "Episode " + modelData.episodeNumber : ""
                    airTime: {
                        const date = Services.AnimeScheduleService.parseDate(modelData.episodeDate);
                        if (!date) return "";
                        return "Today at " + Services.AnimeScheduleService.formatTime(date);
                    }
                    timeUntil: {
                        const date = Services.AnimeScheduleService.parseDate(modelData.episodeDate);
                        return Services.AnimeScheduleService.getTimeUntil(date);
                    }
                    imageUrl: {
                        if (modelData.imageVersionRoute) {
                            return Services.AnimeScheduleService.getImageUrl(modelData.imageVersionRoute);
                        }
                        return "";
                    }
                    isInWatchlist: modelData.route && Services.AnimeScheduleService.watchlist.indexOf(modelData.route) !== -1
                    onWatchlistToggled: function(anime) {
                        Services.AnimeScheduleService.toggleWatchlist(anime);
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: false
                    policy: ScrollBar.AlwaysOff
                }
            }
        }
    }
}
