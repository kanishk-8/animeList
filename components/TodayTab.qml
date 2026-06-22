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
    property var selectedDate: new Date()
    property var weekDates: []
    property string searchText: ""
    property string viewMode: "calendar" // "calendar" or "all"

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

    // Filtered watchlist based on selected day and search text
    property var filteredList: {
        let list = allWatchlistAnime || [];

        // Filter by day first, if in calendar mode
        if (root.viewMode === "calendar" && selectedDate) {
            list = list.filter(anime => {
                const airDate = Services.AnimeScheduleService.parseDate(anime.episodeDate);
                return airDate && root.isSameDay(airDate, selectedDate);
            });
        }

        // Filter by search text
        if (searchText.length > 0) {
            const searchLower = searchText.toLowerCase();
            list = list.filter(anime => {
                const title = (anime.english || anime.romaji || anime.title || anime.route || "").toLowerCase();
                return title.includes(searchLower);
            });
        }

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

        // Week Calendar Strip (Visible only in "calendar" mode)
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            spacing: Theme.spacingXS
            visible: root.viewMode === "calendar"

            Repeater {
                model: weekDates

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: root.isSameDay(modelData, root.selectedDate) ? height / 2 : 10
                    color: root.isSameDay(modelData, root.selectedDate) ? Theme.primary : Theme.surfaceContainerHigh
                    border.color: root.isSameDay(modelData, root.selectedDate) ? Theme.primary : "transparent"
                    border.width: root.isSameDay(modelData, root.selectedDate) ? 1 : 0
                    scale: root.isSameDay(modelData, root.selectedDate) ? 1.0 : 0.96
                    transformOrigin: Item.Center

                    Behavior on radius {
                        NumberAnimation { duration: 160 }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 160 }
                    }

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

        // Content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Loading State
            LoadingState {
                anchors.centerIn: parent
                visible: root.isLoading && filteredList.length === 0
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

            // Empty State
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacingM
                visible: !root.isLoading && filteredList.length === 0 && Services.AnimeScheduleService.apiToken !== "" && !Services.AnimeScheduleService.hasError

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "event_busy"
                    size: 48
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.searchText.length > 0 
                          ? "No search results found" 
                          : (root.viewMode === "calendar" 
                             ? "No anime in your list for " + Qt.formatDate(root.selectedDate, "ddd, MMM d")
                             : "No anime in your list")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: Math.min(implicitWidth, parent.parent.width - Theme.spacingXL * 2)
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.searchText.length > 0 
                          ? "Try a different search query" 
                          : (root.viewMode === "calendar" ? "Pick another day in the week strip" : "Add some anime to your watchlist")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            // Watchlist Anime List
            ListView {
                id: watchlistListView
                anchors.fill: parent
                visible: filteredList.length > 0
                clip: true
                spacing: Theme.spacingXS

                model: filteredList

                delegate: AnimeListItem {
                    width: watchlistListView.width
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
