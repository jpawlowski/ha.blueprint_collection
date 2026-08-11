# The Three Blueprint Domains

Read this when working on a `script` or `template` blueprint, or when unsure which domain
fits.

The `blueprint:` block is identical across all three. What differs is the body below it,
and how users instantiate it.

## Choosing a domain

| You want                                                    | Domain       |
| ----------------------------------------------------------- | ------------ |
| Something that happens on its own when the world changes    | `automation` |
| A reusable procedure the user (or another automation) calls | `script`     |
| A derived entity whose state is computed from others        | `template`   |

If it needs a trigger, it is an automation. If it needs to be _called_, it is a script. If
it needs to _be_ a sensor, it is a template blueprint.

## `automation`

A complete blueprint in the shape this collection recommends for new work — purpose-specific
trigger, `target` selectors, sections, a user-supplied action hook:

```yaml
blueprint:
  name: Motion-activated light
  description: >-
    Turn lights on when motion is detected and off again after the area has
    been quiet for a while. Works with a single sensor or a whole area.

    Needs: motion sensors and lights. On a Home Assistant restart a pending
    off-timer is lost and the lights stay on until the next motion cycle.
  domain: automation
  author: Blueprint Collection
  source_url: https://github.com/<owner>/<repo>/blob/main/blueprints/automation/<author>/motion_light.yaml
  homeassistant:
    min_version: 2026.7.0 # purpose-specific triggers
  input:
    devices:
      name: Devices
      icon: mdi:motion-sensor
      input:
        motion_target:
          name: Motion
          description: Motion sensors, or an area to watch.
          selector:
            target:
              entity:
                - domain: binary_sensor
                  device_class: motion
        light_target:
          name: Lights
          description: The lights to switch.
          selector:
            target:
              entity:
                - domain: light
    behaviour:
      name: Behaviour
      icon: mdi:cog
      collapsed: true # every input below therefore needs a default
      input:
        no_motion_wait:
          name: Wait time
          description: How long to keep the lights on after the last motion.
          default: 120
          selector:
            number: { min: 0, max: 3600, unit_of_measurement: seconds, mode: slider }
        extra_actions:
          name: Additional actions
          description: Runs after the lights are switched on.
          default: []
          selector:
            action:

mode: restart # renewed motion restarts the wait
max_exceeded: silent # re-triggering is the normal case, not a warning

variables:
  no_motion_wait: !input no_motion_wait # bound so templates can read it

triggers:
  - trigger: motion.detected
    target: !input motion_target
    options:
      behavior: each

conditions: []

actions:
  - alias: Switch the lights on
    action: light.turn_on
    target: !input light_target
  - alias: User-supplied actions
    sequence: !input extra_actions # empty default runs as a no-op
  - alias: Wait for the area to go quiet
    wait_for_trigger:
      - trigger: motion.cleared
        target: !input motion_target
        options:
          behavior: all # every sensor must be clear
  - delay:
      seconds: "{{ no_motion_wait }}"
  - alias: Switch the lights off
    action: light.turn_off
    target: !input light_target
```

Users instantiate it with `use_blueprint:` under `automation:` and supply their own
`alias:`. `mode:`/`max_exceeded:` belong to the blueprint, not the user.

Note `behavior: each` on the trigger and `behavior: all` on the wait: any sensor firing
should start the run, but the lights only go off once **all** of them are clear. Getting
that pair wrong is the classic multi-sensor bug.

For the full catalogue of triggers, conditions, waits, and control flow, use the
**ha-automation-patterns** skill.

## `script`

The body is a `sequence:`. Two things are specific to script blueprints:

**`fields:` are the script's own call parameters** — distinct from blueprint `input:`.
Inputs are set once at configuration time; fields are passed on every call.

```yaml
blueprint:
  domain: script
  # …
  input:
    light_target:
      name: Light
      description: The light to flash.
      selector:
        target:
          entity:
            - domain: light

mode: single

fields:
  flash_count:
    name: Flashes
    description: How many times to flash.
    required: false
    default: 3
    selector:
      number:
        min: 1
        max: 10

sequence:
  - repeat:
      count: "{{ flash_count | default(3) | int }}"
      sequence:
        - action: light.toggle
          target: !input light_target
        - delay:
            milliseconds: 500
```

Use an `input` for what is fixed per instance (which light), a `field` for what varies per
call (how many flashes). When in doubt: could two calls reasonably want different values?
Then it is a field.

> **A field's `default:` is documentation, not a value.** It fills the UI, and nothing more.
> When a caller omits the field, the variable is **undefined** — not empty, not defaulted.
> `{{ flash_count | int(3) }}` raises `UndefinedError` in that case, because `int`'s fallback
> only applies to a value that exists. Use `| default(3)` (which handles undefined) or set
> the fallback in a `variables:` step. Verified against the pinned Home Assistant; see
> pitfall W in [pitfalls.md](pitfalls.md).

**Users call it by the script's entity id**, which comes from the key they choose:

```yaml
script:
  flash_hall: # → script.flash_hall
    use_blueprint:
      path: <author>/flash_light.yaml
      input: { light_target: { entity_id: light.hall } }
```

`mode:` matters more here than in automations — a script called from several automations at
once with `mode: single` silently drops calls. Use `queued` or `parallel` where concurrent
calls are expected, and say so in the description.

## `template`

The body is a template entity definition. The top-level key after `blueprint:` and
`variables:` is the entity platform.

```yaml
blueprint:
  domain: template
  # …
  input:
    reference_entity:
      name: Reference entity
      description: The binary sensor to invert.
      selector:
        entity:
          filter:
            domain: binary_sensor

variables:
  reference_entity: !input reference_entity

binary_sensor:
  state: "{{ states(reference_entity) == 'off' }}"
  availability: "{{ has_value(reference_entity) }}"
```

- Supported platforms include `binary_sensor`, `sensor`, `button`, `image`, `number`,
  `select`, `switch`. One platform per blueprint.
- **Never set `name:` or `unique_id:` in the blueprint.** The user supplies both on their
  instance — a hardcoded `unique_id` makes it impossible to create two.
- **`availability:` is not optional in practice.** Without it the entity produces a garbage
  state whenever a source is missing, and that propagates downstream.
- Blueprint inputs are not automatically template variables here either — bind them in
  `variables:` first.

### Numeric sensors: `device_class`, `unit_of_measurement`, `state_class`

For a numeric `sensor:`, these three decide whether the entity is usable beyond a raw number:

```yaml
sensor:
  state: "{{ states(source_entity) | float(0) * 230 }}"
  unit_of_measurement: "W"
  device_class: power # unit conversion, icon, graph formatting
  state_class: measurement # long-term statistics
  availability: "{{ has_value(source_entity) }}"
```

- **Without `state_class`, Home Assistant records no long-term statistics** — the sensor is
  absent from statistics and from long-range history graphs. Set it on any numeric sensor
  whose history is worth keeping; leave it off for diagnostic or one-shot values.
- **`state_class` alone does not make a sensor Energy Dashboard eligible.** That also needs a
  matching `device_class` (`energy`, `power`, `gas`, …).
- Mirror the source sensor's `device_class` where the derived value has the same meaning.

Where the right value depends on the user's source entity, make it an input with a `select`
selector rather than guessing.

### Trigger-based template blueprints

A template blueprint may be **trigger-based**: add `triggers:` (and optionally `conditions:`
/ `actions:`) next to the entity platform, and the entity re-evaluates only when a trigger
fires instead of on every referenced state change.

```yaml
variables:
  source_entity: !input source_entity

triggers:
  - trigger: state
    entity_id: !input source_entity

sensor:
  state: "{{ states(source_entity) | float(0) * 2 }}"
  unit_of_measurement: "W"
  device_class: power
  state_class: measurement
  availability: "{{ has_value(source_entity) }}"
```

Verified against the pinned Home Assistant, including that `device_class` and `state_class`
survive into the created entity.

Use it when the state template is expensive, or when it touches entities whose changes should
**not** trigger a recalculation. A state-based template re-renders on every change of every
entity it references — including ones only read inside an `{% if %}` branch that is currently
false.

The trigger also gives the template access to the `trigger` variable. The trade-off is that
nothing recalculates until a trigger fires, so an entity that must always be current needs
either a state-based template or a `time_pattern` trigger as a safety net.

Users instantiate template blueprints as a **list**:

```yaml
template:
  - use_blueprint:
      path: <author>/inverted_binary_sensor.yaml
      input: { reference_entity: binary_sensor.door }
    name: Door closed
    unique_id: door_closed_inverted
```

Template blueprints have no `mode:`, no triggers, and no actions. If you find yourself
wanting one, you want an automation.

## Reference

- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/)
- [Script syntax](https://www.home-assistant.io/docs/scripts/)
- [Template integration](https://www.home-assistant.io/integrations/template/)
- Working examples of all three: `blueprints/*/<author>/` in this repository
