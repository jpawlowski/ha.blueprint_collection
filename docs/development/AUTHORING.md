# Authoring Blueprints

Orientation for writing a blueprint in this collection. This page covers the shape of the
work and where things live.

> **The authoritative rules live in the agent skill**
> [`.agents/skills/ha-blueprint-authoring/`](../../.agents/skills/ha-blueprint-authoring/SKILL.md).
> It is plain Markdown — read it directly. Everything there applies to humans too; it is
> kept in one place so that agents and people cannot drift apart.

## Anatomy

```yaml
blueprint:
  name: Motion-activated light
  description: >-
    Turn a light on when motion is detected and turn it off again after no
    motion has been detected for a configurable wait time.
  domain: automation
  author: Blueprint Collection
  source_url: https://github.com/<owner>/<repo>/blob/main/blueprints/automation/<author>/motion_light.yaml
  homeassistant:
    min_version: 2024.10.0
  input:
    motion_entity:
      name: Motion sensor
      description: The motion sensor that triggers the light.
      selector:
        entity:
          filter:
            domain: binary_sensor
            device_class: motion

mode: restart
max_exceeded: silent

triggers:
  - trigger: state
    entity_id: !input motion_entity
    from: "off"
    to: "on"

actions:
  - action: light.turn_on
    target: !input light_target
```

Everything above `mode:` is metadata for the import dialog. Everything below is a normal
automation, script, or template entity definition — with `!input` where a value comes from
the user.

## Naming and placement

- Path: `blueprints/<domain>/<author>/<snake_case_name>.yaml`
- The domain folder must match `blueprint.domain`
- The extension must be `.yaml` — Home Assistant's folder scan ignores `.yml`
- **The file name is part of the import URL.** Renaming breaks `source_url` and every
  published link. Choose carefully the first time.

## Workflow

```bash
# 1. Write the file
./script/blueprint-check   # Home Assistant's own validator + repository rules

# 2. Try it for real
./script/develop           # then create an automation from it in the UI

# 3. Write a runtime test (required — see TESTING.md)
./script/test

# 4. Full check before committing
./script/check
```

Add the new blueprint's import badge to the README with `./script/import-links`.

## Where the detail lives

| Question                                                         | Read                                                                                                    |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Which selector, how to filter, how to group inputs into sections | [selectors.md](../../.agents/skills/ha-blueprint-authoring/references/selectors.md)                     |
| Which trigger or condition, and the 2026.7 purpose-specific ones | [triggers-conditions.md](../../.agents/skills/ha-blueprint-authoring/references/triggers-conditions.md) |
| Jinja, `!input` in templates, availability expressions           | [templating.md](../../.agents/skills/ha-blueprint-authoring/references/templating.md)                   |
| Script `fields:`, template entity bodies, choosing a domain      | [domains.md](../../.agents/skills/ha-blueprint-authoring/references/domains.md)                         |
| Which Home Assistant version a feature needs                     | [ha-version-matrix.md](../../.agents/skills/ha-blueprint-authoring/references/ha-version-matrix.md)     |
| A bug that makes no sense                                        | [pitfalls.md](../../.agents/skills/ha-blueprint-authoring/references/pitfalls.md)                       |
| Traces, logs, reload semantics in a live instance                | [debugging.md](../../.agents/skills/ha-blueprint-authoring/references/debugging.md)                     |

## Changing an existing blueprint

Inputs are a public interface. Users have automations configured through them, and they
receive a change only when they **re-import**.

**Breaking** (warn first, use a `BREAKING CHANGE:` commit footer): renaming or removing an
input; changing its meaning, unit, or selector type; changing trigger/action behaviour users
depend on; raising `homeassistant.min_version`; renaming or moving the file.

**Safe:** adding a new input with a default; widening a selector filter; fixing logic that
was plainly wrong; improving the description.

## Related

- [TESTING.md](TESTING.md) — runtime test patterns
- [RELEASE.md](RELEASE.md) — versioning and release notes
- [ARCHITECTURE.md](ARCHITECTURE.md) — why the tooling works the way it does
- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/) ·
  [Selectors](https://www.home-assistant.io/docs/blueprint/selectors/)
