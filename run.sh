#!/usr/bin/env bash
set -euo pipefail


# Permitir conexões locais ao X para apps GUI no Docker
if command -v xhost >/dev/null 2>&1; then
  xhost +local:docker || true
fi

# Setup para X11 forwarding
XAUTH="/tmp/.docker.xauth"
touch "$XAUTH"
if command -v xauth >/dev/null 2>&1; then
  xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH" nmerge - || true
fi

# ── Configurações básicas ────────────────────────────────────────────────
NAME="sentinel_dev"
IMAGE="cerise-sentinel:1.0"
WORKDIR="/workspace"

# ── Executa o container com ambiente de dev completo ────────────────────
docker run --rm -it \
  --name "$NAME" \
  --privileged \
  --network host \
  --ipc host \
  --pid host \
  --env "DISPLAY=${DISPLAY:-:}" \
  --env "QT_X11_NO_MITSHM=1" \
  --env "XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}" \
  --env "TZ=$(cat /etc/timezone)" \
  -v "$(pwd)/modules:${WORKDIR}" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "$HOME/.Xauthority:$HOME/.Xauthority:ro" \
  -v /dev:/dev \
  -v /etc/localtime:/etc/localtime:ro \
  --device /dev/dri:/dev/dri \
  --group-add video \
  --gpus all \
  --workdir "$WORKDIR" \
  "$IMAGE" bash
