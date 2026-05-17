# pape-superpowers

A **personal, intentionally-divergent fork** of [obra/superpowers](https://github.com/obra/superpowers), trimmed and personalized for Carter's Claude Code workflow. Upstream Superpowers is a harness-agnostic methodology, so it re-implements a lot of things Claude Code now does natively. This fork drops those redundant axes and rewires the survivors around plan mode and the pape-docs convention.

This is not meant to be useful to anyone else. See `CLAUDE.local.md` for the full rationale and `CLAUDE.obra.md` for the upstream project's original contributor policy (kept for provenance, not active here).

## What changed from upstream

**Deleted** — every axis that only re-implements a native Claude Code feature:

| Dropped axis | Why |
| --- | --- |
| `superpowers-plans` (writing-plans, executing-plans) | Native plan mode + Plan agent + plan files |
| `superpowers-worktrees` (using-git-worktrees) | Native `EnterWorktree`/`ExitWorktree` |
| `superpowers-subagents` (subagent-driven-development, dispatching-parallel-agents) | Native `Agent`/`Task` tools + parallel agents |
| `superpowers-finishing-branch` (finishing-a-development-branch) | Orphaned without plans+subagents; "merge or PR?" is a plain git ask |
| `superpowers-verification` (verification-before-completion) | Native verify-before-done + the harness's faithful-reporting rule |

**Kept** — the genuine, non-redundant discipline:

- `superpowers-foundation` — using-superpowers (bootstrap) + brainstorming (overhauled, see below)
- `superpowers-tdd` — test-driven-development
- `superpowers-debugging` — systematic-debugging
- `superpowers-code-review` — requesting-code-review, receiving-code-review
- `superpowers-writing-skills` — writing-skills (needed to maintain this fork)
- `superpowers` — umbrella, depends on the five survivors

**brainstorming was overhauled.** Instead of forcibly handing off to the deleted `writing-plans`, it now writes the agreed spec as a **pape-doc** (`pape-docs/<NNNN> <title>.md`, casual, git-excluded — never committed) and then presents a three-way exit:

1. **Hand off to plan mode** (recommended) — re-enter with the spec as input.
2. **Execute now** from the just-approved in-context spec.
3. **Stop at the spec** — the pape-doc is the deliverable.

No skill is force-invoked at the terminal.

## How it works

When you start building something, the agent doesn't jump to code. `using-superpowers` makes it check for a relevant skill first; for anything creative that's `brainstorming`, which teases a spec out of the conversation, shows it back in digestible chunks, gets your sign-off, writes the pape-doc, and then asks how you want to proceed. From there, plan mode (native) and `test-driven-development` / `systematic-debugging` / the code-review pair carry the actual implementation.

The skills trigger automatically — you don't invoke them by hand.

## The workflow

1. **brainstorming** — refines the idea through questions, explores alternatives, presents the design in sections, writes the spec pape-doc, then offers the three-way exit.
2. *(your choice)* native **plan mode**, execute now, or stop.
3. **test-driven-development** — RED-GREEN-REFACTOR; write the failing test, watch it fail, minimal code, watch it pass. Code written before its test gets deleted.
4. **systematic-debugging** — 4-phase root-cause process for any bug or unexpected behavior (bundles root-cause-tracing, defense-in-depth, condition-based-waiting).
5. **requesting-code-review** / **receiving-code-review** — dispatch a reviewer, then evaluate feedback technically rather than performatively.

`writing-skills` is the meta-axis for editing the skills themselves.

## Installation (Claude Code)

This fork is consumed as a Claude Code marketplace:

```bash
/plugin marketplace add CarterPape/pape-superpowers
/plugin install superpowers@pape-superpowers          # full trimmed set
# or install individual axes, e.g.:
/plugin install superpowers-foundation@pape-superpowers
```

The non-Claude harness configs (`.cursor-plugin/`, `.codex-plugin/`, `.opencode/`, `gemini-extension.json`, `GEMINI.md`) still resolve through the root `skills/` inverted symlinks if ever needed, but the maintained path is Claude Code.

## Philosophy

- **Test-Driven Development** — tests first, always
- **Systematic over ad-hoc** — root cause over guessing
- **Lean context** — don't pay session budget for skills that duplicate the harness

## Provenance & license

Built on [Superpowers](https://blog.fsck.com/2025/10/09/superpowers/) by [Jesse Vincent](https://blog.fsck.com) and Prime Radiant. MIT License — see `LICENSE`. This fork stays divergent and is not submitted upstream (see `CLAUDE.local.md` → "Why no PR upstream"); if Jesse's work has helped you, [sponsor it](https://github.com/sponsors/obra).
