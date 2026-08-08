# Home Assistant Blueprint Collection Template

[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-2026.8%2B-blue.svg)](https://www.home-assistant.io/)
[![Python](https://img.shields.io/badge/python-3.14%2B-blue.svg)](https://www.python.org/)
[![AI Agent Ready](https://img.shields.io/badge/AI%20Agent-Ready-purple.svg)](#ai-agent-support)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A template repository for building and maintaining collections of **Home Assistant blueprints** — the reusable
automation, script, and template configurations that users import into their own instance.

Blueprint authors normally have no development environment at all: you edit YAML, restart Home Assistant, click
through the UI, and hope. This template gives blueprints the same treatment integrations get — a real runtime,
schema validation, automated tests, CI, and a defined framework for AI coding agents.

> [!IMPORTANT]
> **Use the template — don't fork!**
> Click the **"Use this template"** button to create your own repository.
> Forking copies the entire commit history, which you don't need and can't easily remove.
> A template repository gives you a **clean start with a single initial commit**.

> [!NOTE]
> **Terminology.** In this repository, "blueprint" always means a **Home Assistant blueprint** — a shareable YAML
> file with a `blueprint:` block and `!input` placeholders. This repository itself is the "collection template".

## 📋 Quick Navigation

- **[Getting Started](#getting-started)** — create your collection in minutes
- **[What You Get](#what-you-get)** — the tooling, and why it matters
- **[Development Guide](#development-guide)** — scripts and daily workflow
- **[Repository Structure](#repository-structure)** — where things live
- **[AI Agent Support](#ai-agent-support)** — the instruction system
- **[Resources](#resources)** — documentation and community

---

## Getting Started

### Step 1: Create your repository

Click **"Use this template"** → **"Create a new repository"** on GitHub.

### Step 2: Open a development environment

- **GitHub Codespaces** ☁️ — browser-based, zero install → see [docs/development/CODESPACES.md](docs/development/CODESPACES.md)
- **Local DevContainer** 💻 — requires Docker + VS Code; open the repository and click **"Reopen in Container"**

Both use the same setup, so your workflow is identical. The container bootstrap installs Home Assistant, the test
framework, and all linters.

### Step 3: Initialize the collection

```bash
./initialize.sh
```

This asks for your collection title, author folder name, and repository slug, then rewrites the placeholders
throughout the repository (blueprint `source_url`s, README links, agent instructions) and deletes itself.

### Step 4: Write your first blueprint

```bash
./script/develop            # Start Home Assistant with your blueprints linked in
```

Open <http://localhost:8123>, go to **Settings > Automations & scenes > Blueprints**, and create an automation
from one of the example blueprints to see the loop working. Then edit the examples or add your own under
`blueprints/<domain>/<author>/`.

```bash
./script/blueprint-check    # Validate against Home Assistant's own schema
./script/test               # Run the runtime test suite
./script/check              # Everything: types, lint, spelling, blueprints
```

## What You Get

### Real validation, not guesswork

`script/blueprint-check` validates every file against **Home Assistant's actual `BLUEPRINT_SCHEMA`** — imported
from the pinned Home Assistant version in the virtual environment, not a reimplementation that drifts. It catches
what the UI would reject at import time, plus repository-level rules Home Assistant does not check:

- Folder domain matches `blueprint.domain`; `.yaml` extension; author subfolder placement
- Declared-but-unused inputs and `!input` references with no definition
- `homeassistant.min_version` present and not newer than the development version
- `source_url` actually points at this repository and this file's path
- Metadata quality (description, author)

### Runtime tests for blueprints

This is the part blueprint authors normally cannot have. Each test installs a blueprint into an in-memory Home
Assistant instance, instantiates it through `use_blueprint`, and asserts **real behavior**:

```python
async def test_light_turns_off_after_motion_clears(hass, install_blueprint):
    await _setup(hass, install_blueprint, wait=0)
    turn_off = async_mock_service(hass, "light", "turn_off")

    hass.states.async_set(MOTION, "on")
    await _settle(hass)
    hass.states.async_set(MOTION, "off")
    await hass.async_block_till_done()

    assert len(turn_off) == 1
```

The included examples cover all three domains and the tricky parts — `wait_for_trigger` suspension, `delay:`
pacing via frozen time, and template entity availability. The whole suite runs in well under a second.

### A live Home Assistant instance

`script/develop` symlinks your blueprints into `config/blueprints/` per file, so edits in the workspace are
immediately visible to the running instance. Create automations from them in the UI, inspect traces, iterate.

### One-click import links

`script/import-links` generates the My Home Assistant import badges for every blueprint from its `source_url` —
paste the output into your README so users can import with one click.

### CI, releases, and template sync

- **Validate** workflow — blueprint schema check + test suite on every push and PR, plus a nightly run
- **Lint** workflow — Ruff, yamllint, shellcheck/shfmt, Prettier, markdownlint
- **release-please** — Conventional Commits → CHANGELOG and version tags
- **HA version sync** — keeps `.ha-version`, `pytest-homeassistant-custom-component`, and the DevContainer pin on
  the same release train
- **Template sync** — pull improvements from this template into your collection later

## Development Guide

**Daily loop:**

```bash
./script/develop            # Start Home Assistant (syncs blueprints first)
./script/blueprint-check    # After editing a blueprint
./script/test               # After changing behavior
./script/check              # Before committing — the full suite
```

**Fix-mode scripts** apply changes and report what they could not fix:

| Script            | Does                                                 |
| ----------------- | ---------------------------------------------------- |
| `script/lint`     | Format + fix Python, Shell, Markdown; check the rest |
| `script/python`   | Ruff format + `ruff check --fix` (tests)             |
| `script/shell`    | `shfmt -w`                                           |
| `script/markdown` | Prettier + markdownlint                              |
| `script/spell`    | `codespell --write-changes`                          |

**Check-only scripts** never modify files: `blueprint-check`, `lint-check`, `python-check`, `yaml-check`,
`shell-check`, `markdown-check`, `type-check`, `spell-check`, `test`.

**Utilities:** `script/help` lists everything · `script/import-links` generates import badges ·
`script/version` prints the release version · `script/setup/reset` resets the Home Assistant config ·
`script/clean` clears caches

## Repository Structure

```text
blueprints/
  automation/<author>/*.yaml   # Automation blueprints
  script/<author>/*.yaml       # Script blueprints
  template/<author>/*.yaml     # Template blueprints
tests/
  conftest.py                  # install_blueprint fixture
  test_<domain>_<name>.py      # One runtime test file per blueprint
config/                        # Local Home Assistant instance (gitignored)
script/                        # Development and validation scripts
docs/
  user/                        # End-user documentation
  development/                 # Architecture, authoring, testing, releases
.github/
  instructions/                # Path-specific AI agent instructions
  prompts/                     # Reusable agent prompts
  workflows/                   # CI
.ha-version                    # Pinned Home Assistant release train
```

The author subfolder matters: Home Assistant mirrors it under `config/blueprints/<domain>/` on the user's
instance, which keeps your blueprints from colliding with someone else's.

## AI Agent Support

The repository ships a complete instruction system so coding agents produce blueprints that pass validation
instead of plausible-looking YAML:

- **[`AGENTS.md`](AGENTS.md)** — the primary reference: terminology, layout, authoring rules, required metadata,
  input/selector guidance, testing patterns, breaking-change policy
- **[`CLAUDE.md`](CLAUDE.md)**, **[`CODEX.md`](CODEX.md)**, **[`.github/copilot-instructions.md`](.github/copilot-instructions.md)** — entry points per agent
- **[`.github/instructions/`](.github/instructions/)** — path-specific rules applied by glob (blueprint authoring,
  tests, YAML, JSON, shell, commit messages)
- **[`.github/prompts/`](.github/prompts/)** — reusable prompts: _Add Blueprint_, _Review Blueprint_,
  _Create ADR_, _Create Implementation Plan_
- **[`AI_POLICY.md`](AI_POLICY.md)** — what agents may claim about review and testing

Agents are told to use the project scripts rather than crafting their own commands, and to never commit or push
without an explicit request.

## Resources

**Home Assistant blueprint documentation:**

- [Blueprint overview](https://www.home-assistant.io/docs/blueprint/)
- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/) — metadata, inputs, sections
- [Selectors](https://www.home-assistant.io/docs/blueprint/selectors/) — every selector type
- [Tutorial](https://www.home-assistant.io/docs/blueprint/tutorial/)
- [Blueprint Exchange forum](https://community.home-assistant.io/c/blueprints-exchange/53) — where collections get shared

**This repository:**

- [docs/development/ARCHITECTURE.md](docs/development/ARCHITECTURE.md) — how the tooling fits together
- [docs/development/AUTHORING.md](docs/development/AUTHORING.md) — writing a good blueprint
- [docs/development/TESTING.md](docs/development/TESTING.md) — the runtime test patterns
- [docs/development/RELEASE.md](docs/development/RELEASE.md) — versioning and releases
- [docs/development/CUSTOMIZATION.md](docs/development/CUSTOMIZATION.md) — adapting the template
- [CONTRIBUTING.md](CONTRIBUTING.md) — contribution guidelines
- [DEPENDENCIES.md](DEPENDENCIES.md) — what is installed and why

## Credits

Built on the tooling and DevContainer foundation of
[jpawlowski/hacs.integration_blueprint](https://github.com/jpawlowski/hacs.integration_blueprint), adapted from
custom integrations to Home Assistant blueprints.

## License

[MIT](LICENSE)
