#!/bin/sh
# Tool installer for the Hoop plugin — one command, no sudo.
#
# Usage: install-tool.sh <fence|hooprs|alcatraz>
#
# Picks the best channel automatically: Homebrew, then npm, then a
# checksum-verified download from GitHub releases into ~/.local/bin.
# The plugin's wrappers look in ~/.local/bin, so the release channel
# needs no PATH changes. Tools without an npm package skip that channel.
#
# Environment overrides:
#   HOOP_INSTALL_CHANNEL=brew|npm|release   force a channel (default: auto)
#   HOOP_FENCE_VERSION / HOOP_HOOPRS_VERSION / HOOP_ALCATRAZ_VERSION=v1.1.0
#                                           release channel: pin a tag (default: latest)
#   HOOP_BIN_DIR=/path                      release channel: install dir (default: ~/.local/bin)
set -eu

tool="${1:-}"
case "$tool" in
  fence)
    REPO="hoophq/fence"
    BREW_FORMULA="hoophq/tap/fence"
    NPM_PKG="@hoophq/fence"
    VERSION_ARG="version" # `fence version`
    BIN_ENV="HOOP_FENCE_BIN"
    pin="${HOOP_FENCE_VERSION:-}"
    ready_msg="guardrails are active for new tool calls; the 🚧 banner appears from the next session"
    ;;
  hooprs)
    REPO="hoophq/rs"
    BREW_FORMULA="hoophq/tap/hooprs"
    NPM_PKG="@hoophq/rs"
    VERSION_ARG="-version" # `hooprs -version`
    BIN_ENV="HOOP_HOOPRS_BIN"
    pin="${HOOP_HOOPRS_VERSION:-}"
    ready_msg="run /hoop:risk-report to scan this session for leaked PII and secrets"
    ;;
  alcatraz)
    REPO="hoophq/alcatraz"
    BREW_FORMULA="hoophq/tap/alcatraz"
    NPM_PKG="" # no npm package (yet)
    VERSION_ARG="version" # `alcatraz version`
    BIN_ENV="HOOP_ALCATRAZ_BIN"
    pin="${HOOP_ALCATRAZ_VERSION:-}"
    ready_msg="run /hoop:pii-scan to scan diffs, files, or pasted content for PII"
    ;;
  *)
    echo "hoop-install: usage: install-tool.sh <fence|hooprs|alcatraz>" >&2
    exit 1
    ;;
esac

say() { echo "hoop-install: $*"; }
err() {
  echo "hoop-install: $*" >&2
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

# Resolve the binary the way the plugin wrappers do: PATH, then common install dirs.
find_tool() {
  command -v "$tool" 2>/dev/null && return 0
  for c in "/opt/homebrew/bin/$tool" "/usr/local/bin/$tool" "$HOME/.local/bin/$tool" "$HOME/go/bin/$tool"; do
    if [ -x "$c" ]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

if existing=$(find_tool); then
  say "$tool $("$existing" "$VERSION_ARG" 2>/dev/null || echo '(version unknown)') is already installed: $existing"
  say "nothing to do"
  exit 0
fi

channel="${HOOP_INSTALL_CHANNEL:-auto}"
if [ "$channel" = auto ]; then
  if have brew; then
    channel=brew
  elif have npm && [ -n "$NPM_PKG" ]; then
    channel=npm
  else
    channel=release
  fi
fi
if [ "$channel" = npm ] && [ -z "$NPM_PKG" ]; then
  err "$tool has no npm package; use HOOP_INSTALL_CHANNEL=brew or release"
fi

case "$channel" in
  brew)
    say "installing via Homebrew: brew install $BREW_FORMULA"
    brew install "$BREW_FORMULA"
    ;;

  npm)
    say "installing via npm: npm install -g $NPM_PKG"
    npm install -g "$NPM_PKG"
    ;;

  release)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
      darwin | linux) ;;
      *) err "unsupported OS: $os — $tool supports macOS and Linux (on Windows, use WSL)" ;;
    esac
    arch=$(uname -m)
    case "$arch" in
      x86_64 | amd64) arch=amd64 ;;
      arm64 | aarch64) arch=arm64 ;;
      *) err "unsupported architecture: $arch" ;;
    esac

    if have curl; then
      dl() { curl -fsSL "$1"; }
      dlo() { curl -fsSL -o "$2" "$1"; }
      # Resolving the tag off the releases/latest redirect avoids GitHub
      # API rate limits (which bite on shared CI runner IPs).
      latest_tag() { curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" | sed 's|.*/tag/||'; }
    elif have wget; then
      dl() { wget -qO- "$1"; }
      dlo() { wget -qO "$2" "$1"; }
      latest_tag() { dl "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | head -1 | cut -d'"' -f4; }
    else
      err "need curl or wget"
    fi

    tag="$pin"
    if [ -z "$tag" ]; then
      tag=$(latest_tag)
      [ -n "$tag" ] || err "could not determine the latest $tool version; set ${BIN_ENV%_BIN}_VERSION"
    fi
    ver=${tag#v} # release filenames drop the leading v

    base="https://github.com/$REPO/releases/download/$tag"
    archive="${tool}_${ver}_${os}_${arch}.tar.gz"

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    say "downloading $archive ($tag)"
    dlo "$base/$archive" "$tmp/$archive" || err "download failed: $base/$archive"

    # Security tooling gets no checksum leniency: verification is mandatory,
    # unlike installers that soft-fail when checksums.txt is unavailable.
    dlo "$base/checksums.txt" "$tmp/checksums.txt" || err "could not download checksums.txt; refusing to install unverified"
    want=$(grep " ${archive}\$" "$tmp/checksums.txt" | awk '{print $1}')
    [ -n "$want" ] || err "no checksum for $archive in checksums.txt"
    if have sha256sum; then
      got=$(sha256sum "$tmp/$archive" | awk '{print $1}')
    elif have shasum; then
      got=$(shasum -a 256 "$tmp/$archive" | awk '{print $1}')
    else
      err "need sha256sum or shasum to verify the download"
    fi
    [ "$got" = "$want" ] || err "checksum mismatch for $archive"
    say "checksum OK"

    tar -xzf "$tmp/$archive" -C "$tmp" "$tool" || err "extract failed"

    bindir="${HOOP_BIN_DIR:-$HOME/.local/bin}"
    mkdir -p "$bindir"
    [ -w "$bindir" ] || err "cannot write to $bindir; set HOOP_BIN_DIR to a writable directory"
    install -m 0755 "$tmp/$tool" "$bindir/$tool"
    installed_at="$bindir/$tool"
    say "installed to $installed_at"
    if [ "$bindir" != "$HOME/.local/bin" ]; then
      say "note: $bindir is not where the plugin looks — set $BIN_ENV=$installed_at in your environment"
    fi
    ;;

  *)
    err "unknown HOOP_INSTALL_CHANNEL: $channel (expected brew, npm, or release)"
    ;;
esac

# The release channel knows exactly where it put the binary; package
# managers need re-discovery.
installed="${installed_at:-}"
if [ -z "$installed" ]; then
  installed=$(find_tool) || err "install finished but $tool was not found — set $BIN_ENV to its location"
fi
say "$tool $("$installed" "$VERSION_ARG" 2>/dev/null || echo '(version unknown)') ready at $installed"
say "$ready_msg"
