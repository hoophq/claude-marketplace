#!/bin/sh
# Fence installer for the Hoop plugin — one command, no sudo.
#
# Picks the best channel automatically: Homebrew, then npm, then a
# checksum-verified download from GitHub releases into ~/.local/bin.
# The plugin's hook wrapper looks in ~/.local/bin, so the release
# channel needs no PATH changes.
#
# Environment overrides:
#   HOOP_INSTALL_CHANNEL=brew|npm|release   force a channel (default: auto)
#   HOOP_FENCE_VERSION=v1.1.0               release channel: pin a tag (default: latest)
#   HOOP_BIN_DIR=/path                      release channel: install dir (default: ~/.local/bin)
set -eu

REPO="hoophq/fence"

say() { echo "hoop-install: $*"; }
err() { echo "hoop-install: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Resolve fence the way the hook wrapper does: PATH, then common install dirs.
find_fence() {
  command -v fence 2>/dev/null && return 0
  for c in /opt/homebrew/bin/fence /usr/local/bin/fence "$HOME/.local/bin/fence" "$HOME/go/bin/fence"; do
    if [ -x "$c" ]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

if existing=$(find_fence); then
  say "fence $("$existing" version 2>/dev/null || echo '(version unknown)') is already installed: $existing"
  say "nothing to do — guardrails are active"
  exit 0
fi

channel="${HOOP_INSTALL_CHANNEL:-auto}"
if [ "$channel" = auto ]; then
  if have brew; then
    channel=brew
  elif have npm; then
    channel=npm
  else
    channel=release
  fi
fi

case "$channel" in
  brew)
    say "installing via Homebrew: brew install hoophq/tap/fence"
    brew install hoophq/tap/fence
    ;;

  npm)
    say "installing via npm: npm install -g @hoophq/fence"
    npm install -g @hoophq/fence
    ;;

  release)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
      darwin | linux) ;;
      *) err "unsupported OS: $os — fence supports macOS and Linux (on Windows, use WSL)" ;;
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

    tag="${HOOP_FENCE_VERSION:-}"
    if [ -z "$tag" ]; then
      tag=$(latest_tag)
      [ -n "$tag" ] || err "could not determine the latest fence version; set HOOP_FENCE_VERSION"
    fi
    ver=${tag#v} # release filenames drop the leading v

    base="https://github.com/$REPO/releases/download/$tag"
    archive="fence_${ver}_${os}_${arch}.tar.gz"

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    say "downloading $archive ($tag)"
    dlo "$base/$archive" "$tmp/$archive" || err "download failed: $base/$archive"

    # A guardrails tool gets no checksum leniency: verification is mandatory,
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

    tar -xzf "$tmp/$archive" -C "$tmp" fence || err "extract failed"

    bindir="${HOOP_BIN_DIR:-$HOME/.local/bin}"
    mkdir -p "$bindir"
    [ -w "$bindir" ] || err "cannot write to $bindir; set HOOP_BIN_DIR to a writable directory"
    install -m 0755 "$tmp/fence" "$bindir/fence"
    installed_at="$bindir/fence"
    say "installed to $installed_at"
    if [ "$bindir" != "$HOME/.local/bin" ]; then
      say "note: $bindir is not where the plugin hooks look — set HOOP_FENCE_BIN=$installed_at in your environment"
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
  installed=$(find_fence) || err "install finished but fence was not found — set HOOP_FENCE_BIN to its location"
fi
say "fence $("$installed" version 2>/dev/null || echo '(version unknown)') ready at $installed"
say "guardrails are active for new tool calls; the 🚧 banner appears from the next session"
