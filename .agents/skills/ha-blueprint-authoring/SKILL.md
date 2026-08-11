---
name: ha-blueprint-authoring
description: >
  Authoring, changing, and reviewing Home Assistant blueprints (automation,
  script, and template domains) in this collection.

  TRIGGER THIS SKILL WHEN:
  - Creating a new blueprint or editing any file under blueprints/
  - Choosing a selector, designing inputs, or grouping inputs into sections
  - Picking triggers/conditions/actions, or an automation mode
  - Writing Jinja in a blueprint, or using !input inside a template
  - Deciding homeassistant.min_version, or whether a change is breaking
  - Reviewing a blueprint before commit, or debugging one in a live HA instance
  - script/blueprint-check fails and the error is not self-explanatory

  SYMPTOMS THAT MEAN YOU SHOULD HAVE READ THIS:
  - Agent writes a free-text selector where a typed selector exists
  - Agent puts !input inside a Jinja expression, or state reads in trigger_variables
  - Agent uses device_id, hardcodes an entity, or uses legacy platform:/service: keys
  - Agent renames an input without flagging it as a breaking change
  - Agent hand-builds a state trigger where a purpose-specific trigger exists
license: MIT
---

# Home Assistant Blueprint Authoring

A blueprint in this repository is a **shareable YAML file with a `blueprint:` block
and `!input` placeholders** that users import into their own Home Assistant. It is
not the repository template this project was generated from.

The mechanical rules are enforced by `script/blueprint-check`. This skill covers the
judgement calls it cannot make, and the facts it cannot teach you.

## Read this before you touch that

| Your change touches…                                                               | Read first                                                                          |
| ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Choosing or configuring a selector; input filters, defaults, sections              | [references/selectors.md](references/selectors.md)                                  |
| Any trigger, condition, or action — especially picking between them                | [references/triggers-conditions.md](references/triggers-conditions.md)              |
| Jinja, `!input` in templates, `variables:`, `trigger_variables:`, availability     | [references/templating.md](references/templating.md)                                |
| A domain-specific body: `script` `fields:`, `template` entity shapes, `automation` | [references/domains.md](references/domains.md)                                      |
| Setting or raising `homeassistant.min_version`, or adopting a newer HA feature     | [references/ha-version-matrix.md](references/ha-version-matrix.md)                  |
| Anything that "should work" but doesn't; a bug you are about to fix                | [references/pitfalls.md](references/pitfalls.md)                                    |
| Testing behaviour against a running HA: traces, logs, reload semantics             | [references/debugging.md](references/debugging.md)                                  |
| A blueprint that has grown past ~20 inputs and needs its own memory file           | [references/\_blueprint-notes.template.md](references/_blueprint-notes.template.md) |

If a change lands in one of these areas and you skipped the file, assume the
"obvious" fix reintroduces a documented pitfall. That is how most entries in
`pitfalls.md` came to exist.

Related skills:

- **ha-automation-patterns** — the broad catalogue of Home Assistant triggers,
  conditions, waits, modes, and control flow. Use it when you need the exact YAML for
  a construct; this skill covers the blueprint-specific subset.
- **ha-blueprint-testing** — runtime tests.
- **ha-blueprint-release** — publishing, versioning, release notes.

## Is this a blueprint at all?

Not everything should be. A blueprint costs an input surface, a compatibility promise,
and a support burden.

| Signal                                                          | Blueprint?                                                          |
| --------------------------------------------------------------- | ------------------------------------------------------------------- |
| The same logic is wanted for several sensors, rooms, or devices | **Yes** — parameterise the varying parts as inputs                  |
| It is meant to be shared or published                           | **Yes** — that is what `source_url` and importing exist for         |
| One specific automation for one specific set of entities        | **No** — write a plain automation                                   |
| The logic differs meaningfully per instance                     | **No** — a blueprint needing many either/or flags is two blueprints |

In this collection the answer is usually yes, because publishing is the point. But a
"blueprint" whose inputs mostly switch behaviour on and off is a sign the concern was not
split.

## Non-negotiables

These hold for every blueprint in this collection. Everything else is judgement.

1. **Every configurable value is an `input` with a typed `selector`.** Free text where
   a selector exists is a bug — a typo passes validation and fails silently at runtime.
2. **Never hardcode an entity, device, or area** in the body. That is what inputs are for.
3. **`entity_id` over `device_id`.** Device references break when users replace hardware.
4. **`!input` never appears inside a Jinja expression.** Bind it to `variables:` first.
5. **Modern syntax only:** plural `triggers:`/`conditions:`/`actions:` with the in-item
   `trigger:`/`condition:`/`action:` keys. Never `platform:`/`service:`.
6. **`source_url` points at this file on `main`.** It is the import URL and the update
   anchor; a wrong one breaks re-import for every user.
7. **`homeassistant.min_version` is honest** — the newest feature you actually use, and
   never above the pinned development HA version.
8. **One concern per blueprint.** A blueprint with a feature-flag input for a second job
   is two blueprints.

## The loop

```bash
# 1. Write blueprints/<domain>/<author>/<snake_case_name>.yaml
script/blueprint-check     # HA's own BLUEPRINT_SCHEMA + repo rules
script/yaml-check          # yamllint

# 2. Try it against a real instance (see references/debugging.md)
./script/develop           # then create an automation from it in the UI

# 3. Runtime test — required, one per blueprint (skill: ha-blueprint-testing)
script/test

# 4. Before committing
script/check
```

`script/blueprint-check` runs Home Assistant's **actual** `BLUEPRINT_SCHEMA` from the
pinned venv. If it passes, the file imports cleanly for users on that version. Do not
write your own `hass`/`pytest`/`pip` invocations — the scripts handle venv, sync, ports,
and cleanup.

When validation fails: run `script/lint` first (it auto-fixes formatting and reports the
rest), then fix manually. If the same error survives three attempts, stop and explain
what you tried instead of looping.

## Metadata contract

```yaml
blueprint:
  name: Motion-activated light # short, imperative, user-facing
  description: >-
    What it does, what it needs, and what is surprising about it.
    Markdown is rendered in the import dialog.
  domain: automation # MUST match the folder it lives in
  author: Blueprint Collection
  source_url: https://github.com/<owner>/<repo>/blob/main/blueprints/automation/<author>/motion_light.yaml
  homeassistant:
    min_version: 2026.7.0 # all three parts required
  input: {} # see references/selectors.md
```

Path is `blueprints/<domain>/<author>/<name>.yaml`. The extension must be
`.yaml` — Home Assistant's folder scan is `glob("**/*.yaml")` and silently ignores `.yml`.

**The description is the only documentation most users read.** Cover, in order: what it
does (one plain sentence), what it needs (entity types, integrations, helpers), and the
caveats — behaviour on HA restart, on rapid re-triggering, when an entity is unavailable.
Skip implementation detail; nobody cares that you use `wait_for_trigger`.

## Building blocks: purpose-specific first

Since HA **2026.7**, purpose-specific triggers and conditions are the default building
blocks — `motion.detected`, `battery.became_low`, `cover.shutter_closed` — and they take
a `target:` that can be an entity, device, area, floor, or label.

```yaml
triggers:
  - trigger: motion.detected
    target: !input motion_target
    options:
      behavior: each
```

Prefer them over hand-built `state`/`numeric_state` triggers: the user picks "motion in
the office" instead of enumerating sensors, and the automation follows area membership as
devices come and go. Full syntax, the `behavior:` values, the domain list, and the cases
where a generic trigger is still correct: [references/triggers-conditions.md](references/triggers-conditions.md).

**The cost, and it is real:** this requires `homeassistant.min_version: 2026.7.0`, which
locks out every user on an older Home Assistant. For a published collection that is a
deliberate trade-off — decide it per blueprint, and state the decision in the commit
message. Raising `min_version` on an _existing_ blueprint is a breaking change.

## Choosing a mode

| Mode       | On re-trigger while running    | Typical use                              |
| ---------- | ------------------------------ | ---------------------------------------- |
| `single`   | Ignore (warns in the log)      | Default; runs that must not overlap      |
| `restart`  | Cancel and start over          | Motion/presence timers — the common case |
| `queued`   | Run after the current finishes | Ordered processing                       |
| `parallel` | Run concurrently               | Independent per-entity work              |

Anything with a wait or delay driven by a repeating trigger wants `restart` plus
`max_exceeded: silent`: renewed motion should extend the light's on-time, not log a
warning. Document the reason whenever the choice is not obvious.

## Changing an existing blueprint

Inputs are a public interface. Users have automations configured through them, and they
receive **nothing** until they re-import.

**Breaking — warn the developer first, and use a `BREAKING CHANGE:` commit footer:**

- Renaming or removing an input, or changing its meaning, unit, or selector type
- Changing trigger/action behaviour users depend on
- Raising `homeassistant.min_version`
- Renaming or moving the file (breaks `source_url` and every published import link)

**Safe:** adding an input _with a default_, widening a selector filter, fixing plainly
wrong logic, improving the description.

When you must break something, prefer **adding** a new input with a default over changing
an old one, and keep the old key working where you can.

## When a blueprint outgrows this skill

A blueprint with many inputs, interacting branches, or persisted state accumulates
project knowledge that does not belong in a generic skill: its invariants, its deliberate
asymmetries, its regression history. Copy
[references/\_blueprint-notes.template.md](references/_blueprint-notes.template.md) to
`blueprints/<domain>/<author>/<name>.notes.md`, fill it in, and link it from
the routing table above. Write it the first time you catch yourself re-deriving a
decision — not before.

## Reference

- [Blueprint schema](https://www.home-assistant.io/docs/blueprint/schema/)
- [Selectors](https://www.home-assistant.io/docs/blueprint/selectors/)
- [Triggers](https://www.home-assistant.io/triggers/) · [Conditions](https://www.home-assistant.io/conditions/) · [Actions](https://www.home-assistant.io/actions/)
- [Automation YAML](https://www.home-assistant.io/docs/automation/yaml/) · [Script syntax](https://www.home-assistant.io/docs/scripts/)
- Repository context and validation scripts: [`AGENTS.md`](../../../AGENTS.md)
