#!/usr/bin/env bash
# Lumos dev toolkit — install the five plugins.
#
# Two modes, because "install into the agent" is not one thing:
#
#   dsh   (default)  a real plugin install: `dsh plugin add <spec>`. The host
#                    mounts the skill itself.
#   cli              portable install for hosts without a plugin system (Cursor,
#                    or any agent that only reads instruction files): fetch the
#                    sources, put the CLIs on PATH, and link the skills into the
#                    user-level skills dir. The CLIs work in any shell; the
#                    skill text is what tells an agent when to call them.
#   all              both.
#
# Two things are easy to get wrong, so they are encoded rather than documented:
#   * malo-browser has no usable source install. Its `out/` is gitignored and
#     produced by `npm run build`, so a clone leaves index.js pointing at a file
#     that does not exist. Both modes use its release tarball instead.
#   * Nothing is swallowed: a failed step prints the exact command and stops.
set -euo pipefail

OWNER="Lumos-789"
RAW_URL="https://raw.githubusercontent.com/${OWNER}/Lumos-dev-toolkit/main/install.sh"
MALO_VERSION="0.1.6"
MALO_TARBALL="https://github.com/${OWNER}/malo-browser/releases/download/v${MALO_VERSION}/malo-browser-${MALO_VERSION}-dsh.tgz"

MODE="dsh"
LUMOS_HOME="${LUMOS_HOME:-$HOME/.local/share/lumos-dev-toolkit}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"

PLUGIN_NAMES=(guster galadon baton malo-browser delivery-video)

plugin_repo() {
  case "$1" in
    guster)         printf '%s\n' "https://github.com/${OWNER}/guster" ;;
    galadon)        printf '%s\n' "https://github.com/${OWNER}/galadon" ;;
    baton)          printf '%s\n' "https://github.com/${OWNER}/baton" ;;
    malo-browser)   printf '%s\n' "https://github.com/${OWNER}/malo-browser" ;;
    delivery-video) printf '%s\n' "https://github.com/${OWNER}/delivery-video-plugin" ;;
    *) return 1 ;;
  esac
}

plugin_spec() {
  case "$1" in
    malo-browser) printf '%s\n' "${MALO_TARBALL}" ;;
    *)            plugin_repo "$1" ;;
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

# Path of the command-line entry inside the source tree; empty when the plugin
# ships no standalone CLI (the skill drives its scripts instead).
plugin_cli() {
  case "$1" in
    guster)   printf '%s\n' "bin/guster" ;;
    galadon)  printf '%s\n' "bin/galadon" ;;
    baton)    printf '%s\n' "scripts/session_control.py" ;;
    *)        printf '\n' ;;
  esac
}

usage() {
  cat <<'EOF'
Install the Lumos dev toolkit into a machine.

Usage:
  ./install.sh [--mode dsh|cli|all] [--dry-run] [--only a,b] [--dsh PATH]

Modes:
  dsh    Install as DeepSeek Harness plugins (default). Needs the dsh CLI.
  cli    Portable: fetch sources, put CLIs on PATH, link skills into the
         user-level skills dir. Works with Cursor and other hosts that have no
         plugin system.
  all    Both.

Options:
  --dry-run     Print what would happen without doing it (needs no dsh).
  --only LIST   Subset: guster,galadon,baton,malo-browser,delivery-video
  --dsh PATH    Path to the dsh CLI (default: $DSH_BIN, then `dsh` on PATH).
  --list        Show the five plugins, then exit.
  -h, --help    Show this help.

Environment (cli mode):
  LUMOS_HOME   Where sources are kept  (default ~/.local/share/lumos-dev-toolkit)
  BIN_DIR      Where CLIs are linked   (default ~/.local/bin)
  SKILLS_DIR   Where skills are linked (default ~/.agents/skills)
EOF
}

DRY_RUN=0
ONLY=""
DSH="${DSH_BIN:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --mode)    [ $# -ge 2 ] || { echo "install: --mode needs a value" >&2; exit 2; }
               MODE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --only)    [ $# -ge 2 ] || { echo "install: --only needs a value" >&2; exit 2; }
               ONLY="$2"; shift 2 ;;
    --dsh)     [ $# -ge 2 ] || { echo "install: --dsh needs a path" >&2; exit 2; }
               DSH="$2"; shift 2 ;;
    --list)    for name in "${PLUGIN_NAMES[@]}"; do
                 cli="$(plugin_cli "$name")"
                 printf '%-16s %-58s cli:%s\n' "$name" "$(plugin_note "$name")" "${cli:-none}"
               done
               exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  dsh|cli|all) ;;
  *) echo "install: --mode must be dsh, cli or all (got '$MODE')" >&2; exit 2 ;;
esac

selected=()
if [ -n "$ONLY" ]; then
  IFS=',' read -r -a requested <<<"$ONLY"
  for want in "${requested[@]}"; do
    want="$(printf '%s' "$want" | tr -d '[:space:]')"
    [ -n "$want" ] || continue
    found=0
    for name in "${PLUGIN_NAMES[@]}"; do
      if [ "$name" = "$want" ]; then found=1; break; fi
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

want_dsh=0
want_cli=0
case "$MODE" in
  dsh) want_dsh=1 ;;
  cli) want_cli=1 ;;
  all) want_dsh=1; want_cli=1 ;;
esac

if [ "$DRY_RUN" -eq 0 ] && [ "$want_dsh" -eq 1 ]; then
  if [ -z "$DSH" ]; then
    DSH="$(command -v dsh 2>/dev/null || true)"
  fi
  if [ -z "$DSH" ] || ! [ -x "$DSH" ]; then
    # Piped from curl there is no ./install.sh on disk, so retry hints must show
    # the form the user actually typed. An inline VAR=... before a pipeline only
    # reaches curl, hence the export form for the piped case. $0 is useless here
    # (it is "/bin/bash" when piped, and that file exists), so use BASH_SOURCE,
    # which is empty for a stdin script.
    if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
      HINT_DASH="$0 --dsh <path-to-dsh>"
      HINT_EXPORT="DSH_BIN=<path-to-dsh> $0"
    else
      HINT_DASH="curl -fsSL $RAW_URL | bash -s -- --dsh <path-to-dsh>"
      HINT_EXPORT="export DSH_BIN=<path-to-dsh>; curl -fsSL $RAW_URL | bash -s --"
    fi
    cat >&2 <<EOF
install: cannot find the dsh CLI.

Pass it explicitly:
  $HINT_DASH
or point DSH_BIN at it:
  $HINT_EXPORT

If you do not use DeepSeek Harness, the portable install needs no dsh at all:
  ${HINT_DASH%--dsh <path-to-dsh>}--mode cli

The commands dsh mode would run:
$(for name in "${selected[@]}"; do printf '  dsh plugin add %s\n' "$(plugin_spec "$name")"; done)
EOF
    exit 1
  fi
fi

echo "Lumos dev toolkit"
echo "  mode    : $MODE"
if [ "$DRY_RUN" -eq 1 ]; then echo "  dry-run : nothing will be written"; fi
echo "  plugins : ${#selected[@]} of ${#PLUGIN_NAMES[@]}"
if [ "$want_cli" -eq 1 ]; then
  echo "  sources : $LUMOS_HOME"
  echo "  bin     : $BIN_DIR"
  echo "  skills  : $SKILLS_DIR"
fi
echo

fail() { printf '    FAILED: %s\n' "$*" >&2; exit 1; }

install_dsh() {
  for name in "${selected[@]}"; do
    spec="$(plugin_spec "$name")"
    printf '==> %s (dsh)\n' "$name"
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
      printf 'install: stopped after a failure; earlier plugins may be installed.\n' >&2
      exit 1
    fi
  done
}

fetch_source() {
  name="$1"
  dest="$LUMOS_HOME/$name"
  if [ -e "$dest" ]; then
    printf '    already present: %s\n' "$dest"
    return 0
  fi
  case "$name" in
    malo-browser)
      tmp="$(mktemp -d)"
      curl -fsSL -o "$tmp/payload.tgz" "$MALO_TARBALL" \
        || fail "download failed: $MALO_TARBALL"
      mkdir -p "$dest"
      tar xzf "$tmp/payload.tgz" -C "$dest" --strip-components=1 \
        || fail "extract failed: $tmp/payload.tgz"
      rm -rf "$tmp"
      [ -f "$dest/out/main/index.js" ] \
        || fail "malo-browser tarball is missing out/main/index.js"
      [[ "$(cat "$dest/package.json" 2>/dev/null)" == *"\"version\": \"$MALO_VERSION\""* ]] \
        || fail "malo-browser tarball is not version $MALO_VERSION"
      ;;
    *)
      git clone --depth 1 "$(plugin_repo "$name")" "$dest" >/dev/null 2>&1 \
        || fail "git clone failed: $(plugin_repo "$name")"
      ;;
  esac
  printf '    fetched: %s\n' "$dest"
}

link_cli() {
  name="$1"
  rel="$(plugin_cli "$name")"
  [ -n "$rel" ] || return 0
  src="$LUMOS_HOME/$name/$rel"
  [ -f "$src" ] || fail "$name: expected CLI at $src"
  # baton's entry point is committed without the exec bit (it is imported as a
  # module upstream); the local clone is ours to fix.
  [ -x "$src" ] || chmod +x "$src"
  mkdir -p "$BIN_DIR"
  ln -sfn "$src" "$BIN_DIR/$name"
  printf '    cli: %s -> %s\n' "$BIN_DIR/$name" "$src"
}

link_skills() {
  name="$1"
  dir="$LUMOS_HOME/$name/skills"
  [ -d "$dir" ] || { printf '    skills: none shipped\n'; return 0; }
  mkdir -p "$SKILLS_DIR"
  for skill in "$dir"/*; do
    [ -d "$skill" ] || continue
    base="$(basename "$skill")"
    ln -sfn "$skill" "$SKILLS_DIR/$base"
    printf '    skill: %s -> %s\n' "$SKILLS_DIR/$base" "$skill"
  done
}

install_cli() {
  for name in "${selected[@]}"; do
    printf '==> %s (cli)\n' "$name"
    printf '    %s\n' "$(plugin_note "$name")"
    if [ "$DRY_RUN" -eq 1 ]; then
      case "$name" in
        malo-browser) printf '    $ curl -fsSL %s | tar xz --strip-components=1 -C %s\n' "$MALO_TARBALL" "$LUMOS_HOME/$name" ;;
        *)            printf '    $ git clone --depth 1 %s %s\n' "$(plugin_repo "$name")" "$LUMOS_HOME/$name" ;;
      esac
      rel="$(plugin_cli "$name")"
      if [ -n "$rel" ]; then printf '    $ ln -s %s/%s %s/%s\n' "$LUMOS_HOME/$name" "$rel" "$BIN_DIR" "$name"; fi
      printf '    $ ln -s %s/%s/skills/* %s/\n\n' "$LUMOS_HOME" "$name" "$SKILLS_DIR"
      continue
    fi
    fetch_source "$name"
    link_cli "$name"
    link_skills "$name"
    printf '\n'
  done
}

if [ "$want_dsh" -eq 1 ]; then install_dsh; fi
if [ "$want_cli" -eq 1 ]; then install_cli; fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "dry-run complete; nothing was written."
  exit 0
fi

if [ "$want_dsh" -eq 1 ]; then
  echo "DSH plugins installed. Verify with: dsh plugin list"
fi

if [ "$want_cli" -eq 1 ]; then
  echo "CLI install done."
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "  note: $BIN_DIR is not on PATH; add it to run the CLIs." ;;
  esac
  cat <<EOF

  The CLIs work in any shell, including Cursor's terminal:
    guster scan | galadon check | baton status

  Skills are linked under $SKILLS_DIR. Hosts that read that directory
  (DSH, Codex) pick them up as-is. For a host that only reads project files
  (Cursor rules, AGENTS.md), point it at the skill once, e.g.:

    当需要上下文治理 / 工程循环 / 任务派发 / 演示录制 / 交付视频时，
    先读 $SKILLS_DIR/<name>/SKILL.md，按里面的命令执行。

  Updating later: \`git -C $LUMOS_HOME/<name> pull\` (the skill links follow).
EOF
fi
