#!/bin/sh
set -eu

# Determine installation directory
if [ "$(id -u)" -eq 0 ]; then
  BIN_DIR="/usr/local/bin"
else
  BIN_DIR="$HOME/.local/bin"
fi

# Create directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Download git-cococo
URL="https://raw.githubusercontent.com/nishidayuya/git-cococo/main/exe/git-cococo"
TARGET="$BIN_DIR/git-cococo"

echo "Installing git-cococo to $TARGET..."

if command -v curl >/dev/null 2>&1; then
  curl -fsL "$URL" -o "$TARGET"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$URL" -O "$TARGET"
else
  echo "Error: curl or wget is required to install git-cococo." >&2
  exit 1
fi

# Set executable permission
chmod +x "$TARGET"

echo "Successfully installed git-cococo to $TARGET"

# Check if BIN_DIR is in PATH
if [ "$BIN_DIR" = "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *:"$BIN_DIR":*) ;;
    *)
      echo ""
      echo "Warning: $BIN_DIR is not in your PATH."
      echo "You may need to add it to your shell's configuration file (e.g., ~/.bashrc or ~/.zshrc):"
      echo "  export PATH=\"\$PATH:$BIN_DIR\""
      ;;
  esac
fi
