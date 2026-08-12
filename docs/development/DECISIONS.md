# Architectural and Design Decisions

This document records significant decisions made while building this collection and its tooling.

## Format

Each decision is documented with:

- **Date:** When the decision was made
- **Context:** Why this decision was necessary
- **Decision:** What was decided
- **Rationale:** Why this approach was chosen
- **Consequences:** Expected impacts and trade-offs

---

## Decision Log

### Validate against Home Assistant's own schema, not a reimplementation

**Date:** Template initialization

**Context:** Blueprints must satisfy Home Assistant's blueprint schema to be importable. A validator could
reimplement that schema, or import it from an installed Home Assistant.

**Decision:** `script/blueprint-check` imports `BLUEPRINT_SCHEMA` and `Blueprint` from the
`homeassistant.components.blueprint` package in the project virtual environment.

**Rationale:**

- It is the exact code path Home Assistant runs at import time, so passing here means importing cleanly
- Selector definitions change often; a reimplementation would drift silently and reject valid blueprints or
  accept invalid ones
- `Blueprint.__init__` already enforces domain match and undefined-`!input` detection for free
- Bumping the pinned Home Assistant version re-validates everything against the new schema at no maintenance cost

**Consequences:**

- Validation requires an installed Home Assistant (fine — the test suite needs one anyway)
- A Home Assistant release that changes the schema can break CI; the nightly `validate.yml` run surfaces this
  before users do
- The validator's own rules are limited to repository conventions, which is the correct division

---

### Test blueprints at runtime, not just structurally

**Date:** Template initialization

**Context:** Schema validation proves a blueprint imports. It says nothing about whether the automation
actually works.

**Decision:** Every blueprint has tests that install it into an in-memory Home Assistant instance
(`pytest-homeassistant-custom-component`), instantiate it via `use_blueprint`, drive it with real state
changes, and assert on service calls and entity states.

**Rationale:**

- The failures that reach users are behavioral: a condition that never passes, a mode that drops runs, a
  template that errors on `unavailable`
- Blueprint authors traditionally have no automated testing at all — this is the main thing the repository adds
- The full Home Assistant runtime is already a dependency, so the marginal cost is a fixture
- Tests run in well under a second, so they are actually run

**Consequences:**

- Adding a blueprint means writing a test; this is a deliberate quality gate
- Tests must handle suspended runs carefully (`wait_for_trigger`, `delay:`) — documented in `TESTING.md`
- Time-dependent behavior needs frozen time rather than real waiting

---

### Per-file symlinks for the development instance

**Date:** Template initialization

**Context:** The running Home Assistant needs the blueprints under `config/blueprints/`, but the source of
truth is `blueprints/` at the repository root (where linting and git see it).

**Decision:** `script/setup/sync-blueprints` creates one relative symlink per blueprint file, mirroring the
directory structure with real directories.

**Rationale:**

- Home Assistant's blueprint scan is `glob("**/*.yaml")`, which follows file symlinks reliably
- Edits in the workspace are immediately live in the running instance — no copy step to forget
- Regular files in `config/blueprints/` (UI-imported blueprints) are left untouched
- Copying instead would create a stale second copy; a directory symlink is not traversed the same way

**Consequences:**

- New blueprint files require a `sync-blueprints` run (or a `develop` restart) to appear
- Stale links from renamed or deleted sources must be cleaned up, which the script does on each run
- `config/` stays gitignored, so the links never enter version control

---

### Distribute via native import, not HACS

**Date:** Template initialization

**Context:** HACS is the usual distribution channel for Home Assistant community content.

**Decision:** Blueprints are distributed through Home Assistant's native blueprint import, using each
blueprint's `source_url` as the import URL. No `hacs.json`, no HACS validation workflow.

**Rationale:**

- HACS has no blueprint category — its publishing documentation lists integrations, plugins, themes, AppDaemon
  apps, Python scripts, and custom templates only
- Home Assistant natively accepts a GitHub `blob` URL and resolves it to raw internally, so the `source_url`
  already _is_ the import URL
- One-click import badges via `my.home-assistant.io` are a better user experience than a store listing

**Consequences:**

- `main` is the release channel: anything merged is immediately importable
- Releases become a communication mechanism (what changed, whether to re-import), not a distribution mechanism
- `source_url` correctness is critical — `script/blueprint-check` verifies it against the file's actual path
- Renaming or moving a blueprint file is a breaking change

---

### Version the collection as a whole

**Date:** Template initialization

**Context:** Blueprints could be versioned individually or as a collection.

**Decision:** One version for the repository, managed by release-please in
`.release-please-manifest.json`. Individual blueprints carry no version.

**Rationale:**

- The blueprint schema has no version field, so a per-file version would be invisible to users
- Users import from `main`; they experience the repository as one artifact
- Conventional Commit scopes already identify which blueprint changed in the changelog

**Consequences:**

- A patch to one blueprint bumps the collection version
- Release notes must name the affected blueprint explicitly
- Semantic versioning is interpreted against the input interface: renaming an input is a major bump

---

### One leading repository for the shared chassis, not a third repository

> **Superseded on 2026-08-12** — see "Retire the chassis sync" at the end of this log. Kept because the
> reasoning still explains why the shared files look the way they do.

**Date:** Template initialization

**Context:** This template and the upstream
[integration blueprint](https://github.com/jpawlowski/hacs.integration_blueprint) share a substantial
development environment: the DevContainer, the agent runtime configuration, the generic scripts, and the linter
configuration. Measured at the time of the split, 38 files were byte-identical. Maintaining them twice invites
drift; the obvious alternatives were a third "chassis" repository or declaring one repository leading.

**Decision:** The integration blueprint is leading for the shared files. This repository pulls them via
`script/chassis-sync`, driven by an explicit allowlist in `.github/chassis-manifest.txt`. A blueprint author's
own repository does not participate — `initialize.sh` removes the chassis sync, and the author receives those
files through the normal template sync from here.

**Rationale:**

- A third repository would mean three places to change, plus versioning and releasing the chassis itself — real
  overhead for ~38 files that change rarely
- The integration blueprint is where this tooling originated and where it is exercised most
- The two-hop chain works because both hops already have a sync mechanism; only the file list differs
- An allowlist is the only safe direction: a denylist would silently pull in every new integration-specific
  file the upstream adds

**Consequences:**

- Chassis files must not be edited here; the pull-request check enforces that
- A file that needs blueprint-specific content is removed from the manifest and owned here instead
- Manifest entries are verified: an entry that no longer exists upstream fails the sync rather than being
  skipped
- Author repositories are unaffected — they never see the upstream integration blueprint

---

### Single Home Assistant version across all tooling

**Date:** Template initialization

**Context:** The schema validator, the test runtime, the DevContainer, and CI each need a Home Assistant
version.

**Decision:** `HA_VERSION` in `.devcontainer/.env` is the single source, read by bootstrap and the workflows.
`script/ha-version-sync` enforces that it and `pytest-homeassistant-custom-component` target the same release
train, and that no workflow hardcodes a version.

**Rationale:**

- The validator and the test runtime must be the same Home Assistant, or a blueprint could validate against one
  version and be tested against another
- The integration template used `hacs.json` for this, but only because HACS required that file; with HACS gone
  there is no reason to invent a replacement file when the project already has a committed environment file
- Symbolic values (`latest`, `beta`) are warned about rather than silently skipped: while one is committed,
  nothing verifies that the test framework agrees with it
- A pre-commit hook catches drift before it reaches CI

**Consequences:**

- Bumping Home Assistant means editing two files in one commit
- `.devcontainer/.env.local` stays exempt, so testing against a beta locally does not fight the check
- `.env` files are agent-protected in this project's Claude Code settings, so an agent can propose a version
  bump but not apply it — deliberate, given the same file would hold secrets in other projects

---

### Retire the chassis sync

**Date:** 2026-08-12

**Context:** The chassis sync pulled ~38 shared development files from the upstream
[integration blueprint](https://github.com/jpawlowski/hacs.integration_blueprint), enforced by an allowlist and
a pull-request drift check. It worked while both repositories stayed close. They then diverged: upstream
restructured its whole agent configuration, and the check went from `Differing: 0` to 16 differing files at
once. Merging that back was not a sync but a migration with naming and layout decisions attached — the
`blueprint-*` prefix alone contradicts this repository's own terminology rule.

At the same time the sync was becoming a poor fit in the other direction. Several files needed
blueprint-specific content and had to be removed from the manifest anyway: the instruction files, `script/lint`
and `script/lint-check`. The list of genuinely shared, genuinely unchanged files was shrinking on its own.

**Decision:** Remove `script/chassis-sync`, `.github/chassis-manifest.txt` and
`.github/workflows/chassis-sync.yml`. Every file in this repository is now owned here. Improvements from
upstream are adopted by hand, as a deliberate act, after someone has read them.

The useful part of upstream's agent layer was ported this way on the same day — see
[SKILLS_UPSTREAM.md](SKILLS_UPSTREAM.md) for what was taken, what was rewritten, and what was left behind.

**Rationale:**

- A sync whose diff has to be hand-resolved every time is a manual port with extra steps, plus a red CI check
- The two repositories now build different things. Upstream's "blueprint" is an integration template; this
  repository's is a Home Assistant blueprint. Shared vocabulary was the last thing holding the sync together
- Byte-identity is the wrong constraint for files that legitimately need local content — every exception had to
  be argued and removed from the manifest individually
- Adopting by hand is what actually happened in practice even while the sync existed

**Consequences:**

- DevContainer and linter improvements from upstream no longer arrive automatically. Nothing watches for them;
  someone has to go and look, and that will sometimes not happen
- The `.templatesyncignore` entries and the `initialize.sh` removal block for the chassis files are gone, so an
  author's repository no longer carries dead references to a mechanism it never had
- `script/skills-sync` is unaffected. It syncs vendored third-party material, not chassis files, and remains
  the one inbound mechanism with an enforced byte-identity guarantee
- If sharing becomes worth automating again, it should be re-argued from scratch rather than restored
