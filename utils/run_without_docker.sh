#!/usr/bin/env bash
set -euo pipefail

# ── Descobre o diretório do script e sobe UM nível ─────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(realpath "$SCRIPT_DIR/..")"
cd "$ROOT_DIR"

# ── Variáveis de ambiente pedidas ──────────────────────────────────────────────
export PX4_SYS_AUTOSTART=4005
export PX4_GZ_MODEL_POSE="0,0,1,0,0,0"
export PX4_SIM_MODEL=sentinel
export PX4_GZ_WORLD=default
export PX4_GZ_SIM_RENDER_ENGINE=ogre2

# (opcional, mas útil em GZ/WSL2)
export GZ_SIM_RESOURCE_PATH="$ROOT_DIR/modules/PX4-Autopilot/Tools/simulation/gz/models:$ROOT_DIR/modules/PX4-Autopilot/Tools/simulation/gz/worlds"

# ── Caminhos de origem e destino ───────────────────────────────────────────────
SRC_MODELS="$ROOT_DIR/modules/simulation_models"
SRC_WORLDS="$ROOT_DIR/modules/simulation_worlds"

DST_MODELS="$ROOT_DIR/modules/PX4-Autopilot/Tools/simulation/gz/models"
DST_WORLDS="$ROOT_DIR/modules/PX4-Autopilot/Tools/simulation/gz/worlds"

PX4_BIN="$ROOT_DIR/modules/PX4-Autopilot/build/px4_sitl_default/bin/px4"

# ── Garantir que destinos existem ──────────────────────────────────────────────
mkdir -p "$DST_MODELS" "$DST_WORLDS"

# ── Copiar conteúdos (prefere rsync; cai para cp -a se não houver) ────────────
copy_all() {
  local src="$1"
  local dst="$2"

  if ! [ -d "$src" ]; then
    echo "ERRO: diretório de origem não existe: $src" >&2
    exit 1
  fi

  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src"/ "$dst"/
  else
    # cp -a não remove arquivos antigos no destino (comportamento seguro)
    cp -a "$src"/. "$dst"/
  fi
}

echo "Copiando modelos: $SRC_MODELS -> $DST_MODELS"
copy_all "$SRC_MODELS" "$DST_MODELS"

echo "Copiando worlds:  $SRC_WORLDS -> $DST_WORLDS"
copy_all "$SRC_WORLDS" "$DST_WORLDS"

# ── Executar o binário do PX4 ─────────────────────────────────────────────────
if [ ! -x "$PX4_BIN" ]; then
  echo "ERRO: binário PX4 não encontrado ou não executável: $PX4_BIN" >&2
  exit 1
fi

echo "Iniciando PX4: $PX4_BIN"
exec "$PX4_BIN"
