#!/usr/bin/env bash
# Qadvisor build script.
#
# The 17 advisor skills (skills/qadvisor-{id}/SKILL.md) are the single source of
# truth. The dispatcher skill (skills/qadvisor/) carries a generated copy of each
# advisor's body in skills/qadvisor/advisors/{id}.md so that it works on its own
# when uploaded to claude.ai / Claude Cowork as one custom skill.
#
# Usage:
#   bash scripts/build.sh [sync]   regenerate skills/qadvisor/advisors/*.md
#   bash scripts/build.sh check    verify generated files and skill metadata (CI)
#   bash scripts/build.sh bundle   sync, then build dist/qadvisor-skill.zip
#                                  (claude.ai-safe: frontmatter is name,
#                                  description and license only)
#
# Portable: macOS bash 3.2 and Linux; needs only POSIX tools, awk and zip.

set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILLS="$ROOT/skills"
DISPATCHER="$SKILLS/qadvisor"
ADVISORS="$DISPATCHER/advisors"
DIST="$ROOT/dist"
MAX_DESC_CHARS=1024          # platform limit (Agent Skills spec, claude.ai upload)
MAX_ADVISOR_DESC_CHARS=260   # project limit: one-line advisor descriptions
MAX_DISPATCHER_DESC_CHARS=1000  # project limit: headroom under the platform cap
BUNDLE_LICENSE=MIT

die() { echo "error: $*" >&2; exit 1; }

# List advisor ids (directory name minus "qadvisor-"), one per line, sorted.
advisor_ids() {
  for dir in "$SKILLS"/qadvisor-*/; do
    [ -f "${dir}SKILL.md" ] || continue
    name=$(basename "$dir")
    echo "${name#qadvisor-}"
  done
}

# Print the YAML frontmatter (without the --- fences). Empty if none.
frontmatter() {
  awk 'NR == 1 { if ($0 != "---") exit; next }
       /^---[[:space:]]*$/ { exit }
       { print }' "$1"
}

# Print the body after the frontmatter, with leading blank lines removed.
body() {
  awk 'NR == 1 && $0 == "---" { infm = 1; next }
       infm && /^---[[:space:]]*$/ { infm = 0; next }
       infm { next }
       !started && /^[[:space:]]*$/ { next }
       { started = 1; print }' "$1"
}

# Print the value of a top-level scalar key from frontmatter on stdin.
# Handles plain, "double-quoted", 'single-quoted' and block (> / |) scalars;
# multi-line values are joined with single spaces (YAML folding).
fm_value() {
  awk -v key="$1" -v q="'" '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    function emit(v) {
      v = trim(v)
      if (v ~ /^".*"$/) { v = substr(v, 2, length(v) - 2); gsub(/\\"/, "\"", v); gsub(/\\\\/, "\\", v) }
      else if (substr(v, 1, 1) == q && substr(v, length(v), 1) == q && length(v) >= 2) { v = substr(v, 2, length(v) - 2); gsub(q q, q, v) }
      print v; found = 1
    }
    collecting {
      if ($0 ~ /^[^[:space:]]/) { emit(val); exit }
      line = trim($0)
      if (line != "") val = (val == "" ? line : val " " line)
      next
    }
    index($0, key ":") == 1 {
      rest = trim(substr($0, length(key) + 2))
      if (rest ~ /^[>|][-+0-9]*$/ || rest == "") { collecting = 1; val = ""; next }
      if (rest ~ /^"/ && rest !~ /[^\\]"$/) { collecting = 1; val = rest; next }  # multi-line quoted
      emit(rest); exit
    }
    END { if (collecting && !found) emit(val) }
  '
}

# Count UTF-8 characters (not bytes): drop continuation bytes, count the rest.
char_count() {
  printf '%s' "$1" | LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' '
}

header_for() {
  echo "<!-- Generated from skills/qadvisor-$1/SKILL.md by scripts/build.sh — edit the source, not this file. -->"
}

# Write the generated advisor file for id $1 to path $2.
render() {
  {
    header_for "$1"
    echo
    body "$SKILLS/qadvisor-$1/SKILL.md"
  } > "$2"
}

cmd_sync() {
  [ -f "$DISPATCHER/SKILL.md" ] || die "missing $DISPATCHER/SKILL.md"
  mkdir -p "$ADVISORS"
  n=0
  for id in $(advisor_ids); do
    tmp="$ADVISORS/.$id.md.tmp"
    render "$id" "$tmp"
    if [ -f "$ADVISORS/$id.md" ] && cmp -s "$tmp" "$ADVISORS/$id.md"; then
      rm -f "$tmp"
    else
      mv "$tmp" "$ADVISORS/$id.md"
      echo "sync: wrote skills/qadvisor/advisors/$id.md"
    fi
    n=$((n + 1))
  done
  for f in "$ADVISORS"/*.md; do
    [ -e "$f" ] || continue
    id=$(basename "$f" .md)
    if [ ! -f "$SKILLS/qadvisor-$id/SKILL.md" ]; then
      rm -f "$f"
      echo "sync: removed orphan skills/qadvisor/advisors/$id.md"
    fi
  done
  echo "sync: OK ($n advisors)"
}

cmd_check() {
  errors=0
  fail() { echo "check: FAIL: $*" >&2; errors=$((errors + 1)); }

  [ -f "$DISPATCHER/SKILL.md" ] || die "missing $DISPATCHER/SKILL.md"
  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/qadvisor-check.XXXXXX")
  trap 'rm -rf "$tmpdir"' EXIT

  # (b) + (c): name matches directory; description present and within its
  # limit: 260 chars for advisors, 1000 for the dispatcher, 1024 otherwise.
  for skill in "$SKILLS"/*/SKILL.md; do
    [ -e "$skill" ] || continue
    dir=$(basename "$(dirname "$skill")")
    rel="skills/$dir/SKILL.md"
    case "$dir" in
      qadvisor) max=$MAX_DISPATCHER_DESC_CHARS ;;
      qadvisor-*) max=$MAX_ADVISOR_DESC_CHARS ;;
      *) max=$MAX_DESC_CHARS ;;
    esac
    fm=$(frontmatter "$skill")
    if [ -z "$fm" ]; then fail "$rel: missing YAML frontmatter"; continue; fi
    name=$(printf '%s\n' "$fm" | fm_value name)
    [ "$name" = "$dir" ] || fail "$rel: frontmatter name '$name' does not match directory '$dir'"
    desc=$(printf '%s\n' "$fm" | fm_value description)
    if [ -z "$desc" ]; then
      fail "$rel: description is missing or empty"
    else
      len=$(char_count "$desc")
      [ "$len" -le "$max" ] || fail "$rel: description is $len characters (max $max)"
    fi
  done

  n=0
  for id in $(advisor_ids); do
    n=$((n + 1))
    src="$SKILLS/qadvisor-$id/SKILL.md"
    # (d) advisors are reached through the dispatcher, never auto-invoked.
    if ! frontmatter "$src" | grep -Eq '^disable-model-invocation:[[:space:]]*true[[:space:]]*$'; then
      fail "skills/qadvisor-$id/SKILL.md: frontmatter lacks 'disable-model-invocation: true'"
    fi
    # (e) dispatcher must reference every advisor file.
    grep -Fq "advisors/$id.md" "$DISPATCHER/SKILL.md" ||
      fail "skills/qadvisor/SKILL.md: no reference to 'advisors/$id.md'"
    # (a) generated file present and up to date.
    gen="$ADVISORS/$id.md"
    if [ ! -f "$gen" ]; then
      fail "skills/qadvisor/advisors/$id.md is missing (run: bash scripts/build.sh sync)"
    else
      render "$id" "$tmpdir/$id.md"
      cmp -s "$tmpdir/$id.md" "$gen" ||
        fail "skills/qadvisor/advisors/$id.md is stale (run: bash scripts/build.sh sync)"
    fi
  done
  [ "$n" -gt 0 ] || fail "no advisor skills found under skills/qadvisor-*/"

  # (a) orphans: generated files whose source skill is gone.
  for f in "$ADVISORS"/*.md; do
    [ -e "$f" ] || continue
    id=$(basename "$f" .md)
    [ -f "$SKILLS/qadvisor-$id/SKILL.md" ] ||
      fail "skills/qadvisor/advisors/$id.md is orphaned: skills/qadvisor-$id/SKILL.md does not exist (run: bash scripts/build.sh sync)"
  done

  if [ "$errors" -gt 0 ]; then
    echo "check: $errors problem(s) found" >&2
    exit 1
  fi
  echo "check: OK ($n advisors)"
}

# Quote a one-line string as a YAML double-quoted scalar (escape \ and ").
# sed, not awk gsub: awk implementations disagree on backslashes in replacements.
yaml_quote() {
  printf '"%s"' "$(printf '%s\n' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
}

# Write the claude.ai-safe dispatcher SKILL.md to $1. claude.ai's skill upload
# rejects any frontmatter key outside name, description, license,
# compatibility, metadata and allowed-tools ("Unexpected key(s) in SKILL.md
# frontmatter"), so Claude Code-only keys such as argument-hint are dropped:
# keep name and description, add license. The body is copied unchanged.
render_bundle_skill() {
  folder=$(basename "$(dirname "$1")")   # the skill's folder inside the zip
  fm=$(frontmatter "$DISPATCHER/SKILL.md")
  [ -n "$fm" ] || die "skills/qadvisor/SKILL.md: missing YAML frontmatter"
  name=$(printf '%s\n' "$fm" | fm_value name)
  desc=$(printf '%s\n' "$fm" | fm_value description)
  [ "$name" = "$folder" ] ||
    die "bundle: frontmatter name '$name' does not match folder '$folder'"
  [ -n "$desc" ] || die "bundle: description is missing or empty"
  len=$(char_count "$desc")
  [ "$len" -le "$MAX_DESC_CHARS" ] ||
    die "bundle: description is $len characters (claude.ai max $MAX_DESC_CHARS)"
  {
    echo "---"
    echo "name: $name"
    echo "description: $(yaml_quote "$desc")"
    echo "license: $BUNDLE_LICENSE"
    echo "---"
    echo
    body "$DISPATCHER/SKILL.md"
  } > "$1"
  # Self-check: the written frontmatter round-trips and uses only allowed keys.
  bad=$(frontmatter "$1" | awk -F: '/^[^[:space:]#][^:]*:/ { print $1 }' |
        grep -Ev '^(name|description|license|compatibility|metadata|allowed-tools)$' || true)
  [ -z "$bad" ] || die "bundle: disallowed frontmatter key(s): $bad"
  [ "$(frontmatter "$1" | fm_value description)" = "$desc" ] ||
    die "bundle: description did not round-trip through YAML quoting"
}

cmd_bundle() {
  command -v zip >/dev/null 2>&1 || die "'zip' is not installed"
  cmd_sync
  stage=$(mktemp -d "${TMPDIR:-/tmp}/qadvisor-bundle.XXXXXX")
  trap 'rm -rf "$stage"' EXIT
  mkdir -p "$stage/qadvisor/advisors"
  render_bundle_skill "$stage/qadvisor/SKILL.md"
  cp "$ADVISORS"/*.md "$stage/qadvisor/advisors/"
  mkdir -p "$DIST"
  out="$DIST/qadvisor-skill.zip"
  rm -f "$out"
  (cd "$stage" && zip -q -r -X "$out" qadvisor)
  size=$(wc -c < "$out" | tr -d ' ')
  echo "bundle: ${out#"$ROOT"/} ($size bytes)"
}

case "${1:-sync}" in
  sync) cmd_sync ;;
  check) cmd_check ;;
  bundle) cmd_bundle ;;
  -h|--help|help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) echo "usage: bash scripts/build.sh [sync|check|bundle]" >&2; exit 2 ;;
esac
