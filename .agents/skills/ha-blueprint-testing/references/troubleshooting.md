# Test Troubleshooting

Symptom → cause → fix. Check here before rewriting a test that "should work".

## The test hangs until the timeout

**Cause, almost always:** `await hass.async_block_till_done()` on a run that is suspended in
`wait_for_trigger` or `delay:`. It waits for the run to _finish_, and the run is waiting for
something the test has not done yet.

**Fix:** use the `_settle()` loop instead, and only use `async_block_till_done()` at points
where the run can genuinely complete.

```python
async def _settle(hass: HomeAssistant) -> None:
    for _ in range(5):
        await asyncio.sleep(0)
```

**Second cause:** a `delay:` the test never advances past. Real time never passes in a
frozen test. `freezer.tick()` + `async_fire_time_changed(hass)`.

Run with `script/test -k <name> --timeout=30` while debugging so a hang fails fast.

## No service calls were captured

1. **The mock was registered after the trigger.** `async_mock_service` only captures calls
   made after it exists. Move it above the state change.
2. **The run has not reached the call yet.** Add `await _settle(hass)` between the trigger
   and the assertion.
3. **The trigger never fired.** See below.
4. **Wrong domain or service name.** `async_mock_service(hass, "light", "turn_on")` captures
   `light.turn_on` only — not `homeassistant.turn_on`, not `light.toggle`.

## The trigger never fires

- **No initial state.** Set the entity before `async_setup_component`. A first
  `async_set(MOTION, "on")` on a nonexistent entity is a `None → on` transition, which does
  not match `from: "off"`.
- **Missing attributes.** Purpose-specific triggers filter by domain _and_ device class. A
  `binary_sensor` without `{"device_class": "motion"}` is invisible to `motion.detected`.
  Numeric triggers also need `unit_of_measurement`.
- **`from:`/`to:` do not match.** A state trigger with `from: "off"` ignores
  `unavailable → on`.
- **The state did not actually change.** `async_set` to the same state with the same
  attributes produces no state-changed event.
- **Setup failed silently.** `async_setup_component` returns `False` on a bad
  instantiation. Always `assert await async_setup_component(...)`.

## `assert turn_on[0].data["entity_id"] == "light.lamp"` fails

`entity_id` in the resulting service call is a **list**: `["light.lamp"]`. A `target` input
is a dict going in and a list coming out.

## `KeyError` on service call data

A key is only present if the blueprint actually set it. Assert on what the blueprint sends,
not on what the service accepts:

```python
assert turn_on[0].data == {"entity_id": [LIGHT]}     # exact
assert "brightness_pct" not in turn_on[0].data       # explicitly absent
```

## `UndefinedError: 'x' is undefined` in a script test

A `field:`'s `default:` is not injected when the caller omits the field. The blueprint must
read it as `{{ x | default(3) }}` — `| int(3)` does not cover an undefined variable.

This is a **blueprint** bug that the test correctly caught. Fix the blueprint, and keep the
omitted-field test.

## The template entity has the wrong entity id

It is derived from the `name` on the instance, not from the blueprint:
`"name": "Inverted door"` → `binary_sensor.inverted_door`. Set `unique_id` too, or a second
instance in another test can collide.

## Test passes alone, fails in the suite

- **Shared entity ids across test files.** Each test gets a fresh `hass`, so this is rare —
  but a module-level mutable (a list, a dict of defaults) is not reset between tests.
- **A dangling task.** An `asyncio.ensure_future(...)` that is never awaited keeps running
  into the next test. Always await it, even if only at the end.

## The blueprint changed and every test fails

Expected when an input was renamed — which is exactly the signal that it is a **breaking
change** for users too. Do not just fix the tests: check whether the rename is justified,
and if it is, warn the developer and use a `BREAKING CHANGE:` commit footer. See the
**ha-blueprint-authoring** skill.

## Reading the failure

Home Assistant's log is captured and printed on failure. It shows blueprint instantiation,
trigger evaluation, and every action, including template errors with the offending
expression.

```bash
script/test -k <name> -v --timeout=30
```

If the log shows no automation setup at all, the blueprint failed to instantiate — usually a
missing required input or a selector rejecting the test value.

## When the test cannot reproduce the reported behaviour

The mental model is wrong, not Home Assistant. Reproduce it in the live instance and read
the trace (**ha-blueprint-authoring** → `references/debugging.md`), then bring the finding
back into a test. A bug you cannot write a test for is a bug you cannot claim to have fixed.
