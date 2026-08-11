# Triggers, Conditions, and Actions

Read this before writing or changing any trigger or condition.

Everything in this file was verified against the Home Assistant version pinned in
`.devcontainer/.env` (`HA_VERSION`). When that version changes, re-derive the catalogue
with the script at the end rather than trusting this text.

## The order to choose in

1. **A purpose-specific trigger/condition** — `motion.detected`, `battery.became_low`,
   `light.is_on`. Default since HA 2026.7.
2. **A generic trigger/condition** — `state`, `numeric_state`, `time`, `template`.
3. **A `template` trigger/condition** — last resort. Templates bypass load-time
   validation and fail silently at runtime.

Most "clever" template conditions are a native condition someone did not look for:

| Template                                          | Native replacement                         |
| ------------------------------------------------- | ------------------------------------------ |
| `{{ states('x') \| float > 25 }}`                 | `numeric_state` condition with `above: 25` |
| `{{ is_state('x','on') and is_state('y','on') }}` | `condition: and` of two state conditions   |
| `{{ now().hour >= 9 }}`                           | `condition: time` with `after: "09:00:00"` |
| `wait_template: "{{ is_state(...) }}"`            | `wait_for_trigger` with a state trigger \* |

\* Not identical: `wait_template` returns immediately when the state is _already_ true;
`wait_for_trigger` waits for a _change_. Switching between them changes behaviour.

## Purpose-specific triggers and conditions

Introduced in HA **2026.7** as the default building blocks. They describe the outcome
("motion detected") instead of the mechanism ("`binary_sensor` went `off` → `on`"), and
they accept an area/floor/label `target:` so the automation follows area membership
instead of a frozen entity list.

### Syntax

The key is `<domain>.<name>`. `target:` is **required**. Everything else — `behavior:`,
`for:`, `threshold:` — lives under **`options:`**, not at the top level. This is the part
that is easy to get wrong and is not shown in the release blog.

```yaml
triggers:
  - trigger: motion.detected
    target: !input motion_target # entity_id / device_id / area_id / floor_id / label_id
    options:
      behavior: each
      for: "00:00:05" # optional; state must hold this long
```

```yaml
conditions:
  - condition: light.is_off
    target: !input light_target
    options:
      behavior: any
```

`target:` takes the same shape a service call does, so a `target` selector input drops
straight in via `!input`. A plain `entity_id:` mapping works too.

### `behavior:` values

Triggers and conditions use **different** vocabularies. Mixing them up is a validation
error, not a silent bug — but it is still the most common mistake here.

| Context       | Values                 | Default | Meaning                                                                                                                                 |
| ------------- | ---------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Trigger**   | `each`, `all`, `first` | `each`  | `each`: fire per matching entity. `all`: fire once when _every_ targeted entity matches. `first`: fire only for the first one to match. |
| **Condition** | `any`, `all`           | `any`   | `any`: pass if at least one targeted entity matches. `all`: pass only if every one does.                                                |

Legacy trigger values `any` and `last` still load but raise a repair issue and are slated
for removal — write `each` and `all`.

### Threshold triggers

Names ending in `_crossed_threshold` (and `_changed`) take a `threshold:` field under
`options:`:

```yaml
triggers:
  - trigger: battery.level_crossed_threshold
    target: !input battery_target
    options:
      behavior: each
      threshold:
        type: below # above | below | between | outside | any
        value:
          number: 20
          unit_of_measurement: "%" # required whenever you give a number
```

- `type: above` / `below` take a single `value:`.
- `type: between` / `outside` take `value_min:` and `value_max:` instead.
- `type: any` is only valid on the `_changed` variants, never on `_crossed_threshold`.
- A `value:` entry is either `{number: …, unit_of_measurement: …}` **or**
  `{entity: input_number.x}` — giving both requires `active_choice:` to disambiguate.

To let the user set the threshold, expose it as a `number` input and reference it —
`number: !input my_threshold`.

### Renames in 2026.7

Old keys no longer load. If you copy an example from before July 2026, check it against
this list:

| Old                              | New                             |
| -------------------------------- | ------------------------------- |
| `battery.low`                    | `battery.became_low`            |
| `battery.not_low`                | `battery.no_longer_low`         |
| `lawn_mower.docked`              | `lawn_mower.returned_to_dock`   |
| `schedule.turned_on`             | `schedule.block_started`        |
| `schedule.turned_off`            | `schedule.block_ended`          |
| `timer.time_remaining`           | `timer.remaining_time_reached`  |
| `update.update_became_available` | `update.became_available`       |
| `vacuum.docked`                  | `vacuum.returned_to_dock`       |
| `climate.target_humidity`        | `climate.is_target_humidity`    |
| `climate.target_temperature`     | `climate.is_target_temperature` |

### The min_version cost

Using any purpose-specific trigger or condition means `homeassistant.min_version: 2026.7.0`.
Home Assistant then refuses the import on older instances — which is the correct
behaviour, but it excludes those users entirely.

For a published collection, decide this per blueprint and record the decision in the
commit message. On an **existing** blueprint, raising `min_version` is a breaking change
(see the authoring skill).

### When a generic trigger is still right

- No purpose-specific trigger exists for what you need (check the catalogue below).
- You need `attribute:` on a state trigger, or a `from:`/`to:` pair the purpose-specific
  variant does not express.
- The blueprint must run on older Home Assistant versions and you are unwilling to pay
  the `min_version` cost.
- You need the trigger's `trigger.to_state` / `trigger.from_state` payload in a template
  in a form the purpose-specific trigger does not provide — verify in a trace before
  assuming this.

## Catalogue

Domains marked ° are device-class pseudo-domains: they target `binary_sensor`/`sensor`
entities with that device class, across integrations.

### Triggers

| Domain                | Keys                                                                                                                                                                                                                                                          |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `air_quality`°        | `gas_detected`, `gas_cleared`, `co_detected`, `co_cleared`, `smoke_detected`, `smoke_cleared`, plus `<measure>_changed` / `<measure>_crossed_threshold` for `co`, `co2`, `pm1`, `pm25`, `pm4`, `pm10`, `ozone`, `voc`, `voc_ratio`, `no`, `no2`, `n2o`, `so2` |
| `alarm_control_panel` | `armed`, `armed_away`, `armed_home`, `armed_night`, `armed_vacation`, `disarmed`, `triggered`                                                                                                                                                                 |
| `assist_satellite`    | `idle`, `listening`, `processing`, `responding`                                                                                                                                                                                                               |
| `battery`°            | `became_low`, `no_longer_low`, `started_charging`, `stopped_charging`, `level_changed`, `level_crossed_threshold`                                                                                                                                             |
| `button`              | `pressed`                                                                                                                                                                                                                                                     |
| `calendar`            | `event_started`, `event_ended`                                                                                                                                                                                                                                |
| `climate`             | `started_cooling`, `started_drying`, `started_heating`, `turned_on`, `turned_off`, `hvac_mode_changed`, `target_humidity_changed`, `target_humidity_crossed_threshold`, `target_temperature_changed`, `target_temperature_crossed_threshold`                  |
| `counter`             | `incremented`, `decremented`, `maximum_reached`, `minimum_reached`, `reset`                                                                                                                                                                                   |
| `cover`               | `<type>_opened` / `<type>_closed` for `awning`, `blind`, `curtain`, `shade`, `shutter`                                                                                                                                                                        |
| `door`°               | `opened`, `closed`                                                                                                                                                                                                                                            |
| `doorbell`°           | `rang`                                                                                                                                                                                                                                                        |
| `event`               | `received`                                                                                                                                                                                                                                                    |
| `fan`                 | `turned_on`, `turned_off`                                                                                                                                                                                                                                     |
| `garage_door`°        | `opened`, `closed`                                                                                                                                                                                                                                            |
| `gate`°               | `opened`, `closed`                                                                                                                                                                                                                                            |
| `humidifier`          | `started_drying`, `started_humidifying`, `turned_on`, `turned_off`, `mode_changed`                                                                                                                                                                            |
| `humidity`°           | `changed`, `crossed_threshold`                                                                                                                                                                                                                                |
| `illuminance`°        | `detected`, `cleared`, `changed`, `crossed_threshold`                                                                                                                                                                                                         |
| `lawn_mower`          | `returned_to_dock`, `errored`, `paused_mowing`, `started_mowing`, `started_returning`                                                                                                                                                                         |
| `light`               | `turned_on`, `turned_off`, `brightness_changed`, `brightness_crossed_threshold`                                                                                                                                                                               |
| `lock`                | `jammed`, `locked`, `opened`, `unlocked`                                                                                                                                                                                                                      |
| `media_player`        | `muted`, `unmuted`, `paused_playing`, `started_playing`, `stopped_playing`, `turned_on`, `turned_off`, `volume_changed`, `volume_crossed_threshold`                                                                                                           |
| `moisture`°           | `detected`, `cleared`, `changed`, `crossed_threshold`                                                                                                                                                                                                         |
| `moon`                | `phase_changed`                                                                                                                                                                                                                                               |
| `motion`°             | `detected`, `cleared`                                                                                                                                                                                                                                         |
| `occupancy`°          | `detected`, `cleared`                                                                                                                                                                                                                                         |
| `power`°              | `changed`, `crossed_threshold`                                                                                                                                                                                                                                |
| `remote`              | `turned_on`, `turned_off`                                                                                                                                                                                                                                     |
| `scene`               | `activated`                                                                                                                                                                                                                                                   |
| `schedule`            | `block_started`, `block_ended`                                                                                                                                                                                                                                |
| `select`              | `selection_changed`                                                                                                                                                                                                                                           |
| `siren`               | `turned_on`, `turned_off`                                                                                                                                                                                                                                     |
| `sun`                 | `sunrise`, `sunset`, `solar_noon`, `solar_midnight`, `dawn`, `dusk`, `elevation_changed`, `elevation_crossed_threshold`                                                                                                                                       |
| `switch`              | `turned_on`, `turned_off`                                                                                                                                                                                                                                     |
| `temperature`°        | `changed`, `crossed_threshold`                                                                                                                                                                                                                                |
| `text`                | `changed`                                                                                                                                                                                                                                                     |
| `timer`               | `started`, `restarted`, `paused`, `cancelled`, `finished`, `remaining_time_reached`                                                                                                                                                                           |
| `todo`                | `item_added`, `item_completed`, `item_removed`                                                                                                                                                                                                                |
| `update`              | `became_available`                                                                                                                                                                                                                                            |
| `vacuum`              | `returned_to_dock`, `errored`, `paused_cleaning`, `started_cleaning`, `started_returning`                                                                                                                                                                     |
| `valve`               | `opened`, `closed`                                                                                                                                                                                                                                            |
| `vibration`°          | `detected`, `cleared`                                                                                                                                                                                                                                         |
| `water_heater`        | `operation_mode_changed`, `turned_on`, `turned_off`, `target_temperature_changed`, `target_temperature_crossed_threshold`                                                                                                                                     |
| `window`°             | `opened`, `closed`                                                                                                                                                                                                                                            |
| `zone`                | `entered`, `left`, `occupancy_detected`, `occupancy_cleared`                                                                                                                                                                                                  |

### Conditions

| Domain                                                         | Keys                                                                                                                                                          |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `air_quality`°                                                 | `is_gas_detected`/`is_gas_cleared`, `is_co_detected`/`is_co_cleared`, `is_smoke_detected`/`is_smoke_cleared`, and `is_<measure>_value` for the measures above |
| `alarm_control_panel`                                          | `is_armed`, `is_armed_away`, `is_armed_home`, `is_armed_night`, `is_armed_vacation`, `is_disarmed`, `is_triggered`                                            |
| `assist_satellite`                                             | `is_idle`, `is_listening`, `is_processing`, `is_responding`                                                                                                   |
| `battery`°                                                     | `is_low`, `is_not_low`, `is_charging`, `is_not_charging`, `is_level`                                                                                          |
| `calendar`                                                     | `is_event_active`                                                                                                                                             |
| `climate`                                                      | `is_on`, `is_off`, `is_cooling`, `is_drying`, `is_heating`, `is_hvac_mode`, `is_target_humidity`, `is_target_temperature`                                     |
| `counter`                                                      | `is_value`                                                                                                                                                    |
| `cover`                                                        | `<type>_is_open` / `<type>_is_closed` for `awning`, `blind`, `curtain`, `shade`, `shutter`                                                                    |
| `door`° `garage_door`° `gate`° `window`° `valve`               | `is_open`, `is_closed`                                                                                                                                        |
| `fan` `remote` `schedule` `siren` `switch`                     | `is_on`, `is_off`                                                                                                                                             |
| `humidifier`                                                   | `is_on`, `is_off`, `is_drying`, `is_humidifying`, `is_mode`, `is_target_humidity`                                                                             |
| `humidity`° `power`° `temperature`°                            | `is_value`                                                                                                                                                    |
| `illuminance`° `moisture`° `motion`° `occupancy`° `vibration`° | `is_detected`, `is_not_detected` (`illuminance`/`moisture` also `is_value`)                                                                                   |
| `lawn_mower`                                                   | `is_docked`, `is_mowing`, `is_paused`, `is_returning`, `is_encountering_an_error`                                                                             |
| `light`                                                        | `is_on`, `is_off`, `is_brightness`                                                                                                                            |
| `lock`                                                         | `is_jammed`, `is_locked`, `is_open`, `is_unlocked`                                                                                                            |
| `media_player`                                                 | `is_on`, `is_off`, `is_playing`, `is_not_playing`, `is_paused`, `is_muted`, `is_unmuted`, `is_volume`                                                         |
| `moon`                                                         | `is_phase`, `is_waxing`, `is_waning`                                                                                                                          |
| `select`                                                       | `is_option_selected`                                                                                                                                          |
| `sun`                                                          | `is_up`, `is_set`, `is_ascending`, `is_descending`, `is_night`, `is_morning_twilight`, `is_evening_twilight`, `elevation`                                     |
| `text`                                                         | `is_equal_to`                                                                                                                                                 |
| `timer`                                                        | `is_active`, `is_paused`, `is_idle`                                                                                                                           |
| `todo`                                                         | `all_completed`, `incomplete`                                                                                                                                 |
| `update`                                                       | `is_available`, `is_not_available`                                                                                                                            |
| `vacuum`                                                       | `is_cleaning`, `is_docked`, `is_paused`, `is_returning`, `is_encountering_an_error`                                                                           |
| `water_heater`                                                 | `is_on`, `is_off`, `is_operation_mode`, `is_target_temperature`                                                                                               |
| `zone`                                                         | `in_zone`, `not_in_zone`, `occupancy_is_detected`, `occupancy_is_not_detected`                                                                                |

### Regenerating the catalogue

Home Assistant ships these as data files, so the installed venv is always authoritative:

```bash
.venv/bin/python - <<'PY'
import glob, os, yaml, homeassistant
sp = os.path.dirname(homeassistant.__file__)
for kind in ("triggers", "conditions"):
    print(f"### {kind}")
    for f in sorted(glob.glob(f"{sp}/components/*/{kind}.yaml")):
        domain = f.split("/components/")[1].split("/")[0]
        keys = [k for k in (yaml.safe_load(open(f)) or {}) if not k.startswith(".")]
        print(f"{domain}: {', '.join(keys)}")
PY
```

The same files also show each key's `target:` entity filter and its `fields:` — read the
domain's `triggers.yaml` when you need the exact selector for a threshold or an option.

## Generic triggers still worth knowing

`state`, `numeric_state`, `template`, `time`, `time_pattern`, `event`, `mqtt`, `webhook`,
`zone`, `geo_location`, `sun`, `tag`, `calendar`, `persistent_notification`, `sentence`,
`homeassistant` (`start`/`shutdown`), `device`.

Notes that matter inside blueprints:

- **`device` triggers are the exception to "no `device_id`"** and only for Zigbee2MQTT /
  ZHA button events, where no entity carries the event. Everywhere else, use entities.
- **`for:` on a state trigger** needs the state to hold; a flapping sensor never fires it.
- **`homeassistant: start`** is how you handle "what if HA restarts mid-run" — automations
  never resume. Decide whether a half-finished state is acceptable, and say so in the
  blueprint description.

## Actions

- Use `action:` for the service call (`action: light.turn_on`), never legacy `service:`.
- Give every `choose:` branch and every non-obvious step an `alias:` — traces are the only
  remote-support tool you get, and an unnamed step is unreadable in one.
- `continue_on_error: true` where a failing optional step should not abort the run.
- An `action` **selector** input lets users inject their own actions ("what should happen
  when this fires") — the single highest-leverage input type for a shared blueprint.
- `enabled:` on an individual trigger/condition/action accepts an `!input` and is
  evaluated at load time. It is the clean way to make a `boolean` input switch a whole
  branch on or off without a runtime condition.

## Reference

- [Triggers](https://www.home-assistant.io/triggers/) · [Conditions](https://www.home-assistant.io/conditions/) · [Actions](https://www.home-assistant.io/actions/)
- [Automation YAML](https://www.home-assistant.io/docs/automation/yaml/)
- [2026.7 release notes](https://www.home-assistant.io/blog/2026/07/01/release-20267/)
