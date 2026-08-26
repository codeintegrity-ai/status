#!/usr/bin/env bash
#
# Guards the vendored theme overrides in layouts/.
#
# cState ships two defects on the v6 line that we cannot reach from config:
# templates calling .Site.LanguageCode (deprecated in Hugo v0.158.0, so the
# build will break when Hugo removes it) and an RSS link built as
# "{{ .Site.BaseURL }}/index.xml", which always renders a doubled slash
# because Hugo normalises BaseURL with a trailing slash. Both are fixed on
# the theme's unreleased v7 branch, so these overrides are a bridge until
# v7 ships -- at which point they should be deleted, not carried forward.
#
# A copied template silently goes stale the moment upstream edits its
# original. This script makes that loud: it records the upstream blob SHA
# each override was copied from and fails when the theme no longer matches.
#
#   ./scripts/check-theme-overrides.sh            verify (used by CI)
#   ./scripts/check-theme-overrides.sh --update   re-baseline after re-syncing
#
set -euo pipefail

cd "$(dirname "$0")/.."

MANIFEST="scripts/theme-overrides.manifest"
THEME="themes/cstate/layouts"
MODE="${1:-check}"

if [ ! -d "$THEME" ]; then
  echo "error: $THEME missing -- run: git submodule update --init --recursive" >&2
  exit 2
fi

drift=0
updated=""

while IFS=$'\t' read -r rel recorded; do
  case "$rel" in ''|\#*) continue ;; esac

  override="layouts/$rel"
  upstream="$THEME/$rel"

  if [ ! -f "$override" ]; then
    echo "error: manifest lists $override but it does not exist" >&2
    drift=1; continue
  fi
  if [ ! -f "$upstream" ]; then
    echo "error: $upstream is gone -- the theme dropped this template." >&2
    echo "       Check whether the override is still needed at all." >&2
    drift=1; continue
  fi

  current="$(git hash-object "$upstream")"

  if [ "$MODE" = "--update" ]; then
    updated="${updated}${rel}	${current}
"
    [ "$current" != "$recorded" ] && echo "re-baselined $rel"
    continue
  fi

  if [ "$current" != "$recorded" ]; then
    drift=1
    echo "DRIFT: $upstream changed upstream since layouts/$rel was vendored." >&2
    echo "       recorded $recorded" >&2
    echo "       current  $current" >&2
    echo "       What changed upstream:" >&2
    # $recorded is a committed blob in the submodule; $upstream is the file on
    # disk, which may not be hashed into the object DB yet -- so compare the
    # recorded blob's contents against the working file directly.
    if git -C themes/cstate cat-file -e "$recorded" 2>/dev/null; then
      git -C themes/cstate cat-file -p "$recorded" 2>/dev/null \
        | diff -u --label "vendored-from" - --label "upstream-now" "$upstream" \
        | sed 's/^/         /' >&2 || true
    else
      echo "         (blob $recorded not in the theme's object DB; fetch the submodule)" >&2
    fi
    echo "       Re-copy the template, re-apply the change named in its header," >&2
    echo "       then run: ./scripts/check-theme-overrides.sh --update" >&2
  fi
done < "$MANIFEST"

if [ "$MODE" = "--update" ]; then
  {
    echo "# path<TAB>upstream blob sha in themes/cstate at vendoring time"
    echo "# Regenerate after re-syncing: scripts/check-theme-overrides.sh --update"
    printf '%s' "$updated"
  } > "$MANIFEST"
  echo "manifest refreshed."
  exit 0
fi

if [ "$drift" -ne 0 ]; then
  echo >&2
  echo "Vendored theme overrides are out of sync with themes/cstate." >&2
  exit 1
fi

echo "theme overrides: in sync with themes/cstate"
