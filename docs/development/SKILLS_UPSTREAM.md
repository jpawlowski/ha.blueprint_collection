# Agent Skills — Coordination With the Upstream Chassis

**Written:** 2026-08-09 · **Checked against upstream:** 2026-08-11 (`a4b9fae`) ·
**Verified against:** Home Assistant 2026.8.1, Claude Code 2.1.226

This repository and the upstream development chassis
([jpawlowski/hacs.integration_blueprint](https://github.com/jpawlowski/hacs.integration_blueprint))
built an agent-skill layer at the same time, independently.

## Convergence — the good news

Both arrived at the same core design without coordinating:

| Decision                                           | Here | Upstream |
| -------------------------------------------------- | ---- | -------- |
| `.agents/skills/` as the real location             | yes  | yes      |
| One `.claude/skills` → `../.agents/skills` symlink | yes  | yes      |
| No `.github/skills` symlink                        | yes  | yes      |
| Markdown tooling extended to `.agents/`            | yes  | yes      |

**Asks 1 and 2 below are therefore already satisfied.** Upstream's `script/markdown` and
`script/markdown-check` now glob `.agents/**/*.md`, which is broader than what this
repository asked for and removes the need for the `globs` workaround in
`.markdownlint-cli2.jsonc` here.

## Where upstream went further

Upstream treats `.agents/` as the root for **all** agent configuration, not just skills:

```text
.agents/README.md
.agents/instructions/          ← the path-scoped instruction files live here
.agents/skills/                ← 16 skills
.agents/scratch/               ← agent scratch space, never committed
.claude/skills   -> ../.agents/skills
.claude/rules/
.github/instructions -> ../.agents/instructions
script/skills-check            ← validates skills against agentskills.io
```

Three deltas this repository has not adopted:

1. **`.github/instructions/` is a symlink into `.agents/instructions/`.** Here those are
   still real files. Adopting this would finish the consolidation.
2. **`script/skills-check` validates skills against the
   [Agent Skills specification](https://agentskills.io/specification)** — frontmatter
   fields, name and description limits, body length, reference depth, resolvable links.
   Nothing here checks that; the skills in this repository have not been run against it.
3. **`.agents/scratch/`** replaces the `.ai-scratch/` convention referenced in `AGENTS.md`.

Upstream has **no vendoring mechanism**, so `script/skills-sync` and the vendored
`ha-automation-patterns` remain this repository's own contribution — Ask 3 still stands.

## Naming — the real collision

There are no duplicate skill names today, but the terminology collides, and this is the
thing to settle before either side syncs:

- Upstream's `blueprint-import`, `blueprint-scaffold`, `blueprint-tooling`,
  `blueprint-skill-maintenance` use "blueprint" to mean **the integration blueprint
  template**. In this repository, `AGENTS.md` explicitly defines "blueprint" as **a Home
  Assistant blueprint**. Syncing those names down here would contradict the repository's own
  terminology rule, in the exact way that rule exists to prevent.
- Upstream's `ha-release` and `ha-testing` overlap in purpose with `ha-blueprint-release`
  and `ha-blueprint-testing` here, while meaning something different (integration releases,
  integration tests).

A workable split: **`ha-blueprint-*` for Home Assistant blueprint work** (this repository),
**`ha-integration-*` for integration development** (upstream), and reserve unprefixed
`blueprint-*` for neither. That requires renames upstream, so it is worth deciding early.

## What exists here today

```text
.agents/skills/                        The real files — cross-agent convention
├── README.md
├── ha-blueprint-authoring/            SKILL.md + 8 references
├── ha-automation-patterns/            wrapper SKILL.md + vendor/ (third-party, verbatim)
├── ha-blueprint-testing/              SKILL.md + 2 references
└── ha-blueprint-release/              SKILL.md

.claude/skills -> ../.agents/skills    One directory symlink, for Claude Code only

.github/skills-manifest.txt            Vendored sources, pinned commits, file mappings
script/skills-sync                     --check / restore / --update
.github/workflows/skills-sync.yml      PR check + weekly update PR
```

Nothing in this list is chassis-managed — verified against `.github/chassis-manifest.txt`.
It was created against an upstream that showed `Differing: 0`; since upstream's own
restructuring on 2026-08-11 the same check reports 16 differing files, none of which this
work touched.

## Verified facts

These were established empirically, not from documentation or memory. Upstream can rely on
them without repeating the work; each line names how to re-check it.

### Skill discovery

| Agent          | Reads `.agents/skills/`? | Consequence                        |
| -------------- | ------------------------ | ---------------------------------- |
| GitHub Copilot | **yes**, natively        | no `.github/skills` symlink needed |
| ChatGPT Codex  | **yes**, natively        | nothing needed                     |
| Claude Code    | **no**                   | `.claude/skills` symlink required  |

- Copilot's documented project-skill locations are `.github/skills`, `.claude/skills`, **and**
  `.agents/skills` ([GitHub docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)).
- Claude Code's shipped binary contains **zero** occurrences of `.agents/skills` and 75 of
  `.claude/skills`. Re-check after any Claude Code update:

  ```bash
  C=$(ls ~/.vscode-server/extensions/anthropic.claude-code-*/resources/native-binary/claude | head -1)
  strings -a "$C" | grep -c ".agents/skills"   # 0 today → symlink still needed
  ```

- **A directory symlink is sufficient**; per-skill symlinks are not required. Confirmed by
  observation: with `.claude/skills -> ../.agents/skills`, all four skills appear in the
  session's skill list. Claude Code's documentation only promises symlink support for a
  `<skill-name>` entry, so keep the per-skill fallback documented
  (`.agents/skills/README.md`) in case that changes.

### Tooling constraints found the hard way

- **`script/markdown` and `script/markdown-check` are chassis-managed, so their Prettier
  globs cannot be changed downstream.** They were `*.md docs/**/*.md .github/**/*.md`, which
  did not reach `.agents/skills/`; upstream has since extended them to include
  `.agents/**/*.md`. Recorded because it is the shape of problem that recurs: a formatter
  glob living in a file this repository may not edit.

- **markdownlint-cli2 _can_ be extended without touching chassis files** — `.markdownlint-cli2.jsonc`
  supports a `globs` key that adds to the command-line globs, and an `ignores` key. That is how
  this repository covers `.agents/skills/**/*.md` today.
- **Prettier has no equivalent.** Its globs live in the chassis script. The pre-commit hook
  (`types: [markdown]`, `pass_filenames: true`) does cover the directory because it operates on
  staged paths, so the gap only shows in a manual `script/markdown` run.
- **A symlinked second path must be excluded from linters.** With both `.github/skills` and
  `.agents/skills` visible, markdownlint-cli2 followed the symlink and Prettier did not — so the
  same file was reported as failing through one path and passing through the other. Exclude every
  symlinked path and lint through the real one.
- **`vendor/` directories must be excluded from all formatters.** A formatting fix there breaks
  the byte-identity that the drift check depends on.

### Vendoring

- Third-party skill material is vendored **verbatim** and pinned to a commit, not a branch.
  A pinned commit is not directly cloneable; `git init`, `fetch --depth 1 <sha>`, then
  `checkout FETCH_HEAD` is required.
- `--update` must preserve manifest comments and blank lines; only the `REF` line moves.
- `script/skills-sync` **no-ops with exit 0 when the manifest is absent.** A repository that
  vendors nothing can carry the script without its CI turning red — this is what makes the
  script chassis-suitable.

## Proposed ownership split

> **The chassis owns the mechanism. Each repository owns its content.**

| Artefact                                                    | Owner       | Rationale                                                                 |
| ----------------------------------------------------------- | ----------- | ------------------------------------------------------------------------- |
| `script/skills-sync`                                        | **chassis** | Generic; no Home Assistant or blueprint knowledge in it                   |
| `.github/workflows/skills-sync.yml`                         | **chassis** | Mirrors `chassis-sync.yml` exactly                                        |
| `.agents/skills/` layout + `.claude/skills` symlink         | **chassis** | A convention only helps if both repositories use the same one             |
| Formatter/linter wiring for `.agents/skills/` and `vendor/` | **chassis** | Requires editing chassis-owned scripts — impossible downstream            |
| `.github/skills-manifest.txt`                               | repository  | Per-repo content, exactly like `.github/chassis-manifest.txt`             |
| The skills themselves                                       | repository  | HA blueprint knowledge is irrelevant to integration development           |
| `initialize.sh` removal block for the sync workflow         | see below   | Currently repo-owned; becomes chassis-owned if upstream adopts the script |

## Asks of the upstream chassis

1. ~~**Extend the Prettier globs in `script/markdown` / `script/markdown-check`.**~~
   **Done upstream in `a4b9fae`** — both now glob `.agents/**/*.md`. Once this repository
   syncs that, the `globs` key in `.markdownlint-cli2.jsonc` becomes redundant and should be
   removed; keep the `ignores` entries.

2. ~~**Adopt `.agents/skills/` with a single `.claude/skills` symlink.**~~
   **Done upstream** — identical to the layout here.

3. **Take `script/skills-sync` and `.github/workflows/skills-sync.yml` into the chassis**
   if vendoring third-party skill material is wanted there. Upstream has no equivalent today.
   Both are ready: the script no-ops with exit 0 when no manifest exists, so a repository that
   vendors nothing carries it without failing CI, and the manifest stays repo-owned like
   `chassis-manifest.txt`.

4. **Exclude vendored paths in the chassis-owned formatter and linter configuration.**
   Upstream already excludes the symlinked paths; vendored directories are the missing half.
   This is not cosmetic: while writing this, `markdownlint --fix` reformatted a vendored file
   during a commit whose configuration did not yet carry the exclusion, and the drift check
   was the only thing that caught it.

5. **Settle the naming split before either side syncs** — see "Naming" above. Renaming after
   the skills are in use in both repositories is far more expensive than agreeing now.

6. **Tell us before adding `initialize.sh` to the chassis manifest.** It is repo-owned today
   and this repository has edited its upstream-sync removal block. If it becomes
   chassis-managed, that edit turns into CI drift and the block has to move upstream first.

## What we should take from upstream

The reverse direction, for whoever rebuilds this repository on the new chassis:

- **`script/skills-check`** — validating skills against the Agent Skills specification is
  something this repository lacks entirely. Expect it to flag things here on first run.
- **`.agents/instructions/` with a `.github/instructions` symlink** — finishes the
  consolidation this repository started.
- **`.agents/scratch/`** — supersedes the `.ai-scratch/` convention in `AGENTS.md`.

**Do not run `script/chassis-sync` casually to get these.** As of 2026-08-11 it reports 16
differing files, because upstream restructured its whole agent configuration. Pulling that in
is a migration with naming and layout decisions attached, not a routine sync.

## Constraints on our side

Things that must keep working, whatever upstream decides:

- **`.agents/skills/` files are synced to author repositories** via template-sync, so they use
  the same `<author>` / `<owner>/<repo>` placeholders as `.github/instructions/*.instructions.md`.
  Concrete values would cause sync churn downstream.
- **`initialize.sh` removes `.github/workflows/skills-sync.yml`** from an author's repository —
  it receives vendored files through template-sync and must not open pull requests against a
  third-party upstream itself. The script and manifest are deliberately kept there so `--check`
  still works.
- **Vendored files must never be edited locally.** `script/skills-sync --check` runs on every
  pull request and fails on any change.

## Open questions

- Should the manifest live at `.github/skills-manifest.txt` (consistent with
  `.github/chassis-manifest.txt`, read by a workflow) or move under `.agents/`?
- Does the chassis want vendoring at all, or only the `.agents/skills/` convention?
- If both repositories vendor from the same third-party upstream, should the pin be shared or
  independent? Independent is simpler and lets each repository review on its own schedule.

## Related

- [`.agents/skills/README.md`](../../.agents/skills/README.md) — the layout and its rules
- [`.github/skills-manifest.txt`](../../.github/skills-manifest.txt) — vendored sources and pins
- [ARCHITECTURE.md](ARCHITECTURE.md) — how chassis sync and template sync fit together
