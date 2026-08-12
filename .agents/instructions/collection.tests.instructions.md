---
applyTo: "tests/**/*.py"
paths:
  - "tests/**/*.py"
name: "Blueprint Runtime Tests"
description: "Non-negotiable rules for the runtime test suite under tests/"
---

# Test Instructions

**Applies to:** `tests/` directory

> **Full testing guidance:** [`.agents/skills/ha-blueprint-testing/`](../../.agents/skills/ha-blueprint-testing/SKILL.md)
> — per-domain setup recipes, frozen time, purpose-specific triggers, and symptom-driven
> troubleshooting for hangs and silent mocks. This file holds only the rules that must apply
> even when the skill is not loaded.

## What Is Tested

Blueprints are tested at **runtime**: each test installs the blueprint into an in-memory
Home Assistant instance, instantiates it via `use_blueprint`, and asserts real behavior —
triggers firing, service calls, template states. Schema-level validation is handled by
`script/blueprint-check`, not by tests.

## Structure

```text
tests/
  conftest.py                 # install_blueprint fixture
  test_automation_<name>.py   # one file per automation blueprint
  test_script_<name>.py       # one file per script blueprint
  test_template_<name>.py     # one file per template blueprint
```

**Every blueprint must have at least one runtime test** covering its happy path. Behavior
changes and bug fixes need a test that would have caught the bug.

## Hard Rules

- **Register service mocks BEFORE triggering** — a call made earlier is executed for real
  and never captured
- **Never sleep in real time** — `freezer.tick(...)` plus `async_fire_time_changed(hass)`
- **`hass.async_block_till_done()` hangs on a suspended run.** While a run is parked in
  `wait_for_trigger` or a `delay:`, yield to the event loop instead:

  ```python
  for _ in range(5):
      await asyncio.sleep(0)
  ```

  Only use `async_block_till_done()` when the run can actually complete.

- **`assert await async_setup_component(...)`** — a failed instantiation returns `False`
  rather than raising
- **Target inputs** take dict form going in (`{"light_target": {"entity_id": "light.lamp"}}`)
  and come back out of the service call as a **list** (`["light.lamp"]`)
- **Template blueprint instances** set `name`/`unique_id` next to `use_blueprint`, in a list:
  `{"template": [{"use_blueprint": {...}, "name": "X", "unique_id": "x"}]}`

## Core Interface Testing

**Test through core interfaces (`hass.states`, `hass.services`), never through internals.**

✅ `hass.states.get("binary_sensor.x")`, `hass.services.async_call("script", "my_script")`

❌ Reaching into automation/script component internals

## Style

- Full type hints (`hass: HomeAssistant`, fixture types from `conftest`)
- One test file per blueprint; small focused functions with descriptive names
- Constants for entity IDs at module top
