# Dependency Management

## The short version

**Blueprints have no dependencies.** They are YAML files interpreted by Home Assistant — there is no package to
install, no library to import, nothing that ships to the user beyond the file itself.

Everything described below exists purely to _develop and verify_ those files: a real Home Assistant to validate
and run them against, a test framework, and linters. None of it reaches anyone who imports a blueprint.

This is why there is no `requirements.txt` in this repository, and why there is no `manifest.json` or
`hacs.json` — those belong to custom integrations, which this is not.

## Files

| File                    | Purpose                                              | Installed by              |
| ----------------------- | ---------------------------------------------------- | ------------------------- |
| `requirements_dev.txt`  | Development tooling (pre-commit, colorlog)           | `script/setup/bootstrap`  |
| `requirements_test.txt` | Blueprint test framework                             | `script/setup/bootstrap`  |
| `package.json`          | Node-based tooling (Prettier, markdownlint, Pyright) | `npm ci` during bootstrap |
| `.ha-version`           | Pinned Home Assistant release train                  | Read by bootstrap and CI  |

`requirements.local.txt` (gitignored) is honored if present, for machine-specific extras you do not want to
commit.

## What bootstrap installs

`script/setup/bootstrap` builds the environment in this order:

1. **Development dependencies** — `requirements_dev.txt`
2. **Test dependencies** — `requirements_test.txt`
3. **Home Assistant's own requirements** — downloaded from the pinned version's tag on GitHub
   (`requirements_all.txt`, `requirements_test.txt`, `package_constraints.txt`)
4. **Home Assistant core** — `homeassistant==<version from .ha-version>`
5. **Node dependencies** — `npm ci`
6. **Git hooks** — `pre-commit install`

Steps 3 and 4 are what make `script/blueprint-check` and `script/test` meaningful: both run against a real Home
Assistant installation, not a stub.

The installed version is recorded in `<venv>/.ha-version`, so bumping `.ha-version` triggers a clean rebuild of
the virtual environment on the next bootstrap instead of silently running against the old one.

## Why Home Assistant Core's requirements

Home Assistant Core publishes `requirements_test.txt`, which pulls in pytest and its plugins, `freezegun`,
`respx`, `syrupy`, and the rest. Installing those from the pinned Home Assistant tag means the test environment
matches what Home Assistant itself uses — the same pytest version, the same plugin behavior.

The repository therefore only declares what Core does _not_ provide:

- `pre-commit` — Core pins `prek` (a Rust reimplementation) instead, but `.pre-commit-config.yaml` targets
  `pre-commit`, so this repository owns that dependency
- `colorlog` — nicer output from the development scripts
- `pytest-homeassistant-custom-component` — the fixtures that give each test its own in-memory Home Assistant

## Version pinning

`.ha-version` is the single source of truth for which Home Assistant to develop against:

```text
2026.8.0
```

A `YYYY.M.0` value means "latest patch in that month". Explicit patches (`2026.8.3`) and pre-releases
(`2026.9.0b1`) are used as-is.

`pytest-homeassistant-custom-component` in `requirements_test.txt` pins a specific Home Assistant version
transitively, so the two must agree. `script/ha-version-sync` enforces that they target the same release train
(`YYYY.M`), and that no CI workflow hardcodes a version instead of reading `.ha-version`. It runs as a
pre-commit hook and as a CI job.

**To bump Home Assistant:** edit `.ha-version` and `requirements_test.txt` in the same commit, then re-run
`script/setup/bootstrap`.

**To test against a different version without changing the repository**, override per machine in
`.devcontainer/.env.local` (gitignored and exempt from the sync check):

```bash
HA_VERSION=beta        # or latest, or 2026.9.0
```

## Node dependencies

| Package             | Used for                                     |
| ------------------- | -------------------------------------------- |
| `prettier`          | Markdown and YAML formatting                 |
| `markdownlint-cli2` | Markdown linting                             |
| `pyright`           | Type checking the test suite                 |
| `@commitlint/*`     | Conventional Commit validation on commit-msg |
| `@github/copilot`   | Copilot CLI                                  |

Pinned exactly in `package.json` and locked in `package-lock.json`; installed with `npm ci`.

## Dependabot

Dependabot watches `requirements_*.txt`, `package.json`, and the GitHub Actions. One workflow is worth knowing
about: `dependabot-ha-stability-check.yml` automatically closes Dependabot PRs that would bump
`pytest-homeassistant-custom-component` to a version depending on a Home Assistant **pre-release**. Dependabot
reopens the PR once a stable release is available, so development never silently moves onto a beta.
