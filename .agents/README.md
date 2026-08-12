# Agent configuration

This directory is the vendor-neutral home for everything AI coding agents read in this
repository. Vendor-specific paths under `.github/` and `.claude/` are symlinks into here, so a
file is written once and every agent gets it.

```text
.agents/
├── instructions/   path-scoped style rules, one file per file type
├── skills/         task-triggered procedures (Agent Skills standard)
└── scratch/        working notes and generated reports — gitignored
```

## Which client reads what

Discovery paths are per-vendor; no standard defines them. The real directories live where the
most clients look, and symlinks fill the rest:

| Client         | Always-loaded context                   | Path-scoped rules                     | Skills            |
| -------------- | --------------------------------------- | ------------------------------------- | ----------------- |
| Codex CLI      | `AGENTS.md` (native)                    | — none; open the file yourself        | `.agents/skills/` |
| GitHub Copilot | `AGENTS.md` (native)                    | `.github/instructions/` via `applyTo` | `.agents/skills/` |
| VS Code        | `AGENTS.md` (native)                    | `.github/instructions/` via `applyTo` | `.agents/skills/` |
| Claude Code    | `CLAUDE.md`, which imports `@AGENTS.md` | `.claude/rules/` via `paths`          | `.claude/skills/` |

```text
.agents/instructions/         real directory — edit here
.agents/skills/               real directory — edit here
.github/instructions        → ../.agents/instructions
.claude/rules/instructions  → ../../.agents/instructions
.claude/skills              → ../.agents/skills
```

Editing through a symlink edits the same file. Do it in `.agents/` anyway, so your diff shows
the path other maintainers see. Never turn a symlink back into a real directory — that is how
vendor copies drift apart. `script/skills-check` verifies all three links, because a broken one
fails silently: the agent behaves exactly like an agent that read the files and ignored them.

Each instructions file carries the same glob list twice: `applyTo` for Copilot and VS Code,
`paths` for Claude Code. `script/skills-check` fails the build if the two disagree, or if
`paths` is missing — a rule without it loads into every Claude Code session instead of the files
it was scoped to.

## The four layers

| Layer                             | Loaded                      | Contains                                             |
| --------------------------------- | --------------------------- | ---------------------------------------------------- |
| `AGENTS.md`                       | always                      | project identity, workflow rules, validation loop    |
| `.agents/instructions/*.md`       | per touched file            | passive style rules for a file type                  |
| `.agents/skills/*/SKILL.md`       | when the task matches       | active procedures — how to carry out a specific task |
| `docs/development/`, `docs/user/` | when a human or agent reads | explanations, decisions, human-facing guides         |

Rule of thumb: _style rules_ belong in `instructions/`, _procedures_ belong in a skill,
_explanations_ belong in `docs/`. If you find yourself repeating a procedure in `AGENTS.md`, it
is a skill.

Codex is the exception on layer two — its nested `AGENTS.md` support keys off the working
directory rather than the file being edited, so nothing loads automatically. Every skill
therefore names the instructions file it depends on.

## Naming

Two prefixes, and the distinction is deliberate:

| Prefix           | Applies to                      | Examples                                        |
| ---------------- | ------------------------------- | ----------------------------------------------- |
| `collection.*`   | instruction files               | `collection.yaml.instructions.md`               |
| `ha-blueprint-*` | skills about the deliverable    | `ha-blueprint-authoring`, `ha-blueprint-review` |
| _(unprefixed)_   | skills about working in general | `requirements-interview`, `repo-tooling`        |

**Nothing here is named `blueprint-*`.** In this repository "blueprint" means a Home Assistant
blueprint and nothing else — `AGENTS.md` says so, and a skill named `blueprint-tooling` would
quietly mean the opposite. The upstream development chassis uses `blueprint-*` for the
integration template it ships, which is why files adopted from there were renamed on the way in.

## Placeholders

Files here use generic placeholders instead of this collection's concrete identifiers, so
template sync can update them without clobbering an initialized repository:

| Placeholder          | Means                                          | Value in this repository |
| -------------------- | ---------------------------------------------- | ------------------------ |
| `<author>`           | the author folder under `blueprints/`          | `ha_blueprint_author`    |
| `<collection-title>` | the collection's display name                  | `Blueprint Collection`   |
| `<owner>/<repo>`     | the GitHub repository the blueprints ship from | this repository          |

`initialize.sh` rewrites the concrete values once, when a collection is created from the
template. Template sync then keeps delivering these files afterwards, which is why a literal
value here would overwrite an author's own name months later. `script/skills-check` rejects the
concrete forms for that reason.

## Validation

```bash
script/skills-check   # skills and instruction files — part of script/lint-check, so CI enforces it
```

Writing and maintaining skills is documented in [`skills/README.md`](skills/README.md).
