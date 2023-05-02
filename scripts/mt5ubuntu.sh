#!/bin/bash

# Copyright 2022, MetaQuotes Ltd.

# MetaTrader download url
URL="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"

# Specify the Python version to install
PYTHON_VERSION="3.11.0"
PYTHON_APP_TYPE="amd64" # amd64 for 64bit applications
FILENAME_DIV="-"

# Wine version to install: stable or devel
WINE_VERSION="stable"

# Prepare: switch to 32 bit and add Wine key
sudo dpkg --add-architecture i386
wget -nc https://dl.winehq.org/wine-builds/winehq.key
sudo mv winehq.key /usr/share/keyrings/winehq-archive.key

# Get Ubuntu version and trim to major only
OS_VER=$(lsb_release -r |cut -f2 |cut -d "." -f1)
# Choose repository based on Ubuntu version
if (( $OS_VER >= 22)); then
    wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq.list
    sudo mv winehq.list /etc/apt/sources.list.d/winehq.list
    elif (( $OS_VER < 22 )) && (( $OS_VER >= 21 )); then
    wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/impish/winehq.list
    sudo mv winehq.list /etc/apt/sources.list.d/winehq.list
    elif (( $OS_VER < 21 )) && (( $OS_VER >=20 )); then
    wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq.list
    sudo mv winehq.list /etc/apt/sources.list.d/winehq.list
    elif (( $OS_VER < 20 )); then
    wget -nc https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/winehq.list
    sudo mv winehq.list /etc/apt/sources.list.d/winehq.list
fi

# Add Wine repository key
wget -nc https://dl.winehq.org/wine-builds/winehq.key
sudo apt-key add winehq.key

# Update package and install Wine
sudo apt update
sudo apt upgrade -y
sudo apt install --install-recommends winehq-${WINE_VERSION} -y

# Download MetaTrader
wget $URL

# Set environment to Windows 10
WINEPREFIX=~/.mt5 winecfg -v=win10
# Start MetaTrader installer
WINEPREFIX=~/.mt5 wine mt5setup.exe /quiet

# Install python

USER_DIR=~/.mt5/drive_c/

# Navigate to the folder where you want to install Python
cd ${USER_DIR}

# Download the Python installer for Windows
wget https://www.python.org/ftp/python/${PYTHON_VERSION}/python${FILENAME_DIV}${PYTHON_VERSION}${FILENAME_DIV}${PYTHON_APP_TYPE}.exe


# Install Python using Wine
WINEPREFIX=~/.mt5 wine python${FILENAME_DIV}${PYTHON_VERSION}${FILENAME_DIV}${PYTHON_APP_TYPE}.exe /quiet InstallAllUsers=1 PrependPath=1

# Verify that Python is installed
WINEPREFIX=~/.mt5 wine cmd /c "python --version"

