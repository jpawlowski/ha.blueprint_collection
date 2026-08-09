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

If you're using GitHub Copilot, path-specific instructions in `.github/instructions/*.instructions.md` provide additional guidance for specific file types (blueprints, Python tests, YAML, etc.). This document serves as the primary reference for all agents.

**Other agent entry points:**

- **Claude Code:** See [`CLAUDE.md`](CLAUDE.md) (pointer to this file)
- **ChatGPT Codex:** See [`CODEX.md`](CODEX.md) (pointer to this file)
- **GitHub Copilot:** See [`.github/copilot-instructions.md`](.github/copilot-instructions.md) (compact version of this file)

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

**Three types of content with clear separation:**

1. **Agent Instructions** - How AI should write blueprints and tests (`.github/instructions/`, `AGENTS.md`)
2. **Developer Documentation** - Architecture and design decisions (`docs/development/`)
3. **User Documentation** - End-user guides and import instructions (`docs/user/`, `README.md`)

**AI Planning:** Use `.ai-scratch/` for temporary notes (never committed)

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

**Commit message format:** Follow [Conventional Commits](https://www.conventionalcommits.org/) — see `.github/instructions/blueprint.commit-message.instructions.md` for full conventions, types, scopes, and examples.

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

### Inputs and Selectors

- Every configurable value MUST be an `input` with `name`, `description`, and a `selector` — never free-text where a
  typed selector exists ([selector docs](https://www.home-assistant.io/docs/blueprint/selectors/))
- Reference inputs with `!input <key>`. Every declared input must be used; every `!input` must be declared
  (`script/blueprint-check` enforces both)
- Provide sensible `default` values wherever possible — an importable blueprint that works with minimal configuration
  gets used, one with ten mandatory fields does not
- Prefer `entity`/`target` selectors with `filter:` (domain, device_class) over unfiltered pickers
- Never hardcode entity IDs, areas, or devices in the logic — that is what inputs are for
- Group many inputs with input `sections` (requires `min_version` >= 2024.6.0); mark advanced ones `collapsed: true`
- To use an input inside a Jinja template, assign it to a variable first
  (`variables: { my_var: !input my_input }`) — `!input` does not work inside template strings

### Blueprint Logic

- Use modern syntax: `triggers:`/`conditions:`/`actions:` with `trigger:`/`condition:`/`action:` keys
  (not the legacy `platform:`/`service:` spellings)
- Choose the automation `mode` deliberately (`single`, `restart`, `queued`, `parallel`) and document why when it is
  not obvious; `restart` + `max_exceeded: silent` is the usual choice for motion/presence patterns
- Reference entities via `entity_id`, never `device_id`, so blueprints survive device replacement
- Keep one blueprint per file and one concern per blueprint — compose instead of building a mega-blueprint
- Template blueprints: the top-level keys after `blueprint:`/`variables:` are the template entity definition
  (`binary_sensor:`, `sensor:`, ...); users set `name:`/`unique_id:` on their `use_blueprint` instance

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

**Patterns to reuse (see the existing tests):**

- `async_mock_service(hass, domain, service)` to capture service calls
- `hass.states.async_set(...)` to simulate triggers
- `freezer.tick(...)` + `async_fire_time_changed(hass)` to advance through `delay:`/`for:` waits
  (`tests/test_script_flash_light.py`)
- A short "settle" loop of `asyncio.sleep(0)` instead of `async_block_till_done()` while a run is suspended in
  `wait_for_trigger` or a delay — `block_till_done` would wait for the whole run and hang the test
  (`tests/test_automation_motion_light.py`)

**Every blueprint in this collection must have at least one runtime test** covering its happy path; behavior changes
and bug fixes need a test that would have caught the bug.

**Running tests:**

```bash
script/test                # All tests
script/test -k motion      # Matching tests only
script/test -v             # Verbose
```

**Python style for tests:** 4 spaces, 120 char lines, double quotes, full type hints. See
`.github/instructions/blueprint.python.instructions.md` and `.github/instructions/blueprint.tests.instructions.md`.

## Shared Chassis Files (do not edit here)

Part of the development environment is maintained upstream in the
[integration blueprint](https://github.com/jpawlowski/hacs.integration_blueprint) and synced into this
repository. Those files are listed in `.github/chassis-manifest.txt` — currently the DevContainer and agent
runtime, `script/.lib/`, the generic scripts (`lint`, `markdown`, `shell`, `type-check`, `help`, …), and the
editor/formatter configuration.

**Never edit a file listed in that manifest.** A pull-request check compares them against upstream and fails on
any local change. If one genuinely needs blueprint-specific content, remove it from the manifest and say so —
taking ownership is a deliberate decision, not a workaround.

```bash
script/chassis-sync --check    # Verify; exit 1 on drift
script/chassis-sync            # Pull upstream changes into the working tree
```

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
