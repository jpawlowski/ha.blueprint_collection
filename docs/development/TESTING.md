# Testing Blueprints

Every blueprint in this collection has runtime tests: a real Home Assistant instance sets up the blueprint,
real state changes drive it, and assertions run against `hass.states` and captured service calls.

This is the capability most blueprint repositories lack. Use it.

## Running

```bash
./script/test                 # Everything
./script/test -k motion       # Matching tests only
./script/test -v              # Verbose
./script/test --timeout=30    # Guard against a hanging test
```

The whole suite should stay well under a second — these tests use an in-memory instance with no I/O.

## The fixture

`tests/conftest.py` provides `install_blueprint`. It takes a path relative to `blueprints/` and returns the
value to use as `use_blueprint.path`:

```python
path = install_blueprint("automation/<author>/motion_light.yaml")
# → "<author>/motion_light.yaml"
```

It copies the real file from the repository, so the test always exercises what ships.

## Setting up each domain

**Automation:**

```python
assert await async_setup_component(
    hass,
    "automation",
    {
        "automation": {
            "alias": "Motion light test",
            "use_blueprint": {
                "path": path,
                "input": {
                    "motion_entity": "binary_sensor.motion",
                    "light_target": {"entity_id": "light.lamp"},
                    "no_motion_wait": 0,
                },
            },
        }
    },
)
await hass.async_block_till_done()
```

**Script** — the key is the script's entity ID; call it with `hass.services.async_call("script", "<key>")`:

```python
{"script": {"flash_test": {"use_blueprint": {"path": path, "input": {...}}}}}
```

**Template** — a list, with `name` and `unique_id` alongside `use_blueprint`:

```python
{"template": [{"use_blueprint": {"path": path, "input": {...}},
               "name": "Inverted door", "unique_id": "inverted_door_test"}]}
```

> [!NOTE]
> `target` inputs take dict form: `{"light_target": {"entity_id": "light.lamp"}}`. The resulting service call
> data has `entity_id` as a **list**: `assert call.data["entity_id"] == ["light.lamp"]`.

## Capturing service calls

Register the mock **before** triggering, or the call is made for real and not recorded:

```python
turn_on = async_mock_service(hass, "light", "turn_on")

hass.states.async_set("binary_sensor.motion", "on")
await _settle(hass)

assert len(turn_on) == 1
assert turn_on[0].data["entity_id"] == ["light.lamp"]
```

## Driving triggers

State triggers fire on `hass.states.async_set`. Set the _initial_ state before setting up the component, so the
first real change is the one that triggers:

```python
hass.states.async_set(MOTION, "off")     # initial
await _setup(...)                        # automation now listening
hass.states.async_set(MOTION, "on")      # this triggers
```

## Waiting correctly

This is the part that bites.

**`hass.async_block_till_done()` waits for the whole automation run to finish.** If the blueprint parks in
`wait_for_trigger` or a `delay:`, the run never finishes and the test hangs until the timeout.

Use it only when the run can actually complete. Otherwise yield to the event loop instead:

```python
async def _settle(hass: HomeAssistant) -> None:
    """Let the run proceed to its suspension point."""
    for _ in range(5):
        await asyncio.sleep(0)
```

That is enough for the actions before the suspension point to execute.

**To get past a `delay:`, advance time.** Real waiting is never acceptable in a test:

```python
task = asyncio.ensure_future(
    hass.services.async_call("script", "flash_paced", blocking=True)
)
await _settle()                          # first action ran, now in the delay
assert len(turn_on) == 1

freezer.tick(timedelta(seconds=5))       # freezer fixture from pytest-freezer
async_fire_time_changed(hass)            # tell HA the clock moved
await _settle()
assert len(turn_off) == 1

freezer.tick(timedelta(seconds=5))
async_fire_time_changed(hass)
await task                               # now the run completes
```

The same pattern advances a `for:` duration on a state trigger.

## What to test

Required for every blueprint:

- **The happy path** — the thing it exists to do

Worth adding, in rough priority order:

- **Defaults** — instantiate without the optional inputs and confirm the documented default applies
- **The negative case** — it does _not_ act when it should not (condition blocks it, wrong state)
- **Timing** — the wait/delay is actually honored, via frozen time
- **Unavailable entities** — templates degrade to `unavailable` rather than erroring
- **Re-triggering** — the chosen `mode` behaves as intended

Any bug fix needs a test that fails before the fix.

## Style

- One test file per blueprint: `test_<domain>_<name>.py`
- Module-level constants for entity IDs
- A small `_setup()` helper when several tests share the same instantiation
- Full type hints; `hass: HomeAssistant`, fixtures typed from `conftest`
- Descriptive test names — `test_light_turns_off_after_motion_clears`, not `test_2`

## Debugging a failing test

```bash
./script/test -k <name> -v --timeout=30
```

Home Assistant's log is captured and printed on failure — it shows automation setup, trigger firing, and every
action. If a test hangs, it is almost always `async_block_till_done()` on a suspended run.

## Reference

- [Home Assistant testing docs](https://developers.home-assistant.io/docs/development_testing)
- [pytest-homeassistant-custom-component](https://github.com/MatthewFlamm/pytest-homeassistant-custom-component)
- Existing tests in `tests/` — the three examples cover all three domains and every pattern above
