# Claude Code Instructions

This repository uses a shared AI agent instruction system. **All instructions are in [`AGENTS.md`](AGENTS.md).**

Read `AGENTS.md` completely before starting any work. It contains:

- Project overview and terminology (what "blueprint" means here)
- Repository layout and blueprint authoring rules
- Required blueprint metadata, inputs, and selector guidance
- Validation commands and quality expectations
- Runtime testing patterns for blueprints
- Breaking change policy for blueprint inputs
- Workflow rules (scope management, documentation, releases)

## Quick Reference

- **Title:** Blueprint Collection
- **Author folder:** `ha_blueprint_author`
- **Blueprints:** `blueprints/{automation,script,template}/ha_blueprint_author/`
- **Validate:** `script/check` (type-check + lint + spell + blueprint-check)
- **Test:** `script/test`
- **Run HA:** `./script/develop`

## Agent Skills

Deep, task-scoped guidance lives in [`.agents/skills/`](.agents/skills/README.md), surfaced to
Claude Code through the `.claude/skills` symlink. Read the matching skill before starting work
in its area:

- `ha-blueprint-authoring` — selectors, triggers and conditions, templating, per-domain
  bodies, `min_version`, pitfalls, live debugging
- `ha-automation-patterns` — the broad catalogue of Home Assistant triggers, conditions,
  waits, modes, and control flow (vendored verbatim from upstream; never edit `vendor/`)
- `ha-blueprint-testing` — runtime test patterns and troubleshooting
- `ha-blueprint-release` — versioning, release notes, import links, publication

Each skill starts with a "read this before you touch that" routing table pointing at the
`references/` file for your specific change.

## Path-Specific Instructions

Additional domain-specific guidance is available in `.github/instructions/*.instructions.md`.
These files use `applyTo` globs to indicate which files they cover.
Consult the relevant instruction file when working on specific file types:

- `blueprint.ha_blueprints.instructions.md` — Blueprint authoring: schema, inputs, selectors, modes
- `blueprint.tests.instructions.md` — Runtime test patterns for blueprints
- `blueprint.python.instructions.md` — Python style for the test suite
- `blueprint.yaml.instructions.md` — YAML formatting
- `blueprint.json.instructions.md` — JSON formatting
- `blueprint.configuration_yaml.instructions.md` — Dev HA configuration
- `blueprint.shell.instructions.md` — Shell script style
- `blueprint.commit-message.instructions.md` — Conventional Commits format (applies to
  every commit, not to a file glob)
