#!/bin/sh

set -eu

defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES || \
  echo "Skipping Xcode macro fingerprint preference update."

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

resolve_scheme_name() {
  # Prefer explicit scheme environment variables, then fall back to configuration.
  if [ -n "${SCHEME_NAME:-}" ]; then
    echo "$SCHEME_NAME"
    return
  fi

  if [ -n "${CI_XCODEBUILD_SCHEME:-}" ]; then
    echo "$CI_XCODEBUILD_SCHEME"
    return
  fi

  if [ -n "${XCODE_SCHEME:-}" ]; then
    echo "$XCODE_SCHEME"
    return
  fi

  if [ -n "${CONFIGURATION:-}" ]; then
    echo "$CONFIGURATION"
    return
  fi

  echo ""
}
SWIFT_MODULE_CACHE_DIR="${TMPDIR:-/tmp}/eudi-swift-module-cache"

mkdir -p "$SWIFT_MODULE_CACHE_DIR"

compose_icon() {
  overlay_relative_path="$1"
  target_relative_path="$2"

  overlay_path="$ROOT_DIR/$overlay_relative_path"
  target_path="$ROOT_DIR/$target_relative_path"
  temp_base_icon="$(mktemp /tmp/eudi-base-icon.XXXXXX)"

  if [ ! -f "$overlay_path" ]; then
    echo "Missing overlay icon: $overlay_relative_path" >&2
    exit 1
  fi

  git -C "$ROOT_DIR" show "HEAD:$target_relative_path" > "$temp_base_icon"

  /usr/bin/xcrun swift -module-cache-path "$SWIFT_MODULE_CACHE_DIR" - "$temp_base_icon" "$overlay_path" "$target_path" <<'SWIFT'
import AppKit
import Foundation

let arguments = CommandLine.arguments

guard arguments.count == 4 else {
  fputs("Expected base, overlay, and output paths.\n", stderr)
  exit(1)
}

let baseURL = URL(fileURLWithPath: arguments[1])
let overlayURL = URL(fileURLWithPath: arguments[2])
let outputURL = URL(fileURLWithPath: arguments[3])

guard let baseImage = NSImage(contentsOf: baseURL) else {
  fputs("Unable to load base image at \(baseURL.path).\n", stderr)
  exit(1)
}

guard let overlayImage = NSImage(contentsOf: overlayURL) else {
  fputs("Unable to load overlay image at \(overlayURL.path).\n", stderr)
  exit(1)
}

let canvasSize = NSSize(width: 1024, height: 1024)
let overlaySize = overlayImage.size
let overlayOrigin = NSPoint(x: 0, y: canvasSize.height - overlaySize.height)
let overlayRect = NSRect(origin: overlayOrigin, size: overlaySize)

let outputImage = NSImage(size: canvasSize)
outputImage.lockFocus()
baseImage.draw(in: NSRect(origin: .zero, size: canvasSize))
overlayImage.draw(in: overlayRect, from: .zero, operation: .sourceOver, fraction: 1.0)
outputImage.unlockFocus()

guard
  let tiffRepresentation = outputImage.tiffRepresentation,
  let bitmapRepresentation = NSBitmapImageRep(data: tiffRepresentation),
  let pngData = bitmapRepresentation.representation(using: .png, properties: [:])
else {
  fputs("Unable to encode output PNG.\n", stderr)
  exit(1)
}

do {
  try pngData.write(to: outputURL, options: .atomic)
} catch {
  fputs("Unable to write output image: \(error).\n", stderr)
  exit(1)
}
SWIFT

  rm -f "$temp_base_icon"
}

scheme_name="$(resolve_scheme_name)"
normalized_scheme_name="$(printf '%s' "$scheme_name" | tr '[:upper:]' '[:lower:]')"

case "$normalized_scheme_name" in
  *demo*)
    echo "Composing Demo app icon for scheme/configuration: $scheme_name"
    compose_icon "ci_scripts/Demo-TopLeft.png" "Wallet/Assets.xcassets/AppIcon.appiconset/app_icon.png"
    ;;
  *dev*)
    echo "Composing Dev app icon for scheme/configuration: $scheme_name"
    compose_icon "ci_scripts/Dev-TopLeft.png" "Wallet/Assets.xcassets/AppIconDev.appiconset/app_icon_dev.png"
    ;;
  *)
    echo "No Demo/Dev marker found in scheme/configuration ('$scheme_name'); skipping icon composition."
    ;;
esac
