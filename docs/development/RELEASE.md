# Releases

## How blueprints reach users

There is no package manager. Users import a blueprint by URL, and the URL points at `main`:

```text
https://github.com/<owner>/<repo>/blob/main/blueprints/<domain>/<author>/<name>.yaml
```

**Anything merged to `main` is immediately importable.** Treat `main` as the release channel and keep it green.

Home Assistant does **not** auto-update imported blueprints. A user receives changes only when they explicitly
**re-import** the blueprint. So a release here is not a distribution event — it is a **communication** event:
it tells users what changed and whether re-importing is worth it or risky.

## Versioning

The collection is versioned as a whole. Individual blueprints are not versioned separately — the blueprint
schema has no version field, and per-file versions would be invisible to users anyway.

- Canonical version: `.release-please-manifest.json`
- Print it: `./script/version` (or `./script/version --tag` for `v0.1.0`)

Semantic versioning, interpreted for blueprints:

| Bump      | Means                                                                              |
| --------- | ---------------------------------------------------------------------------------- |
| **major** | Re-importing requires user action — an input was renamed/removed or behavior moved |
| **minor** | New blueprint, or new capability on an existing one; safe to re-import             |
| **patch** | Bug fix or documentation; safe to re-import                                        |

## Conventional Commits

`release-please` derives the version bump and the changelog from commit subjects. A malformed message produces a
wrong release, which is why `commitlint` runs as a commit-msg hook.

```text
feat(motion-light): add optional lux threshold input
fix(flash-light): honor interval on the final flash
docs: clarify re-import step in getting started
chore(deps): bump pytest-homeassistant-custom-component
```

Breaking changes need the footer — this is what turns a `feat` into a major bump:

```text
feat(motion-light)!: replace wait_time with no_motion_wait

BREAKING CHANGE: The `wait_time` input was renamed to `no_motion_wait`.
Automations created from this blueprint must be reconfigured after re-importing.
```

Scope by blueprint name where it applies. See
[`.agents/instructions/collection.commit-message.instructions.md`](../../.agents/instructions/collection.commit-message.instructions.md).

## The release flow

1. Merge work into `main` (CI must be green — blueprint validation and tests)
2. `release-please` opens or updates a release PR with the computed version and changelog
3. Review the changelog — this is the text users read to decide about re-importing
4. Optionally enrich it: `./script/release-notes --apply` rewrites the PR body into user-facing language
   (it knows blueprint vocabulary and flags where re-importing is needed)
5. Merge the release PR → tag and GitHub Release are created

## Writing release notes users can act on

Users are not developers. The notes must answer two questions: _what changed for me_, and _do I need to
re-import_.

```markdown
### ⚠️ Breaking Changes

- **Motion-activated light**: The wait time field was renamed. After re-importing, open your automations
  created from this blueprint and set the wait time again.

### 🎉 What's New

- **Flash light**: You can now choose how long the light stays on during each flash.

### 🐛 Fixed

- **Motion-activated light**: The light could stay on forever when motion was detected again during the
  wait time. Re-import the blueprint to get the fix.
```

Never mention selectors, schemas, refactors, CI, or tests. `script/release-notes` enforces this tone.

## After releasing

Blueprint file changes need nothing further — `main` already serves them. If a blueprint was **added**,
regenerate the import badges and update the README:

```bash
./script/import-links
```

## Home Assistant version bumps

`HA_VERSION` in `.devcontainer/.env` pins the version used for validation and tests. When bumping it, update
`requirements_test.txt` (`pytest-homeassistant-custom-component`) in the same commit — `script/ha-version-sync`
fails otherwise, both as a pre-commit hook and in CI.

Raising `HA_VERSION` does not raise any blueprint's `homeassistant.min_version`. Only raise a blueprint's
minimum when it actually adopts newer syntax — and note that doing so is a breaking change for users on older
versions.

## Related

- [ARCHITECTURE.md](ARCHITECTURE.md) — why `main` is the release channel
- [AUTHORING.md](AUTHORING.md) — which changes are breaking
