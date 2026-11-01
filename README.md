# Packarch — ISO live XFCE en français, dérivée de CachyOS

Dérivé de [cachyos-live-iso](https://github.com/cachyos/cachyos-live-iso), ce
dépôt construit l'ISO live de **Packarch**, distribution dérivée de [CachyOS](https://cachyos.org), qui démarre sur
**XFCE, en français**, et dont l'installeur Calamares installe, **en ligne et
à jour**, au choix **ce même bureau XFCE** ou **le bureau Openbox
de Packarch**.

Le détail de chaque modification par rapport à l'ISO officielle est dans
[`MODIFS.md`](MODIFS.md).

## Ce que contient l'ISO

- **Bureau XFCE** à la place de KDE Plasma, avec la configuration
  `packarch-xfce-settings` (`cachyos-xfce-settings` ajustée, dépôt Packarch) :
  LightDM, pas de mise en veille ni de verrouillage, pavé numérique activé,
  curseur `Qogir-Dark`.
- **Français partout** : langue `fr_FR.UTF-8`, clavier `fr` (console et X),
  fuseau `Europe/Paris`.
- **Sélecteur de thèmes** dans le tableau de bord : 7 thèmes (`default`,
  `blue`, `gray`, `green`, `purple`, `red`, `yellow`) qui changent d'un clic le
  fond d'écran, le thème GTK, les bordures, les icônes et les couleurs du
  terminal. Les thèmes viennent du dépôt
  [Packarch](https://github.com/packarch/myrepo) de l'auteur.
- **zsh** comme shell par défaut, avec `cachyos-zsh-config` (oh-my-zsh,
  autosuggestions, coloration syntaxique) et une configuration
  **powerlevel10k** prête à l'emploi : pas d'assistant au premier terminal.
- **Applications** : Firefox, Geany (préconfiguré), Meld, htop, catfish, et
  les logiciels de l'auteur : Cryptyrust, LilouCalc, Nounours Player (seul
  lecteur vidéo ; SMPlayer reste proposé dans Packarch Installer),
  packarch-rmatrix.
- **Calamares recompilé** (dossier `calamares/`) :
  - page **« Bureau »** : installation **en ligne** du XFCE du live, avec ses
    réglages et ses thèmes, ou du **bureau Openbox de Packarch** (polybar
    rofi, dunst, 10 thèmes), suivie d'un `pacman -Syu` ;
  - logiciels optionnels à cocher : LibreOffice, GIMP, Steam, Discord,
    FileZilla, KeePassXC, Rust, Qt Creator, impression, accessibilité ;
  - `sudo` sans mot de passe pour le groupe `wheel` sur le système installé ;
  - le mode hors ligne (copie du live) est conservé mais n'est pas utilisé.

## Construire l'ISO

### Prérequis

Un système CachyOS ou Arch Linux avec les dépôts CachyOS configurés :

```bash
sudo pacman -S --needed archiso mkinitcpio-archiso squashfs-tools grub git base-devel
```

Les dépendances de compilation de Calamares (Qt 6, bibliothèques KDE, boost…)
sont installées automatiquement par `makepkg` à la première compilation.

### Construction

En **utilisateur normal** (le mot de passe `sudo` n'est demandé que pour
l'étape de l'ISO) :

```bash
git clone https://github.com/packarch/CachyOS-Packarch.git
cd CachyOS-Packarch
./build.sh
```

`build.sh` enchaîne :

1. `calamares/build.sh` : compile Calamares et le place dans le dépôt local
   `localrepo/`, sauf si cette version y est déjà (monter `pkgrel` après
   chaque modification du patch ; `./build.sh -f` force la recompilation) ;
2. `sudo scripts/buildiso.sh -p desktop -w` : construit l'ISO.

Le bureau Openbox (`packarch-openbox-settings`, `packarch-skin`), les thèmes, icônes et
fonds d'écran viennent du dépôt [packarch]
([myrepo-pkgs](https://github.com/packarch/myrepo-pkgs)) : le publier avant
de construire l'ISO.

L'ISO est produite dans `out/desktop/`, avec ses sommes de contrôle et la
liste de ses paquets.

| Option | Effet |
|---|---|
| `-v` | journal détaillé |
| `-c` | ne pas vider le dossier de travail `build/` avant |
| `-r` | construire en RAM (plus de 23 Go de RAM) |

> Le message `ERROR: An unknown error has occurred` affiché à la fin d'un build
> réussi vient du script d'origine : le code de sortie est bien 0.

## Tester dans une machine virtuelle

`run.sh` démarre une VM QEMU/KVM en UEFI :

```bash
sudo pacman -S --needed qemu-desktop edk2-ovmf virt-viewer

./run.sh                   # live (ISO la plus récente de out/)
./run.sh -i                # système installé sur le disque virtuel
./run.sh --iso FICHIER     # live d'une ISO précise
```

Le disque virtuel (30 Go) et les variables UEFI sont conservés dans
`vm-test/` d'un lancement à l'autre. L'affichage passe par SPICE, dans
`remote-viewer` (`virt-viewer`) : le copier-coller fonctionne entre l'hôte et
la VM, et la résolution de la VM suit la taille de la fenêtre (agent
`spice-vdagent` de l'ISO). Le bouton « Ajuster la résolution » du live reste
utile si l'agent n'a pas encore démarré.

L'installation en ligne demande une connexion Internet et télécharge environ
3 Go.

Le port 2222 de l'hôte mène au SSH de la VM (à activer dans la VM :
`sudo systemctl enable --now sshd` puis `sudo ufw allow ssh`) :
`ssh -p 2222 UTILISATEUR@127.0.0.1`.

## Nettoyer le projet

```bash
./reset.sh        # demande confirmation (-y : sans confirmation)
./reset.sh -k     # garde la machine virtuelle (vm-test/)
```

Supprime tout ce que `build.sh` et `run.sh` génèrent (ISO, dépôt local,
compilation de Calamares, VM…) et remet la date de l'ISO à `AAMMJJ` dans
`archiso/grub/grub.cfg` ; `.gitignore` exclut les mêmes chemins.

## Organisation du dépôt

| Chemin | Contenu |
|---|---|
| `build.sh`, `run.sh`, `reset.sh` | construire, tester, nettoyer |
| `archiso/` | profil archiso : listes de paquets, `pacman.conf`, chargeurs de démarrage |
| `archiso/airootfs/` | fichiers ajoutés au live : réglages non empaquetés (`etc/skel`), configuration de Calamares (`etc/xdg/calamares`), scripts de l'installeur (`usr/local/bin`) ; les réglages XFCE et le sélecteur de thèmes viennent de `packarch-xfce-settings`, les réglages communs de `packarch-system-settings` |
| `calamares/` | `PKGBUILD` de `cachyos-calamares-next` et `live-offline.patch` (modifications du code) |
| `scripts/` | machinerie de build d'origine de CachyOS (`buildiso.sh`…) |
| `MODIFS.md` | documentation complète des modifications |

Pour modifier l'installation (paquets installés, étapes de Calamares), éditer
`archiso/airootfs/etc/xdg/calamares/` et reconstruire l'ISO, sans recompiler
Calamares (voir la section « Installeur Calamares » de [`MODIFS.md`](MODIFS.md)).
Après chaque changement de `live-offline.patch`, incrémenter `pkgrel` dans
`calamares/PKGBUILD`, sinon pacman réutilise l'ancien paquet de son cache.

## Licence

GPL-3.0, comme le projet d'origine : voir [`LICENSE`](LICENSE).
