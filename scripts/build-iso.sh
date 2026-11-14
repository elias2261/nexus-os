#!/bin/bash
# NEXUS OS v0.1 - Uso: ./scripts/build-iso.sh ultralight|standard   (como root)
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
  --apt-recommends true \
  --debian-installer none \
  --binary-images iso-hybrid \
  --iso-application "NEXUS OS" \
  --iso-volume "NEXUS_OS_0_1" \
  --iso-publisher "NEXUS OS Project" \
  --bootappend-live "boot=live components"

mkdir -p config/package-lists
cp "$RAIZ/packages/common.list.chroot" config/package-lists/common.list.chroot
if [ "$PERFIL" = "standard" ]; then
  cp "$RAIZ/packages/standard.list.chroot" config/package-lists/standard.list.chroot
fi

# Login automatico do LightDM (plano B: tela de login user/live)
mkdir -p config/includes.chroot/etc/lightdm/lightdm.conf.d
cat > config/includes.chroot/etc/lightdm/lightdm.conf.d/50-nexus.conf << 'EOF'
[Seat:*]
autologin-user=user
autologin-user-timeout=0
autologin-session=xfce
EOF

# Comando de diagnostico: nexus-diagnostico
mkdir -p config/includes.chroot/usr/local/bin
cat > config/includes.chroot/usr/local/bin/nexus-diagnostico << 'EOF'
#!/bin/sh
echo "== lightdm =="
systemctl status lightdm --no-pager | head -n 15
echo "== erros do boot =="
journalctl -b -p err --no-pager | tail -n 15
echo "== video =="
lspci | grep -i vga
echo "== memoria =="
free -m
echo "== xorg =="
which Xorg
tail -n 15 /var/log/Xorg.0.log 2>/dev/null
EOF
chmod +x config/includes.chroot/usr/local/bin/nexus-diagnostico

lb build 2>&1 | tee "$DESTINO/build.log"

ISO="$(ls -1 "$DESTINO"/*.iso 2>/dev/null | head -n 1 || true)"
[ -n "$ISO" ] || { echo "ERRO: ISO não gerada. Veja $DESTINO/build.log"; exit 1; }
mkdir -p "$RAIZ/iso"
cp "$ISO" "$RAIZ/iso/nexus-os-$PERFIL-teste.iso"
echo "OK: $RAIZ/iso/nexus-os-$PERFIL-teste.iso"
