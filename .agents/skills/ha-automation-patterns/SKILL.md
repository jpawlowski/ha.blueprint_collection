---
name: ha-automation-patterns
description: >
  Home Assistant automation building blocks — the full catalogue of native
  triggers, conditions, wait actions, automation modes, variables, repeat and
  choose forms, and trigger IDs. Vendored from an actively maintained upstream
  skill and framed for blueprint authoring.

  TRIGGER THIS SKILL WHEN:
  - Choosing or configuring any trigger or condition in a blueprint body
  - You need the exact YAML for a trigger/condition type you do not use often
  - Working with wait_for_trigger, delay, repeat, choose, if/then, or parallel
  - Using trigger IDs, response variables, continue_on_error, or stop
  - Checking whether a trigger/condition was renamed or removed in a recent release

  SYMPTOMS THAT MEAN YOU SHOULD HAVE READ THIS:
  - Agent invents trigger YAML instead of looking up the documented shape
  - Agent uses a trigger or condition key removed in 2026.5 or renamed in 2026.7
  - Agent relies on a `for:` duration surviving a restart
  - Agent references a variable declared later in the same variables block
license: MIT
---

# Home Assistant Automation Patterns

The reference is [`vendor/automation-patterns.md`](vendor/automation-patterns.md) — the
catalogue of Home Assistant automation building blocks. Read it whenever you need the exact
shape of a trigger, condition, wait, mode, or control-flow construct.

It is **vendored verbatim** from
[homeassistant-ai/skills](https://github.com/homeassistant-ai/skills) (MIT, see
[`vendor/LICENSE`](vendor/LICENSE)) and pinned to a specific commit in
`.github/skills-manifest.txt`. That upstream tracks Home Assistant release changes quickly —
which is exactly why this collection does not maintain the material itself.

**Never edit anything under `vendor/`.** `script/skills-sync --check` fails on any local
change, and CI runs it on every pull request. Corrections belong upstream; local commentary
belongs in this file.

## Read this before you touch that

| Your change touches…                                                       | Read                                                             |
| -------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Any trigger or condition — which one, and its exact YAML                   | [`vendor/automation-patterns.md`](vendor/automation-patterns.md) |
| The same, but specifically inside a blueprint (`!input`, `target:` inputs) | **ha-blueprint-authoring** → `references/triggers-conditions.md` |
| Jinja anywhere in a blueprint                                              | **ha-blueprint-authoring** → `references/templating.md`          |
| Which Home Assistant version a construct needs                             | **ha-blueprint-authoring** → `references/ha-version-matrix.md`   |

The two overlap deliberately. This skill is the **broad catalogue**; the authoring skill is
the **blueprint-specific subset**, verified against the Home Assistant pinned in this
repository. Where they disagree, the authoring skill wins — it was checked against the
installed version, the vendored file was not.

## Overrides — where the vendored file does not apply here

The upstream skill is written for agents managing a **live Home Assistant instance** through
its API. This repository authors **blueprint YAML files** that other people import. Two
consequences, and they matter:

**1. Ignore every instruction to use the config API or the UI instead of YAML.**

The vendored file says, at the end of its purpose-specific triggers section:

> As with everything in this file, create and update automations through the config API —
> the YAML shows the config shape, not a file to hand-edit.

That is correct advice for its original audience and wrong here. In this repository the YAML
**is** the deliverable. Read the file for the config shapes it documents; disregard the
delivery mechanism it assumes. The same applies to any similar statement upstream adds later.

**2. Everything is a blueprint, so `!input` rules apply on top.**

The vendored file is mostly blueprint-aware — it covers `!input` in `trigger_variables:` and
`enabled:` correctly. But it does not enforce the collection's rules: typed selectors,
no hardcoded entities, `entity_id` over `device_id`, honest `min_version`. Those come from
**ha-blueprint-authoring**, and they are not optional.

## What it is especially good for

Material this collection deliberately does not duplicate:

- **The full generic trigger and condition catalogue** with working YAML for each type
- **Release churn** — presence/person triggers removed in 2026.5, native zone triggers in
  2026.6, the 2026.7 purpose-specific defaults and key renames
- **`for:` durations reset on restart and on `unavailable`**, with a timestamp-attribute
  workaround
- **Variables render in key order**, one at a time — a later key is undefined in an earlier
  one
- **`trigger.event.data` raises `UndefinedError`** when a non-event trigger fires the same
  automation, and the guard for it
- Wait actions, automation modes and `max_exceeded`, `continue_on_error`, `stop`, response
  variables, repeat forms, `if/then` vs `choose`, `parallel`, trigger IDs

## Updating

```bash
script/skills-sync --check     # do the vendored files still match the pin?
script/skills-sync             # restore the pinned state
script/skills-sync --update    # move the pin to the latest upstream, for review
```

A scheduled workflow runs `--update` and opens a pull request. When reviewing it, check the
diff for new config-API framing and extend the Overrides section above if upstream added any.

## Attribution

`vendor/automation-patterns.md` © the upstream authors, MIT licensed. Source:
<https://github.com/homeassistant-ai/skills>. The full licence text is in
[`vendor/LICENSE`](vendor/LICENSE).
