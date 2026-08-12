---
name: agent-skill-maintenance
description: >-
  Maintain the agent skills and instruction files under .agents/. Use when asked to "add a skill", "update the
  skills", "this skill is out of date", "split this skill", "remove a skill", "the skills disagree with the
  instructions", or after bumping the pinned Home Assistant version, which can invalidate advice in several
  skills at once. Covers the rule-versus-procedure seam against .agents/instructions, the pointers that must
  exist on both sides of it, where the catalogue is duplicated, naming, template-sync safety, vendored material,
  and the validation loop. SYMPTOMS — load this if you are about to: write a concrete author folder or collection
  title into a skill; add a skill without listing it in both catalogues; restate in a skill a rule that already
  lives in an instructions file; name a skill `blueprint-*`; edit a skill through one of the symlinked paths; or
  edit anything under a `vendor/` directory.
license: MIT
---

# Maintain the agent skills

**This repository is a template.** Everything under `.agents/` reaches every collection generated from it,
through the template-sync pull request. A skill that is wrong or bloated is not one repository's problem — it is
everyone's.

## How to write a skill

The format, frontmatter rules, folded-scalar requirement, SYMPTOMS convention and authoring principles are in
[`../README.md`](../README.md), and the layout rules for `.agents/` as a whole are in
[`../../README.md`](../../README.md). Read those — this skill does not repeat them. What follows is what is
specific to maintaining a set that ships to other people.

## The seam: rule or procedure?

Every piece of guidance goes in exactly one place. Before writing anything into a skill, ask which of these it
is:

| It is…                                                        | It belongs in…              |
| ------------------------------------------------------------- | --------------------------- |
| A rule that holds whenever a file of that type is edited      | `.agents/instructions/*.md` |
| An ordered procedure, or a decision the developer has to make | `.agents/skills/*/SKILL.md` |
| An explanation or rationale for a human reader                | `docs/development/`         |

"`min_version` must be present and ≤ the installed Home Assistant", "never use `device_id`", "the folder must
match `blueprint.domain`" are rules. "First settle the inputs, then write the YAML, then validate with
`script/blueprint-check`" is a procedure. When a skill needs a rule in order to make sense, **link to it** — do
not copy it. Two copies of a rule become two contradicting rules within a release or two.

Copilot, VS Code and Claude Code all inject the matching instructions file automatically when a file of that type
is touched. Codex does not — its nested `AGENTS.md` support keys off the working directory, not the edited file.
That is why the pointer at the top of each skill names _what_ is in the instructions file rather than just
linking it: for Codex the skill is the only bridge.

**The pointer runs both ways, and a pair is only done when both ends exist.** The skill opens with a
`**Read … first**` block; its instructions file opens with a pointer naming the skill. They cover opposite
failures. The skill's block is for an agent that already knows which task it is on but not which rules bind it.
The instructions file's pointer is for the commoner case: an agent that went straight into the YAML, loaded no
skill, and gets that file injected on the first read — the pointer is the only thing that still routes it.
Neither end summarises the other; both are links. When you rename or remove a skill, both ends move —
`script/skills-check` catches a link that no longer resolves, but it cannot invent a pointer that was never
written.

When you add or change an instructions file, keep `applyTo` (Copilot, VS Code — one comma-separated string) and
`paths` (Claude Code, via the `.claude/rules/instructions` symlink — a YAML list) describing the same patterns. A
file without `paths` is loaded by Claude Code into every session. The full frontmatter contract is in
[`../../README.md`](../../README.md); `script/skills-check` enforces it.

## Naming

| Prefix           | For                                                     | Examples                                        |
| ---------------- | ------------------------------------------------------- | ----------------------------------------------- |
| `ha-blueprint-*` | work on the deliverable                                 | `ha-blueprint-authoring`, `ha-blueprint-review` |
| `ha-*`           | Home Assistant knowledge that is not blueprint-specific | `ha-automation-patterns`                        |
| _(unprefixed)_   | working in this repository at all                       | `repo-tooling`, `change-planning`               |

**Never name a skill `blueprint-*`.** In this repository "blueprint" means a Home Assistant blueprint, and
`AGENTS.md` says so — a skill called `blueprint-tooling` would quietly mean the tooling of the repository, which
is the opposite of what a reader here expects. The upstream development chassis uses that prefix for its own
template, which is exactly why skills adopted from there were renamed on the way in.

## Write for both roles

Skills are synced downstream and read in two kinds of repository: this template, and the collections generated
from it. The same sentence has to be true in both.

- **"this repository", "this collection"** — the repository the agent is in, whichever that is. This is the
  default.
- **"the template", "upstream"** — reserved for the repository this one was generated _from_. Correct downstream,
  and correct here too.
- **"this template"** — almost always wrong downstream, where it claims the maintainer's collection is one.

Use the placeholders `<author>`, `<collection-title>` and `<owner>/<repo>` rather than the values this repository
ships with. `initialize.sh` rewrites the concrete values once, when a collection is created — but template sync
keeps delivering these files for months afterwards, so a literal value here would overwrite an author's own name
long after they set it. `script/skills-check` fails the build if a concrete identifier slips in, including in a
code sample or a negative example.

## Adding a skill

1. Decide it is really a skill and not a rule (see the seam above), and that no existing skill should absorb it.
   Pick the prefix from the table above. Keep the name short: it is what people type to invoke the skill.
2. Create `.agents/skills/<name>/SKILL.md`. Reference files go one level down, in `references/` — never deeper.
3. Add it to the catalogue in **both** places listed below.
4. If it has a partner instructions file, add the pointer there (see the seam above).
5. `script/skills-check && script/markdown`.

## Where the catalogue is duplicated

Adding or renaming a skill means touching these:

| File                       | Form                                                     |
| -------------------------- | -------------------------------------------------------- |
| `.agents/skills/README.md` | table with a "Use when" column                           |
| `AGENTS.md`                | routing table: task → skill → matching instructions file |

There is no generator, but `script/skills-check` verifies both directions: every skill directory is linked from
both files, and every skill link in them resolves. It cannot check that the "Use when" text is any good.

**No other file carries a catalogue, and none should.** Codex and Copilot read `AGENTS.md` natively, and
`CLAUDE.md` imports it with `@AGENTS.md` — all three already have the table. There is deliberately no `CODEX.md`
and no `.github/copilot-instructions.md`; both existed once and were deleted precisely because a second list is a
second thing to forget.

Do not state a skill count anywhere. It is a maintenance trap that goes stale silently.

## Changing an existing skill

- **Behaviour changes are the point; churn is not.** Downstream maintainers review a diff. Rewording for taste
  costs them attention and buys nothing.
- **Check the counterpart instructions file** in the same change. If you add a rule to a skill, it probably
  belongs in the instructions file instead, and if it contradicts one already there, one of the two is now wrong.
- If a downstream maintainer would reasonably have edited this skill locally, remember their change is protected
  only if they listed it in `.templatesyncignore`.

## Removing or renaming a skill

Renaming changes the invocation name and every catalogue entry, and silently breaks any downstream
`.templatesyncignore` entry that pinned the old path. Prefer rewriting a skill in place over renaming it. If it
must go, remove the directory, both catalogue entries, the pointer in its partner instructions file, and any
cross-links from other skills. `script/skills-check` covers all of it — it link-checks the skills, the two
catalogues and `.agents/instructions/` — so run it and fix what it names rather than hunting by hand.

## Vendored material

`.agents/skills/*/vendor/` holds third-party files copied verbatim from another repository and pinned to a
commit in [`.github/skills-manifest.txt`](../../../.github/skills-manifest.txt).

**Never edit them, and never let a formatter touch them.** They must stay byte-identical to their pinned commit;
`script/skills-sync --check` runs on every pull request and fails on any difference. Both
`.markdownlint-cli2.jsonc` and `.prettierignore` exclude `vendor/` for that reason, and
`script/skills-check` skips it too.

To take a newer upstream version: `script/skills-sync --update <ref>`, then read the diff. Anything this
repository wants to say _about_ vendored material goes in the wrapper `SKILL.md` beside it, never inside
`vendor/`.

## After a Home Assistant version bump

`script/ha-version-sync` changes the pinned version; several skills make version-specific claims that may now be
stale. Re-verify against the newly installed source, not from memory:

| Re-check                                                                                                                  | Against                                         |
| ------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| [`ha-blueprint-authoring/references/triggers-conditions.md`](../ha-blueprint-authoring/references/triggers-conditions.md) | the regeneration script at the end of that file |
| [`ha-blueprint-authoring/references/ha-version-matrix.md`](../ha-blueprint-authoring/references/ha-version-matrix.md)     | the release notes for the versions crossed      |
| [`ha-blueprint-authoring/references/selectors.md`](../ha-blueprint-authoring/references/selectors.md)                     | `homeassistant.helpers.selector` in the venv    |
| [`ha-blueprint-testing`](../ha-blueprint-testing/SKILL.md)                                                                | new `DeprecationWarning`s, which fail the suite |

Anything a skill marks as **verified** was established by running code. If a bump could invalidate it, re-run the
check rather than reasoning about it — that mark is the reason the claim is trusted.

## Do not

- Do not edit skills through `.claude/skills/`, or instructions through `.github/instructions/` — they are
  symlinks; edit `.agents/` so the path in your diff matches what other maintainers see.
- Do not add a `.github/skills/` symlink. Every client that would read it already reads `.agents/skills/`.
- Do not add frontmatter fields beyond `name`, `description` and `license` without a concrete reason — each one
  is a portability risk across the clients this repository targets.

`script/skills-check` covers the spec's mechanical limits, so do not restate them in a skill either.
