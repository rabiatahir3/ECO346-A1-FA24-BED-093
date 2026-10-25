#!/bin/bash
set -e

# Detect Rscript
if command -v Rscript >/dev/null 2>&1; then
    RSCRIPT=Rscript
elif [ -f "/home/uwaim/anaconda3/envs/r_env/bin/Rscript" ]; then
    RSCRIPT=/home/uwaim/anaconda3/envs/r_env/bin/Rscript
else
    echo "Rscript not found!" >&2
    exit 1
fi

# Detect python
if command -v python3 >/dev/null 2>&1 && python3 -c "import pandas, matplotlib" >/dev/null 2>&1; then
    PYTHON=python3
elif [ -f "/home/uwaim/anaconda3/bin/python3" ]; then
    PYTHON=/home/uwaim/anaconda3/bin/python3
else
    PYTHON=python3
fi

echo "=========================================================="
echo "Running All Scripts for Assignment 1 (Variant 5: KP Urban)"
echo "Student: Rabia Tahir (FA24-BED-093) <rabii.okiee@gmail.com>"
echo "=========================================================="

echo "[1/4] Running Script 01: Default scatterplot..."
$RSCRIPT scripts/01_default.R

echo "[2/4] Running Script 02: Earnings distribution..."
$RSCRIPT scripts/02_distribution.R

echo "[3/4] Running Script 03: Age-earnings relationship redesign..."
$RSCRIPT scripts/03_relationship.R

echo "[4/4] Running Script 04: Python replication..."
$PYTHON scripts/04_relationship_python.py

echo "=========================================================="
echo "All figures and band tables successfully reproduced!"
echo "Figures saved in figures/: default.svg, distribution.svg, relationship.svg, relationship_python.svg"
echo "=========================================================="
