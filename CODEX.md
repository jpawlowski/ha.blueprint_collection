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

## Path-Specific Instructions

Additional domain-specific guidance is available in `.github/instructions/*.instructions.md`. Review the instruction file whose `applyTo` pattern matches each file you modify.
