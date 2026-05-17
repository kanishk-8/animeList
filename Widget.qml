import QtQuick
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

            headerText: "Anime List"
            detailsText: ""
            showCloseButton: true

            Item {
                width: parent.width
                height: Theme.spacingS
            }

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popoutColumn.headerHeight - popoutColumn.detailsHeight - Theme.spacingXL

                Column {
                    anchors.fill: parent
                    spacing: 0



                    //Tab Bar
                    Item {
                        width: parent.width
                        height: 40

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            height: parent.height
                            spacing: Theme.spacingS

                            Repeater {
                                id: tabRepeater
                                model: ["MyList", "Season", "Search"]

                                Rectangle{
                                    id: tabPill
                                    width: (parent.width - Theme.spacingS * (tabRepeater.model.length - 1)) / tabRepeater.model.length
                                    height: parent.height
                                    radius: height / 2
                                    color: tabBar.currentIndex === index ? Theme.primary : Theme.surfaceContainerHigh
                                    scale: tabBar.currentIndex === index ? 1.0 : 0.96
                                    transformOrigin: Item.Center

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
                                        text: modelData
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: tabBar.currentIndex === index ? Font.Bold : Font.Medium
                                        color: tabBar.currentIndex === index ? Theme.onPrimary : Theme.surfaceText
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: tabBar.currentIndex = index
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Theme.spacingS
                    }

                    Item {
                        width: parent.width
                        height: Theme.spacingS
                    }

                    //Tab Content
                    StackLayout {
                        id: tabBar
                        width: parent.width
                        height: parent.height - 41
                        currentIndex: 0

                        AnimeCalendarComponents.TodayTab {
                        }

                        AnimeCalendarComponents.SeasonTab {
                        }

                        AnimeCalendarComponents.SearchTab {
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 560
    popoutHeight: 560
}
