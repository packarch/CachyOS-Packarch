# Modifications par rapport à l'ISO officielle CachyOS

Ce dépôt est dérivé de [cachyos-live-iso](https://github.com/cachyos/cachyos-live-iso).
L'ISO officielle démarre sur KDE Plasma ; celle-ci démarre sur **XFCE, en français**,
avec un sélecteur de thèmes, et son installeur installe, **en ligne et à jour**,
au choix **ce même bureau XFCE** ou **le bureau Openbox de Packarch**.

**Nom : Packarch.** Depuis le 2026-10-30, l'ISO porte le nom de Packarch partout
où ce n'est pas un nom de CachyOS dont dépend le système : menus de GRUB,
syslinux et systemd-boot (`PACKARCH_VERSION` remplace `CACHYOS_VERSION`), nom
et étiquette de l'ISO (`packarch-desktop-linux-AAMMJJ.iso`, `PACKARCH_AAAAMM`),
`etc/cachyos-release` du live, nom d'hôte du live
(`packarch`) et du système installé (`packarch-<processeur>`), identifiant EFI
du chargeur installé (`packarch`), message de la console (`etc/motd`), dépôt
local `[packarch-live-local]` et fichiers propres à l'ISO
(`50-packarch-live.conf`, `40-packarch-live-locale-gen.hook`). Restent en
CachyOS : les paquets (`cachyos-*`, `linux-cachyos*`, dont
`cachyos-calamares-next`, que notre version remplace), les dépôts, miroirs et
le trousseau de clés, le fichier `etc/cachyos-release` lui-même, le wiki et
les références au projet d'origine. Calamares a son propre
thème, voir [Thème Packarch](#thème-packarch).

`/etc/os-release` et `/etc/lsb-release` (live et système installé) sont réécrits
par les hooks pacman de `cachyos-hooks` à chaque installation ou mise à jour de
`filesystem` : le `etc/os-release` de `airootfs` était écrasé pendant le build
et a été supprimé. `packarch-system-settings` (1.0-5) y remet Packarch avec son
hook `zz-packarch-branding`, exécuté après ceux de CachyOS (ordre alphabétique) :
nom, liens, logo, `ID=packarch`, `ID_LIKE="cachyos arch"` (fastfetch garde le
logo de CachyOS) et `DISTRIB_ID=packarch` (1.0-6). Aucun outil installé ne teste
`ID=cachyos` (recherche du 2026-10-30). Il ajoute aussi l'icône `packarch.png`
au thème GRUB `cachyos` (classe `packarch` de `GRUB_DISTRIBUTOR=Packarch`).
Depuis la 1.0-10, il installe son propre thème GRUB `packarch` (copie du thème
`cachyos` de `cachyos-grub-theme`, GPL-3.0, avec le fond et l'icône de Packarch
et le compte à rebours en français) : `grubcfg.conf` (dans
`archiso/airootfs/etc/xdg/calamares/modules/`) le choisit avec `GRUB_THEME`, et
le hook bascule les systèmes encore sur le thème `cachyos`.

Pas de plymouth : les messages du démarrage défilent toujours. `pacstrap.conf`
(copie de celui du paquet Calamares) n'installe ni `plymouth` ni les thèmes
plymouth de CachyOS, `settings_online.conf` n'exécute plus `plymouthcfg`, et
`bootloader.conf` n'a plus `quiet` dans `kernelParams` (Limine, systemd-boot).
Pour GRUB, `grubcfg` retire `quiet` et `splash` de `/etc/default/grub`, et
`loglevel=4` (niveau par défaut du noyau CachyOS) remplace le `loglevel=3` du
paquet grub. Sans plymouth dans le système, Calamares
n'ajoute ni le hook mkinitcpio `plymouth` ni `splash`. L'ISO live n'a pas
plymouth.

**Entrée Limine.** `limine-entry-tool` et `limine-snapper-sync` retrouvent
l'entrée du système dans `limine.conf` par la ligne `comment: machine-id=`
placée **sous** son en-tête, sinon par le `PRETTY_NAME` d'`os-release`. Calamares
écrivait cette ligne au-dessus de `/+CachyOS` : seul le nom comptait, et passer
`PRETTY_NAME` à Packarch aurait créé une seconde entrée `/+Packarch` à la mise à
jour suivante du noyau. `live-offline.patch` écrit donc `/+Packarch` (nom du
thème) avec le `machine-id` dessous, et le hook de `packarch-system-settings`
(1.0-7) renomme `/+CachyOS` en `/+Packarch` sur les systèmes déjà installés
(réenrôlement de `limine.conf` si `ENABLE_ENROLL_LIMINE_CONFIG=yes`).

## Sommaire

1. [Reconstruire l'ISO](#1-reconstruire-liso)
2. [Bureau : KDE Plasma remplacé par XFCE](#2-bureau--kde-plasma-remplacé-par-xfce)
3. [Langue, clavier et fuseau horaire](#3-langue-clavier-et-fuseau-horaire)
4. [Réglages XFCE (`packarch-xfce-settings`)](#4-réglages-xfce-packarch-xfce-settings)
5. [Sélecteur de thèmes](#5-sélecteur-de-thèmes)
6. [Installeur Calamares](#6-installeur-calamares)
7. [Liste des fichiers modifiés ou ajoutés](#7-liste-des-fichiers-modifiés-ou-ajoutés)
8. [Points connus](#8-points-connus)

---

## 1. Reconstruire l'ISO

### Prérequis (une seule fois)

Sur un système CachyOS ou Arch Linux, avec les dépôts CachyOS configurés :

```bash
sudo pacman -S --needed archiso mkinitcpio-archiso squashfs-tools grub git base-devel
```

Les dépendances de compilation de Calamares (Qt 6, bibliothèques KDE, boost,
cmake…) sont installées automatiquement par `makepkg --syncdeps` à la première
compilation (mot de passe `sudo` demandé). Pour les installer à l'avance, comme
dépendances, afin de pouvoir les retirer facilement ensuite :

```bash
cd calamares
bash -c 'source PKGBUILD; sudo pacman -S --needed --asdeps "${depends[@]}" "${makedepends[@]}"'
```

Pour les retirer plus tard : `sudo pacman -Rns $(pacman -Qdtq)`.

### Construction

Depuis la racine du dépôt, **en utilisateur normal** (le mot de passe `sudo`
est demandé pour l'étape 2) :

```bash
./build.sh          # ou ./build.sh -v pour un journal détaillé
```

`build.sh` enchaîne :

1. `calamares/build.sh` : compile notre Calamares et le met dans le dépôt
   local `localrepo/`
   (`makepkg` refuse de tourner en root), **sauf si cette version y est
   déjà** : monter `pkgrel` après chaque modification du patch, ou forcer
   avec `-f` ;
2. `sudo scripts/buildiso.sh -p desktop -w` : construit l'ISO puis supprime le
   dossier de travail `build/` ;
4. rend à l'utilisateur les fichiers de `out/` (produits par root).

- L'ISO est produite dans `out/desktop/` :
  `packarch-desktop-linux-AAMMJJ.iso`, avec ses sommes `.sha256`/`.sha1` et la
  liste des paquets `.pkgs.txt`.
- Options de `build.sh` : `-f` recompiler Calamares même si sa version est
  déjà dans `localrepo/` ; transmises à `buildiso.sh` : `-v` journal détaillé,
  `-c` ne pas vider le dossier de travail avant, `-r` construire en RAM (plus
  de 23 Go de RAM).
- `scripts/` contient la machinerie d'origine de CachyOS (`buildiso.sh`,
  `util.sh`, `util-msg.sh`, `util-iso.sh`, `util-iso-mount.sh`), qu'il n'est
  plus nécessaire d'appeler directement.

### Tester dans une VM (QEMU/KVM, UEFI)

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf

./run.sh                   # live (ISO la plus récente de out/)
./run.sh -i                # système installé (--installe)
./run.sh --iso FICHIER     # live d'une ISO précise
```

`run.sh` garde dans `vm-test/` le disque virtuel `disque.qcow2` (30 Go, créé
s'il manque) et les variables UEFI `OVMF_VARS.fd`. Le live démarre toujours en
premier (`bootindex`), même quand GRUB du système installé est enregistré dans
les variables UEFI. L'affichage utilise `virtio-vga` **sans accélération 3D**
(avec `virtio-vga-gl` et une carte NVIDIA, la fenêtre reste noire), en
1600×900 au démarrage, l'image étant adaptée à la taille de la fenêtre ; dans
le live, le bouton « Ajuster la résolution » applique la taille de la fenêtre.

### Personnaliser les thèmes Openbox dans la VM

`run.sh` redirige le port 2222 de l'hôte (127.0.0.1 seulement) vers le SSH de
la VM. `vm-themes.sh` échange par ce biais les thèmes
(`~/.config/openbox/themes`) entre la VM et les sources de `packarch-openbox-settings`
(`../myrepo-pkgs`) :

```bash
# une fois par installation, dans la VM :
#   sudo systemctl enable --now sshd && sudo ufw allow ssh
./vm-themes.sh setup UTILISATEUR   # copie la clé SSH (mot de passe demandé une fois)
./vm-themes.sh push [THÈME]        # sources → VM, puis applique le thème
./vm-themes.sh pull                # VM → vm-test/themes, affiche ce qui a changé
./vm-themes.sh ssh [COMMANDE]      # shell ou commande dans la session de la VM
```

`push` remplace les dossiers de thèmes de la VM (les fichiers propres à la VM
restent : `.current`, `.panel`, `.applied`, `.system`, `system.ini`), retire
leurs marqueurs `polybar/.module` pour que `packarch-skin` refasse la
détection du matériel, applique le thème puis enregistre l'état obtenu comme
référence (`vm-test/themes-base`). `pull` n'affiche que ce qui a changé dans la
VM depuis cette référence, sans `colors.ini` ni `colors.rasi` (régénérés par
`packarch-skin` : les couleurs se changent dans `theme.toml`). Les
modifications sont ensuite reportées à la main dans les sources : le
`config.ini` de la VM est adapté à son matériel (`ethernet`, pas de batterie
ni de luminosité), il ne doit pas être recopié tel quel.

### Nettoyer le projet

```bash
./reset.sh        # demande confirmation ; -y sans confirmation
./reset.sh -k     # garde la machine virtuelle (vm-test/)
```

Supprime tout ce que `build.sh` et `run.sh` génèrent : `out/`, `build/`,
`localrepo/`, la compilation de Calamares (`calamares/src`, `pkg`,
`calamares`, `*.pkg.tar.zst`), les fichiers écrits dans
`archiso/` par `scripts/util-iso.sh` (voir section 7) et `vm-test/`, et
remet la date de l'ISO, que `util-iso.sh` écrit dans `archiso/grub/grub.cfg`
à chaque build, à `PACKARCH_VERSION="AAMMJJ"` ; `.gitignore` exclut de toute
façon les mêmes chemins (sauf `grub.cfg`, fichier source).

Supprimés de l'original : `testiso.sh` (VirtualBox), `ci.build.sh` (appelait
un `fix_permissions.sh` absent), `lddd.sh` (outil de développement CachyOS,
inutilisé), `machines/` et `testcases/` (tests automatiques openQA/quickemu
de CachyOS, inutilisés).

---

## 2. Bureau : KDE Plasma remplacé par XFCE

Liste : `archiso/packages_desktop.x86_64`.

**Retirés :**
`plasma-desktop`, `plasma-workspace`, `plasma-integration`, `plasma-nm`,
`plasma-pa`, `plasma-thunderbolt`, `plasma-login-manager`, `polkit-kde-agent`,
`cachyos-kde-settings`, `kxkb2locale1`, `bluedevil`, `breeze-gtk`,
`kde-gtk-config`, `kinfocenter`, `kscreen`, `dolphin`, `konsole`, `kate`,
`kcalc`, `spectacle`, `partitionmanager` (gparted reste),
`alacritty`, `micro`, `vim`, `lftp`,
le noyau LTS (`linux-cachyos-lts`, `linux-cachyos-lts-nvidia-open`,
`linux-cachyos-lts-zfs`) et les outils de secours `clonezilla`, `partimage`,
`irssi`, `lynx`, `wvdial`, `xl2tpd`.

**Un seul noyau : `linux-cachyos`.** Le live démarre dessus partout (GRUB,
syslinux, systemd-boot, `grub/loopback.cfg`) : entrée « CachyOS LTS Kernel »
de GRUB retirée, entrée systemd-boot `02-archiso-linux-cachyos.conf` retirée
(doublon de `01-archiso-linux.conf`), et
`airootfs/etc/mkinitcpio.d/linux.preset` (initramfs du live) pointe sur
`linux-cachyos`. Le système installé n'a pas de LTS non plus (voir
[Corrections du code](#corrections-du-code-live-offlinepatch)).

**Ajoutés :**

| Rôle | Paquets |
|---|---|
| Bureau | `xfce4`, les extensions de `xfce4-goodies` **sauf** `parole`, `xfburn`, `xfce4-sensors-plugin` et `mousepad`, `thunar-archive-plugin`, `thunar-media-tags-plugin`, `packarch-xfce-settings` (réglages XFCE dans `/etc/skel` et sélecteur de thèmes, dépôt Packarch, au lieu de `cachyos-xfce-settings` : voir [section 4](#4-réglages-xfce-packarch-xfce-settings)) |
| Affichage et connexion | `xorg-server`, `xf86-input-libinput`, `lightdm`, `lightdm-gtk-greeter`, `lightdm-gtk-greeter-settings` |
| Remplaçants des outils KDE | `network-manager-applet`, `blueman`, `pavucontrol`, `polkit-gnome`, `gvfs`, `gvfs-mtp`, `gvfs-smb`, `file-roller`, `xarchiver`, `ristretto`, `catfish` (recherche de fichiers) |
| Applications | `geany` (seul éditeur graphique, avec `nano` en console), `meld` (comparaison de fichiers), `nounours-player` (seul lecteur vidéo, avec `mpv` en dépendance ; SMPlayer n'est plus installé, il reste proposé dans Packarch Installer), `htop` (btop est proposé dans Packarch Installer), `yay` |
| Applications de l'auteur (dépôt Packarch) | `cryptyrust` (chiffrement de fichiers), `liloucalc` (calculatrice scientifique), `nounours-player` (lecteur multimédia), `packarch-rmatrix` (effet « Matrix » en console) |
| Démarrage | `cachyos-grub-theme` |

`vim` n'est plus installé : `cachyos-zsh-config`, qui l'exigeait sans s'en
servir, est remplacé par `packarch-zsh-config` (voir ci-dessous).

`cachyos-xfce-settings` n'est plus installé nulle part : `packarch-xfce-settings`
le remplace sur le live et sur le système installé avec XFCE. Ses dépendances
inutilisées par notre configuration ne sont donc plus installées : kvantum,
qt5ct, les thèmes Nord et `char-white`, `capitaine-cursors`,
`cachyos-alacritty-config`, `ttf-fantasque-nerd` et `ttf-fira-sans`.
`qogir-icon-theme` (curseur Qogir-Dark) reste, en dépendance de
`packarch-xfce-settings` et dans le groupe commun aux deux bureaux de
`packages_online.conf`.

**Shell par défaut : zsh** avec la configuration de `cachyos-zsh-config` (oh-my-zsh,
powerlevel10k, autosuggestions, coloration syntaxique), sur le live comme sur le
système installé. Elle est installée par `packarch-zsh-config` ([packarch]) :
mêmes fichiers, renommés (`/etc/skel/.zshrc`,
`/usr/share/packarch-zsh-config/packarch-config.zsh` au lieu de
`/usr/share/cachyos-zsh-config/cachyos-config.zsh`, depuis 1.0.3-3) et mêmes
dépendances, sauf `vim`, dont elle ne se sert pas ; il fournit
`cachyos-zsh-config` (qu'exigeait `cachyos-xfce-settings`) :

- live : `packarch-zsh-config` ajouté à `packages_desktop.x86_64` (son
  `/etc/skel/.zshrc` est copié dans `/home/liveuser` par mkarchiso),
  `etc/passwd` donne `/usr/bin/zsh` à `root` et `liveuser`, et
  `root/.zshrc` charge la même configuration pour root ;
- système installé : `users.conf` (dans `etc/xdg/calamares/modules`) crée l'utilisateur
  avec `/bin/zsh` ; `packarch-zsh-config` est dans `packages_online.conf`
  et son `.zshrc` passe par `/etc/skel`. Root garde bash en installation en
  ligne. Le script `shell-setup` de Calamares, lancé à la fin, essaie zsh
  avant fish (l'original choisissait fish dès qu'il était installé) ;
- `cachyos-fish-config` (et donc fish) retiré du live et de
  `packages_online.conf` : inutile avec zsh.

Toute la configuration zsh est dans `packarch-zsh-config`, rien n'est modifié
après son installation :
- **powerlevel10k par défaut** : `/usr/share/packarch-zsh-config/p10k.zsh`,
  style *lean* sur une ligne en mode `ascii` (aucune police Nerd nécessaire,
  lisible aussi en console), chargé quand `~/.p10k.zsh` n'existe pas : pas
  d'assistant `p10k configure` au premier démarrage, ni de `.p10k.zsh` à
  copier dans `/etc/skel` ou `/root`. `p10k configure` écrit `~/.p10k.zsh`,
  qui prend alors le dessus. Pour changer le style par défaut : modifier
  `p10k.zsh` dans le paquet ;
- **alias `cleanup`** entre apostrophes : la liste des paquets orphelins
  (`pacman -Qtdq`) est calculée quand on l'utilise, et plus à chaque
  démarrage de zsh. Sur le live, sans bases de synchronisation (supprimées par
  mkarchiso), cet appel affichait « database file for '…' does not exist » et
  l'alerte *instant prompt* de powerlevel10k dans chaque terminal ; le
  contournement `etc/zsh/zshrc` du live n'est plus nécessaire ;
- dépendance `expac`, utilisée par l'alias `rip`.

**Gestionnaire de connexion** : `scripts/util-iso.sh` active `lightdm.service` au lieu
de `plasmalogin.service`. Connexion automatique de `liveuser` en session XFCE
par `etc/lightdm/lightdm.conf.d/50-packarch-live.conf` (supprimé du système
installé par `removeun` et `removeun-online`).

**Supprimés de `airootfs`** (réglages KDE) : `etc/plasmalogin.conf`,
`etc/plasmalogin.conf.d/`, le hook `90-cachyos-live-kwin-keyboard.hook`, et dans
`etc/skel/.config/` : `kded5rc`, `kscreenlockerrc`, `kwalletrc`,
`plasma-welcomerc`, `powerdevilrc`, `powermanagementprofilesrc`,
`systemd/user/plasma-login-kwin_wayland.service.d/`.

---

## 3. Langue, clavier et fuseau horaire

| Fichier (`archiso/airootfs/`) | Valeur |
|---|---|
| `etc/locale.conf` | `LANG=fr_FR.UTF-8` (avant : `C.UTF-8`) |
| `etc/locale.gen` | `fr_FR.UTF-8` et `en_US.UTF-8` |
| `etc/pacman.d/hooks/40-packarch-live-locale-gen.hook` | lance `locale-gen` pendant le build |
| `/usr/share/libalpm/hooks/90-packarch-geany-new-instance.hook` (`packarch-system-settings`) | `geany.desktop` lance `geany -i %F` : une nouvelle instance à chaque ouverture ; réappliqué à chaque mise à jour de `geany` (live et système installé) |
| `/usr/share/libalpm/hooks/90-packarch-hide-desktop-entries.hook` + `/usr/bin/packarch-hide-desktop-entries` (`packarch-system-settings`) | ajoute `NoDisplay=true` (entrée cachée des menus XFCE et rofi, mais toujours utilisable comme application par défaut) à « À propos de Xfce » (`xfce4-about`), « Émulateur de terminal », « Lecteur de courriels », « Navigateur web » (`xfce4-terminal-emulator`, `xfce4-mail-reader`, `xfce4-web-browser`), mpv, Qt V4L2 test/video (`qv4l2`, `qvidcap`), Rofi, Rofi Theme Selector et Icon Browser (`yad-icon-browser` : yad reste installé, les menus Openbox s’en servent) ; réappliqué à chaque mise à jour des paquets concernés et à l'installation de `packarch-system-settings` (live et système installé, XFCE et Openbox) |
| `etc/vconsole.conf` | `KEYMAP=fr-latin9` (consoles texte) |
| `etc/X11/xorg.conf.d/00-keyboard.conf` | `XkbLayout fr` (LightDM et XFCE) |
| `etc/localtime` | lien vers `Europe/Paris` (avant : `UTC`) |

---

## 4. Réglages XFCE (`packarch-xfce-settings`)

### Le paquet

Les réglages XFCE sont dans le paquet `packarch-xfce-settings` du dépôt
Packarch (sources : `myrepo-pkgs/packarch-xfce-settings`), installé sur le live
et, avec XFCE, sur le système installé. C'est `cachyos-xfce-settings` 1.0.9
(`/etc/skel` et GSettings) avec nos modifications déjà faites, plus le
sélecteur de thèmes ([section 5](#5-sélecteur-de-thèmes)) : il le remplace
(`replaces`/`conflicts`). Il est en conflit avec `packarch-openbox-settings` (les deux
fournissent des fichiers de `/etc/skel` : GTK, Thunar, xfconf) ; un système
installé a l'un ou l'autre.

Jusqu'au 2026-10-24, l'ISO installait `cachyos-xfce-settings` et un hook pacman
modifiait ses fichiers au build (`sed` sur les fichiers de CachyOS : un
changement de leur part pouvait annuler un réglage sans erreur), puis
`apply-live-config` copiait tout le `/etc/skel` du live sur le système
installé. Les fichiers du paquet ont été vérifiés identiques au `/etc/skel` du
live construit avant ce changement, hors bouton « Ajuster la résolution » et
nettoyage ci-dessous.

**Hook du live** : `mkarchiso` copie `airootfs` **avant** d'installer les
paquets, et un fichier de `airootfs` qui existe aussi dans un paquet fait
échouer le build. Le seul réglage propre au live, le bouton « Ajuster la
résolution », est donc ajouté au `xfce4-panel.xml` du paquet après son
installation par `etc/pacman.d/hooks/80-live-xfce-skel.hook`, qui lance
`80-live-xfce-skel.sh`. Les deux fichiers contiennent `remove from airootfs!` :
le hook d'origine `zzzz99-remove-custom-hooks-from-airootfs.hook` les retire
de l'ISO à la fin.

### Modifications par rapport à `cachyos-xfce-settings`

- **Pas de verrouillage ni de mise en veille** : `xfce4-power-manager.xml`
  (écran jamais éteint, ordinateur jamais mis en veille, pas de verrouillage à
  la veille), `xfce4-screensaver.xml` (économiseur et verrouillage désactivés),
  `xfce4-session.xml` (pas de verrouillage à l'extinction). Équivalent des
  anciens fichiers KDE. S'y ajoute, dans `packarch-system-settings` (XFCE et
  Openbox), `/usr/share/X11/xorg.conf.d/10-packarch-no-blanking.conf` : le
  serveur X n'éteint plus l'écran de lui-même après 10 minutes, y compris sur
  l'écran de connexion LightDM. De même,
  `/usr/share/lightdm/lightdm.conf.d/40-packarch-numlock.conf`
  (`greeter-setup-script=/usr/bin/numlockx on`, `numlockx` en dépendance)
  allume le pavé numérique dès l'écran de connexion.
- **Actions personnalisées de Thunar** (`uca.xml`), `sudo` étant sans mot de
  passe pour le groupe `wheel` :
  - « Thunar Root » : `sudo thunar %f` (au lieu de `pkexec`), icône
    `folder-red` ;
  - « Open a root terminal here » devient « Terminal root » :
    `sudo xfce4-terminal --default-working-directory=%f` (au lieu de `pkexec`) ;
  - « Set as desktop background » supprimée : le greffon de fond d'écran de
    Thunar propose déjà « Définir comme fond d'écran » (et la commande de
    l'action écrivait dans `/backdrop/screen0/monitor0/image-path`, que
    xfdesktop 4.20 ne lit plus).
- **Thunar** (`thunar.xml`) : barre de menus cachée (Ctrl+M l'affiche) et
  entrée « Supprimer » (sans passer par la corbeille) dans le menu contextuel.
  Même réglage dans le `thunar.xml` de `packarch-openbox-settings`.
- **Geany comme éditeur** : `mimeapps.list` remplace `mousepad.desktop` par
  `geany.desktop`.
- **Firefox au lieu de Cachy Browser** (absent de l'ISO) : bouton du tableau de
  bord (`launcher-20`), navigateur par défaut (`helpers.rc`), favoris du menu
  Whisker (Parole et epdfview retirés des favoris).
- **Icône du bouton Thunar** : `default-folder` (absente de la plupart des
  thèmes d'icônes) remplacée par `org.xfce.thunar`.
- **Bouton du sélecteur de thèmes** : lanceur `plugin-30` ajouté après le
  moniteur système, avec « default » en première entrée.
- **Bouton « Ajuster la résolution » (live seulement, hook du live)** :
  lanceur `plugin-31` (`launcher-31/live-fit-display.desktop`, dans
  `airootfs/etc/skel`) après le sélecteur de thèmes. Il lance
  `/usr/local/bin/live-fit-display` (`xrandr --output <écran> --auto`) : dans
  une machine virtuelle, applique la taille de la fenêtre, que XFCE n'applique
  pas tout seul. Absent du système installé, où le script n'existe pas.
- **Thème « default » dès le démarrage** (thème `default` de `packarch-skin`
  depuis 1.0.9-7, écrit par `packarch-skin render` à la construction, voir
  section 5) : `xsettings.xml` (thème GTK `Packarch-Default`, icônes
  `Packarch` (dossiers bleus), curseur `Pear-Dark` au lieu de
  `capitaine-cursors`), `xfwm4.xml` (bordures `Packarch-Default`),
  `xfce4-desktop.xml` (fond `wallpaper-alt.png`), couleurs du terminal ajoutées à
  `terminalrc` (xfce4-terminal les importe dans xfconf au premier lancement).
  Mêmes valeurs dans `.gtkrc-2.0`, `gtk-3.0/settings.ini`,
  `gtk-4.0/settings.ini`, `.icons/default/index.theme` (curseur) et la
  surcharge GSettings `25_packarch-xfce-settings.gschema.override` (au lieu du
  thème `cachyos-nord`, des icônes `Qogir` et de `capitaine-cursors`).
- **Retirés** : réglages de qt5ct et Kvantum (`QT_QPA_PLATFORMTHEME=qt5ct` de
  `.profile` compris : les applications Qt prennent le thème GTK), démarrage
  automatique d'Octopi Notifier (aucun des trois n'est installé) ;
  `BROWSER=firefox` dans `.profile` au lieu de `cachy-browser`. Le script
  d'installation de `cachyos-xfce-settings` (greeter LightDM `cachyos-nord`)
  n'est pas repris : le greeter est réglé par `packarch-system-settings`.
- **Curseur** : celui du thème `packarch-skin` (`packarch-cursors`) depuis
  1.0.9-7 ; `Qogir-Dark` (`qogir-icon-theme`) avant, inchangé par l'ancien
  sélecteur de couleurs.
- **DPI des polices fixé à 96** (1.0.9-2) : `/Xft/DPI` vaut 96 dans
  `xsettings.xml` au lieu d'être vide. Sans valeur, xfsettingsd calcule le
  DPI depuis l'écran : environ 70 avec le pilote NVIDIA (`UseEdidDpi`, voir
  `/var/log/Xorg.0.log`), ce qui réduisait tout le bureau d'un quart.
- **Greeter LightDM sombre** (XFCE et Openbox) : `packarch-system-settings`
  règle dans `/usr/share/lightdm/lightdm-gtk-greeter.conf.d/50-packarch.conf`
  son propre thème GTK `Packarch-Greeter` (le GTK 3 de `Greybird-dark`, dans
  ce paquet depuis 1.0-4), les icônes `Packarch` (dossiers bleus,
  `packarch-icons` ; `Luna-Red-Dark` avant 1.0-12), le curseur `Qogir-Dark` (`qogir-icon-theme`) et le fond
  `/usr/share/backgrounds/wallpaper-alt.png` (`packarch-backgrounds` ;
  `packarch-system-settings` 1.0-3). Le
  greeter lit ce dossier avant `/etc/lightdm/lightdm-gtk-greeter.conf`, dont
  tous les réglages sont commentés : plus de `sed` sur ce fichier.
- **cachy-update toujours installé** (XFCE et Openbox) : dépendance de
  `packarch-system-settings` (1.0-2). Son applet démarre à chaque session
  (`/etc/xdg/autostart/arch-update-tray.desktop` du paquet ; sous Openbox,
  `snixembed` de `packarch-openbox-settings` l'affiche dans polybar) et la
  vérification quotidienne des mises à jour (`arch-update.timer`) est activée
  pour tous les utilisateurs par
  `/usr/lib/systemd/user/timers.target.wants/arch-update.timer`.
- **Pas de galculator** : retiré de l'ISO et de l'installation en ligne ; le
  favori du menu Whisker et la touche Calculatrice (`XF86Calculator` dans
  `xfce4-keyboard-shortcuts.xml`) lancent LilouCalc à la place.
- **Pavé numérique activé** : `keyboards.xml`, `Numlock` à `true`.

### Fichiers ajoutés par le paquet

- `.config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml` : pas de montage
  ni d'ouverture automatiques des disques.
- `.config/xfce4/panel/launcher-30/theme-*.desktop` : les 7 entrées du bouton de
  thèmes.
- `.config/xfcethemes/` : `.current_theme` (`default`) et des liens vers le
  script et les icônes de `/usr/share/xfcethemes`.
- `.xprofile` : lance `init-backdrop.sh` (voir ci-dessous).

### Fichiers ajoutés directement dans `airootfs/etc/skel`

(aucun paquet ne les fournit, donc pas de conflit ; `apply-live-config` les
copie sur le système installé, XFCE ou Openbox, sauf le bouton du live)

- `.config/xfce4/panel/launcher-31/live-fit-display.desktop` : bouton
  « Ajuster la résolution » du live.
- `.bashrc`, `.bash_profile`.
- `.config/geany/geany.conf` : réglages de Geany (police JetBrainsMono Nerd
  Font, thème `darcula`, barre d'outils masquée...), copiés d'une configuration
  personnelle, nom et adresse des modèles (`pref_template_*`) vidés, terminal
  `xfce4-terminal` au lieu de `xterm`. La police vient de
  `ttf-jetbrains-mono-nerd`, ajouté à l'ISO et à l'installation.

---

**Dépannage à distance** (`packarch-depannage`, dépôt
[packarch-depannage](https://github.com/packarch/packarch-depannage), paquet
`myrepo-pkgs/apps/packarch-depannage`), sur le live et le système installé :
fenêtre « Dépannage à distance » (menu Système) ; « Autoriser le dépannage
(1 h) » démarre, avec le mot de passe de l'utilisateur, une session Tailscale
avec Tailscale SSH et affiche le lien de connexion à transmettre à la
personne qui dépanne. Elle l'ouvre avec son compte Tailscale et se connecte
en root (`ssh root@packarch-<nom d'hôte>`). Arrêt automatique (minuterie
systemd), « +1 h », « Arrêter maintenant » ; rien ne tourne en dehors d'une
session, aucun secret sur l'ordinateur. Le réseau Tailscale de la personne
qui dépanne doit isoler `tag:depannage` (README du dépôt).

## 5. Sélecteur de thèmes

Depuis `packarch-xfce-settings` 1.0.9-7, le bureau XFCE utilise **les mêmes
thèmes que le bureau Openbox**, appliqués par **`packarch-skin`** (1.0.0-19) :
`default`, `adaptive`, `cyberpunk`, `hacking`, `packarch`, `pink-city`,
`pink-sylvanas`, `red-satanic`, `spark`, `yellow-flower`.

- les `theme.toml` de `packarch-openbox-settings` sont copiés à la construction dans
  `/usr/share/xfcethemes/themes/<thème>/` (une seule source) ; sur XFCE
  (`XDG_CURRENT_DESKTOP`, ou pas de thèmes Openbox), `packarch-skin apply
  THÈME` règle le fond d'écran du thème (tous les réglages de xfdesktop, et
  ceux par nom d'écran de xfdesktop 4.20,
  `/backdrop/screen0/monitor<SORTIE>/workspace<N>/last-image`, absents d'une
  session neuve), les thèmes GTK, xfwm4 (`[xfce] xfwm4_theme`, par défaut le
  thème GTK ; `Default` pour `hacking`), d'icônes (avec `folder_color`,
  `packarch-folder-color`) et de curseur, le `color-scheme`, les couleurs de
  xfce4-terminal (palette du thème) et de Geany, et place le thème en tête du
  lanceur du tableau de bord. Polices, barre et menus restent propres à
  Openbox (`bar`, `font`, `openbox-menu` refusés sur XFCE).
- le thème courant est dans `~/.config/xfcethemes/.current_theme` ;
  `packarch-skin render` écrit le thème `default` dans le `/etc/skel` du
  paquet (xsettings, xfwm4, xfce4-desktop, terminalrc, GTK 2/3/4,
  `.icons/default`, surcharge GSettings), et `apply-live-config` le refait
  sur le système installé, comme avec Openbox.
- tableau de bord : lanceur `plugin-30` avec un élément par thème
  (`launcher-30/theme-<thème>.desktop`, `packarch-skin apply <thème>`), icône
  `/usr/share/xfcethemes/icons/<thème>.png` (miniature de son fond d'écran),
  et « Couleur des dossiers » (`packarch-folder-color`) en dernier, donc en
  haut de son menu (tableau de bord en bas). Ces fichiers et la liste sont
  écrits par `packarch-skin render` (1.2.0). Si le bouton est retiré du
  tableau de bord, l'entrée de menu « Restaurer le bouton des thèmes »
  (`packarch-skin panel`) le remet avant la liste des fenêtres ; « Thèmes
  Packarch » (`packarch-skin chooser`, fenêtre yad) permet de changer de
  thème sans lui.
- `theme-switcher.sh --<couleur>` ne fait plus que traduire les couleurs de
  l'ancien sélecteur (lanceurs des utilisateurs existants) : `default` →
  `default`, `blue` → `packarch`, `purple` → `pink-sylvanas`, `red` →
  `red-satanic`, `yellow` → `yellow-flower`, `green` → `hacking`, `gray` →
  `adaptive`.
- `init-backdrop.sh` : lancé par `~/.xprofile` avant l'ouverture de la session
  (LightDM). Crée le réglage du fond d'écran des écrans branchés s'il manque
  (fond du thème courant, `packarch-skin wallpaper`). Sans lui, xfdesktop 4.20
  affiche la souris XFCE : la configuration CachyOS utilise l'ancien format
  `monitor0`, que xfdesktop supprime en le convertissant. Une ancienne couleur
  dans `.current_theme` est remplacée par le thème correspondant, appliqué une
  fois la session ouverte.
- conséquence : les deux bureaux utilisent les mêmes paquets de thèmes
  (`packarch-themes`, `packarch-icons`, `packarch-backgrounds`,
  `packarch-cursors`), voir ci-dessous ; l'ISO embarque aussi `packarch-cursors`.

**Thèmes du dépôt Packarch** ([myrepo](https://github.com/packarch/myrepo)
de l'auteur) :

- dépôt `[packarch]` (`SigLevel = Optional TrustAll`,
  `Include = /etc/pacman.d/packarch-mirrorlist`) ajouté à la fin de
  `etc/pacman.conf` (live) et de `etc/pacman-more.conf` (copié comme
  `pacman.conf` du système installé). Pour le build, `archiso/pacman.conf`
  le déclare avec `Server = https://packarch.github.io/myrepo/$arch`
  (pas besoin du fichier de miroirs sur la machine qui construit l'ISO).
- `etc/pacman.d/packarch-mirrorlist` est fourni par `airootfs` et **non** par le
  paquet `packarch-mirrorlist` : ce paquet ne le déclare pas en `backup`, et Calamares
  doit le copier sur le système installé **avant** pacstrap (voir section 6),
  ce qui ferait échouer l'installation du paquet (« existe déjà »).
- paquets installés (live et système installé), un par catégorie (sources :
  [myrepo-pkgs](https://github.com/packarch/myrepo-pkgs)), réduits à ce
  qu'utilisent les 10 thèmes de `packarch-skin` (les mêmes sur Openbox et
  XFCE) et l'écran de connexion — depuis la fusion de 2026-11-01, plus de
  paquets `-openbox` :
  - `packarch-themes` 2.0-7 : `Packarch-<Thème>` (GTK et xfwm4) et
    `OB-Packarch-<Thème>` (Openbox), anciennement `packarch-themes-openbox` ;
  - `packarch-icons` 2.0-9 : `Packarch`, `Hack`, `Luv-Folders(-Dark)`,
    `Qogir-Pink-Dark`, et `Packarch-Base(-Dark)`, `Papirus-Apps` dont ils
    héritent ; dépend de `qogir-icon-theme`, `papirus-icon-theme` et
    `beautyline` (anciennement aussi `packarch-icons-openbox`) ;
  - `packarch-backgrounds` 2.0-6 : les 10 fonds des thèmes, dont
    `wallpaper-alt.png` (thème `default` et écran de connexion)
    (anciennement aussi `packarch-backgrounds-openbox`) ;
  - `packarch-cursors`.
  Les icônes se complètent par héritage : `Packarch` → `Packarch-Base-Dark`
  → `Papirus-Apps`, `Papirus-Dark`.
- **un seul thème d'icônes Luna : `Packarch`** (`packarch-icons` 2.0-8,
  2026-10-31) : l'ancien `Luna-Antidote-Dark` (dossiers bleus `#0096ff`),
  rendu autonome. `Luna`, `Luna-Dark` et les `Luna-*-Dark` sont supprimés, et
  l'ancienne base `Packarch`/`Packarch-Dark` est renommée
  `Packarch-Base`/`Packarch-Base-Dark` (héritages et liens des autres thèmes
  mis à jour). La couleur des dossiers est appliquée par utilisateur par
  **`packarch-folder-color`** (github.com/packarch/packarch-folder-color,
  `apps/packarch-folder-color`) : il génère `~/.local/share/icons/Packarch-<rrggbb>`
  (hérite de `Packarch`, dossiers recolorés, un seul à la fois).
  `packarch-skin` 1.0.0-18 l'appelle avec le `folder_color` des thèmes
  (`default`/`packarch` bleu, `red-satanic` rouge `#ff4747`, `pink-sylvanas`
  violet `#a659ff`, `yellow-flower` jaune `#ffc86a`), sur Openbox et, depuis
  `packarch-xfce-settings` 1.0.9-7, sur XFCE. `/etc/skel` et l'écran de
  connexion utilisent `Packarch` tel quel (bleu, celui du thème `default`).
- ce qu'aucun thème n'utilise (14 thèmes d'icônes dont Vimix-Black(-Dark),
  les thèmes GTK de l'ancien sélecteur XFCE comme Arc-Dark ou Dracula, les
  anciens fonds d'écran dont `xfce-default.png`), regroupé un moment dans
  `packarch-extra` (anciennement `packarch-icons-extra`), a été **supprimé**
  le 2026-11-01 : aucun paquet n'en dépendait. Il reste dans l'historique git
  de myrepo-pkgs.
- plus aucun thème, icône ni fond d'écran n'est copié à la main dans
  `airootfs` (ni copié par `apply-live-config`).

---

## 6. Installeur Calamares

### Pourquoi recompiler Calamares

1. Le paquet officiel `cachyos-calamares-next` 3.4.2-13 était lié à
   `libboost_python314.so.1.91.0` alors que les dépôts fournissent boost 1.92 :
   Calamares ne démarrait pas.
2. Quelques changements du code (voir
   [Corrections du code](#corrections-du-code-live-offlinepatch)).

Le dossier `calamares/` contient donc :

| Fichier | Rôle |
|---|---|
| `PKGBUILD` | celui de [CachyOS-PKGBUILDS](https://github.com/CachyOS/CachyOS-PKGBUILDS) (`cachyos-calamares/`), version `3.4.2-13.8`, figé sur le commit `199d71543db8` de la branche `cachyos-dev`, applique `live-offline.patch` |
| `live-offline.patch` | nos modifications du **code** seulement (6 fichiers, détail ci-dessous) |
| `build.sh` | `makepkg`, puis copie du paquet dans `localrepo/` et `repo-add` ; rien si cette version y est déjà (`-f` : recompiler quand même) |

Calamares est compilé avec
`scripts/makepkg-generic.conf` (`makepkg --config`) : la configuration du
système, mais en code x86-64 générique (`-march=x86-64 -mtune=generic -O2`).
Le `makepkg.conf` de CachyOS peut utiliser `-march=native`, et ces programmes
tournent sur le live ou le système installé, sur n'importe quel processeur.

`scripts/util-iso.sh` ajoute le dépôt local `[packarch-live-local]`
(`Server = file://…/localrepo`, `SigLevel = Optional TrustAll`) **avant**
`[cachyos]` dans la copie de `pacman.conf` utilisée par le build : l'ISO prend
notre Calamares plutôt que l'officiel.

### Configuration : `airootfs/etc/xdg/calamares`

Les fichiers de configuration du paquet (`/etc/calamares/…`) lui
appartiennent et ne peuvent pas être remplacés depuis `airootfs` (mkarchiso
échouerait). Notre configuration est donc dans
`archiso/airootfs/etc/xdg/calamares/` : `settings_online.conf`,
`settings_offline.conf` et `modules/` (`packages_online.conf`,
`netinstall_offline.conf`, `packagechooser_desktop.conf`, `bootloader.conf`,
`packages_offline.conf`, `users.conf`, `welcome.conf`, `shellprocess.conf`,
`shellprocess_initialize_pacman.conf`, `shellprocess_live_config.conf`,
`shellprocess_cleanup_live.conf`). `calamares-online.sh` copie
`settings_online.conf` en `/etc/xdg/calamares/settings.conf` et lance
`calamares -X`, qui cherche `settings.conf` et chaque `modules/<fichier>.conf`
dans `/etc/xdg/calamares` **avant** `/etc/calamares` ; les modules non
modifiés gardent la configuration du paquet. Calamares ne prend `/etc/xdg`
que si `XDG_CONFIG_DIRS` est définie (une variable vide lui donne une liste
vide, pas la valeur par défaut), et `pkexec` l'efface :
`calamares-online.sh` la passe explicitement. Il copie aussi
`settings_online.conf` en `/etc/calamares/settings.conf`, pour garder nos
pages et étapes dans tous les cas. **À vérifier après un test** : aucun
avertissement `No config file for` dans `/home/liveuser/cachy-install.log`
(Calamares continue sans la configuration d'un module qu'il ne trouve pas).

**Modifier la configuration** (liste de paquets, groupes, pages) : éditer ces
fichiers puis reconstruire l'ISO, **sans recompiler Calamares**. Jusqu'au
2026-10-24, elle était dans `live-offline.patch` (environ 1 100 lignes), à
régénérer et recompiler à chaque changement. `removeun` (mode hors ligne)
retire `/etc/xdg/calamares` du système installé.

### Installation en ligne (mode par défaut)

`settings_online.conf` reste la base (installation officielle de CachyOS :
`pacstrap`, choix du chargeur de démarrage, etc.) avec ces changements :

- **Page « Bureau »** (`packagechooser@desktop`, avant « Paquets ») réduite à
  deux choix : **XFCE** (par défaut, le bureau du live) ou **Openbox** (celui
  de Packarch, voir [Bureau Openbox](#bureau-openbox-packarch)). Le live, lui,
  démarre toujours sur XFCE.
- **`shellprocess@initialize_pacman`** copie aussi
  `/etc/pacman.d/packarch-mirrorlist` sur le système installé, avec les
  listes de miroirs CachyOS : pacstrap et pacman y lisent le `pacman.conf` du
  système installé, qui inclut `[packarch]`.
- **Pas de page « Logiciels supplémentaires »** : `netinstall@live` est retiré
  de `settings_online.conf`. La liste de paquets de CachyOS est remplacée par
  les `operations` de **`packages_online.conf`** (options d'origine de
  CachyOS, `packages@online`, lancé après pacstrap), une opération `install`
  par groupe : base CachyOS (noyau `linux-cachyos` seul, microcode, outils
  CachyOS, réseau, pare-feu, bluetooth, son, polices, matériel…, **sans
  `alacritty` ni `micro`**) et **les applications du live communes aux deux
  bureaux** (LightDM, Xorg, geany, nounours-player, firefox et `firefox-i18n-fr`,
  applications Packarch…). `$LOCALE` y est remplacé comme dans netinstall.
  La page **« Bureau »** (`packagechooser_desktop.conf`, méthode `packages`)
  ajoute les paquets du bureau choisi : celui du live pour **XFCE** (mêmes
  paquets que l'ISO, dont `packarch-xfce-settings` : réglages et sélecteur de
  thèmes), `packarch-openbox-settings` et les greffons Thunar pour **Openbox**.
  Les logiciels optionnels (Discord, FileZilla, LibreOffice en français,
  GIMP, Steam, Bombicat, rustup, Qt Creator, KeePassXC, Deadpool,
  impression CUPS, accessibilité) s'installent après l'installation avec
  **Packarch Installer** (liste `pkglist.yaml` de
  `packarch-pi`). Le correctif de `netinstall/PackageModel.cpp` (cocher un
  groupe caché par son nom) reste dans `live-offline.patch`, mais ne sert plus
  à l'installation en ligne.
- **`shellprocess@live_config`**, après l'installation des paquets : lance
  `/usr/local/bin/apply-live-config` (fourni par l'ISO). Il reconnaît le bureau
  choisi aux paquets installés (`openbox` sans `xfce4-session` : Openbox).
  Les réglages du bureau viennent de son paquet (`packarch-xfce-settings`, ou
  `packarch-openbox-settings`, qui fait aussi d'Openbox la session par défaut de
  LightDM : `/etc/lightdm/lightdm.conf.d/60-packarch-openbox.conf`), ceux
  communs aux deux bureaux de `packarch-system-settings` (greeter et pavé
  numérique de LightDM, pas d'extinction de l'écran, hooks de Geany et des
  menus). `apply-live-config` ne copie que ce qui est propre à l'auteur et
  n'a pas sa place dans le dépôt public : la partie du `/etc/skel` du live
  indépendante du bureau (`.bashrc`, `.bash_profile`, `geany.conf` ;
  le reste contient les réglages XFCE, que `xfsettingsd` appliquerait sous
  Openbox, et le bouton propre au live). Avec Openbox, il relance ensuite
  `packarch-skin render / default` dans le système installé : le thème
  default a été écrit dans `/etc/skel` à la construction de
  `packarch-openbox-settings`, sans ce `geany.conf` (couleurs XFCE) ; la première
  session a ainsi le thème default partout, sans `packarch-skin apply`
  (`/etc/skel` est copié dans le dossier personnel à la fin, par l'étape
  `shellprocess`). Il crée aussi `/etc/sudoers.d/90-wheel-nopasswd`
  (`%wheel  ALL=(ALL) NOPASSWD: ALL`) : **`sudo` sans mot de passe** sur le
  système installé. Le nom en `90-` le fait lire après le `10-installer` de
  Calamares (`%wheel ALL=(ALL) ALL`), car c'est la dernière règle qui compte.
  (Il n'installe plus la toolchain Rust : rustup n'est plus proposé par
  Calamares. Après l'avoir installé avec Packarch Installer, lancer
  `rustup default stable`.)
- **Configuration de GitHub au premier login** : `apply-live-config` copie
  aussi `/usr/local/bin/github-setup`, l'archive chiffrée
  `/usr/share/github-setup/myEncryptedFile` (clé SSH GitHub et `gitconfig.sh`,
  chiffrée avec cryptyrust, embarquée dans l'ISO) et l'entrée
  `/etc/xdg/autostart/github-setup.desktop` (`OnlyShowIn=XFCE;OPENBOX;` :
  Openbox la lance aussi, par `openbox-xdg-autostart`). À l'ouverture de session,
  une fenêtre zenity demande le mot de passe de l'archive ; `github-setup` la
  déchiffre dans `$XDG_RUNTIME_DIR` (en RAM ; mot de passe transmis par un
  tube, jamais en argument), l'extrait dans le dossier personnel, met
  `~/.ssh` en 700 et les clés privées en 600, puis lance `~/gitconfig.sh`.
  Ce dernier configure git et ajoute aussi à `/etc/fstab` (par `sudo`, sans
  mot de passe pour `wheel`) les NFS du serveur (`/mnt/medias`, `/mnt/partage`) et le SSD de
  données (`/mnt/ssd`, `nofail`), si leur point de montage n'y est pas déjà ;
  copie de l'original dans `/etc/fstab.avant-github-setup`.
  Mot de passe faux : redemandé. Annuler : « Plus tard » (redemandé à la
  prochaine session) ou « Ne plus demander ». Une fois terminé, le fichier
  `~/.config/github-setup.done` empêche toute nouvelle demande ; journal dans
  `~/.cache/github-setup.log`. Sur le live, rien n'est lancé (l'entrée
  autostart n'est installée que sur le système installé). `zenity` est
  ajouté au groupe du bureau de `packages_online.conf` (`cryptyrust` y était
  déjà). **Seule la version chiffrée est sur l'ISO** : pour changer de clé,
  remplacer `archiso/airootfs/usr/share/github-setup/myEncryptedFile`
  (archive `.tar.gz` chiffrée avec `cryptyrust -e`, extraite dans le dossier
  personnel).
- `packages_online.conf` (options d'origine) fait un `pacman -Syu` après l'installation
  des paquets : **le système installé est à jour**.

### Bureau Openbox (Packarch)

Le choix « Openbox » installe `packarch-openbox-settings` (anciennement
`packarch-openbox`, renommé en 7.0-72 comme `packarch-xfce-settings` ;
`replaces`/`provides`) depuis [packarch] (sources :
[myrepo-pkgs](https://github.com/packarch/myrepo-pkgs), licence GPL3) :
polybar, menus rofi, dunst, picom, kitty et 10 thèmes, changés depuis
le menu du bureau. La configuration est reprise de la version GPL3 de la
configuration Openbox d'Aditya Shakya (7.0-9) ; la version premium (licence
DBAD : 15 thèmes de plus et la fonction « Changer les couleurs ») n'est plus
utilisée. Ses dépendances sont aussi dans [packarch] : `packarch-skin`,
`packarch-themes`, `packarch-icons`, `packarch-cursors`, `packarch-fonts`,
`packarch-backgrounds` et les paquets AUR
(`nitrogen`, `xfce-polkit`, `lead-git`, `skippy-xd-git`, `ksuperkey`,
`betterlockscreen`, `networkmanager-dmenu-git`, `light`…). L'ancien
`packarch-openbox-extras` (`packarch-tcma`, `packarch-reload-theme`, icônes de
dunst) est fusionné dans `packarch-openbox-settings` depuis la 7.0-16 (`replaces`) ;
ses illustrations (`/usr/share/packarch/artworks`), utilisées nulle part, sont
supprimées.

**Sélecteur de thèmes `packarch-skin`** (Rust, dépôt
[packarch-skin](https://github.com/packarch/packarch-skin) depuis 1.1.0, à
côté de `packarch-hello` et `packarch-pi` ; paquet construit par
`myrepo-pkgs/apps/packarch-skin` depuis le tag ; sources dans
`myrepo-pkgs/packarch-skin` avant) : chaque thème est un dossier de
`~/.config/openbox/themes` avec ses dispositions (`polybar/`, `rofi/`)
et un `theme.toml` qui le décrit : fond d'écran (`wallpaper =
"/usr/share/backgrounds/…"`, chemin réel au lieu du lien `wallpaper` du
dossier depuis packarch-openbox-settings 7.0-25 ; changer le fond d'un thème = changer
cette ligne), couleurs
(valeurs, références à d'autres couleurs, `lighten()`/`darken()`), rôles des
couleurs dans la barre, rofi et dunst, polices, thèmes GTK/icônes/curseur,
thème et marges d'Openbox, dunst, picom. Il remplace les scripts
`theme.bash`, `apply.sh` (un par thème), `launch-bar.sh`, `polybar.sh`,
`tint2.sh` (tint2 retiré depuis) et `polybar/launch.sh` :

| Commande | Effet |
|---|---|
| `packarch-skin apply [THÈME]` | applique un thème (par défaut le courant) : fichiers de couleurs de polybar et rofi, kitty, Geany, GTK (xfconf, gsettings), `rc.xml` d'Openbox, dunst, picom, fond d'écran (nitrogen), puis relance la barre |
| `packarch-skin render RACINE [THÈME]` | écrit le thème (par défaut `default`) dans les fichiers de `RACINE/etc/skel`, sans rien lancer : xfconf dans `xsettings.xml`, fond dans `nitrogen/bg-saved.cfg`, `color-scheme` dans `RACINE/usr/share/glib-2.0/schemas/25_packarch-openbox.gschema.override` ; utilisé par le PKGBUILD de `packarch-openbox-settings` (1.0.0-9) |
| `packarch-skin bar` | relance les barres polybar du thème courant (`bars` de `[polybar]` dans `theme.toml`, `main` par défaut) ; détecte au premier lancement de polybar la batterie, l'adaptateur, le rétroéclairage et l'interface réseau (`/sys`) |
| `packarch-skin list`, `current`, `wallpaper`, `check` | thèmes, thème courant, fond d'écran, vérification des `theme.toml` |
| `packarch-skin openbox-menu` | menu « Changer de style » d'Openbox |

Les `theme.toml` ont été générés depuis les `theme.bash` : couleurs écrites
identiques à celles d'`apply.sh` (vérifié sur les 15 thèmes), à une
différence près : l'ancien `sed` de `width =` de dunst modifiait aussi
`progress_bar_*_width`, plus maintenant. `PACKARCH_SKIN_DRY=1` affiche les
commandes au lieu de les lancer (tests).

Modifications de la configuration d'origine :
- **noms Packarch** partout : chemins `/usr/share/packarch` (au lieu de
  `/usr/share/archcraft`), commandes `packarch-reload-theme` et `packarch-tcma`
  (réduites à Openbox ; `archcraft-session`, inutilisé, retiré), pipemenus
  `pa-*`, thèmes d'icônes `Packarch(-Dark)`, police d'icônes `packarch`
  (famille renommée dans le fichier). Les mentions d'auteur (Aditya Shakya)
  sont conservées ;
- **thèmes appliqués par `packarch-skin`** (ci-dessus) ;
- **kitty seul terminal** (raccourcis, menus, polybar,
  `networkmanager-dmenu`, obmenu-generator, `ob-music`, `ob-furminal`,
  « Ouvrir un terminal ici » de Thunar) : alacritty et xfce4-terminal ne sont
  plus installés, le menu « Couleurs du terminal » (schémas d'alacritty) est
  retiré, « Changer de police » modifie `~/.config/kitty/fonts.conf`. Super+Entrée
  et Ctrl+Alt+T ouvrent kitty (Super+Maj+Entrée, en double, retiré) ;
- **deux styles de menu seulement**, « Icônes » (par défaut) et « Glyphes » :
  `menu-simple.xml` et `menu-minimal.xml` supprimés, les thèmes qui les
  utilisaient (easy, gray, hack, kiss, rainy, slime) passent à « Glyphes » ;
- **pavé numérique allumé** à l'ouverture de session, comme sous XFCE :
  `keyboards.xml` (`Numlock` à `true`), appliqué par xfsettingsd ;
- **nano au lieu de vim, plus de ranger** : Ctrl+Alt+V ouvre nano dans
  kitty (plus d'entrée nano dans « Applications en root » depuis 7.0-18) ;
  ranger (Ctrl+Alt+R, menu root) retiré ;
- **plus de dock plank** (7.0-29, `packarch-skin` 1.0.0-7) : dépendance
  `plank` retirée, plus de lancement dans l'`autostart`, section `[plank]`
  retirée des 15 `theme.toml` (`packarch-skin` l'ignore encore dans les
  thèmes déjà copiés dans un `~/.config`), lanceurs `~/.config/plank`
  supprimés, règles `Plank` de `picom.conf` et de polywins retirées ; les
  dossiers `plank/` des thèmes GTK de `packarch-themes` (2.0-3) et l'entrée
  `plank.desktop` de `packarch-hide-desktop-entries` (`packarch-system-settings`)
  aussi ;
- **Menu « Glyphes » aligné** : la police des éléments de menu est
  « police du thème,feather » (`rc.xml`, `packarch-skin` 1.0.0-3, menu
  « Changer de police ») : les codes des glyphes existent aussi dans d'autres
  polices d'icônes, de largeurs différentes ; « Favoris Internet » utilise le
  signet de feather au lieu du globe Font Awesome (7.0-19) ;
- **plus de tint2** (retiré en 7.0-15, rétabli en 7.0-21, retiré à nouveau
  en 7.0-30 avec `packarch-skin` 1.0.0-8) : dépendance, dispositions `tint2/`
  des thèmes, scripts `tint2-*`, menu « Panneau / Barre » (`pa-panel`),
  applets prévus pour tint2 (commentés) dans l'`autostart`, règles picom ;
  `packarch-skin bar` ne prend plus d'argument et ignore `themes/.panel` ;
- **icônes StatusNotifierItem dans la zone de notification** (7.0-23) :
  `snixembed` (dépendance, lancé par `autostart` avant la barre) les affiche
  dans la zone XEmbed de polybar, qui ne connaît pas ce protocole
  (applet de `cachy-update`, par exemple) ;
- **kitty pour les applications `Terminal=true`** (7.0-24) : GLib ne connaît
  pas kitty (il essaie xdg-terminal-exec, gnome-terminal, xfce4-terminal,
  konsole, xterm…), donc « Lancer Cachy-Update » de l'applet ne faisait rien.
  Dépendance `xdg-terminal-exec` et `/etc/xdg/xdg-terminals.list`
  (`kitty.desktop`) ;
- **thème `default` personnalisé** (7.0-26, réglé dans la VM) : fond
  `wallpaper-alt.png`, icônes Luna-Antidote-Dark (aussi dans rofi), curseur
  Pear-Dark et thème Openbox OB-Nordic, au lieu de `default.jpg`, Zafiro,
  Qogirr et OB-Arc-Dark (seul son `theme.toml` change) ;
- **droite de la barre du thème `default` réordonnée** (7.0-29), de droite
  à gauche : extinction, heure, zone de notification, volume, réseau
  (bluetooth juste à sa gauche), batterie, luminosité ;
- **barre du thème `adaptive`** (7.0-29) : polywins au centre (sur le fond de
  la barre, `polywins = true` dans son `theme.toml`), modules `cpu`, `memory`
  et `filesystem` retirés à gauche (nouvelle transition `6LD` après
  `openbox`), bouton d'extinction tout à droite, après la zone de
  notification ;
- **bouton d'extinction tout à droite dans le thème `nord`** (7.0-29) :
  module `sysmenu` ajouté (icône rouge, `rofi-powermenu`) ; dans `beach`, mis
  à droite en 7.0-29 puis retiré de la barre en 7.0-30 ;
- **thèmes réglés dans la VM** (7.0-30, avec `vm-themes.sh`) :
  - liste des fenêtres (polywins) au centre de `pink-city`
    (encadrée `LD … RD`) et dans la barre du bas de `yellow-flower` et
    `default` (en haut au centre pour `default`) ; `polywins = true` dans leur
    `theme.toml` (couleurs du thème écrites par `packarch-skin`) ;
  - `adaptive` : marge autour du bouton d'extinction ;
  - icône du bouton d'extinction de `nord`, `beach` et `rainy` : `\uf011` au
    lieu de `\uf924` (ancienne numérotation de Nerd Fonts, absente de la
    police installée : bouton invisible) ;
  - `red` renommé **`pink-city`** (« Pink City ») : icônes `Qogir-Pink-Dark`
    (GTK et rofi, voir `packarch-icons`) ;
  - `slime` renommé **`yellow-flower`** (« Yellow Flower ») : thème GTK
    Juno-Mirage, OB-Juno-Mirage, icônes Luna-Dark, fond `bouquet.jpg`,
    couleurs Ayu Mirage (accent `#ffcc66`), Geany `bouquet.conf`, menu
    Openbox à icônes, boutons de fenêtre `LIMC` (fermer à droite), icônes de
    la barre agrandies (Symbols Nerd Font 15, `packarch` 17) ;
  - seconde barre en bas dans `yellow-flower` et `default` (`bars = ["main",
    "bottom"]`, marge du bas d'Openbox agrandie) : menu d'applications et
    lanceurs Firefox, Thunar, kitty à gauche (clic droit : Gmail dans
    Firefox, Thunar et kitty en root par `ob-asroot`, mot de passe demandé
    par `rofi-askpass`), heure au centre ; volume à droite, et bouton
    d'extinction en bas (`yellow-flower`) ou en haut à droite (`default`) ;
  - `manhattan` renommé **`packarch`** (« Packarch ») : couleurs du fond `packarch-default.jpg` (anthracite,
    jaune Pac-Man `#f8c602`, couleurs des fantômes pour le terminal), icônes
    Luna-Antidote-Dark ; thème GTK **Manhattan modifié** (`packarch-themes`
    2.0-4) : sélections et cases à cocher orange `#f7901e` au lieu du lilas
    `#b4a1db`, CSS et images GTK2 (aussi pour `pink-city`, qui l'utilise ; le thème GTK garde son nom) ;
    barre ajoutée en haut (polywins, bouton d'extinction ; marge du haut
    d'Openbox agrandie), lanceurs au centre de la barre du bas (sans menu
    d'applications), bureaux à gauche, date et heure complètes en haut au
    centre, menu d'extinction rofi en haut à droite ;
  - `hack` renommé **`hacking`** (« Hacking ») : lanceurs dans la barre du bas, réseau et bluetooth à gauche,
    bureaux après le menu (icône seule, sans « Programmes »), polywins au
    centre de la barre du haut (couleurs fixées dans le script,
    `polywins = false` : les rôles de la barre rendaient la fenêtre active la
    plus sombre), boutons réduire et agrandir (`LIMC`) ;
  - `red-satanic` : thème Openbox OB-Kripton, date et heure complètes au
    centre de la barre du bas, sans processeur, mémoire ni disque ;
  - nouveau thème **`pink-sylvanas`** (« Pink Sylvanas ») : copie de `default` (deux
    barres), fond `sylvanas.jpg` (ajouté à `packarch-backgrounds` 2.0-4),
    couleurs du fond (noir violacé `#1a161c`, argent `#c3c5cd`, mauve, rouge
    des yeux `#d0283c` en accent, teal de la gemme), GTK et Openbox
    Catppuccin-Mocha, icônes Luna-Purple-Dark, Geany `catppuccin-mocha.conf` ;
  - nouveau thème **`cyberpunk`** (« Cyberpunk ») : copie de `default` (deux
    barres), thème GTK Sweet-Dark, OB-Sweet-Dark, icônes BeautyLine (`aur/beautyline`,
    dépendance de `packarch-icons`), palette sombre de Sweet (fond
    `#161925`, accent magenta `#c74ded`), fond `cyberpunk1.jpg`, Geany
    `dracula.conf` ;
  - thèmes **`wave`, `gray`, `forest`, `kiss`, `easy`, `rainy`, `nord` et
    `beach` supprimés** ;
- **4 bureaux au lieu de 5** (7.0-30) : `rc.xml` (`<number>`, noms,
  raccourcis Super+5 et Super+Maj+5 retirés) et icône du 5e bureau
  (`icon-4`) retirée du module des bureaux des 11 thèmes, comme les 4
  espaces de travail de XFCE ;
  - nouveau thème **`red-satanic`** (« Red Satanic ») : copie de
    `default` (deux barres), fond `satanic.jpg`, thème GTK `Satanic`,
    thème Openbox `OB-Kripton`, icônes Luna-Red-Dark, couleurs noir et rouge sang (accent
    `#e01b24`, ambre `#e0a030` des yeux du fond), Geany `red-satanic.conf`
    (copie de Black Scheme sur le fond `#131519` des barres de titre
    d'OB-Kripton au lieu du noir) ;
- **détection du matériel corrigée** (`packarch-skin` 1.0.0-8) : les
  renommages `backlight` → `brightness` (rétroéclairage non Intel) et
  `network` → `ethernet` (connexion filaire) ne touchent plus que les noms de
  modules entiers des lignes `modules-…` : remplacés partout, ils modifiaient
  aussi les commentaires, et `backlight-bar` devenait `brightness-bar`, défini
  par aucun thème (barre de `forest`, supprimé depuis, `hack` et `yellow-flower` non
  lancée) ;
- **Zafiro retiré** (`packarch-icons` 2.0-4) : les 12 variantes (environ
  145 Mo), utilisées par aucun thème ; les valeurs initiales de `/etc/skel`
  (`xsettings.xml`, `gtk-3.0/settings.ini`, `.gtkrc-2.0`, `rofi/config.rasi`
  de `packarch-openbox-settings`) passent à Luna-Antidote-Dark (thème `default`) ;
- **`Qogir-Pink-Dark`** (`packarch-icons` 2.0-4) : les icônes de dossiers
  (`places`, 16 à 128 px et `scalable`) de Qogir-Dark (GPL3) recolorées dans
  le rose du fond `tokyo.png` (`#6ba4e7` → `#da6e89`, `#5294e2` → `#d0607f`,
  `#003579` → `#5c1530`), le reste hérité de Qogir-Dark (`Inherits=`) ;
- **liste des fenêtres au centre de la barre du thème `default`** (7.0-27) :
  polywins (`polybar/scripts/polywins.sh`, repris du thème `easy`) affiche les
  fenêtres du bureau courant ; les fenêtres réduites (`_NET_WM_STATE_HIDDEN`)
  sont grisées et entre crochets (couleur `alt_foreground` du thème, écrite
  par `packarch-skin` 1.0.0-5). Clic gauche : activer ou réduire, milieu :
  fermer, droit : redimensionner avec `slop` (ajouté aux dépendances).
  L'horloge passe à droite, avant le bouton d'extinction ; les modules
  `mpd` et `song` sont retirés de ce thème. Le polywins du thème `easy`
  signale aussi les fenêtres réduites (et affiche « Bureau » au lieu de
  « Desktop ») ;
- **pas de module luminosité ni batterie sans le matériel** (7.0-28,
  `packarch-skin` 1.0.0-6) : sans rétroéclairage (`/sys/class/backlight`) ou
  sans batterie de l'ordinateur (`/sys/class/power_supply`, hors souris et
  claviers), les modules `backlight`/`backlight-bar` et `battery` sont retirés
  de la barre au premier lancement du thème, avec leur encadrement `LD`/`RD` et
  le séparateur voisin (`sep`, `sep2`, `dot`, `dot-alt`, `space`), au lieu
  d'être remplacés par un « NA » rouge (modules `bna`, `btna` et `bna-bar`
  supprimés des 15 thèmes). Les transitions du thème `adaptive` (`3RD`…)
  restent, pour garder le dégradé ;
- **plus de module musique dans polybar** (7.0-28, 15 thèmes) : `mpd`,
  `song`, `mpd_bar` et `spotify` (avec `spotify.sh`) retirés des barres et
  des fichiers de modules, de la même façon que la luminosité et la batterie.
  Le bloc central d'`adaptive`, `beach` et `nord` et la gauche de la barre du
  bas de `hack` sont maintenant vides ;
- **mpd retiré** (7.0-28) : plus de dépendances `mpd` et `mpc`, plus de
  lancement de mpd dans l'`autostart`, scripts `rofi-music` (Super+M) et
  `ob-music` (Ctrl+Alt+M, ncmpcpp) supprimés avec leurs raccourcis (et retirés
  de la liste des scripts mis à jour par `packarch-skin`). Les touches
  multimédia (lecture/pause, arrêt, précédent, suivant) passent par
  `playerctl` et pilotent n'importe quel lecteur MPRIS (Firefox, mpv,
  nounours-player…). La mise en veille du menu d'extinction (rofi et menu
  Openbox) ne lance plus `mpc -q pause` : les commandes étant enchaînées
  par `&&`, son échec sans mpd aurait empêché la veille. `.mpd` et
  `.ncmpcpp` ne sont plus dans les dossiers cachés affichés par
  `pa-places`. `xfce4-mpc-plugin` (greffon mpd du panneau XFCE, inutilisé)
  est retiré de `packages_desktop.x86_64` et de `packages_online.conf`.
  Spotify aussi : script `rofi-spotify` (sans raccourci), thèmes rofi
  `music.rasi` des 15 thèmes et icône dunst `music.png`, inutilisée ;
- **horloge en 24 h** dans les 15 thèmes : `%I:%M %p` remplacé par `%H:%M`
  dans les modules `date` de polybar, dates dans
  l'ordre français (`%d %b %Y`, sans le `It's`/`at` anglais), et
  `locale = ${env:LANG:fr_FR.UTF-8}` dans chaque `config.ini` (polybar ignore
  la langue du système sans cette option : jours et mois en anglais) ; même chose
  pour la date du menu « Infos système » (`pa-sysinfo`). L'écran de
  verrouillage reçoit `time_format="%H:%M"` (`/etc/betterlockscreenrc`) ;
- **traduction en français** de ce qui s'affiche : menus Openbox
  (`menu-*.xml`), pipemenus et `menulib/packarch.cfg`
  (`/usr/share/packarch/openbox`), scripts de `~/.config/openbox/scripts`
  (menus rofi, notifications), scripts polybar des thèmes, libellés polybar
  (hors ligne, muet…), textes des thèmes rofi (« Rechercher... », « Mot de
  passe »…), catégories d'obmenu-generator (`schema.pl`), actions
  personnalisées de Thunar (`uca.xml`) et textes de betterlockscreen
  (`/etc/betterlockscreenrc`). Seuls les textes affichés sont traduits : les
  sorties de `bluetoothctl`, `mpc` ou `playerctl` comparées par les scripts,
  les commentaires et les noms de fichiers restent en anglais.
  `networkmanager-dmenu` n'est pas traduit ;
- **Favoris Internet** : section du menu sous « Applications en root »,
  sous-menu `pa-bookmarks` qui lit
  `~/.config/openbox/favoris.txt` : une ligne `Nom:adresse` par favori (coupée
  au premier `:`), `-` pour un séparateur, `#` pour un commentaire ; ouvert
  avec `xdg-open`. « Modifier les favoris » ouvre le fichier (`exo-open`) ;
- `menulib/packarch.cfg` : `shopt -u patsub_replacement`. Depuis bash 5.2, le
  `&` du remplacement de `${var//motif/remplacement}` vaut le texte trouvé :
  `XMLescape` produisait `'apos;` au lieu de `&apos;` (libellés et commandes
  des sous-menus contenant `'`, `"`, `<` ou `>` cassés) ;
- **thème `default` déjà appliqué dans `/etc/skel`** (`packarch-openbox-settings`
  7.0-32) : le PKGBUILD lance `packarch-skin render "$pkgdir" default`
  (`makedepends`, installé puis retiré par `build.sh`, qui construit
  `packarch-skin` en premier). La première session démarre directement avec
  le thème, sans `packarch-skin apply` au premier login (plus d'attente de
  2 s, de notification, ni de relance de la barre, de dunst et d'Openbox).
  `theme.toml` reste la seule source : les fichiers de `files/etc/skel` ne
  sont pas modifiés à la main. L'adaptation de la barre au matériel reste
  faite au premier lancement de polybar (`packarch-skin bar`) ;
- `autostart` : au premier login, seul `betterlockscreen` prépare, en
  arrière-plan, les images du fond d'écran du thème ; le fichier
  `~/.config/openbox/themes/.applied` évite de le refaire ;
- `autostart` : ne lance plus `xfce-polkit`, déjà démarré par l'autostart XDG
  (`/etc/xdg/autostart/xfce-polkit.desktop`, via `openbox-xdg-autostart`) ;
  deux instances donnaient « An authentication agent already exists » ;
- fichiers XML de xfconf et Thunar : le commentaire de copyright placé avant
  la déclaration XML est retiré ;
- **polices globales** (`packarch-skin` 1.0.0-11, `packarch-openbox-settings`
  7.0-38) : `~/.config/openbox/themes/fonts.toml` (clés de la section
  `[fonts]`, toutes optionnelles) remplace les polices de chaque thème, qui
  ne changent donc plus avec le thème. `packarch-skin font [CIBLE [FAMILLE
  STYLE TAILLE]]` les affiche ou les enregistre et ne recharge que le
  programme concerné ; pour GTK, le démon Thunar est relancé, car il ne lit
  la police qu'au démarrage. Le menu Préférences › Changer de police
  (`pa-change-fonts`) n'est plus que le sélecteur yad, ouvert sur la police
  en place ;
- **DPI des polices fixé à 96** (7.0-41) : `/etc/skel/.Xresources`
  (`Xft.dpi: 96`, fusionné par LightDM avant la session) et `/Xft/DPI` à 96
  dans `xsettings.xml`. Avec le pilote NVIDIA (`UseEdidDpi`), X démarrait à
  environ 70 DPI, qu'Openbox lit à son démarrage : ses polices étaient d'un
  quart plus petites que celles des applications GTK ;
- **Openbox en Noto Sans 10** dans les dix thèmes (7.0-40, au lieu de
  JetBrains Mono 12, police à chasse fixe bien plus large) ; dépendance
  `noto-fonts` (7.0-39) ;
- **rôle `fastfetch`** dans les `[roles]` de `theme.toml` (`packarch-skin`
  1.0.0-12) : couleur du logo, du titre et des libellés de fastfetch, écrite
  dans `~/.config/fastfetch/config.jsonc` avec la liste des modules par
  défaut (un fichier sans `modules` n'affiche rien). La première ligne du
  fichier le marque comme écrit par packarch-skin : un fichier sans elle
  appartient à l'utilisateur et n'est pas modifié. Avec un thème sans ce
  rôle, le fichier est supprimé. `red-satanic` : `fastfetch = "color3"`, et
  son vert du terminal (`color2`, `color10`) devient jaune (7.0-43) ;
- **un thème GTK et un thème Openbox par thème** (`packarch-themes-openbox`
  2.0-5 et 2.0-6, fusionné dans `packarch-themes` 2.0-7, `packarch-openbox-settings` 7.0-44) : `Packarch-<Thème>` et
  `OB-Packarch-<Thème>`, pour qu'une modification ne touche qu'un thème
  (Manhattan était partagé par `packarch` et `pink-city`). Les originaux ont
  été renommés (Satanic, OB-Kripton, Manhattan, Sweet-Dark…) ; Arc-Dark et
  Juno-Mirage, qui servent aussi au bureau XFCE, restent dans
  `packarch-themes` et ont été copiés. La correspondance est dans le
  PKGBUILD de `packarch-themes`. Les autres thèmes GTK et Openbox,
  utilisés par aucun thème, ont été retirés avec la dépendance
  `sweet-gtk-theme` (193 Mo de thèmes ramenés à 59 Mo). Couleurs modifiées
  pour `red-satanic` : accent orange `#f7901e` en GTK au lieu du gris bleuté
  `#9bbfbf`, et rouge `#d7263d` en Openbox ;
- **plus de `packarch-themes`** (7.0-45) : ses thèmes GTK ne servaient qu'au
  bureau XFCE. L'écran de connexion, commun aux deux bureaux, a son propre
  thème `Packarch-Greeter` (`packarch-system-settings` 1.0-4), et
  `packarch-themes` sort du groupe commun de `packages_online.conf`. Depuis
  7.0-72, `packarch-themes` (2.0-7) contient les thèmes de `packarch-skin`
  et redevient une dépendance, à la place de `packarch-themes-openbox` ;
- pas de script `.install` : Calamares copie lui-même `/etc/skel`.

`calamares-online.sh` (lancé par Packarch Hello) garde le rafraîchissement du
trousseau de clés, mais **ne réinstalle plus `cachyos-calamares-next` depuis le
dépôt CachyOS** au lancement, ce qui remplacerait notre version. Il écrit
aussi la sortie de Calamares dans `/home/liveuser/cachy-install.log`.

### Écran de bienvenue : Packarch Hello

CachyOS Hello est remplacé par **Packarch Hello** (paquet `packarch-hello`
du dépôt `[packarch]`, sources sur
[GitHub](https://github.com/packarch/packarch-hello)), un fork de
CachyOS Hello 0.28.1 : nom, logo, textes et liens de Packarch, sans forum,
dons, Discord ni Reddit, sans le code propre à KDE, en anglais et en
français seulement. Son bouton d'installation lance toujours
`calamares-online.sh`, après avoir vérifié seulement la connexion Internet :
plus de comparaison de la version de l'ISO avec `cachyos.org/versions.json`
(qui ne connaît que les ISO CachyOS), ni de test d'édition (Packarch n'a que
l'édition de bureau). Le paquet est en conflit avec `cachyos-hello`. Sur un
système déjà installé, `pacman -Syu` ne propose pas l'échange malgré le
`replaces` : pacman s'arrête au premier dépôt qui contient `cachyos-hello`, et
`[cachyos]` est lu avant `[packarch]`. Il faut lancer
`sudo pacman -S packarch-hello`, qui retire `cachyos-hello`. Il est dans
`packages_desktop.x86_64`, dans les outils CachyOS de
`packages_online.conf`, et dans la liste des paquets gardés de
`removeun-online`.

### Installateur de paquets : Packarch Installer

CachyOS Package Installer (`cachyos-packageinstaller`) est remplacé par
**Packarch Installer** (paquet `packarch-pi` du dépôt
`[packarch]`, sources sur
[GitHub](https://github.com/packarch/packarch-pi)), un fork de la version
1.6.2 : interface en français seulement, onglet Flatpak affiché par défaut.
La liste « Applications populaires » (`pkglist.yaml`) est téléchargée depuis
le dépôt GitHub de Packarch au lieu de celui de CachyOS : la modifier là-bas
suffit, sans reconstruire l'ISO ni le paquet. Packarch Hello (1.2.0 et
suivantes) lance `packarch-pi`. Comme `cachyos-packageinstaller`, il n'est
que dans les outils CachyOS de `packages_online.conf` (le
système installé), pas dans le système live. Les deux paquets peuvent
coexister : sur un système déjà installé, `sudo pacman -S packarch-pi`
l'ajoute, et `cachyos-packageinstaller` peut être retiré à la main.

### Installation hors ligne (conservée, non utilisée)

`settings_offline.conf` copie le système live au lieu de télécharger les
paquets. Il a été corrigé et reste disponible :

- `shellprocess@cleanup_live` lance `/usr/local/bin/cleanup-live-iso` juste
  après la copie : retire les réglages du live (accès `sudo`/polkit sans mot de
  passe, connexion automatique de `tty1`, connexion root SSH, hooks archiso de
  l'initramfs, services du live), copie les noyaux dans `/boot`, initialise le
  trousseau pacman ;
- `netinstall@offline` : les mêmes cases à cocher et catégories (sans Système), installées si Internet est
  disponible (test de connexion ajouté à `welcome.conf`, non bloquant ;
  `update_db: true` dans `packages_offline.conf`) ;
- `grubcfg` ajouté ; GRUB par défaut (Limine n'est pas sur l'ISO).

### Corrections du code (`live-offline.patch`)

- `bootloader/main.py` et `grubcfg/main.py` : sans page de choix du chargeur,
  utilisent GRUB au lieu de ne rien installer.
- `users.conf` (configuration) : shell de l'utilisateur créé `/bin/zsh` au
  lieu de `/bin/bash`.
- `src/scripts/shell-setup` : choisit zsh avant fish (`chsh` à la fin de
  l'installation, après `users.conf`), pour garder le shell du live.
- `pacstrap/main.py` : installe `linux-cachyos` et ses en-têtes seulement,
  sans `linux-cachyos-lts` (ni `linux-cachyos-lts-zfs` sur ZFS), que le module
  ajoutait d'office.
- `shellprocess.conf` (configuration) : `~/.xprofile` n'est plus supprimé du dossier de
  l'utilisateur (nécessaire au fond d'écran), et `cachyos-calamares-next` est
  désinstallé à la toute fin (installation hors ligne).
- `bootloader/main.py` : entrée Limine nommée d'après le thème (`/+Packarch`),
  avec son `machine-id` dessous (voir [Nom : Packarch](#modifications-par-rapport-à-liso-officielle-cachyos)).
- `chwd/main.py` : « Installing needed drivers... » au lieu de « … for
  CachyOS... » (message sans traduction française).

### Thème Packarch

Le thème (`branding`) de Calamares est `packarch`, dans
`archiso/airootfs/etc/calamares/branding/packarch/` (Calamares cherche les
thèmes dans `/etc/calamares/branding/`, pas dans `/etc/xdg`), sélectionné par
`branding: packarch` dans `settings_online.conf` et `settings_offline.conf`.
Il reprend la disposition du thème `cachyos` (barre des étapes en bas,
`calamares-sidebar.qml` et `stylesheet.qss` inchangés), avec :

- l'icône Pac-Man `packarch.png` de Packarch (`logo.png` 64 px, `icon.png`
  128 px, `packarch.png` 512 px pour le diaporama), et une image d'accueil
  `welcome.png` (icône et nom) ; c'est la même que `/usr/share/pixmaps/packarch.png`
  de `packarch-system-settings` 1.0-8 (avatar par défaut de LightDM, logo de
  fastfetch dans kitty) ;
- les couleurs du logo : barre `#1c2027`, étape en cours `#62aeef` ;
- un diaporama `show.qml` en français dessiné en QML (pas d'images à
  traduire), six pages : Packarch, les deux bureaux, le sélecteur de thèmes,
  la base CachyOS, Packarch Hello et Packarch Installer, l'aide ;
- `bootloaderEntryName: Packarch` (`GRUB_DISTRIBUTOR` du système installé) et
  un bouton « Assistance » vers les issues GitHub ; pas de serveur d'envoi des
  journaux (celui de CachyOS est retiré).

Le thème `cachyos` reste installé par le paquet mais n'est plus utilisé.
`removeun` (mode hors ligne) supprime le thème du système installé.

### `removeun` (script d'origine, mode hors ligne)

`boost-libs`, `yaml-cpp` et `squashfs-tools` retirés de sa liste : il les
désinstallait avec `pacman -Rsnc` (cascade), ce qui supprimait Calamares en
pleine installation. `clonezilla` retiré aussi (plus sur l'ISO), et sans carte
NVIDIA il retire `linux-cachyos-nvidia-open` au lieu de
`linux-cachyos-lts-nvidia-open`.

### Mettre à jour Calamares

Quand CachyOS publie une nouvelle version :

```bash
git clone -b cachyos-dev https://github.com/CachyOS/cachyos-calamares calamares-src
cd calamares-src
git apply ../calamares/live-offline.patch     # corriger les conflits éventuels
git add -A && git commit -m "Code changes for the XFCE live ISO"
git format-patch -1 --stdout > ../calamares/live-offline.patch
git rev-parse HEAD~1                          # nouveau commit de base
```

Puis, dans `calamares/PKGBUILD`, mettre à jour `_commit` (et `pkgver`/`pkgrel`
d'après le PKGBUILD de CachyOS), et relancer `./build.sh`. Comparer aussi les
fichiers de configuration de CachyOS (`settings_online.conf` et ceux de
`src/modules/` que nous remplaçons) avec ceux de
`archiso/airootfs/etc/xdg/calamares/`, pour reporter leurs changements.

---

## 7. Liste des fichiers modifiés ou ajoutés

Hors fichiers générés à chaque build (`etc/motd`, `etc/environment`,
`etc/version-tag`, `etc/edition-tag`, `etc/pacman.d/cachyos-mirrorlist`,
`etc/systemd/system/display-manager.service`,
`etc/systemd/system/cachyos-rate-mirrors.timer`, `archiso/packages.x86_64`).

| Fichier | État |
|---|---|
| `MODIFS.md` | ajouté (ce document) |
| `build.sh` | ajouté (reconstruction complète ; vérifie d'abord les paquets prérequis) |
| `run.sh` | ajouté (test dans QEMU, live ou système installé ; vérifie d'abord QEMU et OVMF) |
| `buildiso.sh`, `util*.sh` | déplacés dans `scripts/` ; `buildiso.sh` trouve la racine du dépôt depuis son emplacement, et son piège `EXIT` n'affiche plus « An unknown error has occurred » quand le build réussit |
| `scripts/util-iso.sh` | LightDM ; dépôt local Calamares |
| `scripts/makepkg-generic.conf` | ajouté (compilation en x86-64 générique) |
| `reset.sh`, `.gitignore` | ajoutés (nettoyage du projet) |
| `testiso.sh`, `ci.build.sh`, `lddd.sh`, `machines/`, `testcases/` | supprimés |
| `calamares/PKGBUILD`, `calamares/live-offline.patch`, `calamares/build.sh` | ajoutés |
| `archiso/airootfs/etc/xdg/calamares/` | ajouté (configuration de Calamares, lue avec `calamares -X`) |
| `archiso/airootfs/etc/calamares/branding/packarch/` | ajouté (thème Packarch de Calamares) |
| `localrepo/` | généré par `calamares/build.sh` |
| `archiso/packages_desktop.x86_64` | KDE → XFCE et applications, `cachyos-zsh-config`, `packarch-hello` au lieu de `cachyos-hello`, sans noyau LTS ni outils de secours |
| `archiso/grub/`, `archiso/syslinux/`, `archiso/efiboot/`, `airootfs/etc/mkinitcpio.d/linux.preset` | `linux-cachyos` seul |
| `archiso/airootfs/etc/passwd` | zsh pour `root` et `liveuser` |
| `archiso/airootfs/root/.zshrc` | ajouté (configuration zsh CachyOS pour root) |
| `archiso/profiledef.sh` | permissions 755 de `cleanup-live-iso`, `apply-live-config`, `live-fit-display`, `github-setup` |
| `archiso/airootfs/etc/locale.conf`, `locale.gen`, `vconsole.conf`, `localtime`, `X11/xorg.conf.d/00-keyboard.conf` | français, `Europe/Paris` |
| `archiso/airootfs/etc/lightdm/lightdm.conf.d/50-packarch-live.conf` | ajouté (connexion automatique) |
| `archiso/airootfs/etc/pacman.d/hooks/40-packarch-live-locale-gen.hook` | ajouté |
| `archiso/airootfs/etc/pacman.d/hooks/80-live-xfce-skel.hook` et `.sh` | ajoutés (bouton du live ; `80-cachyos-live-xfce-skel` jusqu'au 2026-10-24) |
| `archiso/airootfs/etc/pacman.d/hooks/90-cachyos-live-kwin-keyboard.hook` | supprimé |
| `archiso/airootfs/etc/plasmalogin.conf`, `plasmalogin.conf.d/` | supprimés |
| `archiso/airootfs/etc/skel/.config/` (réglages KDE) | supprimés |
| `archiso/airootfs/etc/skel/.config/xfce4/panel/launcher-31/`, `geany/`, `.bashrc`, `.bash_profile` | ajoutés (le reste des réglages XFCE et le sélecteur de thèmes sont dans `packarch-xfce-settings`) |
| `archiso/pacman.conf` | dépôt `[packarch]` (build) |
| `archiso/airootfs/etc/pacman.conf`, `etc/pacman-more.conf` | dépôt `[packarch]` ; `CheckSpace` activé (vérifie la place disque avant d'installer, comme Arch ; commenté dans la configuration de CachyOS) |
| `archiso/airootfs/etc/pacman.d/packarch-mirrorlist` | ajouté |
| `archiso/airootfs/usr/local/bin/calamares-online.sh` | modifié |
| `archiso/airootfs/usr/local/bin/apply-live-config` | ajouté |
| `archiso/airootfs/usr/local/bin/live-fit-display` | ajouté (bouton du live) |
| `archiso/airootfs/usr/local/bin/github-setup` | ajouté (configuration de GitHub au premier login) |
| `archiso/airootfs/usr/share/github-setup/` | ajouté (archive chiffrée, entrée autostart) |
| `archiso/airootfs/usr/local/bin/cleanup-live-iso` | ajouté |
| `archiso/airootfs/usr/local/bin/removeun` | modifié |
| `archiso/airootfs/usr/local/bin/removeun-online` | modifié (garde `packarch-hello` au lieu de `cachyos-hello`) |

---

## 8. Points connus

- **Build à cheval sur minuit** : le renommage final échoue (`mv: cannot stat
  …`), car `scripts/buildiso.sh` cherche un fichier daté du jour de fin. L'ISO est
  quand même produite sous le nom `out/desktop/packarch-AAAA.MM.JJ-x86_64.iso`
  (date de début). Défaut du script d'origine, non corrigé.
- **Installation en ligne** : nécessite Internet (Packarch Hello le vérifie avant
  de lancer l'installeur). Elle télécharge tout le système (environ 3 Go).
- **`vim`** reste installé (dépendance de `cachyos-zsh-config`).
- **Bureau Openbox** : l'ISO grossit d'environ 130 Mo (dépôt local). Les
  paquets `-git` (`lead-git`, `skippy-xd-git`, `networkmanager-dmenu-git`)
  prennent la version du jour de leur compilation. Les captures d'écran de la
  page « Bureau » sont celles de CachyOS (`/etc/calamares/images/xfce.jxl`,
  `openbox.jxl`).
- **Mise à jour de Calamares** : notre version ne suit pas automatiquement
  celle de CachyOS (voir [Mettre à jour Calamares](#mettre-à-jour-calamares)).

