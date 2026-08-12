# Architecture

This document explains how the development environment fits together. It is about the **tooling**, not about any
individual blueprint — blueprints are plain YAML with no architecture of their own.

## The problem this repository solves

Home Assistant blueprints are distributed as single YAML files that users import by URL. There is no package
manager, no build step, and no runtime the author controls. The conventional authoring workflow is:

1. Edit YAML
2. Restart Home Assistant or reload the integration
3. Click through the UI to create an automation
4. Trigger it by hand and watch what happens

That loop is slow, and nothing about it is repeatable. A change that breaks an edge case is discovered by users,
not by the author.

This repository replaces that with two mechanisms that both use **the real Home Assistant code**, never a
reimplementation of it.

## Mechanism 1: Schema validation

`script/blueprint-check` imports Home Assistant's own blueprint machinery from the installed virtual environment:

```python
from homeassistant.components.blueprint.models import Blueprint
from homeassistant.components.blueprint.schemas import BLUEPRINT_SCHEMA
from homeassistant.util import yaml as yaml_util

bp = Blueprint(
    yaml_util.load_yaml_dict(path),
    path=rel,
    expected_domain=domain,
    schema=BLUEPRINT_SCHEMA,
)
```

This is the exact code path Home Assistant runs when a user imports the blueprint, so a file that passes here
will import cleanly. `Blueprint.__init__` already rejects a domain mismatch and any `!input` reference without a
matching definition; `BLUEPRINT_SCHEMA` validates every selector.

Because the validator is the real thing, it tracks Home Assistant automatically: bump `HA_VERSION`, and the
blueprints are validated against the new schema with no changes here.

On top of that, `script/blueprint-check` adds repository rules Home Assistant has no opinion about:

| Rule                                            | Why                                                         |
| ----------------------------------------------- | ----------------------------------------------------------- |
| Folder domain matches `blueprint.domain`        | HA loads by folder; a mismatch silently never loads         |
| `.yaml` extension                               | HA's folder scan is `glob("**/*.yaml")` — `.yml` is ignored |
| Author subfolder                                | Keeps imports collision-free on the user's instance         |
| Declared-but-unused inputs                      | Dead form fields confuse users                              |
| `min_version` present and ≤ the installed HA    | An unvalidatable claim is worse than none                   |
| `source_url` matches repository and actual path | A wrong `source_url` breaks re-import for every user        |

## Mechanism 2: Runtime tests

`pytest-homeassistant-custom-component` provides a real, in-memory Home Assistant instance per test. The
`install_blueprint` fixture (`tests/conftest.py`) copies a blueprint from `blueprints/` into that instance's
config directory and returns the path to use with `use_blueprint`:

```text
blueprints/automation/<author>/motion_light.yaml
    │  install_blueprint("automation/<author>/motion_light.yaml")
    ▼
hass.config.path("blueprints/automation/<author>/motion_light.yaml")
    │  async_setup_component(hass, "automation", {... use_blueprint ...})
    ▼
A real automation, driven by real state changes, asserted through hass.states / hass.services
```

Nothing is mocked except the service calls being asserted. The automation is set up, triggered, and executed by
Home Assistant itself, which means the tests catch what actually matters: wrong trigger syntax, a condition that
never passes, a `mode` that drops runs, a template that fails on `unavailable`.

See [TESTING.md](TESTING.md) for the patterns.

## Mechanism 3: The live instance

`script/develop` starts a full Home Assistant against `config/`. Before starting, `script/setup/sync-blueprints`
mirrors `blueprints/` into `config/blueprints/` using **per-file symlinks**:

```text
config/blueprints/automation/<author>/motion_light.yaml
    → ../../../../blueprints/automation/<author>/motion_light.yaml
```

Per-file rather than per-directory, because Home Assistant's blueprint folder scan follows file symlinks but a
directory symlink is not traversed the same way. The consequence is that editing a blueprint in the workspace is
immediately live in the running instance — reload the automation/script/template integration and the change is
in effect. New files need a `sync-blueprints` run to be linked.

Regular files in `config/blueprints/` (blueprints a user imported via the UI) are never overwritten, and stale
symlinks from deleted or renamed sources are cleaned up on each run.

## Version pinning

One Home Assistant version governs everything, recorded as `HA_VERSION` in `.devcontainer/.env`:

```text
.devcontainer/.env       HA_VERSION ── read by ─→ script/setup/bootstrap  (installs HA)
                                    ── read by ─→ .github/workflows/*     (cache keys)
.devcontainer/.env.local HA_VERSION ── overrides ─→ the above (gitignored, personal)
requirements_test.txt               ── pins ─────→ pytest-homeassistant-custom-component
```

`script/ha-version-sync` enforces that all of these target the same release train (`YYYY.M`), and that no
workflow hardcodes a version. It runs as a pre-commit hook and in CI.

This matters because the schema validator and the test runtime must be the _same_ Home Assistant. If they drift,
a blueprint could validate against one version and be tested against another.

## Layout

```text
blueprints/<domain>/<author>/*.yaml   The deliverable — what users import
tests/                                Runtime tests, one file per blueprint
config/                               Local HA instance (gitignored except configuration.yaml)
script/                               Development and validation scripts
  .lib/                               Shared shell libraries
  setup/                              Bootstrap, reset, sync
schemas/json/                         JSON Schema for blueprints (editor support)
schemas/yaml/                         JSON Schema for configuration.yaml (editor support)
docs/user/                            End-user documentation
docs/development/                     This directory
.agents/instructions/                 Path-scoped AI agent rules
.github/prompts/                      Reusable agent prompts
.github/workflows/                    CI
.devcontainer/.env                    HA_VERSION — the pinned Home Assistant version
```

## Distribution

Blueprints are **not** distributed through HACS — HACS has no blueprint category. Distribution is Home
Assistant's native import:

```text
https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=<url-encoded source_url>
```

Home Assistant accepts a GitHub `blob` URL directly and rewrites it to raw internally, so each blueprint's
`source_url` **is** its import URL. `script/import-links` generates the badge markdown from it.

The practical consequence: **`main` is the release channel.** Anything merged is immediately importable. Git tags
and release notes exist to tell users _when to re-import_ and _what changed_ — see [RELEASE.md](RELEASE.md).

## Related documents

- [AUTHORING.md](AUTHORING.md) — writing a good blueprint
- [TESTING.md](TESTING.md) — runtime test patterns
- [RELEASE.md](RELEASE.md) — versioning and releases
- [CUSTOMIZATION.md](CUSTOMIZATION.md) — adapting the template
- [DECISIONS.md](DECISIONS.md) — why things are the way they are
- [SKILLS_UPSTREAM.md](SKILLS_UPSTREAM.md) — the agent layer, and what was ported from the upstream
