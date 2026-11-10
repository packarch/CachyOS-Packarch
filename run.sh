#!/usr/bin/env bash
#
# Démarre une machine virtuelle QEMU (UEFI, KVM) sur le live ou sur le
# système installé avec Calamares.
#
# Usage : ./run.sh                    live (ISO la plus récente de out/)
#         ./run.sh -i | --installe    système installé sur le disque virtuel
#         ./run.sh --iso FICHIER      live d'une ISO précise
#         ./run.sh --cpu MODELE ...   modèle de processeur (défaut : Nehalem)
#         ./run.sh -a | --attache ... QEMU reste attaché au terminal
#
# QEMU est détaché du terminal (setsid) : on peut fermer celui-ci, la VM
# continue. Ses messages vont dans vm-test/qemu.log ; -a le garde attaché
# (messages dans le terminal, Ctrl+C l'arrête), comme avant.
#
# Le disque virtuel (vm-test/disque.qcow2, 30 Go, créé s'il manque) et les
# variables UEFI (vm-test/OVMF_VARS.fd) sont conservés entre deux lancements.
#
# Processeur : Nehalem (niveau x86-64-v2, sans AVX) par défaut, pour tester
# comme sur un ordinateur quelconque : avec -cpu host, l'installateur choisit
# les dépôts du processeur de l'hôte (znver4) et un binaire qui exige AVX-512
# passe inaperçu. --cpu host redonne le processeur de l'hôte. Un système
# installé avec un processeur donné ne démarre pas sur un modèle de niveau
# inférieur : garder le même --cpu avec -i que pendant l'installation.
#
# SSH : le port 2222 de l'hôte (127.0.0.1 seulement) mène au port 22 de la
# VM (à activer dans la VM : sudo systemctl enable --now sshd, puis
# sudo ufw allow ssh), par exemple : ssh -p 2222 UTILISATEUR@127.0.0.1
#
# Affichage : SPICE dans remote-viewer (paquet virt-viewer, ouvert par QEMU :
# -display spice-app), virtio-vga sans accélération GL (virtio-vga-gl donne un
# écran noir avec NVIDIA), 1600x900 au démarrage. Le canal de l'agent SPICE,
# relayé dans la VM par spice-vdagent (sur l'ISO), partage le presse-papiers
# (copier-coller dans les deux sens) et adapte la résolution de la VM à la
# taille de la fenêtre. La fenêtre GTK de QEMU (-display gtk), avec son canal
# qemu-vdagent, ne transmettait pas le presse-papiers.

set -euo pipefail

src_dir=$(dirname "$(readlink -f "$0")")
vm_dir="${src_dir}/vm-test"
disk="${vm_dir}/disque.qcow2"
disk_size=30G
ovmf_code=/usr/share/edk2/x64/OVMF_CODE.4m.fd
ovmf_vars_tpl=/usr/share/edk2/x64/OVMF_VARS.4m.fd
ovmf_vars="${vm_dir}/OVMF_VARS.fd"

usage() {
    sed -n '3,15s/^# \{0,1\}//p' "$0"
    exit "$1"
}

mode=live
iso=""
cpu=Nehalem
attach=false
while (( $# )); do
    case "$1" in
        -i|--installe) mode=installe ;;
        -a|--attache) attach=true ;;
        --iso) iso="${2:?--iso demande un fichier}"; shift ;;
        --cpu) cpu="${2:?--cpu demande un modèle (qemu-system-x86_64 -cpu help)}"; shift ;;
        -h|--help) usage 0 ;;
        *) usage 1 ;;
    esac
    shift
done

# Prérequis (README) : qemu-desktop, edk2-ovmf et virt-viewer (remote-viewer)
if ! command -v qemu-system-x86_64 &>/dev/null || ! command -v qemu-img &>/dev/null ||
    ! command -v remote-viewer &>/dev/null || [[ ! -f ${ovmf_code} ]]; then
    echo "QEMU, OVMF ou remote-viewer manquant :" >&2
    echo "  sudo pacman -S --needed qemu-desktop edk2-ovmf virt-viewer" >&2
    exit 1
fi

mkdir -p "${vm_dir}"
log="${vm_dir}/qemu.log"

# Une VM tourne déjà sur ce disque (QEMU refuserait de l'ouvrir)
if pid=$(pgrep -f -- "file=${disk}," | head -1) && [[ -n ${pid} ]]; then
    echo "Une VM utilise déjà ${disk} (QEMU, PID ${pid})." >&2
    exit 1
fi
[[ -f "${disk}" ]] || qemu-img create -f qcow2 "${disk}" "${disk_size}"
[[ -f "${ovmf_vars}" ]] || cp "${ovmf_vars_tpl}" "${ovmf_vars}"

boot_args=()
if [[ ${mode} == installe ]]; then
    echo "Démarrage du système installé (${disk})"
else
    if [[ -z "${iso}" ]]; then
        iso=$(find "${src_dir}/out" -name '*.iso' -printf '%T@ %p\n' 2>/dev/null |
            sort -n | tail -1 | cut -d' ' -f2-)
    fi
    if [[ ! -f "${iso}" ]]; then
        echo "Aucune ISO trouvée : lancer d'abord ./build.sh" >&2
        exit 1
    fi
    echo "Démarrage du live (${iso})"
    # bootindex (et non -boot order=d) : OVMF le respecte même quand le
    # chargeur du système installé est en tête des entrées UEFI enregistrées
    boot_args=(-drive file="${iso}",media=cdrom,if=none,id=cd0,readonly=on
               -device ide-cd,drive=cd0,bootindex=0 -boot menu=on)
fi

echo "Processeur de la VM : ${cpu}"

qemu_args=(-enable-kvm -machine q35 -cpu "${cpu}" -smp 4 -m 6G \
    -drive if=pflash,format=raw,readonly=on,file="${ovmf_code}" \
    -drive if=pflash,format=raw,file="${ovmf_vars}" \
    -drive file="${disk}",if=none,format=qcow2,id=hd0 \
    -device virtio-blk-pci,drive=hd0,bootindex=1 \
    "${boot_args[@]}" \
    -device virtio-vga,xres=1600,yres=900 -display spice-app \
    -device virtio-serial-pci -chardev spicevmc,id=vdagent,name=vdagent \
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
    -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22 \
    -device qemu-xhci -device usb-tablet \
    -audiodev pipewire,id=snd0 -device intel-hda -device hda-duplex,audiodev=snd0)

if ${attach}; then
    exec qemu-system-x86_64 "${qemu_args[@]}"
fi

# Détaché : nouvelle session (le terminal fermé n'envoie pas SIGHUP à QEMU),
# sans entrée, sortie dans le journal
setsid -f qemu-system-x86_64 "${qemu_args[@]}" </dev/null >"${log}" 2>&1

# Erreur au démarrage (KVM, disque, option…) : QEMU s'arrête aussitôt
sleep 2
if pid=$(pgrep -f -- "file=${disk}," | head -1) && [[ -n ${pid} ]]; then
    echo "VM lancée (QEMU, PID ${pid}) : le terminal peut être fermé."
    echo "Messages de QEMU : ${log}"
else
    echo "QEMU s'est arrêté au démarrage :" >&2
    tail -n 20 "${log}" >&2
    exit 1
fi
