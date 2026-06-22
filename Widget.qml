import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "./components" as AnimeCalendarComponents
import "./services" as Services

PluginComponent {
    id: root

    property string displayText: pluginData.displayText || "Hello"

    property int todayCount: Services.AnimeScheduleService.watchlistTodayCount
    property bool isLoading: Services.AnimeScheduleService.isLoading
    property string barMode: pluginData.barIndicatorMode || "icon_count"
    property string searchText: ""
    property string viewMode: "calendar" // Global view mode: "calendar" or "all"

    // Get next airing time from watchlist
    property string nextAiringTime: {
        var list = Services.AnimeScheduleService.watchlistTodayAnime;
        if (!list || list.length === 0) return "";
        var now = new Date();
        for (var i = 0; i < list.length; i++) {
            var anime = list[i];
            var airDate = Services.AnimeScheduleService.parseDate(anime.episodeDate);
            if (airDate && airDate.getTime() > now.getTime()) {
                return Services.AnimeScheduleService.getTimeUntil(airDate);
            }
        }
        return "";
    }

    // Text to display based on mode
    property string pillText: {
        if (barMode === "icon_only") return "";
        if (barMode === "icon_time") return nextAiringTime || (todayCount > 0 ? todayCount + " today" : "");
        // icon_count (default)
        return todayCount > 0 ? todayCount + " today" : "";
    }

    // Initialize services
    Component.onCompleted: {
        updateApiToken();
        loadWatchlist();
        configureNotifications();
    }

    // Watch for pluginData changes
    onPluginDataChanged: {
        updateApiToken();
        configureNotifications();
    }

    function updateApiToken() {
        const tokenPath = pluginData.apiTokenPath || "";
        if (tokenPath !== Services.AnimeScheduleService.apiTokenPath) {
            Services.AnimeScheduleService.setApiTokenPath(tokenPath);
        } else if (tokenPath) {
            Services.AnimeScheduleService.reloadApiTokenFile();
        }

        const token = pluginData.apiToken || "";
        if (token !== Services.AnimeScheduleService._tokenFromSettings) {
            Services.AnimeScheduleService.setApiToken(token);
        }

        // Update refresh interval from settings
        const refreshInterval = (pluginData.refreshInterval || 15) * 60 * 1000;
        if (refreshInterval !== Services.AnimeScheduleService.updateInterval) {
            Services.AnimeScheduleService.updateInterval = refreshInterval;
        }
    }

    function loadWatchlist() {
        Services.AnimeScheduleService.loadWatchlistFromFile();
    }

    function saveWatchlist() {
        pluginData.watchlist = Services.AnimeScheduleService.watchlist;
    }

    function configureNotifications() {
        Services.NotificationService.configure({
            enableInstantNotifications: pluginData.enableInstantNotifications !== false,
            enableDailyDigest: pluginData.enableDailyDigest !== false,
            digestTime: pluginData.digestTime || "08:00",
            notificationIcon: pluginData.notificationIcon || "x-office-calendar"
        });
    }

    Connections {
        target: Services.AnimeScheduleService
        function onWatchlistModified() {
            root.saveWatchlist();
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "udon"
                size: Theme.iconSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.pillText
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                visible: root.barMode !== "icon_only" && text !== ""
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "calendar_month"
                size: Theme.iconSize
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: {
                    if (root.barMode === "icon_only") return "";
                    if (root.barMode === "icon_time") return root.nextAiringTime || "";
                    return root.todayCount > 0 ? root.todayCount.toString() : "";
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.barMode !== "icon_only" && text !== ""
            }
        }
    }
    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn

            headerText: ""
            detailsText: ""
            showCloseButton: false

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: 0

                    // Header Row (Tabs + Search Bar)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        Layout.topMargin: Theme.spacingS
                        Layout.bottomMargin: Theme.spacingS
                        spacing: Theme.spacingM

                        // Tabs
                        Row {
                            Layout.fillWidth: false
                            Layout.preferredHeight: parent.height
                            spacing: Theme.spacingS

                            Repeater {
                                id: tabRepeater
                                model: ["MyList", "Season"]

                                Rectangle {
                                    id: tabPill
                                    width: 110
                                    height: parent.height
                                    radius: tabBar.currentIndex === index ? height / 2 : 10
                                    color: tabBar.currentIndex === index ? Theme.primary : Theme.surfaceContainerHigh
                                    scale: tabBar.currentIndex === index ? 1.0 : 0.96
                                    transformOrigin: Item.Center

                                    Behavior on radius {
                                        NumberAnimation { duration: 160 }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 160 }
                                    }

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: modelData === "MyList" ? "My List" : modelData
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: tabBar.currentIndex === index ? Font.Bold : Font.Medium
                                        color: tabBar.currentIndex === index ? Theme.onPrimary : Theme.surfaceText

                                        Behavior on color {
                                            ColorAnimation { duration: 160 }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: tabBar.currentIndex = index
                                    }
                                }
                            }
                        }

                        // Search bar
                        TextField {
                            id: globalSearchField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            Layout.alignment: Qt.AlignVCenter

                            placeholderText: ""
                            verticalAlignment: TextInput.AlignVCenter
                            leftPadding: Theme.spacingM
                            rightPadding: Theme.spacingM

                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium

                            focus: true
                            Component.onCompleted: forceActiveFocus()

                            onTextChanged: root.searchText = text

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search anime..."
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceVariantText
                                visible: parent.text === ""
                            }

                            background: Rectangle {
                                radius: height / 2
                                color: Theme.surfaceContainerHigh
                                border.width: 0
                            }
                        }

                        // View Mode Toggle Button
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignVCenter
                            radius: height / 2
                            color: viewModeMouseArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: root.viewMode === "calendar" ? "today" : "view_list"
                                size: 20
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: viewModeMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.viewMode = (root.viewMode === "calendar" ? "all" : "calendar")
                            }

                            ToolTip.visible: viewModeMouseArea.containsMouse
                            ToolTip.text: root.viewMode === "calendar" ? "Switch to list view" : "Switch to calendar view"
                            ToolTip.delay: 500
                        }

                        // Reload Button (moved to top next to search bar)
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignVCenter
                            radius: height / 2
                            color: refreshMouseArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: "refresh"
                                size: 20
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: refreshMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.AnimeScheduleService.forceRefresh()
                            }

                            ToolTip.visible: refreshMouseArea.containsMouse
                            ToolTip.text: "Refresh anime list"
                            ToolTip.delay: 500
                        }
                    }

                    // Tab Content
                    StackLayout {
                        id: tabBar
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: 0

                        AnimeCalendarComponents.TodayTab {
                            searchText: root.searchText
                            viewMode: root.viewMode
                        }

                        AnimeCalendarComponents.SeasonTab {
                            searchText: root.searchText
                            viewMode: root.viewMode
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 560
    popoutHeight: 560
}
