@AGENTS.md

# Claude Code Instructions

Claude Code reads `CLAUDE.md`, not `AGENTS.md`, so the import above is what loads the shared instruction file
every agent in this repository uses. Everything else — project identity, terminology, blueprint authoring rules,
validation, workflow — lives there and is not repeated here.

## How the pieces reach Claude Code

| What              | Path Claude Code reads        | Real location           |
| ----------------- | ----------------------------- | ----------------------- |
| Agent skills      | `.claude/skills/`             | `.agents/skills/`       |
| Path-scoped rules | `.claude/rules/instructions/` | `.agents/instructions/` |

Both are symlinks. **Edit the real `.agents/` paths**, so your diff shows the same file another maintainer would
touch. `script/skills-check` verifies both links, because a broken one fails silently — Claude Code simply
behaves as though the files were never written.

Path-scoped rules load automatically for the file you are working on, matched by the `paths` key in each file's
frontmatter. If they appear not to apply, that key is the first thing to check — a rule with no `paths` loads
into every session instead, and a malformed one silently loads into none.

The skill catalogue lives in the routing table in `AGENTS.md` and in
[`.agents/skills/README.md`](.agents/skills/README.md). It is deliberately not copied here: a third list is a
third thing to forget.
