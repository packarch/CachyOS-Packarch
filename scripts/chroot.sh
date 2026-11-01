# chroot.sh — sourced by calamares/build.sh: builds compiled packages in a clean Arch
# Linux chroot (devtools), so that they run on any x86-64 processor.
#
# Building on this system is not enough, even with -march=x86-64: its glibc
# comes from cachyos-core-znver4, and its startup files (Scrt1.o...) carry the
# "x86 ISA needed: x86-64-v4" ELF note. Every program linked here inherits it,
# and on a processor without AVX-512 the dynamic loader refuses to start it
# ("CPU ISA level is lower than required"). The chroot uses the generic
# packages of Arch Linux (core, extra, multilib), plus the generic [cachyos]
# repository, last, only for the packages that Arch lacks (ckbcomp...).
#
# The chroot is in ~/.cache/packarch-chroot (PACKARCH_CHROOT), created on the
# first build and updated once per run. To start again from scratch:
#   sudo rm -rf ~/.cache/packarch-chroot
#
# Needs devtools (sudo pacman -S devtools).

PACKARCH_CHROOT="${PACKARCH_CHROOT:-${HOME}/.cache/packarch-chroot}"
_chroot_ready=false

# Creates the chroot, or updates it (once per run)
chroot_prepare() {
    ${_chroot_ready} && return 0
    command -v makechrootpkg >/dev/null ||
        { echo "devtools manquant : sudo pacman -S devtools" >&2; return 1; }
    local d="${PACKARCH_CHROOT}"
    mkdir -p "${d}/pkgcache" "${d}/makepkg.conf.d"

    # Own package cache: the cache of this system holds znver4 packages
    cat >"${d}/pacman.conf" <<EOF
[options]
HoldPkg = pacman glibc
Architecture = x86_64
CacheDir = ${d}/pkgcache
ParallelDownloads = 5
DownloadUser = alpm
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

# Generic CachyOS packages, last: only those that Arch Linux lacks
[cachyos]
Server = https://cdn77.cachyos.org/repo/\$arch/\$repo
Server = https://mirror.cachyos.org/repo/\$arch/\$repo
EOF

    # makepkg.conf of Arch Linux (-march=x86-64 -mtune=generic), and ours
    cp /usr/share/devtools/makepkg.conf.d/x86_64.conf "${d}/makepkg.conf"
    rm -f "${d}/makepkg.conf.d/"*.conf
    cp /usr/share/devtools/makepkg.conf.d/x86_64.conf.d/*.conf "${d}/makepkg.conf.d/"
    cat >"${d}/makepkg.conf.d/zz-packarch.conf" <<'EOF'
OPTIONS=("${OPTIONS[@]/#lto/!lto}")
COMPRESSZST=(zstd -c -T0 -19 -)
EOF

    if [[ -d ${d}/root ]]; then
        sudo arch-nspawn -C "${d}/pacman.conf" -M "${d}/makepkg.conf" \
            "${d}/root" pacman -Syu --noconfirm
    else
        sudo mkarchroot -C "${d}/pacman.conf" -M "${d}/makepkg.conf" \
            "${d}/root" base-devel
    fi
    _chroot_ready=true
}

# Builds the PKGBUILD of the current directory in the chroot. Arguments:
# package files to install first (dependencies built here, e.g. gtkmm).
# The packages are written in the current directory.
chroot_build() {
    chroot_prepare
    local args=() f
    for f in "$@"; do args+=(-I "${f}"); done
    makechrootpkg -c -r "${PACKARCH_CHROOT}" "${args[@]}"
    rm -f ./*.log
}

# Prints the "x86 ISA needed" notes above the baseline in the package files
# given (empty: all of them are generic)
check_isa_level() {
    local pkg tmp f
    for pkg in "$@"; do
        tmp="$(mktemp -d)"
        bsdtar -xf "${pkg}" -C "${tmp}" 2>/dev/null
        while IFS= read -r -d '' f; do
            readelf -n "${f}" 2>/dev/null | grep -q 'ISA needed:.*x86-64-v[234]' &&
                echo "${pkg##*/}: ${f#"${tmp}"/}"
        done < <(find "${tmp}" -type f -print0)
        rm -rf "${tmp}"
    done
    return 0
}
