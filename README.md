# CASA Automated Installation Script

Author: Ashwin Raju Kharat
SPASE, IIT Kanpur

## Overview

```bash
curl -fsSL https://raw.githubusercontent.com/ashwin-r-k/SKA-iitk/main/casa_install.sh | bash
```

This script automatically installs and verifies the software required for CASA-based radio astronomy data analysis on Ubuntu systems.

The script can be safely re-run multiple times and acts as both:

* An installation script
* A system verification/check script

Already installed components are detected and skipped automatically.

---

## What the Script Does

### System Packages

Checks for and installs:

* GNU Radio
* Jupyter Notebook

using Ubuntu APT repositories.

### Conda Environment

Checks for Conda installation:

* If Conda is already available, it is reused.
* If Conda is not available, Miniforge is installed automatically.

### CASA Environment

Checks for the CASA conda environment:

* If the environment already exists, installation is skipped.
* Otherwise the environment is created from `casa.yaml`.

### Verification

After installation the script:

* Activates the CASA environment
* Verifies Python functionality
* Verifies CASA package installation
* Prints package versions

---

## Requirements

* Ubuntu Linux
* Internet connection
* Sudo privileges

---

## Usage

### Option 1: Download Repository

Clone the repository:

```bash
git clone https://github.com/ashwin-r-k/SKA-iitk.git
cd SKA-iitk
bash casa_install.sh
```

### Option 2: Run Directly from GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/ashwin-r-k/SKA-iitk/main/casa_install.sh | bash
```

---

## Example Output

```text
✔ Internet connection detected
✔ GNU Radio already installed
✔ Jupyter Notebook already installed
✔ Conda already installed
✔ Conda environment 'casa' already exists
✔ Activated environment: casa
✔ Installation / check completed
```

---

## Activating CASA Later

Open a new terminal and run:

```bash
conda activate casa
```

---

## Repository

https://github.com/ashwin-r-k/SKA-iitk

---

## Contact

Ashwin Raju Kharat
M.Tech, SPASE
Indian Institute of Technology Kanpur
