# Customization

How to adapt this template to your own collection, and which parts are safe to change.

## Initialization

`./initialize.sh` runs once and replaces the template placeholders throughout the repository:

| Placeholder                          | Becomes                 | Appears in                                                |
| ------------------------------------ | ----------------------- | --------------------------------------------------------- |
| `ha_blueprint_author`                | Your author folder name | `blueprints/*/`, `source_url`s, tests, agent instructions |
| `Blueprint Collection`               | Your collection title   | READMEs, agent instructions, blueprint `author:` fields   |
| `jpawlowski/ha.blueprint_collection` | Your repo slug          | `source_url`s, README links, workflow guards              |

It then deletes itself. Run it before writing your first blueprint — changing `source_url`s afterwards means
re-publishing every import link.

**Choosing an author folder name:** it becomes part of the import path on every user's instance
(`config/blueprints/automation/<author>/`). Use something identifiably yours — your GitHub handle works well.
Snake_case, no spaces.

## Adding blueprints

Put files in `blueprints/<domain>/<author>/`. The three domain folders (`automation`, `script`, `template`) are
fixed — Home Assistant only loads those. See [AUTHORING.md](AUTHORING.md).

Nested subfolders under the author folder work, and Home Assistant mirrors them, but they lengthen the import
path for no real benefit. Keep it flat unless the collection gets large.

## Removing the examples

The three example blueprints and their tests exist to demonstrate the patterns. To start clean:

```bash
rm blueprints/automation/<author>/motion_light.yaml
rm blueprints/script/<author>/flash_light.yaml
rm blueprints/template/<author>/inverted_binary_sensor.yaml
rm tests/test_automation_motion_light.py
rm tests/test_script_flash_light.py
rm tests/test_template_inverted_binary_sensor.py
```

Keep `tests/conftest.py` — the `install_blueprint` fixture is what makes runtime tests possible. Read the test
files before deleting them; they document the waiting patterns that are easy to get wrong.

If you only publish one domain, delete the unused folders. `script/blueprint-check` skips folders that do not
exist.

## Home Assistant version

`HA_VERSION` in `.devcontainer/.env` pins the version used for validation and tests:

```bash
HA_VERSION=2026.8
```

`YYYY.M` means "latest patch of that month". To develop against a different version, either edit that value
(and `requirements_test.txt` — `script/ha-version-sync` enforces the pairing), or override per-machine in
`.devcontainer/.env.local`:

```bash
HA_VERSION=beta      # or latest, or an explicit 2026.9.0
```

`.env.local` is gitignored and exempt from the sync check, which makes it the right place to test against a
Home Assistant beta without touching the repository's pin.

## Script hooks

Extend any script without editing it. Drop a file in `script/hooks/`:

```bash
# script/hooks/develop.pre.sh — sourced before Home Assistant starts
log_info "Seeding demo entities"
```

Naming is `<script-name>.<pre|post>.sh`; nested scripts use their path (`setup/sync-blueprints.post.sh`). Hooks
are _sourced_, so they can read and set variables in the calling script. `script/hooks/` is in
`.templatesyncignore`, so template updates never touch them.

The same mechanism exists for the DevContainer in `.devcontainer/hooks/`.

## Linting and formatting

| File                      | Governs                                   |
| ------------------------- | ----------------------------------------- |
| `.yamllint.yml`           | YAML style (blueprints, workflows)        |
| `pyproject.toml`          | Ruff rules, Pyright, pytest configuration |
| `.markdownlint.json`      | Markdown rules                            |
| `.prettierrc.yml`         | Markdown/YAML formatting                  |
| `.pre-commit-config.yaml` | Which hooks run on commit                 |

The Ruff configuration is inherited from Home Assistant Core's own, minus the integration-specific rules. It is
strict on purpose; loosening it is fine for a collection whose only Python is tests, but leave the import
ordering alone — it keeps `homeassistant` imports grouped predictably.

## CI workflows

| Workflow                            | Does                                                     |
| ----------------------------------- | -------------------------------------------------------- |
| `validate.yml`                      | `blueprint-check` and `test` on push, PR, and nightly    |
| `lint.yml`                          | All linters                                              |
| `ha-version-sync-check.yml`         | Version sources agree                                    |
| `release-please.yml`                | Release PRs from Conventional Commits                    |
| `dependabot-ha-stability-check.yml` | Closes Dependabot PRs that would pin HA to a pre-release |
| `template-sync.yml`                 | Pulls updates from this template                         |
| `copilot-setup-steps.yml`           | Environment for the Copilot coding agent                 |

The nightly `validate.yml` run is worth keeping: it catches the case where a new Home Assistant release changes
the blueprint schema and your blueprints stop validating — before your users find out.

## Template sync

`.templatesyncignore` lists what template updates must never overwrite: your blueprints, tests, README, agent
identity files, and configuration you have customized. Add anything else you want to own outright.

To stop syncing entirely, delete `.github/workflows/template-sync.yml`.

## Chassis sync (collection template only)

> [!NOTE]
> This section applies to the collection **template** repository. `initialize.sh` removes the chassis sync from
> your own repository — you receive these files through the normal template sync above.

The shared development environment (DevContainer, agent runtime, generic scripts, linter configuration) is not
maintained twice. The upstream
[integration blueprint](https://github.com/jpawlowski/hacs.integration_blueprint) is the **leading** repository
for those files; the collection template pulls them in:

```text
hacs.integration_blueprint  ──chassis-sync──▶  ha.blueprint_collection  ──template-sync──▶  your collection
      (leading for the chassis)                  (leading for blueprints)
```

The file list is an explicit **allowlist** in `.github/chassis-manifest.txt` — never a denylist, because a
denylist would silently pull in every new integration-specific file the upstream adds. Adding an entry is a
deliberate statement that the file is generic and identical in both repositories.

```bash
script/chassis-sync --check    # Is anything out of date? (exit 1 if yes)
script/chassis-sync            # Apply upstream changes to the working tree
```

`.github/workflows/chassis-sync.yml` runs the check on every pull request — so a chassis file edited here
instead of upstream fails CI — and opens a pull request weekly when upstream has moved on.

**When a chassis file needs blueprint-specific content:** remove it from the manifest and own it here. That is
the intended escape hatch, not an exception. `.markdownlint-cli2.jsonc` is the existing example — upstream
excludes a HACS directory that does not exist here.

**When an entry disappears upstream** (renamed or deleted), `script/chassis-sync` fails rather than skipping it,
because the alternative is quietly keeping a copy nobody maintains.

## AI agent instructions

Adjust these as your collection develops conventions:

- `AGENTS.md` — the primary reference, read by all agents
- `.github/copilot-instructions.md` — compact version for Copilot
- `.github/instructions/*.instructions.md` — path-scoped rules, applied by `applyTo` glob
- `.github/prompts/*.prompt.md` — reusable prompts

`AGENTS.md`, `CLAUDE.md`, `CODEX.md`, and `copilot-instructions.md` are in `.templatesyncignore` because they
carry your project identity. The path-specific instruction files use generic placeholders and _are_ synced —
move a file out of `.github/instructions/` if you want to own it.

## Home Assistant dev configuration

`config/configuration.yaml` is the only tracked file in `config/`. It loads `automation:`, `script:`,
`template:`, and development-friendly logging. Add helpers or demo entities you want available while testing.

`./script/setup/reset` wipes the instance and restores this file; `--full` also restores it from git.
