---
name: change-planning
description: >-
  Plan a large change to this blueprint collection before writing YAML, or record an architectural decision.
  Use when asked to "create a plan", "plan this feature", "how should we approach", "propose an architecture",
  "write an ADR", "document this decision", "should this be one blueprint or two", or whenever a change would
  touch more than about ten files or restructure a blueprint's inputs. Covers when a plan is mandatory, the
  phased plan format, where plans live, when a decision is worth recording, and the DECISIONS.md entry format
  used by this project. SYMPTOMS — load this if you are about to: start a refactor spanning more than ten files
  without confirmation; write a plan whose phases name no files; write one in prose nobody will finish reading;
  create a planning markdown file outside `.agents/scratch/`; or make a hard-to-reverse choice about inputs or
  file names without recording why.
license: MIT
---

# Plan changes and record decisions

## When a plan is required

| Situation                                         | What to do                                             |
| ------------------------------------------------- | ------------------------------------------------------ |
| A single blueprint or fix, up to ~8 files         | Just implement it completely; no plan needed           |
| Several independent blueprints                    | Implement one at a time, suggest a commit between each |
| >10 files, or restructuring a published blueprint | **Write a plan and get explicit confirmation first**   |
| A choice with long-term consequences              | Write the plan _and_ record the decision               |

Do not start a large refactor because it seems obviously right. The developer decides scope.

A plan can only be as good as the requirements under it. If you cannot state the goal back in one sentence, or
the phases would encode a guess, run [`requirements-interview`](../requirements-interview/SKILL.md) first — its
brief is the input this plan needs.

## Writing the plan

Plans are working documents, not deliverables. Put them in `.agents/scratch/` — that directory is gitignored and
exists for exactly this. Do not create markdown files elsewhere in the repository without being asked.

Structure:

```markdown
# Plan: <what and why in one line>

## Goal

<One line: what changes for the user when this is done.>

## Current state

<Bullets. What exists today, with file references, and what specifically is in the way.>

## Approach

<Bullets. The chosen approach, and what you deliberately did not choose.>

## Phases

### Phase 1 — <name>

- **Files:** `blueprints/automation/<author>/motion_light.yaml`, `tests/test_automation_motion_light.py`, …
- **Changes:** <specific edits>
- **Verification:** `script/blueprint-check`, `script/test -k motion`, and <what to check in the UI>
- **Independently shippable:** yes / no

### Phase 2 — …

## Breaking changes

<None, or: which inputs change and what users must redo after re-importing.>

## Risks and open questions

<Each one: the question, who answers it, and what it blocks. "None" is a valid section.>
```

**Write it to be read, not to be complete.** A plan over ~10 files exists to be confirmed before
implementation — and a plan nobody finishes reading gets confirmed anyway, which turns that gate into a
formality and hands the agent a mandate the developer never actually gave.

- Notes, not prose. Fragments beat sentences; drop the grammar that carries no information.
- One screen per phase. If a phase needs more, it is two phases.
- Do not restate the request, the repository, or the brief. When a
  [`requirements-interview`](../requirements-interview/SKILL.md) brief exists, link it — its **Decided** and
  **Open** lists do not get copied in.
- Concision is about wording, never about scope: what you are not doing still has to be written down.

Rules that make a plan useful:

- Every phase names actual files. "Improve the motion blueprint" is not a phase.
- Every phase ends in a verifiable state — `script/check` passes and `script/test` is green.
- Order phases so the risky, uncertain part comes early. Discovering the approach is wrong in phase 1 is cheap;
  in phase 5 it is not.
- Keep phases independently reviewable, ideally one commit each.
- **Name the seams**, once, under Approach: the shapes one phase fixes and the later ones are then stuck with.

### The seams, in this repository

A blueprint has an unusually hard public surface, because users receive changes only when they **re-import**,
and their existing automations keep the values they configured. Four things are cheap to change while they are a
line in a plan and expensive afterwards:

| Seam                            | Why it is a seam                                                                    |
| ------------------------------- | ----------------------------------------------------------------------------------- |
| **Input names**                 | The user's stored configuration is keyed by them. A rename silently drops the value |
| **Selector types**              | Changing one changes what the stored value _means_, not just how it is picked       |
| **The file name and path**      | It is the import URL (`source_url`). Renaming breaks every published link           |
| **`homeassistant.min_version`** | Raising it makes the blueprint refuse to load on instances that had it working      |

Together with what you are not doing, this is the part the developer should actually check.

- Say what you are **not** doing. Scope creep in a plan is scope creep in the implementation.

Present the plan, wait for confirmation, then implement phase by phase. Report deviations from the plan as they
happen rather than at the end.

## Recording a decision

Record a decision in [`docs/development/DECISIONS.md`](../../../docs/development/DECISIONS.md) when it is
expensive to reverse and the reasoning would otherwise be lost:

- One blueprint with a mode switch, or two separate blueprints.
- Splitting an input, merging two, or replacing a selector with a different type.
- Whether something belongs in the `automation`, `script`, or `template` domain.
- Requiring a Home Assistant version for a feature, instead of writing the compatible-but-uglier form.
- Anything you had to argue yourself into.

Do **not** record: routine authoring choices, anything the YAML already makes obvious, a restatement of a Home
Assistant convention, or a breaking change made before `1.0.0` — those are expected at that stage, and their
record is the `BREAKING CHANGE:` footer in the commit
([`ha-blueprint-release`](../ha-blueprint-release/SKILL.md)).

The bar is all three of: hard to reverse, a genuine trade-off rather than the one sensible option, and
surprising to a reader who was not there. **Most sessions produce no entry, and that is the normal outcome** — a
log padded with decisions that made themselves is one nobody reads when a real one is in it.

### Entry format

Append to the decision log, matching the entries already there:

```markdown
### <Decision in imperative form, e.g. "Ship one blueprint with an area mode rather than two">

**Date:** YYYY-MM-DD

**Context:** <The situation that forced a choice. What constraint made this non-obvious.>

**Decision:** <What was decided, stated plainly.>

**Rationale:**

- <Why this option won>
- <What the alternatives were and why they lost>

**Consequences:**

- <What this now obliges the blueprints to do>
- <What becomes harder, and what we accept as a trade-off>
```

Be honest in **Consequences**. A decision record that lists only benefits is marketing, and it is useless to the
person who has to revisit it in two years.

Keep entries in the "Decision Log" section in chronological order, newest last, separated by `---`. Entries that
were later reversed stay in the log — add a new entry that supersedes them and say so, rather than editing
history.

## Handoff

When a plan spans more than one session, leave the plan file in `.agents/scratch/` with phase checkboxes
updated, so the next session can pick it up without re-deriving the context.

**`.agents/scratch/` is gitignored**, so it survives the next session but not a fresh clone, a second machine, or
a second contributor. Before the work stretches that far, move anything that must outlive it to its real home: a
hard-to-reverse choice into the decision log above, a per-blueprint note into the template at
[`_blueprint-notes.template.md`](../ha-blueprint-authoring/references/_blueprint-notes.template.md), and
everything else into the commit messages of the phases already shipped. What is left in the scratch file should
be losable.
