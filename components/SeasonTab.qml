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
    property var animeList: Services.AnimeScheduleService.timetable
    property var selectedDate: new Date()
    property var weekDates: []

    // Filtered list based on selected day
    property var filteredList: {
        let list = animeList || [];
        if (!selectedDate) return list;

        list = list.filter(anime => {
            const airDate = Services.AnimeScheduleService.parseDate(anime.episodeDate);
            return airDate && root.isSameDay(airDate, selectedDate);
        });

        return list;
    }

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear() &&
               a.getMonth() === b.getMonth() &&
               a.getDate() === b.getDate();
    }

    function startOfWeek(date) {
        const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        const day = d.getDay(); // 0=Sun
        const diff = (day + 6) % 7; // Monday-start week
        d.setDate(d.getDate() - diff);
        return d;
    }

    function buildWeekDates(baseDate) {
        const start = startOfWeek(baseDate);
        const days = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate());
            d.setDate(start.getDate() + i);
            days.push(d);
        }
        return days;
    }

    Component.onCompleted: {
        weekDates = buildWeekDates(selectedDate);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // Week Calendar Strip + Refresh
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            spacing: Theme.spacingS

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                spacing: Theme.spacingXS

                Repeater {
                    model: weekDates

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: height / 2
                        color: root.isSameDay(modelData, root.selectedDate) ? Theme.primary : Theme.surfaceContainerHigh
                        border.color: root.isSameDay(modelData, root.selectedDate) ? Theme.primary : "transparent"
                        border.width: root.isSameDay(modelData, root.selectedDate) ? 1 : 0
                        scale: root.isSameDay(modelData, root.selectedDate) ? 1.0 : 0.96
                        transformOrigin: Item.Center

                        Behavior on scale {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutBack
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: 2

                            StyledText {
                                width: parent.width
                                text: Qt.formatDate(modelData, "ddd")
                                font.pixelSize: Theme.fontSizeSmall
                                horizontalAlignment: Text.AlignHCenter
                                color: root.isSameDay(modelData, root.selectedDate) ? Theme.onPrimary : Theme.surfaceText
                            }

                            StyledText {
                                width: parent.width
                                text: Qt.formatDate(modelData, "d")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                color: root.isSameDay(modelData, root.selectedDate) ? Theme.onPrimary : Theme.surfaceText
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedDate = modelData
                        }
                    }
                }
            }

            // Refresh Button (compact)
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                radius: height / 2
                color: refreshMouseArea.containsMouse ? Theme.primaryContainer : Theme.surfaceContainerHigh

                DankIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    size: 16
                    color: refreshMouseArea.containsMouse ? Theme.onPrimaryContainer : Theme.surfaceVariantText

                    RotationAnimation on rotation {
                        running: root.isLoading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: refreshMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.isLoading) {
                            Services.AnimeScheduleService.forceRefresh();
                        }
                    }
                }

                ToolTip.visible: refreshMouseArea.containsMouse
                ToolTip.text: "Refresh anime list"
                ToolTip.delay: 500
            }
        }

        // Content Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading State
            LoadingState {
                anchors.centerIn: parent
                visible: root.isLoading && filteredList.length === 0
            }

            // Empty State
            EmptyState {
                anchors.centerIn: parent
                visible: !root.isLoading && filteredList.length === 0 && Services.AnimeScheduleService.apiToken !== ""
                message: "No anime for " + Qt.formatDate(root.selectedDate, "ddd, MMM d")
                details: "Pick another day in the week strip"
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

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Configure your token in plugin settings"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            // Error State
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingM
                visible: Services.AnimeScheduleService.hasError && !root.isLoading

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "error"
                    size: 48
                    color: Theme.error
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Error loading data"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Services.AnimeScheduleService.errorMessage
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: Math.min(implicitWidth, parent.parent.width - Theme.spacingXL * 2)
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: retryText.width + Theme.spacingL * 2
                    height: retryText.height + Theme.spacingM
                    radius: Theme.cornerRadius
                    color: retryArea.containsMouse ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    border.color: Theme.primary
                    border.width: 1

                    StyledText {
                        id: retryText
                        anchors.centerIn: parent
                        text: "Retry"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primary
                    }

                    MouseArea {
                        id: retryArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.AnimeScheduleService.forceRefresh()
                    }
                }
            }

            // Anime List
            ListView {
                id: animeListView
                anchors.fill: parent
                visible: filteredList.length > 0
                clip: true
                spacing: Theme.spacingXS

                model: filteredList

                delegate: AnimeListItem {
                    width: animeListView.width
                    anime: modelData
                    title: modelData.english || modelData.romaji || modelData.title || modelData.route || "Unknown"
                    episodeNumber: modelData.episodeNumber ? "Episode " + modelData.episodeNumber : ""
                    airTime: {
                        const date = Services.AnimeScheduleService.parseDate(modelData.episodeDate);
                        if (!date) return "";
                        return Services.AnimeScheduleService.formatDate(date) + " at " + Services.AnimeScheduleService.formatTime(date);
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
