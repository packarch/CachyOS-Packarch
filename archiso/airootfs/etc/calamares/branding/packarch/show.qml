/* === This file is part of Calamares - <https://calamares.io> ===
 *
 *   SPDX-FileCopyrightText: 2015 Teo Mrnjavac <teo@kde.org>
 *   SPDX-FileCopyrightText: 2018 Adriaan de Groot <groot@kde.org>
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Calamares is Free Software: see the License-Identifier above.
 *
 *   Slideshow of Packarch: text slides in French, drawn in QML (no images to
 *   translate), in the colors of the logo.
 */

import QtQuick 2.15;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 20000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    // Background, logo, title and text of a slide
    component PackarchSlide: Slide {
        id: slide
        property string title
        property string body

        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#232831" }
                GradientStop { position: 1.0; color: "#16191f" }
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width * 0.8
            spacing: slide.height * 0.035

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "packarch.png"
                width: slide.height * 0.22
                height: width
                sourceSize.width: width
                sourceSize.height: height
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: slide.title
                color: "#62aeef"
                font.family: "Noto Sans"
                font.bold: true
                font.pixelSize: Math.max(20, slide.height * 0.075)
                wrapMode: Text.WordWrap
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: slide.width * 0.18
                height: 3
                radius: 1.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#62aeef" }
                    GradientStop { position: 1.0; color: "#98c379" }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: slide.body
                color: "#d8dee9"
                font.family: "Noto Sans"
                font.pixelSize: Math.max(13, slide.height * 0.042)
                lineHeight: 1.25
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                linkColor: "#98c379"
            }
        }
    }

    PackarchSlide {
        title: "Bienvenue dans Packarch"
        body: "Packarch est une distribution basée sur CachyOS et Arch Linux, " +
              "entièrement en français, avec ses propres bureaux, thèmes et logiciels."
    }

    PackarchSlide {
        title: "Trois bureaux au choix"
        body: "Le bureau <b>XFCE</b> que vous utilisez en ce moment, le bureau " +
              "<b>Openbox</b> de Packarch, léger, avec polybar, rofi et dunst, ou " +
              "<b>Sway</b>, sous Wayland, avec ses fenêtres en mosaïque."
    }

    PackarchSlide {
        title: "Des thèmes en un clic"
        body: "Le sélecteur de thèmes change d'un coup le fond d'écran, le thème GTK, " +
              "les bordures des fenêtres, les icônes et les couleurs du terminal."
    }

    PackarchSlide {
        title: "La base CachyOS"
        body: "Le noyau <b>linux-cachyos</b>, des paquets optimisés pour votre " +
              "processeur et des mises à jour continues avec pacman."
    }

    PackarchSlide {
        title: "Packarch Hello et Packarch Installer"
        body: "Au premier démarrage, Packarch Hello vous accueille. Packarch Installer " +
              "installe en quelques clics une sélection de logiciels, les paquets des " +
              "dépôts et des Flatpak."
    }

    PackarchSlide {
        title: "Besoin d'aide ?"
        body: "Signalez un problème sur GitHub :<br><b>github.com/packarch/CachyOS-Packarch/issues</b>" +
              "<br><br>Le wiki de CachyOS reste valable pour l'essentiel :<br><b>wiki.cachyos.org</b>"
    }

    // When this slideshow is loaded as a V1 slideshow, only
    // activatedInCalamares is set, which starts the timer (see above).
    //
    // In V2, also the onActivate() and onLeave() methods are called.
    function onActivate() {
        presentation.currentSlide = 0;
    }

    function onLeave() {
    }
}
