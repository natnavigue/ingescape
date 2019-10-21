import QtQuick 2.8
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import I2Quick 1.0

import INGESCAPE 1.0

//import "../theme" as Theme

Item {
    id: rootItem

    //--------------------------------
    //
    // Properties
    //
    //--------------------------------

    // Controller associated to our view
    property var controller: null;

    // Model of action
    property var action: null;

    // Flag indicating if our action item contains the mouse (rollover)
    property bool actionItemIsHovered: false;

    // Flag indicating if our action item is pressed
    property bool actionItemIsPressed: false;

    // Flag indicating if our action is selected
    property bool actionItemIsSelected: controller && action && (controller.selectedAction === action);

    //width: parent.width
    height: 42


    //--------------------------------
    //
    // Signals
    //
    //--------------------------------

    // signal emitted when the delete confirmation popup is needed because the action is already used in the platform
    signal needConfirmationToDeleteAction(var action);


    //--------------------------------
    //
    // Content
    //
    //--------------------------------

    Rectangle {
        anchors {
            fill: parent
        }

        color: rootItem.actionItemIsHovered ? IngeScapeTheme.actionsListItemRollOverBackgroundColor : IngeScapeTheme.actionsListItemBackgroundColor

        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }

            color: IngeScapeTheme.blackColor

            height: 1
        }

        Rectangle {
            id: selectionFeedback

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }

            width: 6
            color: IngeScapeTheme.selectionColor

            visible: rootItem.actionItemIsSelected
        }

        I2SvgItem {
            id: grip

            anchors {
                left: selectionFeedback.right
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }

            svgFileCache: IngeScapeTheme.svgFileIngeScape
            svgElementId: rootItem.actionItemIsPressed ? "grip-drag-drop-rollover-pressed" : "grip-drag-drop-rollover"

            visible: rootItem.actionItemIsHovered
        }

        // Feedback visible if all conditions are valids
        Rectangle {
            id: feedbackValidConditions

            anchors {
                left: grip.right
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
            height: 4
            width: 4
            radius: 2

            color: IngeScapeTheme.orangeColor
            opacity: (rootItem.action && rootItem.action.isValid) ? 1 : 0
        }

        // Action name
        MouseArea {
            id: btnActionName

            anchors {
                left : parent.left
                leftMargin: 40
                verticalCenter: parent.verticalCenter
            }
            height: actionName.height
            width: actionName.width

            hoverEnabled: true

            onClicked: {
                if (controller && rootItem.action) {
                    // Open the editor of our action
                    controller.openActionEditorWithModel(rootItem.action);
                }
            }

            TextMetrics {
                id: textMetrics_ActionName

                elideWidth: rootItem.width - btnActionName.anchors.leftMargin - rightRow.width - rightRow.anchors.rightMargin - 5
                elide: Text.ElideRight

                text: rootItem.action ? rootItem.action.name : ""
                font: IngeScapeTheme.headingFont
            }

            // Name
            Text {
                id: actionName

                anchors {
                    left: parent.left
                }

                color: btnActionName.pressed ? IngeScapeTheme.actionsListPressedLabelColor : IngeScapeTheme.actionsListLabelColor

                text: textMetrics_ActionName.elidedText
                font: IngeScapeTheme.headingFont
            }

            // Underline
            Rectangle {
                anchors {
                    left: actionName.left
                    right: actionName.right
                    bottom: parent.bottom
                }
                height: 2

                visible: btnActionName.containsMouse
                color: actionName.color
            }
        }

        Row {
            id: rightRow

            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                rightMargin: 6
            }

            spacing: 12

            LabellessSvgButton {
                id: playButton

                anchors.verticalCenter: parent.verticalCenter

                visible: rootItem.actionItemIsHovered || popupActionOptions.isOpened

                pressedID: releasedID + "-pressed"
                releasedID: "list-play"
                disabledID: releasedID

                onClicked: {
                    console.log("QML: play action '" + rootItem.action.name + "'");
                    if (controller) {
                        controller.executeEffectsOfAction(rootItem.action);
                    }
                }
            }

            LabellessSvgButton {
                id: btnOptions

                anchors.verticalCenter: parent.verticalCenter

                visible: rootItem.actionItemIsHovered || popupActionOptions.isOpened

                releasedID: "button-options"
                pressedID: releasedID + "-pressed"
                disabledID : releasedID

                onClicked: {
                    popupActionOptions.openInScreen();
                }
            }

            LabellessSvgButton {
                id: removeButton

                anchors.verticalCenter: parent.verticalCenter

                //visible: rootItem.actionItemIsSelected
                visible: rootItem.actionItemIsHovered || popupActionOptions.isOpened

                pressedID: releasedID + "-pressed"
                releasedID: "delete"
                disabledID: releasedID

                onClicked: {
                    if (controller && rootItem.action)
                    {
                        // FIXME: Common does not access to IngeScapeEditorC
                        if (controller.isActionInsertedInTimeLine(rootItem.action)
                                || IngeScapeEditorC.agentsMappingC.isActionInsertedInMapping(rootItem.action))
                        {
                            rootItem.needConfirmationToDeleteAction(rootItem.action);
                        }
                        else {
                            // Delete our action
                            controller.deleteAction(rootItem.action);
                        }
                    }
                }
            }
        }
    }

    //
    // Menu popup with options about the action
    //
    MenuPopup {
        id : popupActionOptions

        anchors {
            top: rootItem.top
            left: rootItem.right
            leftMargin: 2
        }

        readonly property int optionHeight: 30

        // Get height from children
        height: bgPopupActionOptions.y + bgPopupActionOptions.height
        width: 230

        isModal: true;
        layerColor: "transparent"
        dismissOnOutsideTap : true;

        keepRelativePositionToInitialParent : true;

        onClosed: {

        }
        onOpened: {

        }

        Rectangle {
            id: bgPopupActionOptions

            height: actionOptions.y + actionOptions.height
            anchors {
                right: parent.right
                left: parent.left
            }
            color: IngeScapeTheme.veryDarkGreyColor
            radius: 5
            border {
                color: IngeScapeTheme.blueGreyColor2
                width: 1
            }

            Column {
                id: actionOptions

                anchors {
                    right: parent.right
                    left: parent.left
                }

                Button {
                    id: optionDuplicate

                    height: popupActionOptions.optionHeight
                    width: parent.width

                    text: qsTr("Duplicate...")

                    //enabled: (rootItem.host && !rootItem.host.isON)
                    enabled: true

                    style: ButtonStyleOfOption {
                    }

                    onClicked: {
                        if (rootItem.controller && rootItem.action) {
                            rootItem.controller.openActionEditorToDuplicateModel(rootItem.action);
                        }
                        popupActionOptions.close();
                    }
                }
            }
        }
    }
}
