---
name: ha-blueprint-review
description: >-
  Perform a structured quality review of the blueprints in this collection, either as a full audit or scoped to a
  diff. Use when asked to "review the blueprint", "audit the collection", "is this ready to publish", "review my
  changes", "what's missing before release", or before opening a pull request that touches blueprints/. Covers
  running the automated gates first, then auditing the input interface, trigger and condition correctness,
  runtime behaviour, templating safety, the user-facing text, and distribution metadata — and reporting findings
  ranked by severity with concrete fixes. SYMPTOMS — load this if you are about to: report a review that only
  restates validator output; claim real-device testing that did not happen; give a finding without a file path
  and a fix; or judge a blueprint without running `script/blueprint-check` and the test suite first.
license: MIT
---

# Review a blueprint

A review that only restates the validator is worthless. Run the machines first, then spend your attention on what
they cannot see: whether the inputs are an interface someone can live with, whether the automation behaves under
restart and failure, and whether a user reading the import dialog would understand what they are getting.

**Read [`ha-blueprint-authoring`](../ha-blueprint-authoring/SKILL.md) first** if you have not already — this skill
audits against the rules it states, and its
[`references/pitfalls.md`](../ha-blueprint-authoring/references/pitfalls.md) is the symptom catalogue behind most
sections below.

## 0. Scope the review

Ask, or infer from the request:

- **Full audit** of the collection, or **diff review** of the current branch?
- Is the blueprint already published? Everything in section 6 changes weight if users have imported it.

For a diff review: `git diff main...HEAD --stat`, then read the changed files in full — not just the hunks. A
blueprint is small enough that reading it whole always pays.

## 1. Automated gates (always first)

```bash
script/blueprint-check   # Home Assistant's own BLUEPRINT_SCHEMA + this repository's rules
script/test              # the runtime tests
script/lint              # formats, then reports what it could not fix
script/type-check        # pyright over the test suite
```

Anything these report is a finding, not something to fix silently mid-review — but note that `script/lint`
auto-heals formatting, so only its **remaining** output counts.

`script/blueprint-check` runs the same code path Home Assistant runs on import, so a pass means the file will
import. It says nothing about whether the automation does the right thing.

## 2. The input interface

This is the part that is expensive to get wrong, because users receive changes only on re-import and keep the
values they already chose.

- Every input has a `name` and a `description` that make sense **without** the YAML next to them.
- No free-text `text:` selector where a typed selector exists. This is the single most common finding.
- `target:` where the user should be able to pick an area or label; `entity:` only where one specific entity is
  genuinely meant.
- Every `number:` selector has a unit, a range and a step.
- Every `select:` lists its complete option set, and nothing in the body assumes an option that is not there.
- Optional inputs have a `default:` that reproduces the previous behaviour exactly.
- Inputs are grouped into sections once there are more than a handful — and **no required input hides inside a
  collapsed section**. The schema permits it; the user never sees the field (pitfall G).
- No input is declared and unused, and none is used but undeclared. `script/blueprint-check` catches both.

## 3. Triggers, conditions and actions

- A purpose-specific trigger is used where one exists, rather than a hand-built state trigger. If the resulting
  `min_version` is not acceptable, that is a decision to state, not to skip silently.
- `behavior:` is correct for the intent: trigger `each` / `all` / `first`, condition `any` / `all`. The defaults
  differ between the two, and `any` on a condition means "one sensor is enough" (pitfall N).
- Transitions guard against `unavailable` and `unknown` — `to: "on"` without a `from:` fires when a sensor comes
  back from being unreachable (pitfall K).
- `for:` on a flapping sensor is understood: the timer restarts on every intermediate change (pitfall L).
- A `target` holding several entities is not treated as one thing in conditions (pitfall M).
- No `device_id` anywhere. It breaks the moment a user replaces hardware (pitfall O).
- No legacy `platform:` / `service:` keys (pitfall H).
- `mode:` matches the intent, and `max_exceeded: silent` is set only where re-triggering is genuinely normal.

## 4. Templating

- No `!input` inside a Jinja expression — it is a YAML tag, resolved before Jinja runs (pitfall B).
- No state reads in `trigger_variables:` (pitfall C).
- Every optional entity reference survives the input being unset (pitfall E).
- Booleans coming out of templates are treated as strings where they are (pitfall D).
- For a `script` blueprint: no `field:` default is assumed to exist as a variable — it is not injected, so
  `| int(3)` on an unset field raises and `| default(3) | int` does not (pitfall W).

## 5. Runtime behaviour

The questions the schema cannot answer, and the reason the runtime tests exist:

- What happens on a Home Assistant restart mid-run? A pending `delay:` or `wait_for_trigger` is lost. If that
  matters, the description says so (pitfall J).
- Does a renewed trigger restart the wait, or does the first run win? (pitfall I)
- Is there a manual-override path — someone switched the light by hand?
- Is there a test covering the happy path, and one for every bug ever fixed here?

## 6. Distribution and user-facing text

- `blueprint.description` says what it does, what it needs, and what is surprising about it. A description that
  only restates the name is a finding (pitfall V).
- `homeassistant.min_version` is present, has all three parts, and is not higher than anything the blueprint
  actually needs.
- `source_url` matches the repository and the real path. A wrong one breaks re-import for every user
  (pitfall S) — `script/blueprint-check` verifies this.
- The file name has not changed. It is the import URL.
- The domain folder matches `blueprint.domain`, and the extension is `.yaml` (pitfall A).
- If anything in section 2 changed on a published blueprint, it is a **breaking change**: it needs a
  `BREAKING CHANGE:` commit footer and a release note telling users to re-import
  ([`ha-blueprint-release`](../ha-blueprint-release/SKILL.md)).

## Report format

Rank by severity and be specific. A finding without a file path and a fix is noise.

```markdown
## Summary

<2–3 sentences: overall state, biggest risk, and whether it is publishable as-is.>

## Critical — must fix before release

### 1. <Title>

- **Where:** `blueprints/automation/<author>/motion_light.yaml:42`
- **Problem:** <what is wrong and what it breaks for a user>
- **Fix:** <concrete change>

## Warnings — should fix

## Suggestions — nice to have

## Breaking changes

<None, or: which inputs changed and what users must redo after re-importing.>

## Verified

<What you actually ran, and what you could not verify.>
```

Be honest in the last section. Do not describe checks you did not run, and do not imply that a blueprint was
tested against real devices when it was not — that is an explicit rule of this project's
[`AI_POLICY.md`](../../../AI_POLICY.md). "Passed `script/test`" and "works in a real home" are different claims,
and only the first one is yours to make.

## After the review

Report findings; do not silently fix them unless the developer asked for fixes. If they did, fix in severity
order, run `script/blueprint-check && script/test` after each group, and state what you changed.
