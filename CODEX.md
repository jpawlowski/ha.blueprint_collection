# ChatGPT Codex Instructions

ChatGPT Codex reads project instructions from [`AGENTS.md`](AGENTS.md). Read that file completely before starting any work.

`AGENTS.md` contains the shared guidance for this collection of Home Assistant blueprints, including repository layout, authoring rules, validation commands, runtime testing patterns, and the breaking-change policy for blueprint inputs.

## Quick Reference

- **Title:** Blueprint Collection
- **Author folder:** `ha_blueprint_author`
- **Blueprints:** `blueprints/{automation,script,template}/ha_blueprint_author/`
- **Validate:** `script/check` (type-check + lint + spell + blueprint-check)
- **Test:** `script/test`
- **Run HA:** `./script/develop`

## Agent Skills

Deep, task-scoped guidance lives in [`.agents/skills/`](.agents/skills/README.md) — plain Markdown, shared by all agents. Read the matching skill before starting work in its area:

- [`ha-blueprint-authoring`](.agents/skills/ha-blueprint-authoring/SKILL.md) — selectors, triggers and conditions, templating, per-domain bodies, `min_version`, pitfalls, live debugging
- [`ha-automation-patterns`](.agents/skills/ha-automation-patterns/SKILL.md) — the broad catalogue of Home Assistant triggers, conditions, waits, modes, and control flow (vendored verbatim from upstream; never edit `vendor/`)
- [`ha-blueprint-testing`](.agents/skills/ha-blueprint-testing/SKILL.md) — runtime test patterns and troubleshooting
- [`ha-blueprint-release`](.agents/skills/ha-blueprint-release/SKILL.md) — versioning, release notes, import links, publication

Each skill starts with a routing table that tells you which `references/` file to open for your specific change.

## Path-Specific Instructions

Additional domain-specific guidance is available in `.github/instructions/*.instructions.md`. Review the instruction file whose `applyTo` pattern matches each file you modify.
