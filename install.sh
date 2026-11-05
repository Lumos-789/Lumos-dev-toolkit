#!/usr/bin/env bash
# Lumos dev toolkit — install the five plugins into DeepSeek Harness.
#
# Design notes:
#   * malo-browser is installed from its GitHub Release tarball, not from the
#     source tree. Its `out/` directory is gitignored and built by `npm run
#     build`; a source install leaves index.js pointing at a file that does not
#     exist. The release tarball ships `out/` prebuilt.
#   * The other four have no version tags upstream, so they install from the
#     default branch. VERSIONS.md records the commit each was released from.
#   * Nothing is swallowed: a failed install prints the exact command and stops.
set -euo pipefail

OWNER="Lumos-789"
MALO_TARBALL="https://github.com/${OWNER}/malo-browser/releases/download/v0.1.6/malo-browser-0.1.6-dsh.tgz"

PLUGIN_NAMES=(guster galadon baton malo-browser delivery-video)

plugin_spec() {
  case "$1" in
    guster)         printf '%s\n' "https://github.com/${OWNER}/guster" ;;
    galadon)        printf '%s\n' "https://github.com/${OWNER}/galadon" ;;
    baton)          printf '%s\n' "https://github.com/${OWNER}/baton" ;;
    malo-browser)   printf '%s\n' "${MALO_TARBALL}" ;;
    delivery-video) printf '%s\n' "https://github.com/${OWNER}/delivery-video-plugin" ;;
    *) return 1 ;;
  esac
}

plugin_note() {
  case "$1" in
    guster)         printf '%s\n' "context audit / .agents layout / CHI score" ;;
    galadon)        printf '%s\n' "Spec -> Build -> Verify -> Ship -> Learn loop" ;;
    baton)          printf '%s\n' "ticket / DAG / subagent control plane" ;;
    malo-browser)   printf '%s\n' "browser runtime for scripted demos (release tarball)" ;;
    delivery-video) printf '%s\n' "real-recording delivery video + quality gate" ;;
    *) return 1 ;;
  esac
}

usage() {
  cat <<'EOF'
Install the Lumos dev toolkit plugins into DeepSeek Harness.

Usage:
  ./install.sh [--dry-run] [--only a,b] [--dsh PATH] [--list]

Options:
  --dry-run     Print the commands without running them (does not need dsh).
  --only LIST   Install a comma-separated subset: guster,galadon,baton,
                malo-browser,delivery-video
  --dsh PATH    Path to the dsh CLI (default: $DSH_BIN, then `dsh` on PATH).
  --list        Show what would be installed, then exit.
  -h, --help    Show this help.

Installs from GitHub at the commits recorded in VERSIONS.md. malo-browser is
installed from its release tarball because a source install is missing the
built `out/` directory.
EOF
}

DRY_RUN=0
ONLY=""
DSH="${DSH_BIN:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --only)    [ $# -ge 2 ] || { echo "install: --only needs a value" >&2; exit 2; }
               ONLY="$2"; shift 2 ;;
    --dsh)     [ $# -ge 2 ] || { echo "install: --dsh needs a path" >&2; exit 2; }
               DSH="$2"; shift 2 ;;
    --list)    for name in "${PLUGIN_NAMES[@]}"; do
                 printf '%-16s %s\n' "$name" "$(plugin_note "$name")"
               done
               exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

selected=()
if [ -n "$ONLY" ]; then
  IFS=',' read -r -a requested <<<"$ONLY"
  for want in "${requested[@]}"; do
    want="$(printf '%s' "$want" | tr -d '[:space:]')"
    [ -n "$want" ] || continue
    found=0
    for name in "${PLUGIN_NAMES[@]}"; do
      [ "$name" = "$want" ] && found=1 && break
    done
    if [ "$found" -ne 1 ]; then
      echo "install: unknown plugin in --only: $want" >&2
      echo "install: choose from ${PLUGIN_NAMES[*]}" >&2
      exit 2
    fi
    selected+=("$want")
  done
  [ "${#selected[@]}" -gt 0 ] || { echo "install: --only selected nothing" >&2; exit 2; }
else
  selected=("${PLUGIN_NAMES[@]}")
fi

if [ "$DRY_RUN" -eq 0 ]; then
  if [ -z "$DSH" ]; then
    DSH="$(command -v dsh 2>/dev/null || true)"
  fi
  if [ -z "$DSH" ] || ! [ -x "$DSH" ]; then
    cat >&2 <<EOF
install: cannot find the dsh CLI.

Pass it explicitly:
  ./install.sh --dsh /path/to/dsh
or export it:
  DSH_BIN=/path/to/dsh ./install.sh

The commands this script would run:
$(for name in "${selected[@]}"; do printf '  dsh plugin add %s\n' "$(plugin_spec "$name")"; done)
EOF
    exit 1
  fi
fi

echo "Lumos dev toolkit"
echo "  plugins : ${#selected[@]} of ${#PLUGIN_NAMES[@]}"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  mode    : dry-run (nothing will be installed)"
fi
echo

failed=0
for name in "${selected[@]}"; do
  spec="$(plugin_spec "$name")"
  printf '==> %s\n' "$name"
  printf '    %s\n' "$(plugin_note "$name")"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '    $ dsh plugin add %s\n\n' "$spec"
    continue
  fi
  if "$DSH" plugin add "$spec"; then
    printf '    ok\n\n'
  else
    status=$?
    printf '    FAILED (exit %s)\n' "$status" >&2
    printf '    rerun by hand: %s plugin add %s\n' "$DSH" "$spec" >&2
    failed=1
    break
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "install: stopped after a failure; earlier plugins may already be installed." >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "dry-run complete; nothing was installed."
  exit 0
fi

cat <<'EOF'
installed.

Verify inside DeepSeek Harness:
  - ask for a plugin's skill by name (guster, galadon, baton, malo-browser,
    delivery-video) and let the agent load it
  - or run: dsh plugin list

See README.md for how the five fit together, and docs/seams.md for the two
places where they do NOT line up out of the box.
EOF
