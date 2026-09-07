#!/bin/sh

set -eu
# Xcode Cloud cannot interactively approve package build tool plugins.
# "Validatation" is the spelling required by Xcode for this preference.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES || \
  echo "Skipping Xcode macro fingerprint preference update."
