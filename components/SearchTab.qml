import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "../services" as Services

Item {
    id: root
    anchors.fill: parent

    property string searchText: ""
    property string filterType: "all"
    property bool isLoading: Services.AnimeScheduleService.isLoading
    property var animeList: Services.AnimeScheduleService.timetable

    // Filtered list based on search and filter
    property var filteredList: {
        let list = animeList || [];

        // Filter by search text
        if (searchText.length > 0) {
            const searchLower = searchText.toLowerCase();
            list = list.filter(anime => {
                const title = (anime.english || anime.romaji ||anime.title || anime.route || "").toLowerCase();
                return title.includes(searchLower);
            });
        }

        return list;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // 1. Search, Filter Row, and Refresh Button
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            spacing: Theme.spacingS

            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter

                placeholderText: "Search anime..."
                verticalAlignment: TextInput.AlignVCenter
                leftPadding: Theme.spacingM

                color: Theme.surfaceText
                placeholderTextColor: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeMedium

                onTextChanged: root.searchText = text

                background: Rectangle {
                    radius: height / 2
                    color: Theme.surfaceContainerHigh
                    border.width: 0
                }
            }

            ComboBox {
                id: typeFilter
                Layout.preferredWidth: 90
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter

                model: ["All", "SUB", "DUB", "RAW"]
                currentIndex: 0

                contentItem: StyledText {
                    text: typeFilter.displayText
                    color: Theme.surfaceText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    rightPadding: Theme.spacingL
                }

                indicator: DankIcon {
                    name: "expand_more"
                    size: 16
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                }

                background: Rectangle {
                    radius: height / 2
                    color: Theme.surfaceContainerHigh
                    border.width: 0
                }

                popup: Popup {
                    y: typeFilter.height + Theme.spacingXS
                    width: typeFilter.width
                    implicitHeight: contentItem.implicitHeight
                    padding: Theme.spacingXS

                    background: Rectangle {
                        radius: Theme.cornerRadiusSmall
                        color: Theme.surfaceContainerHigh
                        border.width: 0
                    }

                    contentItem: ListView {
                        implicitHeight: contentHeight
                        model: typeFilter.popup.visible ? typeFilter.delegateModel : null
                        currentIndex: typeFilter.highlightedIndex
                        clip: true

                        delegate: ItemDelegate {
                            width: typeFilter.width
                            padding: Theme.spacingS

                            contentItem: StyledText {
                                text: modelData
                                color: Theme.surfaceText
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                radius: Theme.cornerRadiusSmall
                                color: highlighted ? Theme.surfaceContainerHighest : "transparent"
                            }
                        }
                    }
                }

                onActivated: {
                    root.filterType = currentText.toLowerCase();
                }

                onCurrentIndexChanged: {
                    if (currentIndex < 0) currentIndex = 0;
                }
            }

            // Refresh Button
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

        // 2. Content Area
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

            // Results count
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: Theme.spacingS
                visible: filteredList.length > 0 && searchText.length > 0
                width: countText.width + Theme.spacingM
                height: countText.height + Theme.spacingXS
                radius: Theme.cornerRadiusSmall
                color: Theme.surfaceContainerHighest
                opacity: 0.9

                StyledText {
                    id: countText
                    anchors.centerIn: parent
                    text: filteredList.length + " results"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
