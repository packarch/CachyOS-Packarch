#!/usr/bin/env bash
#
# Échange les thèmes Openbox (~/.config/openbox/themes) entre les sources de
# packarch-openbox-settings (../myrepo-pkgs) et la VM lancée par ./run.sh -i, par SSH
# (port 2222 de l'hôte).
#
# Usage : ./vm-themes.sh setup UTILISATEUR   une fois par installation
#         ./vm-themes.sh push [THÈME]        sources → VM, puis applique THÈME
#                                            (par défaut le thème courant)
#         ./vm-themes.sh pull                VM → vm-test/themes, puis affiche
#                                            ce qui a changé dans la VM
#         ./vm-themes.sh ssh [COMMANDE]      shell ou commande dans la VM
#
# setup : avant, dans la VM, `sudo systemctl enable --now sshd` et
# `sudo ufw allow ssh` (le pare-feu bloque sinon la connexion) ; à lancer dans
# un vrai terminal (et non avec le ! de Claude Code, sans terminal pour le
# mot de passe). Copie la clé SSH de l'hôte (mot de passe de l'utilisateur
# de la VM demandé une fois) et retient
# l'utilisateur dans vm-test/ssh-user, puis fait un premier pull.
#
# push remplace chaque dossier de thème de la VM par celui des sources (les
# fichiers propres à la VM restent : .current, .panel, .applied, .system,
# system.ini) et supprime leur marqueur polybar/.module : packarch-skin
# refait la détection du matériel au lancement de la barre. Ensuite il
# enregistre l'état de la VM comme référence (vm-test/themes-base).
#
# pull compare la VM à cette référence : seules les modifications faites dans
# la VM depuis le dernier push (ou setup) sont affichées. Les fichiers
# régénérés par packarch-skin (colors.ini, colors.rasi) sont ignorés : les
# couleurs se changent dans theme.toml.

set -euo pipefail

src_dir=$(dirname "$(readlink -f "$0")")
vm_dir="${src_dir}/vm-test"
themes_src="$(readlink -f "${src_dir}/../myrepo-pkgs")/packarch-openbox-settings/files/etc/skel/.config/openbox/themes"
user_file="${vm_dir}/ssh-user"
pulled="${vm_dir}/themes"
base="${vm_dir}/themes-base"
vm_themes='.config/openbox/themes'

# La clé d'hôte change à chaque réinstallation : pas de known_hosts
ssh_opts=(-p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
          -o LogLevel=ERROR)

usage() {
    sed -n '6,13s/^# \{0,1\}//p' "$0"
    exit "$1"
}

vm_user() {
    [[ -f ${user_file} ]] || { echo "Lancer d'abord ./vm-themes.sh setup UTILISATEUR" >&2; exit 1; }
    cat "${user_file}"
}

vm() {
    ssh "${ssh_opts[@]}" "$(vm_user)@127.0.0.1" "$@"
}

# Copie des thèmes de la VM dans le dossier $1
fetch() {
    rm -rf "$1"
    mkdir -p "$1"
    vm "tar -C ${vm_themes} -c ." | tar -C "$1" -x
}

# Session graphique de la VM, pour packarch-skin (xfconf, gsettings, barre) :
# tout l'environnement d'openbox, sinon la barre relancée hérite de celui de
# SSH (PATH sans ~/.config/openbox/scripts : rofi-powermenu introuvable...)
session_env='export DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
ob=$(pgrep -xo -u "$(id -u)" openbox) &&
    while IFS= read -r -d "" v; do export "$v"; done < /proc/$ob/environ'

case "${1:-}" in
    setup)
        user="${2:?setup demande le nom de l utilisateur de la VM}"
        [[ -f ~/.ssh/id_ed25519.pub ]] || ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
        ssh-copy-id "${ssh_opts[@]}" -i ~/.ssh/id_ed25519.pub "${user}@127.0.0.1"
        mkdir -p "${vm_dir}"
        echo "${user}" > "${user_file}"
        fetch "${base}"
        fetch "${pulled}"
        echo "Prêt : thèmes de la VM enregistrés comme référence (${base})."
        ;;
    push)
        theme="${2:-}"
        names=()
        for d in "${themes_src}"/*/; do names+=("$(basename "${d}")"); done
        vm "cd ${vm_themes} && rm -rf ${names[*]}"
        tar -C "${themes_src}" -c "${names[@]}" | vm "tar -C ${vm_themes} -x"
        # Le shell de connexion peut être zsh : bash pour les motifs et $?
        apply="${session_env}
            rm -f ${vm_themes}/*/polybar/.module
            packarch-skin apply ${theme} </dev/null >/tmp/vm-themes.log 2>&1
            rc=\$?; cat /tmp/vm-themes.log; exit \$rc"
        vm "bash -c $(printf '%q' "${apply}")"
        fetch "${base}"
        fetch "${pulled}"
        echo "Thèmes envoyés et appliqués ($(vm "cat ${vm_themes}/.current"))."
        ;;
    pull)
        [[ -d ${base} ]] || { echo "Pas de référence : lancer setup ou push" >&2; exit 1; }
        fetch "${pulled}"
        echo "Thème courant : $(cat "${pulled}/.current" 2>/dev/null || echo default)"
        if (cd "${vm_dir}" && diff -ru -x colors.ini -x colors.rasi -x .applied \
                "$(basename "${base}")" "$(basename "${pulled}")"); then
            echo "Aucune modification dans la VM depuis la référence."
        fi
        ;;
    ssh)
        shift
        if (( $# )); then vm "bash -c $(printf '%q' "${session_env}; $*")"; else ssh -t "${ssh_opts[@]}" "$(vm_user)@127.0.0.1"; fi
        ;;
    -h|--help) usage 0 ;;
    *) usage 1 ;;
esac
