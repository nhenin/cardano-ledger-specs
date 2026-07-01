#!/usr/bin/env bash
# Launch HLS in the repo's nix environment (via direnv).
# IMPORTANT: prefer 'haskell-language-server' (provided by the nix devshell,
# first on PATH) over the '-wrapper' binary, which only exists under GHCup and
# would start an incompatible HLS.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:$PATH"
exec direnv exec "$ROOT" sh -c \
  'case "$(command -v haskell-language-server)" in
     /nix/store/*) exec haskell-language-server "$@" ;;
   esac
   HLS=$(command -v haskell-language-server-wrapper || command -v haskell-language-server) \
     || { echo "HLS not found in the devShell" >&2; exit 1; }
   exec "$HLS" "$@"' \
  hls "$@"
