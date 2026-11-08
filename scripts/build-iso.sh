#!/bin/bash
# Uso: ./scripts/build-iso.sh ultralight|standard   (como root)
# Gera uma ISO de TESTE em build/<perfil>/ e copia para iso/.
set -euo pipefail

PERFIL="${1:-}"
case "$PERFIL" in ultralight|standard) ;; *) echo "Use: $0 ultralight|standard"; exit 1;; esac
[ "$(id -u)" -eq 0 ] || { echo "Rode como root."; exit 1; }

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
DESTINO="$RAIZ/build/$PERFIL"
mkdir -p "$DESTINO" && cd "$DESTINO"

lb clean --purge >/dev/null 2>&1 || true

lb config \
  --distribution trixie \
  --architectures amd64 \
  --archive-areas "main contrib non-free-firmware" \
  --security true \
  --apt-recommends false \
  --debian-installer none \
  --binary-images iso-hybrid \
  --iso-application "NEXUS OS" \
  --iso-volume "NEXUS_OS_1_0" \
  --iso-publisher "NEXUS OS Project" \
  --bootappend-live "boot=live components quiet splash"

mkdir -p config/package-lists
cp "$RAIZ/packages/common.list.chroot" config/package-lists/common.list.chroot
if [ "$PERFIL" = "standard" ]; then
  cp "$RAIZ/packages/standard.list.chroot" config/package-lists/standard.list.chroot
fi

lb build 2>&1 | tee "$DESTINO/build.log"

ISO="$(ls -1 "$DESTINO"/*.iso 2>/dev/null | head -n 1 || true)"
[ -n "$ISO" ] || { echo "ERRO: ISO não gerada. Veja $DESTINO/build.log"; exit 1; }
mkdir -p "$RAIZ/iso"
cp "$ISO" "$RAIZ/iso/nexus-os-$PERFIL-teste.iso"
echo "OK: $RAIZ/iso/nexus-os-$PERFIL-teste.iso"
