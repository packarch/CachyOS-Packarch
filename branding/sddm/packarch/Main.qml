// SPDX-License-Identifier: MIT
// Thème SDDM de Packarch (prototype) : un fond
// propre à SDDM (« Packarch Linux » au centre, pacman et ligne de fantômes en bas) : le
// panneau de connexion sous le texte, l'heure en haut, le nom de la
// machine et l'alimentation en bas.

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: racine
    width: 1920
    height: 1080
    color: config.couleurFond || "#16161a"

    readonly property string police: config.font || "Noto Sans"
    readonly property color texte: config.couleurTexte || "#e6e6e6"
    readonly property color discret: config.couleurDiscrete || "#8b8b95"
    readonly property color accent: config.couleurAccent || "#f8c602"
    readonly property color erreur: config.couleurErreur || "#ff5a48"
    readonly property real echelle: Math.max(0.6, height / 1080)

    function connecter() {
        message.text = ""
        sddm.login(utilisateur.currentValue, motDePasse.text, session.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "Mot de passe incorrect"
            motDePasse.text = ""
            motDePasse.forceActiveFocus()
        }
        function onLoginSucceeded() {
            message.text = ""
        }
    }

    Image {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // --- Heure et date, en haut au centre ---------------------------------
    Column {
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 40 * echelle }
        spacing: 2 * echelle
        Text {
            id: heure
            anchors.horizontalCenter: parent.horizontalCenter
            color: texte
            font { family: police; pixelSize: 54 * echelle; weight: Font.Light }
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: discret
            font { family: police; pixelSize: 18 * echelle }
        }
        Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
                const maintenant = new Date()
                heure.text = maintenant.toLocaleTimeString(Qt.locale("fr_FR"), "HH:mm")
                date.text = maintenant.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
            }
        }
    }

    // --- Panneau de connexion, sous le fantôme ---------------------------
    ColumnLayout {
        id: panneau
        width: 380 * echelle
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * (config.hauteurPanneau || 0.80) - height / 2
        spacing: 12 * echelle

        ComboBox {
            id: utilisateur
            Layout.fillWidth: true
            model: userModel
            textRole: "realName"
            valueRole: "name"
            currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
            font { family: police; pixelSize: 17 * echelle }
            displayText: currentText !== "" ? currentText : currentValue
            contentItem: Text {
                leftPadding: 14 * echelle
                text: utilisateur.displayText
                color: texte
                font: utilisateur.font
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitHeight: 44 * echelle
                radius: 8 * echelle
                color: "#cc16161a"
                border.color: utilisateur.activeFocus ? accent : "#33ffffff"
            }
            delegate: ItemDelegate {
                width: utilisateur.width
                contentItem: Text {
                    leftPadding: 10 * echelle
                    text: model.realName !== "" ? model.realName : model.name
                    color: highlighted ? accent : texte
                    font: utilisateur.font
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 6 * echelle
                    color: highlighted ? "#3a3420" : "#16161a"
                }
                highlighted: utilisateur.highlightedIndex === index
            }
            popup: Popup {
                y: utilisateur.height + 4 * echelle
                width: utilisateur.width
                padding: 4 * echelle
                implicitHeight: contentItem.implicitHeight + 2 * padding
                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: utilisateur.popup.visible ? utilisateur.delegateModel : null
                    currentIndex: utilisateur.highlightedIndex
                }
                background: Rectangle {
                    radius: 8 * echelle
                    color: "#16161a"
                    border.color: "#44ffffff"
                }
            }
        }

        TextField {
            id: motDePasse
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: "Mot de passe"
            placeholderTextColor: discret
            color: texte
            font { family: police; pixelSize: 17 * echelle }
            leftPadding: 14 * echelle
            focus: true
            background: Rectangle {
                implicitHeight: 44 * echelle
                radius: 8 * echelle
                color: "#cc16161a"
                border.color: motDePasse.activeFocus ? accent : "#33ffffff"
            }
            Keys.onReturnPressed: connecter()
            Keys.onEnterPressed: connecter()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * echelle

            ComboBox {
                id: session
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                font { family: police; pixelSize: 14 * echelle }
                contentItem: Text {
                    leftPadding: 12 * echelle
                    text: session.displayText
                    color: discret
                    font: session.font
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitHeight: 38 * echelle
                    radius: 8 * echelle
                    color: "#9916161a"
                    border.color: "#22ffffff"
                }
                delegate: ItemDelegate {
                    width: session.width
                    contentItem: Text {
                        leftPadding: 8 * echelle
                        text: model.name
                        color: highlighted ? accent : texte
                        font: session.font
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 6 * echelle
                        color: highlighted ? "#3a3420" : "#16161a"
                    }
                    highlighted: session.highlightedIndex === index
                }
                popup: Popup {
                    y: session.height + 4 * echelle
                    width: session.width
                    padding: 4 * echelle
                    implicitHeight: contentItem.implicitHeight + 2 * padding
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: session.popup.visible ? session.delegateModel : null
                        currentIndex: session.highlightedIndex
                    }
                    background: Rectangle {
                        radius: 8 * echelle
                        color: "#16161a"
                        border.color: "#44ffffff"
                    }
                }
            }

            Button {
                id: bouton
                text: "Se connecter"
                font { family: police; pixelSize: 15 * echelle; bold: true }
                onClicked: connecter()
                contentItem: Text {
                    text: bouton.text
                    font: bouton.font
                    color: "#16161a"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitHeight: 38 * echelle
                    implicitWidth: 130 * echelle
                    radius: 8 * echelle
                    color: bouton.down ? Qt.darker(accent, 1.2) : accent
                }
            }
        }

        Text {
            id: message
            Layout.alignment: Qt.AlignHCenter
            color: erreur
            font { family: police; pixelSize: 15 * echelle }
        }
    }

    // --- Nom de la machine et alimentation, en bas au centre ----------------
    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 36 * echelle }
        spacing: 28 * echelle
        Text {
            text: sddm.hostName
            visible: text !== ""
            color: discret
            font { family: police; pixelSize: 15 * echelle; bold: true }
        }
        Repeater {
            model: [
                { nom: "Veille", action: function() { sddm.suspend() }, visible: sddm.canSuspend },
                { nom: "Redémarrer", action: function() { sddm.reboot() }, visible: sddm.canReboot },
                { nom: "Éteindre", action: function() { sddm.powerOff() }, visible: sddm.canPowerOff }
            ]
            delegate: Text {
                required property var modelData
                visible: modelData.visible
                text: modelData.nom
                color: zone.containsMouse ? accent : discret
                font { family: police; pixelSize: 15 * echelle }
                MouseArea {
                    id: zone
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.action()
                }
            }
        }
    }

    Component.onCompleted: motDePasse.forceActiveFocus()
}
