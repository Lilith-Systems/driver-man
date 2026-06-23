#!/bin/bash
set -e

echo "[MALKUTH] Deploying Driver Man network..."

DIR="/home/tehlappy/Desktop/Lilith/server/driver_man"
cd "$DIR"

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

echo "Installing required dependencies..."
pip install --upgrade pip
pip install numpy networkx

echo "Staging the final code and pushing the Driver Man network live..."
python3 router.py

echo "[MALKUTH] Driver Man network is now LIVE."
