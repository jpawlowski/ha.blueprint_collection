# Test Recipes

Copy-paste starting points. All verified against the pinned Home Assistant.

## Imports

```python
from __future__ import annotations

import asyncio
from datetime import timedelta

from pytest_homeassistant_custom_component.common import (
    async_fire_time_changed,
    async_mock_service,
)

from homeassistant.core import HomeAssistant
from homeassistant.setup import async_setup_component

from .conftest import InstallBlueprint
```

## Settle helper

```python
async def _settle(hass: HomeAssistant) -> None:
    """Let the run proceed to its suspension point."""
    for _ in range(5):
        await asyncio.sleep(0)
```

Five iterations is the convention here. Raise it if a run needs more steps before its
suspension point; do not replace it with a sleep.

## Setting up an `automation` blueprint

```python
path = install_blueprint("automation/<author>/motion_light.yaml")
hass.states.async_set(MOTION, "off")     # initial state BEFORE setup

assert await async_setup_component(
    hass,
    "automation",
    {
        "automation": {
            "alias": "Motion light test",
            "use_blueprint": {
                "path": path,
                "input": {
                    "motion_entity": MOTION,
                    "light_target": {"entity_id": LIGHT},
                    "no_motion_wait": 0,
                },
            },
        }
    },
)
await hass.async_block_till_done()
```

`assert await async_setup_component(...)` — a blueprint that fails to instantiate returns
`False` rather than raising, and without the assert the test fails later with a confusing
message.

## Setting up a `script` blueprint

The dict key becomes the entity id: `script.flash_test`.

```python
path = install_blueprint("script/<author>/flash_light.yaml")

assert await async_setup_component(
    hass,
    "script",
    {
        "script": {
            "flash_test": {
                "use_blueprint": {
                    "path": path,
                    "input": {"light_target": {"entity_id": LIGHT}, "flash_count": 2},
                }
            }
        }
    },
)
await hass.async_block_till_done()

await hass.services.async_call("script", "flash_test", blocking=True)
```

**Script `fields:`** are passed as service data, not as blueprint inputs:

```python
await hass.services.async_call("script", "flash_test", {"flash_count": 5}, blocking=True)
```

A field's `default:` is **not** injected when the caller omits it — the variable is
undefined. Test both the explicit call and the omitted one; the omitted case is where
`| int(3)` blows up and `| default(3)` does not.

## Setting up a `template` blueprint

A **list**, with `name` and `unique_id` alongside `use_blueprint`:

```python
path = install_blueprint("template/<author>/inverted_binary_sensor.yaml")
hass.states.async_set(SOURCE, "on")

assert await async_setup_component(
    hass,
    "template",
    {
        "template": [
            {
                "use_blueprint": {"path": path, "input": {"reference_entity": SOURCE}},
                "name": "Inverted door",
                "unique_id": "inverted_door_test",
            }
        ]
    },
)
await hass.async_block_till_done()

assert hass.states.get("binary_sensor.inverted_door").state == "off"
```

Template entities have no run to wait for — assert on `hass.states` directly.

## Capturing service calls

```python
turn_on = async_mock_service(hass, "light", "turn_on")

hass.states.async_set(MOTION, "on")
await _settle(hass)

assert len(turn_on) == 1
assert turn_on[0].data["entity_id"] == [LIGHT]      # LIST
assert turn_on[0].data["brightness_pct"] == 50
```

**Register the mock before triggering.** A call made before the mock exists is executed for
real and never recorded — the classic "assert len(calls) == 0" failure.

**A `target` input arrives as a dict** in the test input (`{"entity_id": "light.lamp"}`)
and comes back out of the service call as a **list** (`["light.lamp"]`). Comparing to a
bare string always fails.

## Driving a state trigger

Set the initial state **before** `async_setup_component`, so the first real change is the
one that triggers:

```python
hass.states.async_set(MOTION, "off")   # initial
await _setup(...)                      # automation now listening
hass.states.async_set(MOTION, "on")    # this triggers
```

Attributes matter for anything filtered or numeric:

```python
hass.states.async_set(
    BATTERY, "50",
    {"device_class": "battery", "unit_of_measurement": "%", "state_class": "measurement"},
)
```

Purpose-specific triggers select entities by domain **and device class**, so a
`binary_sensor` without `{"device_class": "motion"}` will never fire `motion.detected`.

## Purpose-specific triggers with a target

Pass the target as a dict, exactly as the blueprint's `target` input expects:

```python
"input": {
    "motion_target": {"entity_id": MOTION},
    "light_target": {"entity_id": LIGHT},
}
```

To exercise `behavior:`, target two entities and drive them independently:

```python
"motion_target": {"entity_id": [MOTION_A, MOTION_B]},
```

`behavior: each` fires per entity; `behavior: all` fires once when both match. Asserting the
call count with two entities is what distinguishes them.

## Advancing time

```python
async def test_delay_is_honored(hass, install_blueprint, freezer) -> None:
    await _setup(hass, install_blueprint)
    turn_on = async_mock_service(hass, "light", "turn_on")
    turn_off = async_mock_service(hass, "light", "turn_off")

    task = asyncio.ensure_future(
        hass.services.async_call("script", "flash_paced", blocking=True)
    )
    await _settle(hass)
    assert len(turn_on) == 1        # first action ran, now parked in the delay

    freezer.tick(timedelta(seconds=5))
    async_fire_time_changed(hass)
    await _settle(hass)
    assert len(turn_off) == 1

    freezer.tick(timedelta(seconds=5))
    async_fire_time_changed(hass)
    await task                       # now the run can complete
```

The `freezer` fixture comes from `pytest-freezer`. The same pattern advances a `for:`
duration on a state trigger.

Wrapping a blocking service call in `asyncio.ensure_future` is what lets you inspect state
while the run is suspended. Await the task at the end so the test does not leave it dangling.

## Asserting a negative

```python
hass.states.async_set(MOTION, "on")
await _settle(hass)

assert len(turn_off) == 0
```

Give the run a chance to act before asserting it did not. Asserting immediately after
`async_set` passes for the wrong reason — nothing has run yet.

## Unavailable entities

```python
hass.states.async_set(SOURCE, "unavailable")
await hass.async_block_till_done()

assert hass.states.get("binary_sensor.inverted_door").state == "unavailable"
```

For automations, assert that no service call happened and that no template error appears —
`caplog` catches the latter.

## Defaults

Instantiate without the optional inputs and assert the documented default applies:

```python
"input": {"motion_entity": MOTION, "light_target": {"entity_id": LIGHT}}
# no_motion_wait omitted → blueprint default of 120s
```

Then advance 119 seconds and assert nothing happened, 1 more and assert it did. This is the
only test that actually pins a default; asserting the YAML has one does not.
