---
name: ha-blueprint-testing
description: >
  Writing and debugging runtime tests for Home Assistant blueprints in this
  collection — pytest against a real in-memory Home Assistant instance.

  TRIGGER THIS SKILL WHEN:
  - Adding or changing any file under tests/
  - A new blueprint needs its required runtime test
  - A blueprint bug needs a regression test
  - script/test fails, hangs, or times out
  - Deciding what a blueprint test should actually assert

  SYMPTOMS THAT MEAN YOU SHOULD HAVE READ THIS:
  - Test hangs until timeout after calling async_block_till_done() on a suspended run
  - Test sleeps in real time instead of advancing a frozen clock
  - Service mock registered after the trigger, so nothing is captured
  - Assertion compares entity_id to a string where Home Assistant produces a list
  - Blueprint changed with no test that would have caught the bug
license: MIT
---

# Home Assistant Blueprint Testing

Blueprints here are tested at **runtime**, not just schema-checked. Each test copies the
real blueprint file into an in-memory Home Assistant instance, instantiates it with
`use_blueprint`, drives it with real state changes, and asserts on captured service calls
and entity states.

This is the capability most blueprint repositories do not have. It is what catches a
condition that never passes, a `mode:` that drops runs, and a template that dies on
`unavailable`.

## Read this before you touch that

| Your test involves…                                                 | Read first                                                     |
| ------------------------------------------------------------------- | -------------------------------------------------------------- |
| Setting up any of the three domains; triggers; targets; frozen time | [references/recipes.md](references/recipes.md)                 |
| A hang, a timeout, a flake, or a mock that captures nothing         | [references/troubleshooting.md](references/troubleshooting.md) |
| Behaviour of the blueprint itself rather than the test              | the **ha-blueprint-authoring** skill                           |

## Rules

1. **Every blueprint has at least one runtime test** covering its happy path.
2. **Every bug fix gets a test that fails before the fix.** Write it first, watch it fail,
   then fix. A regression test that never failed proves nothing.
3. **One test file per blueprint:** `tests/test_<domain>_<name>.py`.
4. **Never sleep in real time.** Use `freezer.tick()` + `async_fire_time_changed()`.
5. **Register service mocks before triggering.** A call made before the mock exists is
   executed for real and never recorded.
6. **The whole suite stays under a second.** These are in-memory instances with no I/O; if
   a test is slow, it is waiting on something it should be advancing.

## Running

```bash
script/test                 # everything
script/test -k motion       # matching tests only
script/test -v              # verbose
script/test --timeout=30    # guard against a hang while debugging
```

Use the script. It handles the venv and the pytest configuration; a hand-rolled `pytest`
invocation will not find the fixtures.

## The fixture

`tests/conftest.py` provides `install_blueprint`. It takes a path relative to `blueprints/`
and returns the value for `use_blueprint.path`:

```python
path = install_blueprint("automation/<author>/motion_light.yaml")
# → "<author>/motion_light.yaml"
```

It copies the **real file from the repository**, so every test exercises exactly what ships.
Nothing is stubbed except the service calls being asserted.

## The shape of a test

```python
"""Tests for the motion_light automation blueprint."""

from __future__ import annotations

import asyncio

from pytest_homeassistant_custom_component.common import async_mock_service

from homeassistant.core import HomeAssistant
from homeassistant.setup import async_setup_component

from .conftest import InstallBlueprint

BLUEPRINT = "automation/<author>/motion_light.yaml"
MOTION = "binary_sensor.motion"
LIGHT = "light.lamp"


async def test_light_turns_on_with_motion(
    hass: HomeAssistant, install_blueprint: InstallBlueprint
) -> None:
    """Light turns on as soon as motion is detected."""
    path = install_blueprint(BLUEPRINT)
    hass.states.async_set(MOTION, "off")          # initial state, before setup
    assert await async_setup_component(hass, "automation", {...})
    await hass.async_block_till_done()

    turn_on = async_mock_service(hass, "light", "turn_on")   # mock before trigger

    hass.states.async_set(MOTION, "on")           # this is the trigger
    await _settle(hass)

    assert len(turn_on) == 1
    assert turn_on[0].data["entity_id"] == [LIGHT]           # a list, not a string
```

Three things in that skeleton are the ones people get wrong: the **initial state before
setup**, the **mock before the trigger**, and **`entity_id` as a list**. Full per-domain
setups in [references/recipes.md](references/recipes.md).

## Waiting correctly

This is where blueprint tests differ from ordinary HA tests, and it is where they hang.

**`hass.async_block_till_done()` waits for the whole automation run to finish.** If the
blueprint is parked in `wait_for_trigger` or `delay:`, the run never finishes and the test
hangs until the timeout.

Use it only when the run can actually complete. Otherwise yield to the event loop:

```python
async def _settle(hass: HomeAssistant) -> None:
    """Let the run proceed to its suspension point."""
    for _ in range(5):
        await asyncio.sleep(0)
```

To get past a `delay:` or a `for:` duration, advance the clock — never wait:

```python
freezer.tick(timedelta(seconds=5))    # pytest-freezer fixture
async_fire_time_changed(hass)         # tell HA the clock moved
await _settle(hass)
```

Both steps are required. `freezer.tick()` alone moves the clock without telling Home
Assistant's scheduler about it.

## What to test

Required:

- **The happy path** — the thing the blueprint exists to do

Then, in rough order of value:

- **Defaults** — instantiate without the optional inputs; confirm the documented default applies
- **The negative case** — it does _not_ act when it should not
- **Timing** — the wait or delay is actually honoured, via frozen time
- **Unavailable entities** — templates degrade to `unavailable` instead of erroring
- **Re-triggering** — the chosen `mode` behaves as intended

For a blueprint using purpose-specific triggers, also cover **`behavior:`** with more than
one entity in the target — `each` vs `all` is exactly the kind of thing that is right for
one entity and wrong for three.

## Style

- Module-level constants for entity ids and the blueprint path
- A small `_setup()` helper when several tests share an instantiation
- Full type hints; `hass: HomeAssistant`, fixtures typed from `conftest`
- Descriptive names — `test_light_turns_off_after_motion_clears`, not `test_2`
- 4 spaces, 120-char lines, double quotes (see `.agents/instructions/collection.python.instructions.md`)

## Reference

- [pytest-homeassistant-custom-component](https://github.com/MatthewFlamm/pytest-homeassistant-custom-component)
- [Home Assistant testing docs](https://developers.home-assistant.io/docs/development_testing)
- Working examples covering all three domains: `tests/` in this repository
