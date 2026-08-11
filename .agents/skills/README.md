# Agent Skills

Shared, agent-agnostic skills for this blueprint collection. `.agents/skills/` is the
cross-agent convention and the **single source** — edit here.

| Agent          | Finds them via                            |
| -------------- | ----------------------------------------- |
| GitHub Copilot | `.agents/skills/` — natively, no symlink  |
| ChatGPT Codex  | `.agents/skills/` — natively, no symlink  |
| Claude Code    | `.claude/skills` → symlink to this folder |

Copilot discovers project skills in `.github/skills`, `.claude/skills`, **and**
`.agents/skills`, so it needs nothing extra. Claude Code reads only `.claude/skills` at
project level — verified against the shipped binary, which contains no reference to
`.agents/skills` — so that one directory symlink stays until upstream adds the path.

If a skill ever fails to show up in Claude Code (`/skills`, or typing `/ha-blueprint-authoring`),
the documented-and-guaranteed fallback is a symlink per skill instead of one for the
directory:

```bash
rm .claude/skills && mkdir -p .claude/skills
for s in .agents/skills/*/; do ln -s "../../$s" ".claude/skills/$(basename "$s")"; done
```

## The skills

| Skill                                                       | Use it for                                                                                                            |
| ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| [`ha-blueprint-authoring`](ha-blueprint-authoring/SKILL.md) | Writing, changing, or reviewing a blueprint: selectors, inputs, triggers, templating, modes, `min_version`, debugging |
| [`ha-automation-patterns`](ha-automation-patterns/SKILL.md) | The broad catalogue of Home Assistant triggers, conditions, waits, modes, and control flow — **vendored**             |
| [`ha-blueprint-testing`](ha-blueprint-testing/SKILL.md)     | Runtime tests against an in-memory Home Assistant instance                                                            |
| [`ha-blueprint-release`](ha-blueprint-release/SKILL.md)     | Versioning, user-facing release notes, import links, community publication                                            |

Each skill is a thin `SKILL.md` (the index and the always-binding rules) plus `references/`
files that are read only when a task touches their area. Start at the routing table at the
top of the `SKILL.md`.

`ha-blueprint-authoring` and `ha-automation-patterns` overlap deliberately: the first is the
blueprint-specific subset, verified against the Home Assistant pinned in this repository; the
second is the broad catalogue. **Where they disagree, the authoring skill wins.**

## Vendored content

`ha-automation-patterns/vendor/` holds third-party material copied verbatim from
[homeassistant-ai/skills](https://github.com/homeassistant-ai/skills) (MIT). The sources,
pinned commits, and file mappings live in [`.github/skills-manifest.txt`](../../.github/skills-manifest.txt).

**Never edit anything under a `vendor/` directory.** It must stay byte-identical to its
pinned commit; `script/skills-sync --check` fails otherwise and CI runs it on every pull
request. Corrections go upstream; local commentary goes in the wrapper `SKILL.md`.

```bash
script/skills-sync --check     # do the vendored files still match the pin?
script/skills-sync             # restore the pinned state
script/skills-sync --update    # move the pin to the latest upstream, for review
```

Why vendor rather than install the upstream skill: it is monolithic (installing it also
brings dashboards, AppDaemon, and helper guidance this collection has no use for), and its
own `SKILL.md` tells agents to prefer the Home Assistant config API and UI helpers over
writing YAML — the opposite of what a blueprint collection does. Vendoring takes the
reference material without the framing; the wrapper `SKILL.md` states the overrides.

## Relationship to the other instruction files

- **[`AGENTS.md`](../../AGENTS.md)** — the repository's primary agent entry point: layout,
  scripts, workflow, commit rules. Always in context.
- **`.github/instructions/*.instructions.md`** — path-scoped rules Copilot applies
  automatically by glob. Deliberately short; they point here for detail.
- **`.agents/skills/`** — the depth. Loaded on demand, so it can be long without costing
  context on every turn.
- **`docs/development/`** — documentation for humans: architecture, decisions, onboarding.

**One fact lives in one place.** When something is true of blueprint _authoring_, it belongs
in a skill and the other files link to it. Duplicating a rule into two files means one of
them will be wrong within a release.

## Adding a skill

1. Create `.agents/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`,
   `license`). Put trigger phrases in the `description` — that is what agents match on.
2. Add a row to the table above.

No symlink step: `.claude/skills` points at this whole directory, and the other agents read
`.agents/skills/` directly.

To vendor a third-party file instead, add an `UPSTREAM`/`REF` block and a mapping to
`.github/skills-manifest.txt`, run `script/skills-sync`, vendor the source repository's
licence alongside it, and write a wrapper `SKILL.md` that states where the upstream framing
does not apply here.

Keep `SKILL.md` under roughly 200 lines. Depth goes in `references/`, linked from a routing
table — that is the whole point of the split.

## Editing rules

- **Verify against the pinned Home Assistant**, not against documentation or memory. The
  installed venv is the source of truth; several facts in these files were corrected by
  probing it, and the probe commands are included so they can be re-run after an
  `HA_VERSION` bump.
- **Mark what you could not verify.** A row labelled "verify" is useful; a confidently wrong
  version number is not.
- Do not restate `AGENTS.md`. Link to it.

## Linting

`.markdownlint-cli2.jsonc` adds `.agents/skills/**/*.md` to the markdownlint globs and
excludes the `.claude/skills/` symlink and every `vendor/` directory, so each file is linted
exactly once, through its real path.

Prettier is the exception: its globs live in `script/markdown`, which is chassis-managed and
must not be edited here, and they do not reach this directory. The pre-commit hook formats
staged files by path and therefore does cover it. To format outside a commit:

```bash
./node_modules/.bin/prettier --write ".agents/skills/**/*.md"
```
