---
name: ha-blueprint-release
description: >
  Releasing and publishing Home Assistant blueprints from this collection —
  versioning, user-facing release notes, import links, and community publication.

  TRIGGER THIS SKILL WHEN:
  - Preparing or reviewing a release, or a release-please pull request
  - Writing or rewriting release notes and changelog entries
  - Adding a new blueprint to the README, or regenerating import badges
  - Drafting a Blueprint Exchange forum post or other community announcement
  - Deciding whether a change needs a major/minor/patch bump
  - Communicating a breaking change to users

  SYMPTOMS THAT MEAN YOU SHOULD HAVE READ THIS:
  - Release notes written in developer language (selectors, schemas, refactors, CI)
  - A breaking change shipped without telling users what to reconfigure
  - A new blueprint merged without an import badge in the README
  - An agent claiming human review or real-device testing that did not happen
license: MIT
---

# Releasing Blueprints

## The one thing to internalise

**There is no distribution channel.** Users import a blueprint by URL, and the URL points at
`main`:

```text
https://github.com/<owner>/<repo>/blob/main/blueprints/<domain>/<author>/<name>.yaml
```

Anything merged to `main` is immediately importable. **Treat `main` as released** and keep
it green.

Home Assistant does **not** auto-update imported blueprints. A user receives a change only
when they explicitly **re-import**. So a release here is not a distribution event — it is a
**communication** event. Its entire job is to tell users what changed and whether
re-importing is worth it or risky.

Every decision in this skill follows from that.

## Versioning

The collection is versioned as a whole. Individual blueprints are not versioned separately —
the blueprint schema has no version field, and per-file versions would be invisible to users.

- Canonical version: `.release-please-manifest.json`
- Print it: `./script/version` (or `./script/version --tag`)

Semantic versioning, interpreted for blueprints:

| Bump      | Means                                                                                |
| --------- | ------------------------------------------------------------------------------------ |
| **major** | Re-importing requires user action — an input was renamed/removed, or behaviour moved |
| **minor** | A new blueprint, or a new capability on an existing one; safe to re-import           |
| **patch** | Bug fix or documentation; safe to re-import                                          |

Raising a blueprint's `homeassistant.min_version` is a **major** change: users below the new
floor lose the ability to re-import at all.

## Conventional Commits drive everything

`release-please` derives both the version bump and the changelog from commit subjects. A
malformed message produces a wrong release — which is why `commitlint` runs as a commit-msg
hook.

```text
feat(motion-light): add optional lux threshold input
fix(flash-light): honor interval on the final flash
docs: clarify re-import step in getting started
```

Scope by blueprint name where it applies. Breaking changes need the footer — that is what
turns a `feat` into a major bump:

```text
feat(motion-light)!: replace wait_time with no_motion_wait

BREAKING CHANGE: The `wait_time` input was renamed to `no_motion_wait`.
Automations created from this blueprint must be reconfigured after re-importing.
```

Full conventions: `.agents/instructions/collection.commit-message.instructions.md`.

## The flow

1. Merge work into `main` — CI green (blueprint validation and tests)
2. `release-please` opens or updates a release PR with the computed version and changelog
3. **Review the changelog.** This is the text users read to decide about re-importing
4. Optionally enrich it: `./script/release-notes --apply` rewrites the PR body into
   user-facing language
5. Merge the release PR → tag and GitHub Release are created

## Writing release notes users can act on

Users are not developers. The notes answer exactly two questions: **what changed for me**,
and **do I need to re-import**.

```markdown
### ⚠️ Breaking Changes

- **Motion-activated light**: The wait time field was renamed. After re-importing, open
  your automations created from this blueprint and set the wait time again.

### 🎉 What's New

- **Flash light**: You can now choose how long the light stays on during each flash.

### 🐛 Fixed

- **Motion-activated light**: The light could stay on forever when motion was detected
  again during the wait time. Re-import the blueprint to get the fix.
```

Rules:

- **Name the blueprint** by its user-facing `name:`, not its filename
- **Say whether to re-import**, every time it matters
- **Spell out the user action** for a breaking change — "reconfigure the wait time", not
  "input renamed"
- **Never mention** selectors, schemas, refactors, CI, tests, or internal input keys
- A change users cannot observe does not belong in the notes at all

`script/release-notes` enforces this tone; it does not replace judgement about what matters.

## After releasing

Blueprint file changes need nothing further — `main` already serves them.

If a blueprint was **added**, regenerate the import badges and update the README:

```bash
./script/import-links            # markdown badges
./script/import-links --url      # plain import URLs
```

The badge is derived from each file's `source_url`, so a wrong `source_url` produces a badge
that imports the wrong file or nothing at all. `script/blueprint-check` verifies it against
the file's real path.

## Home Assistant version bumps

`HA_VERSION` in `.devcontainer/.env` pins the version used for validation and tests. When
bumping it, update `pytest-homeassistant-custom-component` in `requirements_test.txt` in the
same commit — `script/ha-version-sync` fails otherwise, as a pre-commit hook and in CI.
**Both files are agent-protected: propose the change, do not apply it.**

Raising `HA_VERSION` does **not** raise any blueprint's `homeassistant.min_version`. Only
raise a blueprint's minimum when it actually adopts newer syntax — and that is a breaking
change for users on older versions.

## Publishing to the community

The [Blueprint Exchange](https://community.home-assistant.io/c/blueprints-exchange/53) is
the usual venue. A post needs:

- What the blueprint does, in a sentence, before anything else
- The **My Home Assistant import badge** (`./script/import-links`)
- Required entities, integrations, or helpers
- Known limitations and behaviour on restart
- A link to the repository for issues

Follow the destination's rules — the forum category has its own, and they take precedence
over anything here.

**Two hard constraints from [`AI_POLICY.md`](../../../AI_POLICY.md), which applies to all
publication material:**

1. **Prepare publication material as a draft for human review.** Do not post, announce, or
   publish autonomously.
2. **Never overstate.** Do not claim human review, maintainer understanding, automated
   coverage, or real-device testing that did not happen. If a blueprint was only validated
   and unit-tested, say that — it is genuinely more than most published blueprints have.

## Commit rules

- **Never commit automatically.** Only when the developer explicitly asks, each time. A
  previous request is not standing permission.
- **Never ask about pushing.** The developer handles `git push`.

## Reference

- `docs/development/RELEASE.md` — the process in this repository
- [Blueprint Exchange](https://community.home-assistant.io/c/blueprints-exchange/53)
- [My Home Assistant import link generator](https://my.home-assistant.io/create-link/?redirect=blueprint_import)
- Breaking-change policy: the **ha-blueprint-authoring** skill
