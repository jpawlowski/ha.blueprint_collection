---
agent: "agent"
tools: ["search/codebase", "runCommands"]
description: "Review a blueprint for schema, UX, and breaking-change risks"
---

# Review Blueprint

Your goal is to review one or all blueprints in this collection for quality, correctness, and user experience.

If not provided, ask which blueprint to review (or review all under `blueprints/`).

## Checklist

**Metadata:**

- [ ] `name` short and user-facing; `description` explains purpose, requirements, caveats
- [ ] `source_url` points at this file on `main`; `author` set
- [ ] `homeassistant.min_version` matches the syntax used (e.g. `triggers:`/`actions:` → 2024.10,
      input sections → 2024.6) and does not exceed `.ha-version`

**Inputs:**

- [ ] Every configurable value is an input with a typed selector (with `filter:` where possible)
- [ ] Defaults provided wherever sensible; blueprint works with minimal configuration
- [ ] No unused inputs, no free-text where a selector exists
- [ ] Inputs used in Jinja templates go through `variables:` first

**Logic:**

- [ ] Modern syntax only (`triggers:`/`actions:` with `trigger:`/`action:` keys)
- [ ] `entity_id` references, never `device_id`; nothing hardcoded
- [ ] `mode` is deliberate and appropriate for re-trigger behavior
- [ ] Edge cases considered: entity unavailable, restart mid-run, rapid re-trigger

**Verification:**

- [ ] `script/blueprint-check` passes
- [ ] A runtime test exists and covers the happy path; `script/test` passes

**Report format:** One finding per line with file, severity (error/warning/suggestion), and a concrete fix.
Do not change files unless asked.
