# Inputs and Selectors

Read this before adding, changing, or filtering an input.

## The rules

**Every configurable value is an input with a typed selector.** A `text` selector where
an `entity` selector belongs lets a typo through, and the blueprint fails silently at
runtime instead of at configuration time.

**Filter aggressively.** `domain`, `device_class`, and `integration` filters turn "pick
from 400 entities" into "pick from 3". An unfiltered picker is a support ticket.

**Default what has a sensible default, require what does not.** An input _with_ a
`default:` is optional; _without_ one it is required. Use that deliberately:

- The entities the blueprint acts on → **required** (there is no universally correct entity)
- Behaviour tuning: wait times, brightness, thresholds → **defaulted**

A blueprint that works after filling in two fields gets used. One with ten mandatory
fields gets abandoned in the import dialog.

**Do not expose what has exactly one sensible value.** Every field is a decision you push
onto the user.

## `target` vs `entity` — the decision people get wrong

Both point at "the thing", but they produce different shapes:

- **`entity` → an entity_id (or list).** Use when you need the id itself: a trigger's
  `entity_id:`, a `states()` lookup, an `attribute` selector's anchor.
- **`target` → a target dict** (`entity_id` / `device_id` / `area_id` / `floor_id` /
  `label_id`). Use when the value flows straight into an action's `target:` — or into a
  purpose-specific trigger's `target:`. The user can then say "all lights in the living
  room" instead of enumerating entities.

```yaml
# entity — you need the concrete id
triggers:
  - trigger: state
    entity_id: !input motion_sensor

# target — passed through untouched
actions:
  - action: light.turn_on
    target: !input light_target
```

Rule of thumb: **acting on it → `target`; reading or referencing it → `entity`.**

> A `target` input arrives in tests as a dict — `{"light_target": {"entity_id": "light.lamp"}}` —
> and the resulting service call carries `entity_id` as a **list**. See the testing skill.

## Common selectors

```yaml
# Entity, filtered
motion_sensor:
  name: Motion sensor
  description: The sensor that triggers the automation.
  selector:
    entity:
      filter:
        domain: binary_sensor
        device_class: motion
      # multiple: true      # accept a list
      # include_entities / exclude_entities also available

# Target, filtered
light_target:
  name: Lights
  description: The lights to switch.
  selector:
    target:
      entity:
        - domain: light

# Number
no_motion_wait:
  name: Wait time
  description: How long to keep the light on after the last motion.
  default: 120
  selector:
    number:
      min: 0
      max: 3600
      step: 10
      unit_of_measurement: seconds
      mode: slider # or box

# Fixed choice
transition_mode:
  name: Transition
  default: fade
  selector:
    select:
      options:
        - label: Fade
          value: fade
        - label: Instant
          value: instant
      # mode: dropdown | list ; multiple: true ; custom_value: true

# Duration
cooldown:
  name: Cooldown
  default: { minutes: 5 }
  selector:
    duration:
      enable_day: false
      enable_second: true

# User-supplied actions — high leverage in a shared blueprint
extra_actions:
  name: Additional actions
  description: Runs after the light is switched on.
  default: []
  selector:
    action:
```

`filter:` accepts a **list** of filter blocks, which are OR-ed:

```yaml
selector:
  entity:
    filter:
      - domain: binary_sensor
        device_class: motion
      - domain: binary_sensor
        device_class: occupancy
```

## All selector types

Registered in the pinned Home Assistant. Regenerate with
`.venv/bin/python -c "from homeassistant.helpers import selector; print(sorted(selector.SELECTORS))"`.

| Selector                     | Yields                              | Notes                                                           |
| ---------------------------- | ----------------------------------- | --------------------------------------------------------------- |
| `action`                     | list of actions                     | Let users inject their own actions                              |
| `addon` / `app`              | slug                                | HA OS only; `app` is the 2026.2+ name for add-ons               |
| `area`                       | area id(s)                          | `device:` / `entity:` filters, `multiple:`, `reorder:`          |
| `assist_pipeline`            | pipeline id                         |                                                                 |
| `attribute`                  | attribute key                       | Requires `entity_id:` to anchor the list                        |
| `automation_behavior`        | `each`/`all`/`first` or `any`/`all` | `mode: trigger` or `mode: condition`; for 2026.7 triggers       |
| `backup_location`            | location name                       | HA OS only                                                      |
| `boolean`                    | true/false                          |                                                                 |
| `choose`                     | `{active_choice: …, …}`             | Offers the user a choice _between_ selectors                    |
| `color_rgb`                  | `[r, g, b]`                         |                                                                 |
| `color_temp`                 | number                              | `unit: kelvin` — mireds were removed in HA 2026.3               |
| `condition`                  | list of conditions                  | User-supplied conditions                                        |
| `config_entry`               | entry id                            | `integration:` filter                                           |
| `constant`                   | fixed value or nothing              | A checkbox that yields a fixed value; `value:`, `label:`        |
| `conversation_agent`         | agent id                            |                                                                 |
| `country`                    | ISO 3166 code                       | `countries:`, `no_sort:`                                        |
| `date` / `datetime` / `time` | string                              | `YYYY-MM-DD` / `YYYY-MM-DD HH:MM:SS` / `HH:MM:SS`               |
| `device`                     | device id(s)                        | Prefer entities; legitimate for Zigbee button device triggers   |
| `duration`                   | duration mapping                    | `enable_day/second/millisecond`, `allow_negative`               |
| `entity`                     | entity_id(s)                        | `filter:`, `include_entities`, `exclude_entities`, `multiple`   |
| `file`                       | file id                             |                                                                 |
| `floor`                      | floor id(s)                         |                                                                 |
| `icon`                       | `mdi:…`                             | `placeholder:`                                                  |
| `label`                      | label id(s)                         |                                                                 |
| `language`                   | RFC 5646 code                       | `languages:`, `native_name:`                                    |
| `location`                   | `{latitude, longitude, radius?}`    | `radius: true` to include one                                   |
| `media`                      | media dict                          | `accept:` MIME patterns                                         |
| `number`                     | number                              | `min`, `max`, `step`, `unit_of_measurement`, `mode`             |
| `numeric_threshold`          | threshold mapping                   | For 2026.7 threshold triggers — see triggers-conditions.md      |
| `object`                     | arbitrary YAML                      | Last resort; `fields:` gives it structure, `multiple:` a list   |
| `qr_code`                    | nothing (display only)              | `data:` required                                                |
| `select`                     | option value(s)                     | `options:` required; `multiple`, `custom_value`, `mode`, `sort` |
| `serial_port`                | port path                           |                                                                 |
| `state`                      | state string(s)                     | Anchored by `entity_id:`; `hide_states:`                        |
| `statistic`                  | statistic id(s)                     |                                                                 |
| `target`                     | target dict                         | `entity:` filter with domain/device_class/integration           |
| `template`                   | Jinja string                        | Hands the user a template — validate what you do with it        |
| `text`                       | string(s)                           | `multiline`, `prefix`, `suffix`, `type`, `multiple`             |
| `theme`                      | theme name                          |                                                                 |
| `trigger`                    | list of triggers                    | User-supplied triggers                                          |

## Sections

Once a blueprint exceeds roughly six inputs, group them. Requires HA `2024.6.0`.

```yaml
input:
  devices:
    name: Devices
    icon: mdi:motion-sensor
    input:
      motion_sensor:
        name: Motion sensor
        selector: { entity: { filter: { domain: binary_sensor, device_class: motion } } }
  behaviour:
    name: Behaviour
    icon: mdi:cog
    collapsed: true
    input:
      no_motion_wait:
        name: Wait time
        default: 120
        selector: { number: { min: 0, max: 3600 } }
```

- **Give every input inside a `collapsed: true` section a `default:`.** The schema does not
  enforce this (verified against the pinned HA), which makes it worse, not better: a
  required field hidden inside a collapsed section is one the user never sees and never
  fills in.
- Sections are display-only. `!input motion_sensor` still works regardless of nesting, and
  input keys stay globally unique.
- Put the common path in the first, expanded section; push advanced knobs into a collapsed one.

## Gotchas

- **`script/blueprint-check` fails on declared-but-unused and used-but-undeclared inputs.**
  Both directions. Delete inputs you stopped using.
- **`default: []` on an entity selector** is the idiom for "optional entity". Every
  `states(x)` on such an input must be guarded with `x != []` — see
  [templating.md](templating.md).
- **Do not default a `target` or `entity` input that the blueprint acts on.** There is no
  universally correct entity, and a defaulted-empty required field reads as configured.
- **Input keys are a public interface.** Renaming one breaks every existing automation
  built on the blueprint.

## Reference

- [Selectors](https://www.home-assistant.io/docs/blueprint/selectors/)
- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/)
