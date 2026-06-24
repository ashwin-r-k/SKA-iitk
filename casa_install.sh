#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="$HOME/miniforge3"
ENV_FILE="casa.yaml"

echo "====================================================="
echo " CASA Automated Installation Script"
echo "====================================================="
echo
echo "Prerequisites:"
echo "  1. Internet connection must be active."
echo "  2. casa.yaml and casa_install.sh must be in the same folder."
echo "  3. Miniforge3-Linux-x86_64.sh may also be placed in the same folder."
echo "     Otherwise it will be downloaded automatically."
echo
echo "Example folder structure:"
echo
echo "  /home/user/casa_install_ashwin/"
echo "  ├── casa_install.sh"
echo "  ├── casa.yaml"
echo "  └── Miniforge3-Linux-x86_64.sh   (optional)"
echo
echo "To run:"
echo "  cd /home/user/casa_install_ashwin"
echo "  bash casa_install.sh"
echo

echo "[INFO] Current directory:"
pwd
echo

# Check for casa.yaml

if [[ ! -f "casa.yaml" ]]; then
echo
echo "[ERROR] casa.yaml not found."
echo "[ERROR] Please ensure casa.yaml is present in the same folder as casa_install.sh."
echo "[ERROR] Installation aborted."
exit 1
fi

echo "[OK] Found casa.yaml"

# Check internet connectivity

if ! ping -c 1 github.com >/dev/null 2>&1; then
echo
echo "[ERROR] No internet connection detected."
echo "[ERROR] Please connect to the internet and try again."
echo "[ERROR] Installation aborted."
exit 1
fi

echo "[OK] Internet connection detected."
echo
echo "Starting installation..."
echo




# --------------------------------------------------
# Find or Download Miniforge
# --------------------------------------------------

if [[ -f "./Miniforge3-Linux-x86_64.sh" ]]; then
    INSTALLER="./Miniforge3-Linux-x86_64.sh"
    echo "[INFO] Using local installer"
else
    INSTALLER="/tmp/Miniforge3-Linux-x86_64.sh"

    echo "[INFO] Downloading Miniforge..."
    wget -q --show-progress \
        -O "$INSTALLER" \
        "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

    chmod +x "$INSTALLER"
fi

# --------------------------------------------------
# Install Miniforge
# --------------------------------------------------

if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "[INFO] Installing Miniforge..."
    bash "$INSTALLER" -b -p "$INSTALL_DIR"
else
    echo "[INFO] Miniforge already installed."
fi

# --------------------------------------------------
# Setup Conda for Bash
# --------------------------------------------------

echo "[INFO] Initializing Conda..."

"$INSTALL_DIR/bin/conda" init bash

# Make conda available immediately
source "$INSTALL_DIR/etc/profile.d/conda.sh"

# Disable base auto-activation
conda config --set auto_activate_base false

# --------------------------------------------------
# Read Environment Name
# --------------------------------------------------

if [[ ! -f "$ENV_FILE" ]]; then
    echo "[ERROR] Missing $ENV_FILE"
    exit 1
fi

ENV_NAME=$(awk '/^name:/ {print $2}' "$ENV_FILE")

if [[ -z "$ENV_NAME" ]]; then
    echo "[ERROR] Could not determine environment name."
    exit 1
fi

echo "[INFO] Environment: $ENV_NAME"

# --------------------------------------------------
# Create Environment
# --------------------------------------------------

if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "[INFO] Environment already exists."
else
    echo "[INFO] Creating environment..."
    conda env create -f "$ENV_FILE"
fi

# --------------------------------------------------
# Activate Environment
# --------------------------------------------------

echo "[INFO] Activating environment..."

conda activate "$ENV_NAME"

echo
echo "[INFO] Active environment:"
echo "CONDA_DEFAULT_ENV=$CONDA_DEFAULT_ENV"

echo
which python
python --version

# --------------------------------------------------
# CASA Verification
# --------------------------------------------------

python << EOF
try:
    import casatools

    print("\\nCASA successfully imported")

    try:
        from casatools import version
        print("CASA Version:", version())
    except Exception:
        pass

except Exception as e:
    print("\\nCASA import failed")
    raise
EOF

echo
echo "======================================"
echo " Installation Complete"
echo "======================================"
echo
echo "Future terminals can activate CASA using:"
echo 
echo "    conda activate $ENV_NAME"
echo