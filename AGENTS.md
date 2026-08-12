# AI Agent Instructions

This document provides guidance for AI coding agents working on this collection of Home Assistant blueprints.

## Project Overview

This repository hosts a collection of **Home Assistant blueprints** — reusable, parameterized automation, script, and
template configurations that users import into their own Home Assistant instance. It was generated from a blueprint
collection template and ships a complete development and test environment.

> **Terminology (important):** In this repository, "blueprint" means a **Home Assistant blueprint** — a shareable YAML
> file with a `blueprint:` metadata block and `!input` placeholders. It does NOT mean the repository template this
> project was created from (that is called the "collection template" where it needs a name).

**Collection details:**

- **Title:** Blueprint Collection
- **Author folder:** `ha_blueprint_author`
- **Repository:** jpawlowski/ha.blueprint_collection

**Key directories:**

- `blueprints/automation/ha_blueprint_author/` - Automation blueprints
- `blueprints/script/ha_blueprint_author/` - Script blueprints
- `blueprints/template/ha_blueprint_author/` - Template blueprints
- `config/` - Home Assistant configuration for local testing
- `tests/` - Runtime tests that instantiate the blueprints in an in-memory HA instance
- `script/` - Development and validation scripts
- `.agents/` - Everything AI agents read: `instructions/`, `skills/`, `scratch/` (see [`.agents/README.md`](.agents/README.md))

**Local Home Assistant instance:**

**Always use the project's scripts** — do NOT craft your own `hass`, `pip`, `pytest`, or similar commands. The scripts
handle environment setup, virtual environments, blueprint syncing, port management, and cleanup that raw commands miss.
Agents that bypass scripts frequently break.

**Devcontainer CLI tools:** The devcontainer provides common agent-facing CLI tools including `bat`, `delta`/`git-delta`, `eza`, `fd`/`fdfind`, `fzf`, `http`/`httpie`, `hyperfine`, `ipython`, `jq`, `jo`, `mlr`/`miller`, `rg`/`ripgrep`, `shellcheck`, `shfmt`, `sponge`, `sqlite3`, `tree`, `yq`, and `yamllint`. Prefer these explicit container tools over assuming a VS Code extension exposes an equivalent CLI on `PATH`.

**CLI compatibility notes:** Some commands are available via compatibility aliases because Debian package names differ from what agents often expect. Prefer `bat`, `fd`, `git-delta`, `httpie`, `ipython`, `miller`, and `ripgrep` as stable spellings. `yq` is installed as the Mike Farah variant, so standard `yq eval`/`yq e` syntax is expected.

**Start Home Assistant:**

```bash
./script/develop
```

This syncs the repository blueprints into `config/blueprints/` (per-file symlinks, so edits are live) and starts HA
with debug logging. Create an automation/script from a blueprint via **Settings > Automations & scenes > Blueprints**
to test it interactively.

**Force restart (when HA is unresponsive or port conflicts):**

```bash
pkill -f "hass --config" || true && pkill -f "debugpy.*5678" || true && ./script/develop
```

**Picking up blueprint changes in a running instance:** Blueprint files are symlinked, so file edits are immediately
visible — but automations/scripts created from a blueprint cache their configuration. Reload via
**Developer Tools > YAML > Automations/Scripts/Template entities**, or restart HA. New blueprint files require
`./script/setup/sync-blueprints` (or a `develop` restart) to be linked.

**Reading logs:**

- Live: Terminal where `./script/develop` runs
- File: `config/home-assistant.log` (most recent), `config/home-assistant.log.1` (previous)
- Automation debugging: **Settings > Automations > (automation) > Traces** shows step-by-step execution

**Context-specific instructions:**

Path-scoped rules live in [`.agents/instructions/*.instructions.md`](.agents/instructions/) and
are injected automatically for the file types they name. This document is the primary reference
for all agents.

## Agent Skills

Deep, task-scoped guidance lives in [`.agents/skills/`](.agents/skills/README.md) — loaded on
demand, so it can go into detail without costing context on every turn. Read the matching
skill **before** starting work in its area:

| Task                                                                                               | Skill                                                                        | Instructions                                |
| -------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------- |
| Writing or changing a blueprint — selectors, triggers, templating, `min_version`                   | [`ha-blueprint-authoring`](.agents/skills/ha-blueprint-authoring/SKILL.md)   | `collection.ha_blueprints.instructions.md`  |
| Looking up the exact YAML for a Home Assistant trigger, condition, wait, or control-flow construct | [`ha-automation-patterns`](.agents/skills/ha-automation-patterns/SKILL.md)   | —                                           |
| Runtime tests in `tests/`                                                                          | [`ha-blueprint-testing`](.agents/skills/ha-blueprint-testing/SKILL.md)       | `collection.tests.instructions.md`          |
| Auditing a blueprint or a branch before a pull request                                             | [`ha-blueprint-review`](.agents/skills/ha-blueprint-review/SKILL.md)         | —                                           |
| Releases, release notes, import links, community publication                                       | [`ha-blueprint-release`](.agents/skills/ha-blueprint-release/SKILL.md)       | `collection.commit-message.instructions.md` |
| Settling requirements before any YAML is written                                                   | [`requirements-interview`](.agents/skills/requirements-interview/SKILL.md)   | —                                           |
| Planning a change over ~10 files, or recording a decision                                          | [`change-planning`](.agents/skills/change-planning/SKILL.md)                 | —                                           |
| Which `script/` command to run, hooks, devcontainer environment, the sync mechanisms               | [`repo-tooling`](.agents/skills/repo-tooling/SKILL.md)                       | `collection.shell.instructions.md`          |
| Adding, changing or removing anything under `.agents/`                                             | [`agent-skill-maintenance`](.agents/skills/agent-skill-maintenance/SKILL.md) | `collection.markdown.instructions.md`       |

Each skill is a short `SKILL.md` plus `references/` files read only when a task touches
their area. `.agents/` is the cross-agent convention and the single source; the vendor-specific
paths under `.github/` and `.claude/` are symlinks into it. One copy, every agent — see
[`.agents/README.md`](.agents/README.md).

`ha-automation-patterns` is **vendored verbatim** from an upstream repository and pinned in
`.github/skills-manifest.txt`. Never edit anything under a `vendor/` directory —
`script/skills-sync --check` fails on any local change. Where it disagrees with
`ha-blueprint-authoring`, the authoring skill wins: it was verified against the Home
Assistant version pinned here.

**The skills are the single source for how to author and test blueprints.** This document
keeps the non-negotiable rules so they are always in context; anything beyond them belongs
in a skill, not here.

**Other agent entry points:** ChatGPT Codex and GitHub Copilot read this file natively, so there is nothing else
to load. Claude Code reads [`CLAUDE.md`](CLAUDE.md), which imports this file with `@AGENTS.md` and adds only what
is specific to Claude Code.

## Working With Developers

### Community AI Policy

Read and follow [`AI_POLICY.md`](AI_POLICY.md). This project permits extensive AI assistance, but agents must not
overstate human review, maintainer understanding, automated coverage, or real-device testing. Prepare publication
material as drafts for human review and follow the policy of any destination (e.g. the Home Assistant Blueprint
Exchange forum).

### When Instructions Conflict With Requests

If a developer requests something that contradicts these instructions:

1. **Clarify the intent** - Ask if they want you to deviate from the documented guidelines
2. **Confirm understanding** - Restate what you understood to avoid misinterpretation
3. **Suggest instruction updates** - If this represents a permanent change in approach, offer to update these instructions
4. **Proceed once confirmed** - Follow the developer's explicit direction after clarification

### Maintaining These Instructions

**This project was recently initialized from a template.** Instructions should evolve as the project matures:

- Refine guidelines based on actual project needs
- Remove outdated rules that no longer apply
- Consolidate redundant sections to prevent bloat
- Keep files focused - Move architectural decisions to `docs/development/`

### Documentation vs. Instructions

**Four types of content with clear separation:**

1. **Agent Instructions** - Always-in-context rules (`AGENTS.md`, `.agents/instructions/`)
2. **Agent Skills** - On-demand depth: how to author, test, and release blueprints (`.agents/skills/`)
3. **Developer Documentation** - Architecture and design decisions (`docs/development/`)
4. **User Documentation** - End-user guides and import instructions (`docs/user/`, `README.md`)

**One fact lives in one place.** A rule about blueprint authoring belongs in the skill, and the other files link
to it. Duplicating it means one copy will be wrong within a release.

**AI Planning:** Use `.agents/scratch/` for temporary notes (never committed)

**Rules:**

- ❌ **NEVER** create random markdown files in code directories
- ❌ **NEVER** create documentation in `.github/` unless it's a GitHub-specified file
- ✅ **ALWAYS ask first** before creating permanent documentation
- ✅ **Prefer the blueprint's `description` field** over separate markdown files for per-blueprint documentation

### Session and Context Management

**Commit suggestions:**

When a task completes and the developer moves to a new topic, suggest committing changes. Offer a commit message based on the work done.

**Commit rules (CRITICAL):**

- **Never commit automatically** — only commit when the developer explicitly requests it
- A previous commit request is NOT a standing permission; each commit requires a fresh explicit instruction
- **Never ask about pushing** — the developer always handles `git push` themselves; do not offer or suggest it

**Commit message format:** Follow [Conventional Commits](https://www.conventionalcommits.org/) — see `.agents/instructions/collection.commit-message.instructions.md` for full conventions, types, scopes, and examples.

## Blueprint Authoring Rules

### Repository Layout

Every blueprint lives at `blueprints/<domain>/<author>/<name>.yaml`:

- `<domain>` is one of `automation`, `script`, or `template` and MUST match the `blueprint.domain` value in the file
- `<author>` is this collection's author folder (`ha_blueprint_author`) — it keeps imports collision-free on the
  user's instance, because Home Assistant mirrors the folder structure under `config/blueprints/<domain>/`
- The file extension MUST be `.yaml` (Home Assistant ignores `.yml`)

**Do NOT create:**

- Files directly in `blueprints/<domain>/` (always use the author subfolder)
- Any other top-level folder inside `blueprints/` (Home Assistant only loads the three domain folders)

### Editor Support

`schemas/json/blueprint_schema.json` is mapped to `blueprints/**/*.yaml` in the VS Code settings, so the editor
offers completion for the `blueprint:` block and flags typos, unknown domains, malformed `min_version`, and
malformed selectors while you type.

That mapping is not cosmetic: without it the YAML extension auto-matches an unrelated third-party schema from
SchemaStore purely because of the `blueprints/` path name, and reports every valid blueprint as invalid. Do not
remove it.

The editor schema is an approximation and only ever a convenience — `script/blueprint-check` runs Home
Assistant's own validator and stays authoritative. `tests/test_editor_schema.py` keeps the two from drifting.

### Required Metadata

Every blueprint MUST declare in its `blueprint:` block:

- `name` — short, imperative, user-facing (e.g. "Motion-activated light")
- `description` — what it does, what it needs, and any caveats; Markdown is allowed and shown in the import dialog
- `domain` — `automation`, `script`, or `template`
- `author` — the collection author
- `source_url` — the GitHub blob URL of THIS file on `main`
  (`https://github.com/<owner>/<repo>/blob/main/blueprints/<domain>/<author>/<name>.yaml`).
  This is what makes re-import and "update blueprint" work for users. `script/blueprint-check` verifies it matches
  the file's actual path.
- `homeassistant.min_version` — the oldest HA version the blueprint works on. Raise it when using newer syntax
  (e.g. `triggers:`/`actions:` keys require 2024.10). It must never be newer than the development Home Assistant
  version (`HA_VERSION` in `.devcontainer/.env`),
  otherwise CI cannot validate the blueprint.

### Inputs, Selectors, and Logic

The non-negotiables — full guidance in
[`ha-blueprint-authoring`](.agents/skills/ha-blueprint-authoring/SKILL.md):

- Every configurable value MUST be an `input` with `name`, `description`, and a typed `selector` — never free text
  where a selector exists. Filter `entity`/`target` selectors by `domain` and `device_class`
- Reference inputs with `!input <key>`. Every declared input must be used; every `!input` must be declared
  (`script/blueprint-check` enforces both)
- **`!input` does not work inside Jinja** — assign to a variable first
  (`variables: { my_var: !input my_input }`)
- Provide sensible `default` values wherever possible; every input in a `collapsed: true` section needs one
- Never hardcode entity IDs, areas, or devices — that is what inputs are for
- Reference entities via `entity_id`, never `device_id`, so blueprints survive device replacement
- Modern syntax only: `triggers:`/`conditions:`/`actions:` with `trigger:`/`condition:`/`action:` keys
  (not legacy `platform:`/`service:`)
- **Prefer the purpose-specific triggers and conditions** introduced in HA 2026.7
  (`motion.detected`, `light.is_on`) with a `target:` — they require `min_version: 2026.7.0`, which is a
  deliberate trade-off; see the skill's `references/triggers-conditions.md`
- Choose the automation `mode` deliberately and document why when it is not obvious; `restart` +
  `max_exceeded: silent` is the usual choice for motion/presence patterns
- Keep one blueprint per file and one concern per blueprint — compose instead of building a mega-blueprint
- Template blueprints: the top-level keys after `blueprint:`/`variables:` are the template entity definition;
  users set `name:`/`unique_id:` on their `use_blueprint` instance

### Breaking Changes

A blueprint is an interface: users have automations built on it, configured through its inputs.

**Always warn the developer before:**

- Renaming or removing an input (existing automations lose their configuration for it)
- Changing an input's meaning, unit, or selector type
- Changing trigger/action behavior users likely depend on
- Raising `homeassistant.min_version`
- Renaming or moving a blueprint file (breaks the `source_url` and every import link in READMEs/forum posts)

**Remember:** users only receive changes when they re-import the blueprint. A "fix" in the repository does not reach
existing installations automatically — mention re-importing in release notes for anything users should pick up.

**When breaking changes are necessary:** document them in the commit message (`BREAKING CHANGE:` footer) so
release-please surfaces them prominently.

## Validation Scripts

**Before committing, always run the full suite:**

```bash
script/check      # Full validation: type-check + lint-check + spell-check + blueprint-check
```

**After editing specific file types, use the targeted script — it is faster:**

| Changed files                          | Run this                                       | Why faster                                 |
| -------------------------------------- | ---------------------------------------------- | ------------------------------------------ |
| `blueprints/**/*.yaml`                 | `script/blueprint-check` + `script/yaml-check` | HA schema + repo rules + yamllint only     |
| `tests/**/*.py` only                   | `script/python` + `script/type-check`          | Fixes + reports ruff; skips yaml, markdown |
| `*.md` only                            | `script/markdown`                              | Prettier + markdownlint only               |
| `script/` or `.devcontainer/*.sh` only | `script/shell` + `script/shell-check`          | Fixes shfmt, then checks shellcheck        |
| Multiple types or unsure               | `script/lint` + `script/blueprint-check`       | Safe default for agents                    |

**What `script/blueprint-check` validates:**

- Every file against Home Assistant's own `BLUEPRINT_SCHEMA` (the exact schema of the pinned HA version)
- Folder domain matches `blueprint.domain`; `.yaml` extension; author subfolder placement
- Declared-but-unused and used-but-undeclared inputs
- `homeassistant.min_version` present and not newer than the development Home Assistant version
- `source_url` points to this repository and the file's actual path (when a git origin exists)
- Metadata quality (description, author)

**Fix / format scripts (apply changes automatically):**

```bash
script/lint         # Format + fix all types (Python, Shell, Markdown)
script/python       # Ruff format + ruff check --fix  (tests)
script/shell        # shfmt -w                        (Shell only)
script/spell        # codespell --write-changes        (spelling)
script/markdown     # Prettier --write + markdownlint  (Markdown only)
```

**Check-only scripts (never modify files):**

```bash
script/blueprint-check # HA blueprint schema + repository rules
script/lint-check      # Check all types without changes
script/python-check    # Ruff format --check + ruff check  (tests)
script/yaml-check      # yamllint                           (YAML only)
script/shell-check     # shfmt -d + shellcheck              (Shell only)
script/markdown-check  # Prettier --check + markdownlint    (Markdown only)
script/type-check      # Pyright                            (types only)
script/spell-check     # codespell                          (spelling only)
script/test            # pytest                             (blueprint runtime tests)
```

**Error recovery:** When validation fails, run `script/lint` first — it auto-fixes formatting and prints what it could
not fix. Then fix remaining errors manually. If the same error persists after 3 attempts, stop and explain what you
tried instead of looping.

## Testing

Blueprints are tested at **runtime**, not just schema-checked: each test copies the blueprint into an in-memory Home
Assistant instance (via the `install_blueprint` fixture in `tests/conftest.py`), instantiates it with
`use_blueprint`, and asserts real behavior — triggers firing, service calls, template states.

**Every blueprint in this collection must have at least one runtime test** covering its happy path; behavior changes
and bug fixes need a test that would have caught the bug.

The three rules that cause most failures — full patterns and troubleshooting in
[`ha-blueprint-testing`](.agents/skills/ha-blueprint-testing/SKILL.md):

- Register `async_mock_service(hass, domain, service)` **before** triggering, or the call is made for real and
  never captured
- Never sleep in real time — `freezer.tick(...)` + `async_fire_time_changed(hass)` to advance through
  `delay:`/`for:` waits
- `async_block_till_done()` hangs on a run suspended in `wait_for_trigger` or a delay; use a short settle loop of
  `asyncio.sleep(0)` instead, and only block when the run can actually complete

**Running tests:**

```bash
script/test                # All tests
script/test -k motion      # Matching tests only
script/test -v             # Verbose
```

**Python style for tests:** 4 spaces, 120 char lines, double quotes, full type hints. See
`.agents/instructions/collection.python.instructions.md` and `.agents/instructions/collection.tests.instructions.md`.

## Vendored Files (never edit)

Anything under a `vendor/` directory is third-party material copied verbatim and pinned to a commit in
`.github/skills-manifest.txt`. It must stay byte-identical to that pin — `script/skills-sync --check` runs on
every pull request and fails on any difference, including one a formatter made. To take a newer version, run
`script/skills-sync --update <ref>` and review the diff. Commentary about vendored material goes in the wrapper
`SKILL.md` beside it, never inside `vendor/`.

Everything else in this repository is owned here. The development environment originally came from the
[integration blueprint](https://github.com/jpawlowski/hacs.integration_blueprint), but that sync was retired on
2026-08-12 — see [DECISIONS.md](docs/development/DECISIONS.md). Improvements from there are now adopted by hand,
deliberately, when someone decides they are worth it.

## Versioning and Releases

- The collection is released as a whole via release-please; the version lives in `.release-please-manifest.json`
  (`script/version` prints it). Individual blueprints are not versioned separately.
- The development/CI Home Assistant version is pinned as `HA_VERSION` in `.devcontainer/.env` and must stay on
  the same release train as `pytest-homeassistant-custom-component` in `requirements_test.txt`
  (`script/ha-version-sync` checks this). That file is agent-protected — propose the change, do not apply it.
- Users import blueprints from `main` via the `source_url`/import links — anything merged to `main` is immediately
  importable. Treat `main` as released.

## Research and Validation

**When uncertain, consult official documentation:**

- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/) — metadata, inputs, sections
- [Selectors](https://www.home-assistant.io/docs/blueprint/selectors/) — all selector types and options
- [Blueprint tutorial](https://www.home-assistant.io/docs/blueprint/tutorial/) — authoring walk-through
- [Automation YAML](https://www.home-assistant.io/docs/automation/yaml/) — triggers, conditions, actions
- [Script syntax](https://www.home-assistant.io/docs/scripts/) — sequences, repeat, wait, choose
- [Template integration](https://www.home-assistant.io/integrations/template/) — template blueprint entity config
- [Blueprint Exchange rules](https://community.home-assistant.io/c/blueprints-exchange/53) — for forum publication

**Don't rely on assumptions:**

- Home Assistant blueprint capabilities evolve frequently (sections, template blueprints, new selectors)
- What worked in older versions may be deprecated; check the min_version implications of new syntax
- The installed HA version in the venv is the source of truth — `script/blueprint-check` validates against its
  actual schema, and `script/test` runs against its actual runtime

## Tool Parallelization

**Safe to call in parallel:**

- Multiple `read_file` operations (different files or different sections of same file)
- `file_search` + `read_file` + `grep_search` (independent read-only operations)
- `semantic_search` followed by parallel `read_file` of results (but only 1 semantic_search at a time)

**Never call in parallel:**

- Multiple `run_in_terminal` commands (execute sequentially, wait for output)
- Multiple `replace_string_in_file` on the same file (use `multi_replace_string_in_file` instead)
- `semantic_search` with other `semantic_search` (execute one at a time)

**Best practices:**

- Batch independent read operations together in one parallel call
- After gathering context in parallel, provide brief progress update before proceeding
- For file edits, use `multi_replace_string_in_file` when making multiple changes
- Terminal commands must always be sequential to see output before next command

## Additional Resources

- [Home Assistant Blueprint Docs](https://www.home-assistant.io/docs/blueprint/) - Primary reference
- [Blueprint Exchange Forum](https://community.home-assistant.io/c/blueprints-exchange/53) - Community sharing
- [My Home Assistant import links](https://my.home-assistant.io/create-link/?redirect=blueprint_import) - Import badge generator
- [Ruff Rules](https://docs.astral.sh/ruff/rules/) - Linter documentation
- [pytest Documentation](https://docs.pytest.org/) - Testing framework
- See `CONTRIBUTING.md` for contribution guidelines
