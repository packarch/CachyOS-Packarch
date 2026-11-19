#!/usr/bin/env bash
#
# Refait les images de la marque Packarch à partir des sources de ce dossier :
#   ../fonds/packarch-default.jpg        fond du thème packarch (bureau) et de
#                                        LightDM : grand fantôme sombre derrière
#                                        « Packarch Linux »
#   ../sddm/packarch/background.jpg      fond du thème SDDM : labyrinthe entier,
#                                        salle qui contient « Packarch Linux » et
#                                        la connexion, ligne d'un pacman et de
#                                        fantômes en bas
#   ../sddm/packarch/background-sans-fantomes.jpg   le même sans la ligne
#   ../fonds/packarch-labyrinthe.jpg     variante pour le bureau : labyrinthe
#                                        entier (sans fondu), texte dans une
#                                        salle au centre, sans fantômes
#
# Usage : ./construire.sh   (ImageMagick 7, rsvg-convert, python3, polices
# Noto Sans Bold et Light). Images en 3840 × 2160 ; graines fixes (grain,
# labyrinthe) : le résultat est le même à chaque fois.

set -euo pipefail
src=$(dirname "$(readlink -f "$0")")
cd "$src"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

L=3840 H=2160
fond='#0e0e11'
gras=/usr/share/fonts/noto/NotoSans-Bold.ttf
fin=/usr/share/fonts/noto/NotoSans-Light.ttf

# --- Texte « Pa?kar?h Linux » : les deux « c » remplacés par des pacmans ---
# Corps 200 ; la hauteur et la position du « c » de Noto Sans Bold (113 px,
# haut à 103 px dans une ligne de 274 px) placent le pacman sur la ligne de
# base, avec le léger débord des lettres rondes.
for t in Pa kar h; do
	magick -background none -fill '#e6e6e6' -font "$gras" -pointsize 200 label:"$t" "$tmp/seg-$t.png"
done
rsvg-convert -w 131 -h 131 packarch-logo.svg -o "$tmp/pac-lettre.png"
magick -size 135x274 xc:none "$tmp/pac-lettre.png" -geometry +2+92 -composite "$tmp/seg-pac.png"
magick "$tmp/seg-Pa.png" "$tmp/seg-pac.png" "$tmp/seg-kar.png" "$tmp/seg-pac.png" "$tmp/seg-h.png" \
	-background none +append "$tmp/mot.png"
magick -background none -fill '#f0b429' -font "$fin" -pointsize 200 label:'Linux' "$tmp/linux.png"
magick "$tmp/mot.png" \( -size 55x274 xc:none \) "$tmp/linux.png" -background none +append \
	-trim +repage "$tmp/texte.png"

# --- Texture commune : trame de pastilles et grain fin ---------------------
magick -size 48x48 xc:"$fond" -fill '#141418' -draw 'circle 24,24 24,26' "$tmp/tuile.png"
magick -size ${L}x${H} tile:"$tmp/tuile.png" "$tmp/trame.png"
# Grain en niveaux de gris, ±2 niveaux environ, sans changer la luminosité
magick -size ${L}x${H} xc:gray50 -seed 42 -attenuate 1 +noise Gaussian -colorspace gray \
	+level 49%,51% "$tmp/grain.png"
grain() { magick "$1" "$tmp/grain.png" -compose linear-light -composite "$2"; }
jpeg() { magick "$1" -strip -sampling-factor 4:4:4 -quality 92 "$2"; }

# --- Fond du thème packarch (bureau, LightDM) -------------------------------
mkdir -p ../fonds
rsvg-convert -h 1000 fantome-sombre.svg -o "$tmp/fantome-sombre.png"
magick "$tmp/trame.png" "$tmp/fantome-sombre.png" -gravity center -geometry +0-130 -composite "$tmp/b.png"
grain "$tmp/b.png" "$tmp/bg.png"
magick "$tmp/texte.png" -filter Lanczos -resize 45% "$tmp/texte45.png"
magick "$tmp/bg.png" "$tmp/texte45.png" -gravity center -compose over -composite "$tmp/bureau.png"
jpeg "$tmp/bureau.png" ../fonds/packarch-default.jpg

# --- Fond SDDM : labyrinthe entier, salle pour le texte et la connexion ----
mkdir -p ../sddm/packarch
# Salle de 12 x 8 cases (rangées 7 à 14) qui contient « Packarch Linux » et
# le panneau de connexion de Main.qml (hauteurPanneau de theme.conf)
# Quelques fantômes dans les couloirs, en pleines couleurs (murs à 70 %)
sddm_laby=(--salle --salle-l=12 --salle-h=8 --salle-y=7 --fantomes=6)
python3 -I labyrinthe.py "${sddm_laby[@]}" > "$tmp/labyrinthe.svg"
python3 -I labyrinthe.py "${sddm_laby[@]}" --fantomes-seuls > "$tmp/fantomes-laby.svg"
rsvg-convert "$tmp/labyrinthe.svg" -o "$tmp/labyrinthe.png"
rsvg-convert "$tmp/fantomes-laby.svg" -o "$tmp/fantomes-laby.png"
magick "$tmp/labyrinthe.png" -channel A -evaluate multiply 0.7 +channel "$tmp/labyrinthe-a.png"
magick -size ${L}x${H} xc:"$fond" "$tmp/labyrinthe-a.png" -compose over -composite \
	"$tmp/fantomes-laby.png" -compose over -composite "$tmp/laby.png"

# Ligne du bas : pacman et pastilles, puis fantômes de 8 couleurs sur toute
# la largeur, centrée
hl=56
couleurs=(rouge vert rose bleu orange violet cyan turquoise)
for c in "${couleurs[@]}"; do rsvg-convert -h $hl fantome-$c.svg -o "$tmp/f-$c.png"; done
rsvg-convert -h $((hl * 100 / 90)) packarch-logo-large.svg -o "$tmp/pacman.png"
w=$(magick identify -format %w "$tmp/f-rouge.png")
pw=$(magick identify -format %w "$tmp/pacman.png")
ecart_f=24 ecart_p=30
pas=$((w + ecart_f))
n=$(( (L - 2 * 150 - pw - ecart_p + ecart_f) / pas ))
largeur=$((pw + ecart_p + n * pas - ecart_f))
marge=$(( (L - largeur) / 2 ))
y=$((H - 230 - hl))
args=()
for ((i = 0; i < n; i++)); do
	args+=("$tmp/f-${couleurs[i % 8]}.png" -geometry +$((marge + pw + ecart_p + i * pas))+$y -composite)
done
magick "$tmp/laby.png" "$tmp/pacman.png" -geometry +${marge}+$((y - 3)) -composite "${args[@]}" "$tmp/laby-ligne.png"

magick "$tmp/texte.png" -filter Lanczos -resize 52% "$tmp/texte52.png"
th=$(magick identify -format %h "$tmp/texte52.png")
for v in laby-ligne laby; do
	grain "$tmp/$v.png" "$tmp/$v-g.png"
	# Texte en haut de la salle (centre à 818 px), panneau dessous
	magick "$tmp/$v-g.png" "$tmp/texte52.png" -gravity north -geometry +0+$((818 - th / 2)) -compose over -composite "$tmp/$v-t.png"
done
jpeg "$tmp/laby-ligne-t.png" ../sddm/packarch/background.jpg
jpeg "$tmp/laby-t.png" ../sddm/packarch/background-sans-fantomes.jpg

# --- Variante du bureau : labyrinthe entier (sans fondu), texte au centre,
# sans la ligne de fantômes ---------------------------------------------------
# Le texte est dans une salle du labyrinthe (labyrinthe.py --salle)
python3 -I labyrinthe.py --salle --fantomes=6 > "$tmp/labyrinthe-salle.svg"
python3 -I labyrinthe.py --salle --fantomes=6 --fantomes-seuls > "$tmp/fantomes-salle.svg"
rsvg-convert "$tmp/labyrinthe-salle.svg" -o "$tmp/labyrinthe-salle.png"
rsvg-convert "$tmp/fantomes-salle.svg" -o "$tmp/fantomes-salle.png"
magick "$tmp/labyrinthe-salle.png" -channel A -evaluate multiply 0.7 +channel "$tmp/laby-plein-a.png"
magick -size ${L}x${H} xc:"$fond" "$tmp/laby-plein-a.png" -compose over -composite \
	"$tmp/fantomes-salle.png" -compose over -composite "$tmp/laby-plein.png"
grain "$tmp/laby-plein.png" "$tmp/laby-plein-g.png"
magick "$tmp/laby-plein-g.png" "$tmp/texte52.png" -gravity center -compose over -composite "$tmp/laby-plein-t.png"
jpeg "$tmp/laby-plein-t.png" ../fonds/packarch-labyrinthe.jpg

echo "Images refaites : ../fonds/packarch-default.jpg, ../fonds/packarch-labyrinthe.jpg, ../sddm/packarch/background.jpg, background-sans-fantomes.jpg"
