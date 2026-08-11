# Feature → `min_version` Matrix

Read this before adopting a Home Assistant feature you have not used in this collection
before, and before changing `homeassistant.min_version`.

## Why this is a distribution decision

`homeassistant.min_version` is the oldest Home Assistant a blueprint runs on. Home
Assistant **refuses the import** below it — which is correct behaviour, and also the
reason it is not a technical detail:

- Setting it too low means users import a blueprint that breaks at runtime.
- Setting it too high excludes users who cannot or will not upgrade.
- **Raising it on an existing blueprint is a breaking change.** Users below the new
  floor lose the ability to re-import and never receive another fix.

Two hard constraints:

1. It must cover the newest syntax the file actually uses.
2. It must not exceed the pinned development Home Assistant (`HA_VERSION` in
   `.devcontainer/.env`) — otherwise CI cannot validate the claim, and
   `script/blueprint-check` fails. An unvalidatable claim is worse than none.

## The matrix

| Feature                                                                                    | Requires     | Source                 |
| ------------------------------------------------------------------------------------------ | ------------ | ---------------------- |
| Blueprints, `input:`, `!input`, selectors                                                  | long-stable  | —                      |
| `homeassistant.min_version` itself                                                         | 2022.4.0     | schema docs            |
| `script` domain blueprints                                                                 | 2024.4.0     | 2024.4 release notes   |
| Input `sections` (grouping, `collapsed:`, `icon:`)                                         | 2024.6.0     | 2024.6 release notes   |
| In-item `action:` key replacing `service:`                                                 | 2024.8.0     | 2024.8 release notes   |
| Plural `triggers:`/`conditions:`/`actions:` with in-item `trigger:`/`condition:`/`action:` | 2024.10.0    | 2024.10 release notes  |
| `color_temp` selector in Kelvin only (mireds removed)                                      | 2026.3.0     | 2026.3 breaking change |
| **Purpose-specific triggers and conditions** with `target:` / `options:`                   | **2026.7.0** | 2026.7 release notes   |
| `automation_behavior` and `numeric_threshold` selectors                                    | 2026.7.0     | ships with the above   |
| `template` domain blueprints                                                               | verify       | see below              |
| `label` / `floor` selectors                                                                | verify       | see below              |

**Rows marked "verify"** were not confirmed to a specific release while writing this file —
labels and floors themselves arrived in 2024.4, and template blueprints somewhere in the
2024.x line, but neither release note names the selector or the blueprint domain. Do not
copy a number into a blueprint from here. Confirm against the feature's documentation page
before declaring a floor below 2024.10.0 for either, and replace the row once you know.

For anything not listed, check the feature's documentation page — Home Assistant notes the
introducing release — and confirm against the pinned venv before relying on it.

## Current baseline in this collection

The existing blueprints target **2024.10.0**: modern trigger/action syntax, no input
sections, no purpose-specific triggers.

**New blueprints should use purpose-specific triggers and conditions** and therefore declare
`min_version: 2026.7.0`. They give users area/floor/label targeting instead of enumerated
entity lists, which is the difference between a blueprint that scales with a home and one
that has to be reconfigured every time a sensor is added.

Say so in the commit message when a new blueprint sets a 2026.7.0 floor, so the trade-off is
on the record rather than an accident.

**Do not retrofit existing blueprints.** Converting `motion_light.yaml` from a `state`
trigger to `motion.detected` would raise its floor from 2024.10.0 to 2026.7.0 and cut off
every user below that — a breaking change for a cosmetic gain. If a converted variant is
genuinely wanted, ship it as a new blueprint alongside the old one.

## Verifying against the pinned Home Assistant

The installed venv is the source of truth, not the documentation:

```bash
# Which HA is actually installed
.venv/bin/python -c "import homeassistant.const as c; print(c.__version__)"

# Is a selector available?
.venv/bin/python -c "from homeassistant.helpers import selector; print(sorted(selector.SELECTORS))"

# Purpose-specific trigger/condition catalogue — see triggers-conditions.md
```

The fastest end-to-end check is still a throwaway blueprint plus `script/blueprint-check`,
followed by a runtime test. Schema validation proves it imports; only a runtime test proves
it does anything.

## Reference

- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/)
- [Home Assistant release notes](https://www.home-assistant.io/blog/categories/release-notes/)
- Version pinning mechanics: `docs/development/ARCHITECTURE.md`
