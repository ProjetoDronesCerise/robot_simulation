#!/usr/bin/env bash
set -euo pipefail

# ── Descobre o diretório do script e sobe UM nível ─────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(realpath "$SCRIPT_DIR/..")"
cd "$ROOT_DIR"

# ── Variáveis de ambiente pedidas ──────────────────────────────────────────────
export PX4_SYS_AUTOSTART=4002
export PX4_GZ_MODEL_POSE="0,0,0.1,0,0,0"
export PX4_SIM_MODEL=sentinel
export PX4_GZ_WORLD=cae
export PX4_GZ_SIM_RENDER_ENGINE=ogre2

# ── Caminhos de origem e destino ───────────────────────────────────────────────
SRC_MODELS="$ROOT_DIR/modules/simulation_models"
SRC_WORLDS="$ROOT_DIR/modules/simulation_worlds"

# coleções extras (NÃO serão copiadas; só entram no RESOURCE_PATH)
EXTRA_MODELS="$ROOT_DIR/modules/gazebo_models_worlds_collection/models"
EXTRA_WORLDS="$ROOT_DIR/modules/gazebo_models_worlds_collection/worlds"

DST_MODELS="$ROOT_DIR/modules/PX4-Autopilot/Tools/simulation/gz/models"
DST_WORLDS="$ROOT_DIR/modules/PX4-Autopilot/Tools/simulation/gz/worlds"

PX4_BIN="$ROOT_DIR/modules/PX4-Autopilot/build/px4_sitl_default/bin/px4"

# ── Garantir que destinos existem ──────────────────────────────────────────────
mkdir -p "$DST_MODELS" "$DST_WORLDS"

# ── Copiar conteúdos base (apenas SRC_* → DST_*). NÃO copiamos EXTRA_* ─────────
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
    cp -a "$src"/. "$dst"/
  fi
}

echo "Copiando modelos base: $SRC_MODELS -> $DST_MODELS"
copy_all "$SRC_MODELS" "$DST_MODELS"

echo "Copiando worlds base:  $SRC_WORLDS -> $DST_WORLDS"
copy_all "$SRC_WORLDS" "$DST_WORLDS"

# ── Montar GZ_SIM_RESOURCE_PATH incluindo extras sem copiar ────────────────────
# Lista de candidatos (ordem de prioridade: DST_* depois EXTRA_*)
CANDIDATE_PATHS=(
  "$DST_MODELS"
  "$DST_WORLDS"
  "$EXTRA_MODELS"
  "$EXTRA_WORLDS"
)

# Filtra apenas os que existem e remove duplicados
declare -A seen=()
RESOURCE_PATHS=()
for p in "${CANDIDATE_PATHS[@]}"; do
  if [ -d "$p" ] && [ -z "${seen["$p"]+yes}" ]; then
    RESOURCE_PATHS+=("$p")
    seen["$p"]=1
  fi
done

# Se já houver GZ_SIM_RESOURCE_PATH no ambiente, preserva (no fim da lista)
if [ "${GZ_SIM_RESOURCE_PATH:-}" != "" ]; then
  IFS=':' read -r -a EXISTING <<< "$GZ_SIM_RESOURCE_PATH"
  for p in "${EXISTING[@]}"; do
    if [ -d "$p" ] && [ -z "${seen["$p"]+yes}" ]; then
      RESOURCE_PATHS+=("$p")
      seen["$p"]=1
    fi
  done
fi

# Exporta as variáveis
export GZ_SIM_RESOURCE_PATH="$(IFS=:; echo "${RESOURCE_PATHS[*]}")"
export IGN_GAZEBO_RESOURCE_PATH="$GZ_SIM_RESOURCE_PATH"

echo "GZ_SIM_RESOURCE_PATH = $GZ_SIM_RESOURCE_PATH"

# ── Executar o binário do PX4 ─────────────────────────────────────────────────
if [ ! -x "$PX4_BIN" ]; then
  echo "ERRO: binário PX4 não encontrado ou não executável: $PX4_BIN" >&2
  exit 1
fi

echo "Iniciando PX4: $PX4_BIN"
exec "$PX4_BIN"
