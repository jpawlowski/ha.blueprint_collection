# Testing Blueprints

Every blueprint in this collection has runtime tests: a real Home Assistant instance sets up
the blueprint, real state changes drive it, and assertions run against `hass.states` and
captured service calls.

This is the capability most blueprint repositories lack. Use it.

> **The patterns and the troubleshooting live in the agent skill**
> [`.agents/skills/ha-blueprint-testing/`](../../.agents/skills/ha-blueprint-testing/SKILL.md),
> with copy-paste recipes in
> [`references/recipes.md`](../../.agents/skills/ha-blueprint-testing/references/recipes.md)
> and symptom-driven fixes in
> [`references/troubleshooting.md`](../../.agents/skills/ha-blueprint-testing/references/troubleshooting.md).
> Plain Markdown — read them directly.

## Running

```bash
./script/test                 # Everything
./script/test -k motion       # Matching tests only
./script/test -v              # Verbose
./script/test --timeout=30    # Guard against a hanging test
```

The whole suite should stay well under a second — these tests use an in-memory instance with
no I/O.

## How it works

`pytest-homeassistant-custom-component` provides a real, in-memory Home Assistant instance
per test. The `install_blueprint` fixture (`tests/conftest.py`) copies a blueprint from
`blueprints/` into that instance's config directory and returns the path for `use_blueprint`:

```python
path = install_blueprint("automation/<author>/motion_light.yaml")
# → "<author>/motion_light.yaml"
```

It copies the **real file from the repository**, so every test exercises what ships. Nothing
is mocked except the service calls being asserted — the automation is set up, triggered, and
executed by Home Assistant itself.

That is what catches the things schema validation cannot: a trigger that never matches, a
condition that never passes, a `mode:` that drops runs, a template that dies on `unavailable`.

## Requirements

- **Every blueprint has at least one runtime test** covering its happy path
- **Every bug fix has a test that fails before the fix**
- One test file per blueprint: `tests/test_<domain>_<name>.py`

## The one thing that bites

`hass.async_block_till_done()` waits for the **whole run** to finish. If the blueprint is
parked in `wait_for_trigger` or a `delay:`, the run never finishes and the test hangs until
the timeout.

Use it only where the run can genuinely complete; otherwise yield to the event loop, and
advance a frozen clock instead of waiting. Both patterns are in the skill.

## Related

- [AUTHORING.md](AUTHORING.md) — writing the blueprint under test
- [ARCHITECTURE.md](ARCHITECTURE.md) — why the test runtime and the validator share one
  pinned Home Assistant version
- [pytest-homeassistant-custom-component](https://github.com/MatthewFlamm/pytest-homeassistant-custom-component)
- Existing tests in `tests/` — three examples covering all three domains
