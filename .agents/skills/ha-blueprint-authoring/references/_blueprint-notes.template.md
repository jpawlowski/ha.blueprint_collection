# Blueprint Notes Template

A template for the memory file of a **single, large** blueprint. Copy the block below to
`blueprints/<domain>/<author>/<name>.notes.md`, fill it in, and add a row to the routing
table in [`../SKILL.md`](../SKILL.md) so agents find it.

## When to create one

Only when the blueprint has outgrown what a generic skill can carry:

- Many inputs with interacting effects, or persisted state between runs
- Branches whose order or conditions matter and are not obvious from reading them
- A regression history — the same bug class returning in new places
- Deliberate asymmetries that look like bugs and invite "cleanup"

**Write it the first time you catch yourself re-deriving a decision, not before.** A notes
file for a 60-line blueprint is overhead that goes stale and then misleads.

## What does not belong in it

- Anything true of blueprints in general → the skill's `references/`
- Repository-wide architecture decisions → `docs/development/DECISIONS.md`
- What the code plainly says → nothing; do not narrate the implementation
- Anything already in the blueprint's user-facing `description:`

Keep it one file. If it needs sections split across files, the blueprint probably needs
splitting instead.

## The template

Delete any section that stays empty — an empty heading is worse than no heading.

```markdown
# `<name>.yaml` — Implementation Notes

Read before changing this blueprint.

## What it does

Two or three sentences of the mental model a maintainer needs. Not the user-facing
description; that lives in the blueprint's `description:` field.

## Invariants

Rules that must hold. Violating one is a bug even when validation passes and tests are
green. One line each; the rationale goes in the next section if it needs one.

1.
2.

## Deliberate asymmetries

Things that look inconsistent and are not. Each entry: what looks wrong, why it is that
way, and what breaks if someone "harmonises" it.

### Name of the thing that looks wrong

**Looks like:**
**Actually:**
**Do not:**

## Input contract

Only inputs with non-obvious semantics: units, interactions with other inputs, what an
empty value means. Do not restate the selector — that is in the YAML.

| Input | Non-obvious behaviour |
| ----- | --------------------- |
|       |                       |

## Regression history

Bugs specific to this blueprint. Generic blueprint pitfalls belong in the skill's
`references/pitfalls.md` instead — this section is for what only bites here.

### Short symptom

**Symptom:**
**Cause:**
**Fix:**
**Rule:**

## Test coverage

Which behaviours the tests pin, and — more usefully — which they do not. A future agent
needs to know where it is walking without a net.

- Covered:
- Not covered:

## Open questions

Known-unresolved things, so the next session does not rediscover them. Delete entries as
they are answered.
```
