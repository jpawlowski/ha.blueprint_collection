---
applyTo: "**/*.py"
paths:
  - "**/*.py"
name: "Python Style"
description: "Style, typing and docstring rules for the test suite and tooling"
---

# Python Code Instructions

**Applies to:** All Python files (in this repository: the blueprint test suite and tooling)

## Code Style

- 4 spaces indentation, 120 character line length, double quotes
- Full type hints on all functions, fixtures, and variables where not inferred
- `from __future__ import annotations` at the top of every module
- Async for all Home Assistant interaction (`async def` tests via pytest-asyncio auto mode)

## Type Annotations

- Annotate `hass: HomeAssistant` and use fixture type aliases from `conftest.py`
- Prefer PEP 695 type aliases (`type X = ...`) for callable fixture types
- No `Any` unless genuinely unavoidable

## Imports

- Import order is enforced by Ruff (isort rules); `homeassistant` counts as first-party
- Test helpers come from `pytest_homeassistant_custom_component.common`
  (`async_mock_service`, `async_fire_time_changed`, ...)
- Relative imports inside `tests/` (`from .conftest import ...`)

## Validation

- `script/python` — Ruff format + lint with auto-fix
- `script/type-check` — Pyright (basic mode); no auto-fix, always a manual loop
- Generate code that passes both on first run; use `# noqa: CODE` only for genuine false positives

## Verify Current Patterns

Home Assistant test APIs evolve; when unsure, check
[developers.home-assistant.io](https://developers.home-assistant.io/docs/development_testing) and the
pinned `pytest-homeassistant-custom-component` version in `requirements_test.txt`.
