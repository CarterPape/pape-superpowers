#!/usr/bin/env bash
# Verify (and repair) the inverted-symlink layout: every root-level
# skills/<skill> and hooks/<file> entry should be a relative symlink that
# points into the correct plugins/<axis>/{skills,hooks}/ canonical location.
#
# Single source of truth lives under plugins/<axis>/. Root entries are
# symlinks so non-Claude harnesses (Cursor, Codex, OpenCode, Gemini) can
# keep reading from a flat root namespace while the Claude Code plugin
# install pipeline ingests each axis subtree as pure files.
#
# Run after every upstream pull; the /sync command does it automatically.
# Idempotent — re-running on an already-correct tree is a no-op.
#
# Bails out loudly on anything that needs human attention:
#   - a root entry exists as a regular file or directory (e.g. upstream
#     added a new skill that has not been assigned to an axis yet)
#   - an expected canonical target under plugins/<axis>/ is missing
#   - a symlink points somewhere unexpected
#   - a skill is claimed by more than one axis (mapping bug)

set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

# Map axis plugin name -> space-separated skill names that live in it.
# Keep in sync with .claude-plugin/marketplace.json and
# plugins/superpowers/.claude-plugin/plugin.json (the umbrella's deps).
declare -a AXES=(
  "superpowers-foundation:using-superpowers brainstorming"
  "superpowers-tdd:test-driven-development"
  "superpowers-verification:verification-before-completion"
  "superpowers-code-review:requesting-code-review receiving-code-review"
  "superpowers-finishing-branch:finishing-a-development-branch"
  "superpowers-worktrees:using-git-worktrees"
  "superpowers-subagents:subagent-driven-development dispatching-parallel-agents"
  "superpowers-plans:writing-plans executing-plans"
  "superpowers-debugging:systematic-debugging"
  "superpowers-writing-skills:writing-skills"
)

# Foundation owns the SessionStart hook (it bootstraps using-superpowers).
HOOK_OWNER="superpowers-foundation"
HOOK_FILES=(hooks.json hooks-cursor.json session-start run-hook.cmd)

errors=0
fixed=0
checked=0

err() { echo "✘ $*" >&2; errors=$((errors + 1)); }
fix() { echo "🔧 $*"; fixed=$((fixed + 1)); }

# Verify (and repair) a single root entry: ensure rel-link "$root_path"
# points to "$expected_target" (a path relative to the directory holding
# the symlink). Bails on the root entry being a regular file/dir.
verify_link() {
  local root_path="$1" expected_target="$2" canonical_abs="$3"
  checked=$((checked + 1))

  if [[ ! -e "$canonical_abs" && ! -L "$canonical_abs" ]]; then
    err "canonical target missing: $canonical_abs (cannot link $root_path)"
    return
  fi

  if [[ -L "$root_path" ]]; then
    local current
    current="$(readlink "$root_path")"
    if [[ "$current" == "$expected_target" ]]; then
      return
    fi
    err "$root_path symlinks to '$current'; expected '$expected_target'"
    return
  fi

  if [[ -e "$root_path" ]]; then
    err "$root_path exists as a regular file or directory; expected a symlink to $expected_target. (Likely an unassigned upstream addition — assign it to an axis in this script's AXES table, then move it under plugins/<axis>/.)"
    return
  fi

  ln -s "$expected_target" "$root_path"
  fix "created $root_path -> $expected_target"
}

echo "🔍 Verifying inverted-symlink layout (root → plugins/<axis>/)"

# 1. Sanity: no skill claimed by more than one axis.
owned_list=""
for entry in "${AXES[@]}"; do
  axis="${entry%%:*}"
  skills="${entry#*:}"
  for skill in $skills; do
    prior=$(printf '%s\n' "$owned_list" | awk -F: -v s="$skill" '$1==s{print $2}')
    if [[ -n "$prior" ]]; then
      err "skill '$skill' is claimed by both '$prior' and '$axis'"
    fi
    owned_list="${owned_list}${skill}:${axis}"$'\n'
  done
done

# 2. Verify every owned skill is symlinked at root and present at plugins/<axis>/.
mkdir -p skills
for entry in "${AXES[@]}"; do
  axis="${entry%%:*}"
  skills="${entry#*:}"
  for skill in $skills; do
    canonical_abs="$REPO_ROOT/plugins/$axis/skills/$skill"
    expected_target="../plugins/$axis/skills/$skill"
    verify_link "skills/$skill" "$expected_target" "$canonical_abs"
  done
done

# 3. Surface any root skill that has no axis assignment. Could be a stale
#    leftover (skill removed upstream but root entry still present) or a
#    fresh upstream addition we need to slot into an axis.
if [[ -d skills ]]; then
  for entry in skills/*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    name="$(basename "$entry")"
    if ! printf '%s\n' "$owned_list" | awk -F: -v s="$name" 'BEGIN{f=0}$1==s{f=1}END{exit !f}'; then
      err "skills/$name has no axis assignment in this script's AXES table"
    fi
  done
fi

# 4. Verify hooks. All four hook files live under plugins/$HOOK_OWNER/hooks/
#    and are exposed as root symlinks.
mkdir -p hooks
for f in "${HOOK_FILES[@]}"; do
  canonical_abs="$REPO_ROOT/plugins/$HOOK_OWNER/hooks/$f"
  expected_target="../plugins/$HOOK_OWNER/hooks/$f"
  verify_link "hooks/$f" "$expected_target" "$canonical_abs"
done

if [[ $errors -gt 0 ]]; then
  echo "❌ ${errors} problem(s) — fix them and re-run." >&2
  exit 1
fi

if [[ $fixed -gt 0 ]]; then
  echo "✅ checked ${checked} entr(ies); repaired ${fixed}."
else
  echo "✅ checked ${checked} entr(ies); already in sync."
fi
