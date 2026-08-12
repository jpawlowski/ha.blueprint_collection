---
agent: "agent"
tools: ["search/codebase", "edit", "runCommands"]
description: "Create a new Home Assistant blueprint with tests and import link"
---

# Add Blueprint

Your goal is to add a new Home Assistant blueprint (automation, script, or template) to this collection.

If not provided, ask for:

1. **Domain** - automation, script, or template
2. **Purpose** - what the blueprint should do, in one or two sentences
3. **Configurable parts** - which entities/values the user should choose

## Steps

1. **Read the rules** in `.agents/instructions/collection.ha_blueprints.instructions.md` and study an existing
   blueprint of the same domain under `blueprints/<domain>/`
2. **Create the file** at `blueprints/<domain>/<author>/<snake_case_name>.yaml` with complete metadata
   (`name`, `description`, `domain`, `author`, `source_url`, `homeassistant.min_version`)
3. **Design the inputs**: typed selectors with filters, descriptions, sensible defaults; no free-text where a
   selector exists; no hardcoded entities in the logic
4. **Validate**: `script/blueprint-check` and `script/yaml-check` must pass
5. **Write a runtime test** in `tests/test_<domain>_<name>.py` following the patterns in existing tests
   (install_blueprint fixture, `async_mock_service`, freezer time-advance for delays)
6. **Run** `script/test` until green
7. **Add the import link** for the new blueprint to `README.md` (My Home Assistant import badge pattern used there)

## Quality Bar

- The blueprint must work with only its required inputs configured (defaults cover the rest)
- The description must explain what it does, what it needs, and any caveats
- The test must cover the happy path through core interfaces (`hass.states`, `hass.services`)
