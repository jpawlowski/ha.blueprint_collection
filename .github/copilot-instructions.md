# GitHub Copilot Instructions

> **Comprehensive docs:** See [`AGENTS.md`](../AGENTS.md) at the repository root for full AI agent documentation.
>
> **Why two files?** This file is loaded automatically by GitHub Copilot. `AGENTS.md` serves non-Copilot agents (Claude Code, Cursor, etc.) who don't read this file. Some overlap is intentional. Path-specific `*.instructions.md` files provide detailed patterns per file type — avoid duplicating their content here.

> **AI policy:** Read [`AI_POLICY.md`](../AI_POLICY.md). Extensive AI assistance is permitted, but never overstate human
> review, automated coverage, or real-device testing. Treat publication material as a draft for human review and follow
> the rules of the destination (e.g. the Home Assistant Blueprint Exchange forum).

## Project Identity

This repository is a collection of **Home Assistant blueprints** — reusable automation, script, and template
configurations that users import into their own instance. "Blueprint" always means a Home Assistant blueprint here.

- **Title:** Blueprint Collection
- **Author folder:** `ha_blueprint_author`
- **Blueprints:** `blueprints/{automation,script,template}/ha_blueprint_author/*.yaml`
- **Validate:** `script/check` (type-check + lint-check + spell-check + blueprint-check)
- **Test:** `script/test` (runtime tests in an in-memory HA instance)
- **Start HA:** `./script/develop` (syncs blueprints, starts on port 8123)
- **Force restart:** `pkill -f "hass --config" || true && pkill -f "debugpy.*5678" || true && ./script/develop`

## Code Quality Baseline

- **Blueprints (YAML):** 2 spaces, modern HA syntax (`triggers:`/`actions:` with `trigger:`/`action:` keys — no
  legacy `platform:`/`service:` style), `.yaml` extension
- **Python (tests):** 4 spaces, 120 char lines, double quotes, full type hints
- **JSON:** 2 spaces, no trailing commas, no comments

Before considering any coding task complete, the following **must** pass:

```bash
script/check      # type-check + lint-check + spell-check + blueprint-check
script/test       # runtime tests
```

## Blueprint Rules (Quick Reference)

- File location: `blueprints/<domain>/ha_blueprint_author/<name>.yaml`; `<domain>` must match `blueprint.domain`
- Required metadata: `name`, `description`, `domain`, `author`, `source_url` (GitHub blob URL of the file on `main`),
  `homeassistant.min_version`
- Every configurable value is an `input` with `name`, `description`, and a typed `selector`; provide `default`s
- Reference inputs with `!input`; in Jinja templates assign to a variable first (`variables: {x: !input x}`)
- Use `entity_id`, never `device_id`; never hardcode entities in logic
- Choose automation `mode` deliberately (`restart` + `max_exceeded: silent` for motion patterns)
- Every blueprint needs at least one runtime test in `tests/` (see existing tests for the patterns:
  `install_blueprint` fixture, `async_mock_service`, freezer time-advance for delays)

## Breaking Changes

Inputs are a public interface. Warn before renaming/removing inputs, changing their meaning or selector, changing
trigger/action behavior, raising `min_version`, or renaming/moving files (breaks import links). Users only receive
changes when they re-import — say so in release notes. Use a `BREAKING CHANGE:` commit footer.

## Workflow

- **Small changes:** Edit blueprint → `script/blueprint-check` → adapt/add test → `script/test`
- **New blueprint:** Author file with full metadata → validate → write runtime test → add import link to README
- **Commits:** Conventional Commits (see `blueprint.commit-message.instructions.md`); never commit or push
  without an explicit request
- **Temporary notes:** `.ai-scratch/` (never committed); never create stray markdown files

## Path-Specific Instructions

- `blueprint.ha_blueprints.instructions.md` — Blueprint authoring (schema, inputs, selectors, modes)
- `blueprint.tests.instructions.md` — Runtime test patterns
- `blueprint.python.instructions.md` — Python style for tests
- `blueprint.yaml.instructions.md` / `blueprint.json.instructions.md` — Formatting
- `blueprint.configuration_yaml.instructions.md` — Dev HA configuration
- `blueprint.shell.instructions.md` — Shell script style
- `blueprint.commit-message.instructions.md` — Commit format
