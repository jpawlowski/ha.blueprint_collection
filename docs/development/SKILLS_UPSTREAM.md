# The Agent Layer, and What Came From Upstream

**Written:** 2026-08-09 · **Port completed:** 2026-08-12 against upstream `07b2216` ·
**Verified against:** Home Assistant 2026.8.1, Claude Code 2.1.226

This repository and the upstream development chassis
([jpawlowski/hacs.integration_blueprint](https://github.com/jpawlowski/hacs.integration_blueprint))
built an agent layer at the same time, independently, and arrived at the same core design
without coordinating. On 2026-08-12 the useful remainder was ported here **once, by hand**.

There is no ongoing agent-layer sync with the chassis, and there is no plan for one. This
document records what was adopted, what was deliberately left behind, and the facts that were
expensive enough to establish that they should not be re-derived.

## What exists here today

```text
.agents/README.md                      Layout, client discovery, the four layers, placeholders
.agents/instructions/                  collection.*.instructions.md — path-scoped rules
.agents/skills/                        9 skills
.agents/scratch/                       Working notes — gitignored

.claude/skills             -> ../.agents/skills
.claude/rules/instructions -> ../../.agents/instructions
.github/instructions       -> ../.agents/instructions

script/skills-check                    Agent Skills spec + this repository's own contracts
script/skills-sync                     Vendored third-party files — --check / restore / --update
.github/skills-manifest.txt            Vendored sources, pinned commits, file mappings
.github/workflows/skills-sync.yml      PR drift check + weekly update PR
```

The skills split three ways: `ha-blueprint-*` for work on the deliverable, `ha-*` for Home
Assistant knowledge that is not blueprint-specific, and unprefixed names for working in the
repository at all. **Nothing is named `blueprint-*`** — see "Naming" below.

## What was taken from upstream

| Adopted                                                   | Changed on the way in                                                                                               |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `script/skills-check` + `.lib/skills_check.py`            | Placeholders, the unconditional-instructions name, `vendor/` skipped; the marker checks replaced by a symlink check |
| `.agents/instructions/` + two symlinks                    | Renamed `blueprint.*` → `collection.*`; every file gained `paths`, `name`, `description`                            |
| `.agents/README.md`                                       | Rewritten around this repository's placeholders and naming rules                                                    |
| `.agents/scratch/`                                        | Replaces the old `.ai-scratch/` convention                                                                          |
| `script/markdown` globbing `.agents/**`                   | Taken verbatim, which restored chassis byte-identity                                                                |
| `ha-grill` → `requirements-interview`                     | Question bank rewritten entirely for blueprints                                                                     |
| `ha-planning` → `change-planning`                         | Seams rewritten: inputs, selectors, file name, `min_version`                                                        |
| `ha-quality-review` → `ha-blueprint-review`               | Process shell kept; the checklist is new, derived from `pitfalls.md`                                                |
| `blueprint-tooling` → `repo-tooling`                      | hassfest and the dependency section dropped; hook table regenerated from source                                     |
| `blueprint-skill-maintenance` → `agent-skill-maintenance` | Rewritten around this repository's roles and vendoring                                                              |
| An `npm` ecosystem in `.github/dependabot.yml`            | A gap in the upstream file, fixed here rather than reproduced                                                       |

Taking `script/markdown` and `script/markdown-check` from upstream made the `globs` key in
`.markdownlint-cli2.jsonc` redundant, and it was removed. Both scripts are chassis-managed and
are now byte-identical again.

## What was deliberately not taken

- **`script/ha` and `script/.lib/ha_cli/`** — a REST client for driving a running instance.
  The upstream port plan calls it "the biggest rewrite", and the runtime test suite here
  already covers the need without a running instance or a network round trip.
- **`script/setup/seed-auth` and `.lib/seed_auth.py`** — they exist solely to mint the token
  `script/ha` uses. Without that CLI they are dead code. They also do not skip onboarding,
  which is the thing that would have justified them on their own.
- **`blueprint-scaffold`, `ha-config-flow`, `ha-coordinator-debug`, `ha-entity-platform`,
  `ha-modern-apis`, `ha-service-action`, `ha-testing`, `ha-translations`** — Python
  integration internals with no blueprint equivalent.
- **`ha-breaking-changes`** — the concept matters here, but the invariants are entirely
  different. It lives in `ha-blueprint-release` and the input-interface rules instead.

Upstream has **no vendoring mechanism**, so `script/skills-sync`, the manifest and the
workflow remain this repository's own contribution.

## Naming — the collision that had to be resolved

Upstream uses `blueprint-*` to mean **the integration blueprint template**. `AGENTS.md` here
defines "blueprint" as **a Home Assistant blueprint**, and says so in a Terminology note
precisely to prevent this confusion. Carrying the upstream names down would have contradicted
the repository's own rule in the exact way that rule exists to prevent.

Resolved by renaming on the way in — both the skills (table above) and the instruction files,
whose `blueprint.*` prefix was a chassis artefact carrying the same wrong meaning. The five
generic instruction files were removed from `.github/chassis-manifest.txt` at the same time,
under that file's own rule: a file needing repository-specific content is owned here.

## Verified facts

These were established empirically, not from documentation or memory; each line names how to
re-check it.

### Skill discovery

| Agent          | Reads `.agents/skills/`? | Consequence                        |
| -------------- | ------------------------ | ---------------------------------- |
| GitHub Copilot | **yes**, natively        | no `.github/skills` symlink needed |
| ChatGPT Codex  | **yes**, natively        | nothing needed                     |
| Claude Code    | **no**                   | `.claude/skills` symlink required  |

- Copilot's documented project-skill locations are `.github/skills`, `.claude/skills`, **and**
  `.agents/skills` ([GitHub docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)).
- Claude Code's shipped binary contains **zero** occurrences of `.agents/skills` and 75 of
  `.claude/skills`. Re-check after any Claude Code update:

  ```bash
  C=$(ls ~/.vscode-server/extensions/anthropic.claude-code-*/resources/native-binary/claude | head -1)
  strings -a "$C" | grep -c ".agents/skills"   # 0 today → symlink still needed
  ```

- **A directory symlink is sufficient**; per-skill symlinks are not required. Confirmed by
  observation: with `.claude/skills -> ../.agents/skills`, every skill appears in the session's
  skill list. Claude Code's documentation only promises symlink support for a `<skill-name>`
  entry, so the per-skill fallback stays documented in
  [`.agents/skills/README.md`](../../.agents/skills/README.md) in case that changes.

### Tooling constraints found the hard way

- **A symlinked second path must be excluded from linters.** With both `.github/skills` and
  `.agents/skills` visible, markdownlint-cli2 followed the symlink and Prettier did not — so the
  same file was reported as failing through one path and passing through the other. Exclude
  every symlinked path and lint through the real one. All three symlinks are excluded in
  `.markdownlint-cli2.jsonc` and `.prettierignore` today.
- **`vendor/` directories must be excluded from all formatters.** A formatting fix there breaks
  the byte-identity the drift check depends on. This is not hypothetical: while this layer was
  being built, `markdownlint --fix` reformatted a vendored file during a commit whose
  configuration did not yet carry the exclusion, and `script/skills-sync --check` was the only
  thing that caught it.
- **markdownlint-cli2 can be extended without touching chassis files** via the `globs` key;
  Prettier cannot — its globs live in `script/markdown`. That asymmetry drove the workaround
  that upstream's change later made unnecessary.

### Vendoring

- Third-party skill material is vendored **verbatim** and pinned to a commit, not a branch.
  A pinned commit is not directly cloneable; `git init`, `fetch --depth 1 <sha>`, then
  `checkout FETCH_HEAD` is required.
- `--update` must preserve manifest comments and blank lines; only the `REF` line moves.
- `script/skills-sync` **no-ops with exit 0 when the manifest is absent**, so a repository that
  vendors nothing can carry the script without its CI turning red.

## Constraints that must keep holding

- **`.agents/` files are synced to author repositories** via template-sync, so they use the
  `<author>`, `<collection-title>` and `<owner>/<repo>` placeholders. A concrete value would
  overwrite an author's own name months after `initialize.sh` set it. `script/skills-check`
  rejects the concrete forms.
- **`initialize.sh` removes `.github/workflows/skills-sync.yml`** from an author's repository —
  it receives vendored files through template-sync and must not open pull requests against a
  third-party upstream itself. The script and manifest are deliberately kept so `--check` works.
- **Vendored files must never be edited locally.** `script/skills-sync --check` runs on every
  pull request and fails on any change.

## Still open

- **Offering `script/skills-sync` upstream.** They have no vendoring mechanism; this one is
  generic and no-ops without a manifest. Worth a pull request if the relationship stays friendly.
- **Watching upstream by hand.** The chassis sync was retired the same day
  ([`DECISIONS.md`](DECISIONS.md)), so nothing now notices when a DevContainer or linter
  improvement lands there. That is the accepted cost, not an oversight — but it means someone
  has to go and look occasionally, and the honest expectation is that this will sometimes not
  happen.
