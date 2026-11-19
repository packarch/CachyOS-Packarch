# Marque Packarch : sources des images

Tout se refait avec `sources/construire.sh` (ImageMagick 7, `rsvg-convert`,
`python3`, polices Noto Sans Bold et Light ; graines fixes : mêmes images à
chaque fois). Images en 3840 × 2160.

| Fichier | Contenu |
|---|---|
| `fonds/packarch-default.jpg` | fond du thème packarch (bureau) et de LightDM : fond `#0e0e11`, trame de pastilles, grain fin, grand fantôme à peine plus sombre derrière « Pa🟡kar🟡h Linux » |
| `fonds/packarch-labyrinthe.jpg` | variante pour le bureau : labyrinthe entier (sans fondu, 70 %), « Pa🟡kar🟡h Linux » dans une salle au centre du labyrinthe (cadre à double trait, ouverte à gauche et à droite), 6 fantômes dans les couloirs |
| `sddm/packarch/` | thème SDDM (prototype, Qt 6) : `Main.qml`, `theme.conf`, `metadata.desktop` |
| `sddm/packarch/background.jpg` | son fond : labyrinthe entier (70 %), salle de 12 × 8 cases qui contient « Pa🟡kar🟡h Linux » et le panneau de connexion, 6 fantômes dans les couloirs, ligne d'un pacman et de 45 fantômes de 8 couleurs en bas |
| `sddm/packarch/background-sans-fantomes.jpg` | le même sans la ligne du bas (`background=` de `theme.conf`) |

## Sources (`sources/`)

- `packarch-logo.svg` : le pacman jaune (logo de Packarch) ; aussi les deux
  « c » de « Packarch » dans le texte.
- `packarch-logo-large.svg` : le pacman et ses trois pastilles.
- `fantome-{rouge,rose,cyan,orange,vert,violet,bleu,turquoise}.svg` : fantômes
  en dégradé, yeux vers la droite.
- `fantome-sombre.svg` : fantôme `#08080a` (à peine plus sombre que le fond),
  yeux découpés.
- `labyrinthe.py` : labyrinthe parfait (graine 7, couloirs de 96 px) avec
  quelques boucles, murs `#26336b`, pastilles au milieu des couloirs ; écrit un
  SVG sur la sortie standard. `--salle` : salle de 10 × 3 cases pour le texte
  (comme la maison des fantômes du jeu) ; `--salle-y=N` sa rangée du haut,
  `--salle-l=N` et `--salle-h=N` sa taille en cases, `--cadre-seul` et
  `--sans-cadre` pour dessiner son cadre à part ; `--fantomes=N` : N fantômes
  de couleur dans les couloirs (un par zone de l'écran), `--fantomes-seuls`
  pour les dessiner sur un calque à part, en pleines couleurs.
- `construire.sh` : texte « Packarch Linux » (Noto Sans Bold, `#e6e6e6` ;
  « Linux » en Noto Sans Light, `#f0b429` ; pacmans à la place des « c »),
  trame, grain, fondu du labyrinthe et assemblage des trois images.
