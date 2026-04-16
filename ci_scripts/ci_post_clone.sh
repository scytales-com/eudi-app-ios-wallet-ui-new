#!/bin/sh

set -eu

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES || \
  echo "Skipping Xcode macro fingerprint preference update."
