#!/usr/bin/env bash
# HarmonyOS-style setup for macOS Apple Silicon M4
set -e
echo "=== OurOS Build Setup (macOS M4) ==="
command -v brew &>/dev/null || { echo "Install Homebrew: https://brew.sh"; exit 1; }
brew install nasm
brew install qemu
brew tap nativeos/i686-elf-toolchain 2>/dev/null || true
brew install nativeos/i686-elf-toolchain/i686-elf-binutils || true
brew install nativeos/i686-elf-toolchain/i686-elf-gcc
echo ""
echo "Done! Build: cd hamaruyos && make"
echo "Run:         make run"
echo "Debug:       make debug"
