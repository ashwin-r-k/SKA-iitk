# SKA-iitk

## CASA Installation

This repository includes a Bash installer for setting up CASA on Linux x86_64 systems.

To run it directly from GitHub, download both the installer and the environment file into the same folder, then execute the script:

```bash
mkdir -p ~/casa-install
cd ~/casa-install
curl -fsSLO https://raw.githubusercontent.com/ashwin-r-k/SKA-iitk/main/casa_install.sh
curl -fsSLO https://raw.githubusercontent.com/ashwin-r-k/SKA-iitk/main/casa.yaml
bash casa_install.sh
```

The script will download Miniforge automatically if it is not already present. It also checks for an internet connection and expects `casa.yaml` to be in the same directory as `casa_install.sh`.