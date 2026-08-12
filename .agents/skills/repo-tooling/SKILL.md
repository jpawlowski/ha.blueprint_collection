---
name: repo-tooling
description: >-
  Use this repository's development tooling correctly — the script/ validation and formatting commands, the
  fix-versus-check distinction, the live Home Assistant instance, extending scripts with pre/post hook scripts,
  devcontainer environment variables, and the two sync mechanisms. Use when asked to "run the checks", "fix the
  lint errors", "why is CI failing", "add a hook", "customize the setup", "exclude a file from template sync",
  or when a validation command fails and you need to know which script to reach for. SYMPTOMS — load this if you
  are about to: run `ruff`, `pyright`, `pytest`, or `hass` directly instead of the project script; run a `-check`
  script after a fix script; edit a synced script instead of adding a hook; or edit a file under a `vendor/`
  directory.
license: MIT
---

# Repository tooling

## Rule zero: use the project scripts

Never craft your own `hass`, `pip`, `pytest`, or `ruff` invocation. The scripts activate the right virtual
environment, manage ports and processes, and run hooks. Agents that bypass them break in ways that look like
code bugs.

## Which script to run

Pick the narrowest one that covers what you changed:

| Changed files                          | Run                                   |
| -------------------------------------- | ------------------------------------- |
| `blueprints/**/*.yaml`                 | `script/blueprint-check`              |
| Other `*.yaml` / `*.yml`               | `script/yaml-check`                   |
| `*.py` only                            | `script/python` + `script/type-check` |
| `*.md` only                            | `script/markdown`                     |
| `.agents/**`                           | `script/skills-check`                 |
| `script/` or `.devcontainer/*.sh` only | `script/shell` + `script/shell-check` |
| Multiple types, or unsure              | `script/check`                        |

`script/blueprint-check` is the one that matters most here. It imports Home Assistant's own `BLUEPRINT_SCHEMA`
from the installed virtual environment, so a file that passes it will import cleanly on a user's instance — see
[`ARCHITECTURE.md`](../../../docs/development/ARCHITECTURE.md).

### Fix mode vs. check mode

**Fix-mode scripts auto-heal files _and_ print what they could not fix.** Their output is the complete picture —
there is no need to run the matching `-check` script afterwards.

```bash
# Loop until both exit 0:
script/lint         # formats Python, shell, markdown; checks yaml + skills; reports the rest
script/type-check   # pyright — never auto-fixes, always a manual loop
```

| Fix mode          | Check mode (read-only, for CI)                                                                               |
| ----------------- | ------------------------------------------------------------------------------------------------------------ |
| `script/lint`     | `script/lint-check`                                                                                          |
| `script/python`   | `script/python-check`                                                                                        |
| `script/shell`    | `script/shell-check`                                                                                         |
| `script/markdown` | `script/markdown-check`                                                                                      |
| `script/spell`    | `script/spell-check`                                                                                         |
| —                 | `script/check` (type + lint + spell + blueprints), `script/yaml-check`, `script/skills-check`, `script/test` |

Agents should use fix mode. **`script/check` is the gate to run before saying a task is complete**, and
`script/test` alongside it.

### Other scripts

```bash
script/develop                # start Home Assistant on :8123 against config/
script/test                   # pytest — the runtime blueprint tests
script/blueprint-check        # HA's own validator + this repository's rules
script/import-links           # My Home Assistant import links for every blueprint
script/skills-check           # validate .agents/ (also part of lint / lint-check)
script/skills-sync            # vendored third-party skill files — see below
script/version                # the current collection version
script/ha-version-sync        # align the pinned HA version across config files
script/clean                  # remove caches, logs, build artifacts
script/help                   # list every script with its description
```

### The live instance

`script/develop` starts a full Home Assistant against `config/`. Before starting,
`script/setup/sync-blueprints` mirrors `blueprints/` into `config/blueprints/` using **per-file symlinks**, so
editing a blueprint in the workspace is immediately live — reload the automation, script, or template
integration and the change is in effect. A **new** file needs a `sync-blueprints` run before it is linked.

Debugging a running blueprint — traces, logs, reload semantics — is covered in
[`ha-blueprint-authoring/references/debugging.md`](../ha-blueprint-authoring/references/debugging.md).

### When a check keeps failing

1. Fix the specific error the tool reported.
2. If it fails again, question your understanding rather than repeating the same edit.
3. After three attempts, stop and explain what you tried and what the tool said.

`# noqa: CODE` and `# type: ignore[code]` are allowed for genuine false positives or third-party gaps — always
with a specific code, never bare, and sparingly.

## Extending the scripts with hooks

Every script supports sourced `pre` and `post` hook scripts under `script/hooks/` and `.devcontainer/hooks/`.
Prefer them over editing a script directly: hook directories are excluded from template sync, the scripts are
not, so an edit to a script is overwritten in an author's collection while a hook survives.

| File                                         | When to read                                                                                                                            |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| [`references/hooks.md`](references/hooks.md) | Adding or debugging a hook. Naming convention, the complete pre/post hook table, examples, and the rules that apply to sourced scripts. |

## Devcontainer environment

Two layers, both sourced by the lifecycle scripts:

| File                       | Committed          | Purpose                        |
| -------------------------- | ------------------ | ------------------------------ |
| `.devcontainer/.env`       | ✅ yes             | project defaults for everyone  |
| `.devcontainer/.env.local` | ❌ no (gitignored) | personal overrides, always win |

| Variable     | Default | Effect                                              |
| ------------ | ------- | --------------------------------------------------- |
| `HA_VERSION` | pinned  | `latest`, `beta`, `YEAR.MONTH`, or an exact version |
| `APT_UPDATE` | `0`     | `1` runs `apt-get update && upgrade` during setup   |

`HA_VERSION` in `.devcontainer/.env` is the **single source** for the pinned Home Assistant version, read by
bootstrap and by the workflows. `script/ha-version-sync` enforces that it and `pytest-homeassistant-custom-component`
target the same release train. Both `.devcontainer/.env` and `requirements_test.txt` are agent-protected: propose
a version bump, do not apply one.

Changes require **Dev Containers: Rebuild Container**. These files are not visible to devcontainer _features_ or
`containerEnv` — those are set at image build time and must be edited in `devcontainer.json`.

Scripts under `script/` read the **process** environment and do not source these files. Variables that steer them
are therefore set in a hook.

## The two sync mechanisms

They run in opposite directions and are easy to confuse:

| Script / workflow                     | Direction | Brings                                                              |
| ------------------------------------- | --------- | ------------------------------------------------------------------- |
| `script/skills-sync`                  | inbound   | third-party skill material vendored into `.agents/skills/*/vendor/` |
| `.github/workflows/template-sync.yml` | outbound  | this repository's files into an author's own collection             |

Nothing else syncs in. Every other file is owned here — the chassis sync that once pulled shared development
files from upstream was retired on 2026-08-12
([`DECISIONS.md`](../../../docs/development/DECISIONS.md)), so there is no such thing as a file you must not edit
because upstream owns it. The one exception is `vendor/`:

**Never edit a file under a `vendor/` directory.** It must stay byte-identical to its pinned upstream commit;
`script/skills-sync --check` runs on every pull request and fails on any change, including one a formatter made.
To take a newer version, run `script/skills-sync --update <ref>`.

Template sync uses `-X theirs`, so **the template version wins** on any file both sides changed. To permanently
own a file, add it to `.templatesyncignore` (gitignore glob syntax) rather than resolving the same conflict every
week. Background and recovery procedures are in
[`CUSTOMIZATION.md`](../../../docs/development/CUSTOMIZATION.md).
