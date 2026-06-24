#!/usr/bin/env bash
set -euo pipefail

# =====================================================
# CASA Auto Install + Check Script
# =====================================================

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

ok()   { echo -e "${GREEN}✔${RESET} $*"; }
skip() { echo -e "${YELLOW}↷${RESET} $*"; }
info() { echo -e "${BLUE}•${RESET} $*"; }
err()  { echo -e "${RED}✘${RESET} $*"; }

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
WORKDIR="$(pwd)"

INSTALL_DIR="$HOME/miniforge3"
LOCAL_YAML="$WORKDIR/casa.yaml"
REMOTE_YAML_URL="https://raw.githubusercontent.com/ashwin-r-k/SKA-iitk/main/casa.yaml"
MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

is_dpkg_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

require_sudo() {
    if [[ "${EUID}" -eq 0 ]]; then
        SUDO=""
    else
        if ! have_cmd sudo; then
            err "sudo is required for apt installs but was not found."
            exit 1
        fi
        SUDO="sudo"
    fi
}

apt_update_once() {
    info "Running apt update..."
    $SUDO apt-get update -y
}

install_if_missing() {
    local pkg="$1"
    local check_cmd="${2:-}"
    local present=false

    if [[ -n "$check_cmd" ]] && have_cmd "$check_cmd"; then
        present=true
    elif is_dpkg_installed "$pkg"; then
        present=true
    fi

    if [[ "$present" == true ]]; then
        ok "$pkg already installed"
        return 0
    fi

    return 1
}

echo "====================================================="
echo " CASA Automated Installation Script"
echo " Author: Ashwin"
echo "====================================================="
echo
echo "How to run:"
echo "  cd <folder-containing-script-and-casa.yaml>"
echo "  bash ${SCRIPT_NAME}"
echo
echo "Example folder:"
echo "  /home/ashwin/casa_install_ashwin/"
echo "    ├── casa_install.sh"
echo "    ├── casa.yaml"
echo "    └── Miniforge3-Linux-x86_64.sh   (optional)"
echo
echo "Notes:"
echo "  • Internet should be active."
echo "  • If casa.yaml is missing locally, it will be downloaded from GitHub."
echo "  • Miniforge is installed only if conda is missing."
echo "  • Existing CASA conda env is skipped."
echo

require_sudo

# -----------------------------------------------------
# Basic connectivity check
# -----------------------------------------------------
if ! curl -fsI https://raw.githubusercontent.com >/dev/null 2>&1; then
    err "No internet connection detected."
    err "Please connect to the internet and run again."
    exit 1
fi
ok "Internet connection detected"

# -----------------------------------------------------
# 1) APT packages: Jupyter Notebook + GNU Radio
# -----------------------------------------------------
APT_PKGS=()

if install_if_missing "gnuradio" "gnuradio-companion"; then
    :
else
    info "GNU Radio not found"
    APT_PKGS+=("gnuradio")
fi

if install_if_missing "jupyter-notebook" "jupyter-notebook"; then
    :
elif is_dpkg_installed "python3-notebook"; then
    ok "Jupyter Notebook already installed (python3-notebook)"
else
    info "Jupyter Notebook not found"
    # Prefer jupyter-notebook if available, otherwise fall back.
    APT_PKGS+=("jupyter-notebook")
fi

if (( ${#APT_PKGS[@]} > 0 )); then
    apt_update_once

    # If jupyter-notebook package is unavailable, fall back cleanly.
    FINAL_APT_PKGS=()
    for pkg in "${APT_PKGS[@]}"; do
        if [[ "$pkg" == "jupyter-notebook" ]]; then
            if apt-cache show jupyter-notebook >/dev/null 2>&1; then
                FINAL_APT_PKGS+=("jupyter-notebook")
            elif apt-cache show python3-notebook >/dev/null 2>&1; then
                FINAL_APT_PKGS+=("python3-notebook")
            else
                err "No apt package found for Jupyter Notebook."
                exit 1
            fi
        else
            FINAL_APT_PKGS+=("$pkg")
        fi
    done

    info "Installing apt packages: ${FINAL_APT_PKGS[*]}"
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y "${FINAL_APT_PKGS[@]}"
else
    ok "APT packages already satisfied"
fi

# -----------------------------------------------------
# 2) Conda / Miniforge only if conda is missing
# -----------------------------------------------------
CONDA_BIN=""
CONDA_BASE=""

if have_cmd conda; then
    CONDA_BIN="$(command -v conda)"
    CONDA_BASE="$("$CONDA_BIN" info --base 2>/dev/null || true)"
    if [[ -n "${CONDA_BASE}" && -x "${CONDA_BASE}/bin/conda" ]]; then
        ok "Conda already installed"
    else
        ok "Conda found in PATH"
    fi
else
    skip "Conda not found; installing Miniforge"

    if [[ -f "$WORKDIR/Miniforge3-Linux-x86_64.sh" ]]; then
        INSTALLER="$WORKDIR/Miniforge3-Linux-x86_64.sh"
        ok "Using local Miniforge installer"
    else
        INSTALLER="/tmp/Miniforge3-Linux-x86_64.sh"
        info "Downloading Miniforge installer..."
        curl -fsSL "$MINIFORGE_URL" -o "$INSTALLER"
        chmod +x "$INSTALLER"
    fi

    info "Installing Miniforge to: $INSTALL_DIR"
    bash "$INSTALLER" -b -p "$INSTALL_DIR"

    CONDA_BASE="$INSTALL_DIR"
    CONDA_BIN="$INSTALL_DIR/bin/conda"
fi

if [[ -z "${CONDA_BASE}" ]]; then
    if [[ -x "$INSTALL_DIR/bin/conda" ]]; then
        CONDA_BASE="$INSTALL_DIR"
        CONDA_BIN="$INSTALL_DIR/bin/conda"
    else
        err "Unable to locate conda after installation."
        exit 1
    fi
fi

# Make conda available in this shell and future shells
# This writes the bash init block once; safe to repeat.
"$CONDA_BIN" init bash >/dev/null 2>&1 || true
source "$CONDA_BASE/etc/profile.d/conda.sh"
conda config --set auto_activate_base false >/dev/null 2>&1 || true

ok "Conda initialized for bash"

# -----------------------------------------------------
# 3) CASA YAML: local file first, else download
# -----------------------------------------------------
if [[ -f "$LOCAL_YAML" ]]; then
    CASA_YAML="$LOCAL_YAML"
    ok "Found local casa.yaml"
else
    CASA_YAML="/tmp/casa.yaml"
    skip "Local casa.yaml not found; downloading from GitHub"
    curl -fsSL "$REMOTE_YAML_URL" -o "$CASA_YAML"
fi

ENV_NAME="$(awk -F': *' '/^name:/ {print $2; exit}' "$CASA_YAML" | tr -d '\r' | xargs)"
if [[ -z "$ENV_NAME" ]]; then
    err "Could not read environment name from casa.yaml"
    exit 1
fi
info "CASA environment name: $ENV_NAME"

# -----------------------------------------------------
# 4) Create CASA env only if it does not exist
# -----------------------------------------------------
if conda env list | awk '{print $1}' | grep -Fxq "$ENV_NAME"; then
    ok "Conda environment '$ENV_NAME' already exists"
else
    info "Creating conda environment '$ENV_NAME' from casa.yaml"
    conda env create -f "$CASA_YAML"
fi

# -----------------------------------------------------
# 5) Activate CASA env and verify in Python
# -----------------------------------------------------
conda activate "$ENV_NAME"
ok "Activated environment: $CONDA_DEFAULT_ENV"

echo
info "Python in active env:"
which python
python --version

echo
info "Checking CASA packages in Python..."
python - <<'PY'
from importlib import metadata

packages = ["casatools", "casatasks", "casaconfig", "casaviewer"]
print("Python check: OK")
for pkg in packages:
    try:
        print(f"{pkg}: {metadata.version(pkg)}")
    except metadata.PackageNotFoundError:
        print(f"{pkg}: not found")
PY

echo
ok "Installation / check completed"
echo "To use later:"
echo "  conda activate ${ENV_NAME}"