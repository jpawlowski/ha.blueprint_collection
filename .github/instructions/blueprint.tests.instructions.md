---
applyTo: "tests/**/*.py"
---

# Test Instructions

**Applies to:** `tests/` directory

**Official documentation:** [Home Assistant Testing](https://developers.home-assistant.io/docs/development_testing)

## What Is Tested

Blueprints are tested at **runtime**: each test installs the blueprint into an in-memory Home Assistant instance,
instantiates it via `use_blueprint`, and asserts real behavior — triggers firing, service calls, template states.
Schema-level validation is handled by `script/blueprint-check`, not by tests.

## Test Structure

```text
tests/
  conftest.py                              # install_blueprint fixture
  test_automation_<name>.py                # one file per automation blueprint
  test_script_<name>.py                    # one file per script blueprint
  test_template_<name>.py                  # one file per template blueprint
```

**Every blueprint must have at least one runtime test** covering its happy path. Behavior changes and bug
fixes need a test that would have caught the bug.

## Core Patterns

**Install and instantiate** (the `install_blueprint` fixture returns the `use_blueprint.path` value):

```python
path = install_blueprint("automation/<author>/<name>.yaml")
assert await async_setup_component(
    hass,
    "automation",
    {"automation": {"use_blueprint": {"path": path, "input": {...}}}},
)
await hass.async_block_till_done()
```

**Capture service calls** with `async_mock_service` — register mocks BEFORE triggering:

```python
turn_on = async_mock_service(hass, "light", "turn_on")
hass.states.async_set("binary_sensor.motion", "on")
```

**Advance through delays** with the `freezer` fixture plus `async_fire_time_changed`:

```python
freezer.tick(timedelta(seconds=5))
async_fire_time_changed(hass)
```

**Suspended runs:** While a run is parked in `wait_for_trigger` or a `delay`, `hass.async_block_till_done()`
waits for the whole run and hangs the test. Yield to the event loop instead:

```python
for _ in range(5):
    await asyncio.sleep(0)
```

Only use `async_block_till_done()` when the run can actually complete.

**Target inputs** take dict form: `{"light_target": {"entity_id": "light.lamp"}}`.

**Template blueprint instances** set `name`/`unique_id` next to `use_blueprint`:

```python
{"template": [{"use_blueprint": {...}, "name": "X", "unique_id": "x"}]}
```

## Core Interface Testing

**Rule: Test through core interfaces (`hass.states`, `hass.services`), never through internals.**

✅ **Correct:** `hass.states.get("binary_sensor.x")`, `hass.services.async_call("script", "my_script")`

❌ **Wrong:** Reaching into automation/script component internals

## Style

- Full type hints (`hass: HomeAssistant`, fixture types from `conftest`)
- One test file per blueprint; small focused test functions with descriptive names
- Constants for entity IDs at module top
- No sleeps with real durations — always freezer/time-changed or `asyncio.sleep(0)` yields
