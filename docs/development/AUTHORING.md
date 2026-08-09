# Authoring Blueprints

How to write a blueprint in this collection. The mechanical rules are enforced by `script/blueprint-check`; this
document covers the judgement calls it cannot make.

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

Everything above `mode:` is metadata for the import dialog. Everything below is a normal automation, script, or
template entity definition — with `!input` where a value comes from the user.

## Naming and placement

- Path: `blueprints/<domain>/<author>/<snake_case_name>.yaml`
- The domain folder must match `blueprint.domain`
- The extension must be `.yaml` — Home Assistant's folder scan ignores `.yml`
- **The file name is part of the import URL.** Renaming breaks `source_url` and every published link. Choose
  carefully the first time.

## Writing the description

The description is what users read in the import dialog before deciding whether to trust your blueprint. It
supports Markdown. Cover:

1. **What it does** — one sentence, plainly
2. **What it needs** — required entity types, integrations, or helpers
3. **Caveats** — anything surprising: what happens on Home Assistant restart, on rapid re-triggering, when an
   entity is unavailable

Skip implementation detail. Users do not care that you use `wait_for_trigger`.

## Designing inputs

**Every configurable value is an input.** If a user might plausibly want a different value, it is an input, not
a constant in the logic. Conversely, do not expose things that have exactly one sensible value — each field is a
decision you push onto the user.

**Always use a typed selector.** Free text where a selector exists is a bug:

```yaml
# ✅ Filtered, cannot pick something unusable
selector:
  entity:
    filter:
      domain: binary_sensor
      device_class: motion

# ❌ User can type anything
selector:
  text:
```

Filter aggressively — `domain`, `device_class`, and `integration` filters turn "pick from 400 entities" into
"pick from 3". See the [selector reference](https://www.home-assistant.io/docs/blueprint/selectors/).

**Provide defaults wherever a sensible one exists.** A blueprint that works after filling in two required fields
gets used; one with ten mandatory fields gets abandoned in the import dialog.

**Use `target` for things you act on, `entity` for things you read.** A `target` selector lets users pick
entities, devices, or whole areas at once, which is almost always what you want on the acting side.

**Group with sections** once you exceed roughly six inputs (requires `min_version: 2024.6.0`). Put the advanced
ones in a `collapsed: true` section so the common path stays short.

**`!input` does not work inside Jinja.** Assign to a variable first:

```yaml
variables:
  reference_entity: !input reference_entity
# then: "{{ states(reference_entity) }}"
```

## Choosing a mode

| Mode       | Behavior on re-trigger while running | Typical use                              |
| ---------- | ------------------------------------ | ---------------------------------------- |
| `single`   | Ignore (warns in the log)            | Default; runs that must not overlap      |
| `restart`  | Cancel and start over                | Motion/presence timers — the common case |
| `queued`   | Run after the current one finishes   | Ordered processing                       |
| `parallel` | Run concurrently                     | Independent per-entity work              |

For anything with a wait or delay driven by a repeating trigger, `restart` plus `max_exceeded: silent` is
almost always right: renewed motion should extend the light's on-time, not log a warning.

## Rules that keep blueprints working

**Use `entity_id`, never `device_id`.** Device references break when a user replaces hardware; entity IDs
survive, and users understand them.

**Never hardcode an entity, area, or device.** That is what inputs are for. A hardcoded `light.living_room` makes
the blueprint useless to everyone else.

**Use modern syntax.** `triggers:`/`conditions:`/`actions:` with `trigger:`/`condition:`/`action:` keys — not the
legacy `platform:`/`service:` spellings. This requires `min_version: 2024.10.0`.

**Set `min_version` honestly.** It must reflect the newest syntax you actually use, and it may not exceed the
development Home Assistant version (`HA_VERSION` in `.devcontainer/.env`) — otherwise CI cannot validate what
you claim.

**One concern per blueprint.** A blueprint that does motion lighting _and_ presence simulation _and_
notifications is three blueprints. Composition beats configuration flags.

## Handling edge cases

Think through these before writing the test — they are where blueprints break in the field:

- **Entity unavailable or unknown** — does the template blow up? Use `has_value()` in `availability:`
- **Home Assistant restart mid-run** — automations do not resume; is a half-finished state acceptable?
- **Rapid re-triggering** — does the mode handle it the way users expect?
- **The user picks multiple entities** — `target` selectors allow it; does the logic still make sense?

## Workflow

```bash
# 1. Write the file
# 2. Validate against Home Assistant's own schema
./script/blueprint-check

# 3. Try it for real
./script/develop     # then create an automation from it in the UI

# 4. Write a runtime test (required — see TESTING.md)
./script/test

# 5. Full check before committing
./script/check
```

Add the new blueprint's import badge to the README with `./script/import-links`.

## Changing an existing blueprint

Inputs are a public interface. Users have automations configured through them.

**Breaking** (warn the developer, use a `BREAKING CHANGE:` commit footer):

- Renaming or removing an input
- Changing an input's meaning, unit, or selector type
- Changing trigger/action behavior users depend on
- Raising `homeassistant.min_version`
- Renaming or moving the file

**Safe:**

- Adding a new input **with a default**
- Widening a selector filter
- Fixing logic that was plainly wrong
- Improving the description

Remember that users only receive any change when they **re-import**. A fix in `main` does not reach existing
installations — say so in the release notes when it matters.

## Reference

- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/)
- [Selectors](https://www.home-assistant.io/docs/blueprint/selectors/)
- [Automation YAML](https://www.home-assistant.io/docs/automation/yaml/)
- [Script syntax](https://www.home-assistant.io/docs/scripts/)
- [Template integration](https://www.home-assistant.io/integrations/template/)
