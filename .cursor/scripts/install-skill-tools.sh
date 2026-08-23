#!/usr/bin/env bash
# Idempotent toolchain for F-library skills. Cloud Agents run this via
# `.cursor/environment.json` `install` during each Build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REQ="${ROOT}/.cursor/scripts/requirements-skill-tools.txt"
VENV="${ROOT}/.venv"
PYTHON_BIN="${VENV}/bin/python"
PYTHON3=python3

log() { printf '[install-skill-tools] %s\n' "$*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_apt_packages() {
  if ! have_cmd apt-get; then
    log "apt-get not found; skip system packages"
    return 0
  fi
  if ! have_cmd sudo; then
    log "sudo not found; skip system packages"
    return 0
  fi

  local pkgs=(
    python3
    python3-pip
    python3-venv
    python3-dev
    libglib2.0-0
    libgomp1
    libsm6
    libxext6
    libxrender1
  )

  log "installing system packages for RapidOCR/OpenCV"
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}"
  # Ubuntu 24.04: libgl1; 22.04: libgl1-mesa-glx
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libgl1 \
    || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libgl1-mesa-glx \
    || log "warning: no libGL package; RapidOCR import may fail"
}

ensure_python() {
  if have_cmd python3; then
    PYTHON3=python3
  elif have_cmd python; then
    PYTHON3=python
  else
    log "python3 is required"
    exit 1
  fi
  log "base interpreter: $("${PYTHON3}" -c 'import sys; print(sys.executable, sys.version.split()[0])')"
}

ensure_venv() {
  if [[ ! -x "${PYTHON_BIN}" ]]; then
    log "creating venv at ${VENV}"
    "${PYTHON3}" -m venv "${VENV}"
  else
    log "reusing venv at ${VENV}"
  fi
  "${PYTHON_BIN}" -m pip install -U pip
  "${PYTHON_BIN}" -m pip install -r "${REQ}"
}

verify() {
  log "verifying skill imports"
  "${PYTHON_BIN}" - <<'PY'
import ebooklib
import pymupdf
from rapidocr_onnxruntime import RapidOCR

print("pymupdf", pymupdf.version)
print("ebooklib ok")
ocr = RapidOCR()
print("RapidOCR ready", type(ocr).__name__)
PY
}

install_apt_packages
ensure_python
ensure_venv
verify
log "done; use ${PYTHON_BIN}"
