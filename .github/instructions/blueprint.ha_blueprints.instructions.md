---
applyTo: "blueprints/**/*.yaml"
---

# Home Assistant Blueprint Instructions

**Applies to:** All blueprint files under `blueprints/`

**Official documentation:**

- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/)
- [Selectors](https://www.home-assistant.io/docs/blueprint/selectors/)
- [Blueprint tutorial](https://www.home-assistant.io/docs/blueprint/tutorial/)

## File Placement

```text
blueprints/
  automation/<author>/<name>.yaml   # domain: automation
  script/<author>/<name>.yaml       # domain: script
  template/<author>/<name>.yaml     # domain: template
```

- The domain folder MUST match the `blueprint.domain` value
- Always use the author subfolder — Home Assistant mirrors this structure under
  `config/blueprints/<domain>/`, so the author folder keeps imports collision-free
- Extension MUST be `.yaml` (`.yml` is not loaded by Home Assistant)
- Snake_case file names; the file name is part of the import path and the `source_url` — renaming is a breaking change

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

- `source_url` must point at THIS file on `main` — `script/blueprint-check` verifies path and repository
- `min_version` is the oldest HA version the blueprint runs on; raise it when adopting newer syntax
  (`triggers:`/`actions:` keys → 2024.10; input `sections` → 2024.6). It must not exceed the development Home Assistant version

## Inputs

- Every configurable value is an `input` with `name`, `description`, and a typed `selector`
- Never use free-text input where a typed selector exists; prefer `entity`/`target` selectors with `filter:`
- Provide `default` values wherever sensible — minimal-configuration blueprints get used
- Reference inputs with `!input <key>`; declared-but-unused and used-but-undeclared inputs are CI errors
- `!input` does not work inside Jinja template strings — assign to a variable first:

  ```yaml
  variables:
    my_entity: !input my_entity
  # then: "{{ states(my_entity) }}"
  ```

- Group many inputs with input `sections`; mark advanced sections `collapsed: true`

## Logic Rules

- Modern syntax only: `triggers:`/`conditions:`/`actions:` with `trigger:`/`condition:`/`action:` keys
  (never legacy `platform:`/`service:`)
- `entity_id` over `device_id` — device references break when users replace hardware
- Never hardcode entity IDs, areas, or devices — that is what inputs are for
- Choose `mode` deliberately:
  - `single` — default; ignore re-trigger while running
  - `restart` — re-trigger restarts the run (motion/presence timers); pair with `max_exceeded: silent`
  - `queued`/`parallel` — only with a documented reason
- One blueprint per file, one concern per blueprint

## Template Blueprints

The top-level keys after `blueprint:` and `variables:` form the template entity definition:

```yaml
variables:
  reference_entity: !input reference_entity

binary_sensor:
  state: "{{ states(reference_entity) == 'off' }}"
  availability: "{{ has_value(reference_entity) }}"
```

Users provide `name:` and `unique_id:` on their `use_blueprint` instance — do not hardcode them in the blueprint.

## Validation and Testing

- `script/blueprint-check` — HA schema validation plus repository rules; run after every blueprint edit
- `script/test` — every blueprint needs at least one runtime test (see `tests/` for patterns)
- To try a blueprint interactively: `./script/develop`, then create an automation/script from it in the HA UI

## Breaking Changes

Inputs are a public interface. The following require an explicit warning to the developer and a
`BREAKING CHANGE:` commit footer:

- Renaming or removing an input, or changing its meaning/unit/selector type
- Changing trigger/action behavior users likely depend on
- Raising `homeassistant.min_version`
- Renaming or moving a blueprint file (breaks `source_url` and every published import link)

Users only receive changes when they **re-import** the blueprint — release notes must say when re-importing
is needed.
