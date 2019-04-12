/*
 *	IngeScape Assessments
 *
 *  Copyright © 2019 Ingenuity i/o. All rights reserved.
 *
 *	See license terms for the rights and conditions
 *	defined by copyright holders.
 *
 *
 *	Contributors:
 *      Vincent Peyruqueou <peyruqueou@ingenuity.io>
 *
 */

import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import I2Quick 1.0

import INGESCAPE 1.0


I2PopupBase {
    id: rootPopup

    height: 500
    width: 500

    anchors.centerIn: parent

    isModal: true
    dismissOnOutsideTap: false
    keepRelativePositionToInitialParent: false


    //--------------------------------------------------------
    //
    //
    // Properties
    //
    //
    //--------------------------------------------------------

    property ExperimentationController controller: null;

    property ExperimentationM experimentation: null

    //property SubjectM selectedSubject: null
    //property TaskM selectedTask: null

    property date currentDate: new Date();


    //--------------------------------
    //
    //
    // Signals
    //
    //
    //--------------------------------

    //
    //signal cancelTODO();


    //--------------------------------
    //
    //
    // Slots
    //
    //
    //--------------------------------

    onOpened: {

        rootPopup.currentDate = new Date();

        /*if (experimentation) {
            console.log(experimentation.name + " with " + experimentation.allSubjects.count + " subjects and " + experimentation.allTasks.count + " tasks");
        }
        else {
            console.log("NO experimentation !!!");
        }*/
    }


    //--------------------------------
    //
    //
    // Functions
    //
    //
    //--------------------------------

    //
    // Reset all user inputs and close the popup
    //
    function resetInputsAndClosePopup() {
        console.log("QML: Reset all user inputs and close popup");

        // Reset all user inputs
        //txtRecordName.text = "";
        comboSubjects.selectedIndex = -1;
        comboTasks.selectedIndex = -1;

        // Close the popup
        rootPopup.close();
    }


    //--------------------------------
    //
    // Content
    //
    //--------------------------------

    Rectangle {

        anchors {
            fill: parent
        }
        radius: 5
        border {
            width: 2
            color: IngeScapeTheme.editorsBackgroundBorderColor
        }
        color: IngeScapeTheme.editorsBackgroundColor


        Text {
            id: title

            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 20
                topMargin: 20
            }
            height: 25

            //horizontalAlignment: Text.AlignHCenter

            text: qsTr("New record")

            color: IngeScapeTheme.whiteColor
            font {
                family: IngeScapeTheme.textFontFamily
                weight : Font.Medium
                pixelSize : 18
            }
        }

        Column {
            anchors {
                top: title.bottom
                topMargin: 30
                left: parent.left
                leftMargin: 10
            }

            spacing: 30


            Row {
                id: rowName

                spacing: 10

                Text {
                    text: qsTr("Name:")

                    width: 150
                    height: 30

                    color: IngeScapeTheme.whiteColor
                    font {
                        family: IngeScapeTheme.textFontFamily
                        weight : Font.Medium
                        pixelSize : 16
                    }
                }

                /*TextField {
                    id: txtRecordName

                    height: 30
                    width: 250

                    //verticalAlignment: TextInput.AlignVCenter
                    text: ""

                    style: I2TextFieldStyle {
                        backgroundColor: IngeScapeTheme.darkBlueGreyColor
                        borderColor: IngeScapeTheme.whiteColor
                        borderErrorColor: IngeScapeTheme.redColor
                        radiusTextBox: 1
                        borderWidth: 0;
                        borderWidthActive: 1
                        textIdleColor: IngeScapeTheme.whiteColor;
                        textDisabledColor: IngeScapeTheme.darkGreyColor

                        padding.left: 3
                        padding.right: 3

                        font {
                            pixelSize:15
                            family: IngeScapeTheme.textFontFamily
                        }
                    }
                }*/

                Text {
                    id: txtRecordName

                    // the subject and the task are defined
                    text: if (comboSubjects.selectedItem && comboTasks.selectedItem) {
                              String("Record-%1-%2-%3").arg(comboSubjects.selectedItem.name).arg(comboTasks.selectedItem.name).arg(rootPopup.currentDate.toLocaleString(Qt.locale(), "yyyyMMdd-hhmmss"));
                          }
                    // Only the subject is defined
                          else if (comboSubjects.selectedItem) {
                              String("Record-%1-???-%2").arg(comboSubjects.selectedItem.name).arg(rootPopup.currentDate.toLocaleString(Qt.locale(), "yyyyMMdd-hhmmss"));
                          }
                    // Only the task is defined
                          else if (comboTasks.selectedItem) {
                              String("Record-???-%1-%2").arg(comboTasks.selectedItem.name).arg(rootPopup.currentDate.toLocaleString(Qt.locale(), "yyyyMMdd-hhmmss"));
                          }
                          else {
                              String("Record-???-???-%1").arg(rootPopup.currentDate.toLocaleString(Qt.locale(), "yyyyMMdd-hhmmss"));
                          }

                    width: 250
                    height: 30

                    color: IngeScapeTheme.whiteColor
                    font {
                        family: IngeScapeTheme.textFontFamily
                        weight : Font.Medium
                        pixelSize : 16
                    }
                }
            }

            Row {
                id: rowSubject

                spacing: 10

                Text {
                    text: qsTr("Subject:")

                    width: 150
                    height: 30

                    color: IngeScapeTheme.whiteColor
                    font {
                        family: IngeScapeTheme.textFontFamily
                        weight : Font.Medium
                        pixelSize : 16
                    }
                }

                I2ComboboxItemModel {
                    id: comboSubjects

                    model: rootItem.experimentation ? rootItem.experimentation.allSubjects : null

                    function modelToString(_model) {
                        if (_model) {
                            return _model.name;
                        }
                        else {
                            return "";
                        }
                    }

                    /*onSelectedItemChanged: {
                        console.log("Subject " + comboSubjects.selectedItem);
                        rootPopup.selectedSubject = comboSubjects.selectedItem;
                    }*/
                }
            }

            Row {
                id: rowTask

                spacing: 10

                Text {
                    text: qsTr("Task:")

                    width: 150
                    height: 30

                    color: IngeScapeTheme.whiteColor
                    font {
                        family: IngeScapeTheme.textFontFamily
                        weight : Font.Medium
                        pixelSize : 16
                    }
                }

                I2ComboboxItemModel {
                    id: comboTasks

                    model: rootItem.experimentation ? rootItem.experimentation.allTasks : null

                    function modelToString(_model) {
                        if (_model) {
                            return _model.name;
                        }
                        else {
                            return "";
                        }
                    }

                    /*onSelectedItemChanged: {
                        console.log("Task " + comboTasks.selectedItem);
                        rootPopup.selectedTask = comboTasks.selectedItem;
                    }*/
                }
            }

        }


        Row {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom : parent.bottom
                bottomMargin: 16
            }
            spacing : 15

            Button {
                id: cancelButton

                property var boundingBox: IngeScapeTheme.svgFileINGESCAPE.boundsOnElement("button");

                anchors {
                    verticalCenter: parent.verticalCenter
                }

                height: boundingBox.height
                width: boundingBox.width

                activeFocusOnPress: true
                text: "Cancel"

                style: I2SvgButtonStyle {
                    fileCache: IngeScapeTheme.svgFileINGESCAPE

                    pressedID: releasedID + "-pressed"
                    releasedID: "button"
                    disabledID: releasedID + "-disabled"

                    font {
                        family: IngeScapeTheme.textFontFamily
                        weight : Font.Medium
                        pixelSize : 16
                    }
                    labelColorPressed: IngeScapeTheme.blackColor
                    labelColorReleased: IngeScapeTheme.whiteColor
                    labelColorDisabled: IngeScapeTheme.whiteColor

                }

                onClicked: {
                    console.log("QML: cancel");

                    // Reset all user inputs and close the popup
                    rootPopup.resetInputsAndClosePopup();
                }
            }

            Button {
                id: okButton

                property var boundingBox: IngeScapeTheme.svgFileINGESCAPE.boundsOnElement("button");

                anchors {
                    verticalCenter: parent.verticalCenter
                }

                height: boundingBox.height
                width: boundingBox.width

                activeFocusOnPress: true
                text: "OK"

                //enabled: (txtRecordName.text.length > 0) && (comboSubjects.selectedItem !== null) && (comboTasks.selectedItem !== null)
                enabled: (txtRecordName.text.length > 0) && (typeof comboSubjects.selectedItem !== 'undefined') && (typeof comboTasks.selectedItem !== 'undefined')

                style: I2SvgButtonStyle {
                    fileCache: IngeScapeTheme.svgFileINGESCAPE

                    pressedID: releasedID + "-pressed"
                    releasedID: "button"
                    disabledID: releasedID + "-disabled"

                    font {
                        family: IngeScapeTheme.textFontFamily
                        weight : Font.Medium
                        pixelSize : 16
                    }
                    labelColorPressed: IngeScapeTheme.blackColor
                    labelColorReleased: IngeScapeTheme.whiteColor
                    labelColorDisabled: IngeScapeTheme.greyColor

                }

                onClicked: {
                    //console.log("QML: create new Record " + txtRecordName.text);

                    if (controller && comboSubjects.selectedItem && comboTasks.selectedItem)
                    {
                        controller.createNewRecordForSubjectAndTask(txtRecordName.text, comboSubjects.selectedItem, comboTasks.selectedItem);
                    }

                    // Reset all user inputs and close the popup
                    rootPopup.resetInputsAndClosePopup();
                }
            }
        }

    }

}
