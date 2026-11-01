#!/bin/sh

set -e

brew install switchaudio-osx

# formula の hex (hexdump) と名前が衝突するため tap 付きで指定する
brew install --cask anomalyco/tap/hex

brew install --cask \
          1password \
          1password-cli \
          appcleaner \
          deskpad \
          google-gemini \
          ghostty \
          keycastr \
          zoom
