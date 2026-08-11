---
applyTo: "blueprints/**/*.yaml"
---

# Home Assistant Blueprint Instructions

**Applies to:** All blueprint files under `blueprints/`

> **Full authoring guidance:** [`.agents/skills/ha-blueprint-authoring/`](../../.agents/skills/ha-blueprint-authoring/SKILL.md)
> — selectors, triggers and conditions (including the 2026.7 purpose-specific ones),
> templating, per-domain bodies, the `min_version` matrix, known pitfalls, and live
> debugging. Read it before any non-trivial change. This file holds only the rules that
> must apply even when the skill is not loaded.

## File Placement

```text
blueprints/
  automation/<author>/<name>.yaml   # domain: automation
  script/<author>/<name>.yaml       # domain: script
  template/<author>/<name>.yaml     # domain: template
```

- The domain folder MUST match the `blueprint.domain` value
- Always use the author subfolder — Home Assistant mirrors this structure under
  `config/blueprints/<domain>/`
- Extension MUST be `.yaml` (`.yml` is not loaded by Home Assistant)
- Snake_case file names; the file name is part of the import path and the `source_url` —
  renaming is a breaking change

## Required Metadata

```yaml
blueprint:
  name: Motion-activated light
  description: >-
    What it does, what it needs, caveats. Markdown allowed — this is the
    text users see in the import dialog.
  domain: automation
  author: Blueprint Collection
  source_url: https://github.com/<owner>/<repo>/blob/main/blueprints/automation/<author>/<name>.yaml
  homeassistant:
    min_version: 2024.10.0
```

- `source_url` must point at THIS file on `main` — `script/blueprint-check` verifies path
  and repository
- `min_version` is the oldest HA version the blueprint runs on, and must not exceed the
  development Home Assistant version. Raising it on an existing blueprint is a **breaking
  change** — see the skill's `ha-version-matrix.md`

## Hard Rules

- Every configurable value is an `input` with `name`, `description`, and a **typed
  `selector`** — never free text where a selector exists
- Reference inputs with `!input`; declared-but-unused and used-but-undeclared inputs are CI
  errors
- **`!input` does not work inside Jinja** — assign to a variable first:
  `variables: {my_entity: !input my_entity}`
- `entity_id` over `device_id`; never hardcode entities, areas, or devices
- Modern syntax only: plural `triggers:`/`conditions:`/`actions:` with in-item
  `trigger:`/`condition:`/`action:` keys — never legacy `platform:`/`service:`
- Prefer the 2026.7 purpose-specific triggers/conditions (`motion.detected`, `light.is_on`)
  with a `target:` — note they require `min_version: 2026.7.0`
- Choose `mode` deliberately; `restart` + `max_exceeded: silent` for motion/presence timers
- One blueprint per file, one concern per blueprint
- Every input in a `collapsed: true` section needs a `default:`

## Breaking Changes

Inputs are a public interface. These require an explicit warning to the developer and a
`BREAKING CHANGE:` commit footer:

- Renaming or removing an input, or changing its meaning/unit/selector type
- Changing trigger/action behavior users likely depend on
- Raising `homeassistant.min_version`
- Renaming or moving a blueprint file

Users only receive changes when they **re-import** — release notes must say when
re-importing is needed.

## Validation

- `script/blueprint-check` — HA schema validation plus repository rules; run after every edit
- `script/test` — every blueprint needs at least one runtime test
- `./script/develop` — try it interactively in a real instance
