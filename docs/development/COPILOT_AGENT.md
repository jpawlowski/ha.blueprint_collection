# Working with GitHub Copilot Coding Agent

## Prompting for a New Blueprint

**Context:** The repository documents its blueprint rules in `AGENTS.md`,
`.github/instructions/blueprint.ha_blueprints.instructions.md`, and the existing example blueprints. Point the
agent at those and let it follow them.

For routine work, prefer the ready-made prompt file: `.github/prompts/Add Blueprint.prompt.md`.

### What to Include in Your Prompt

**Essential information:**

- **What the blueprint should do** - the behavior, in two or three sentences
- **Domain** - automation, script, or template
- **What the user should be able to configure** - the inputs you have in mind

**Optional (the agent can work these out):**

- Selector types and filters - it will derive them from the entity kinds involved
- Automation mode - it will pick based on the re-trigger behavior you describe
- Edge cases - it should surface them; confirm or correct its assumptions

### Prompt Template

```markdown
Add a new [automation|script|template] blueprint to this collection: [NAME].

Behavior: [2-3 sentences describing what it does and when]

Configurable by the user:

- [input 1 - what the user picks and why]
- [input 2 - with a default of X]

Follow the rules in AGENTS.md and .github/instructions/blueprint.ha_blueprints.instructions.md.

Tasks:

1. Create the blueprint under blueprints/<domain>/<author>/ with complete metadata
2. Design inputs with filtered selectors and sensible defaults
3. Run script/blueprint-check until it passes
4. Write a runtime test in tests/ following the existing test patterns
5. Run script/test until green
6. Add the import badge to README.md using script/import-links
```

### Example: Lights off when everyone leaves

```markdown
Add a new automation blueprint to this collection: Turn off lights when everyone leaves.

Behavior: When the last person leaves home (a group or person entity goes to "not_home"),
turn off the selected lights after a short grace period. If someone returns during the
grace period, do nothing.

Configurable by the user:

- The presence entity to watch (person or device_tracker)
- The lights to turn off (target selector)
- Grace period, default 5 minutes

Follow the rules in AGENTS.md and .github/instructions/blueprint.ha_blueprints.instructions.md.

Tasks:

1. Create the blueprint under blueprints/automation/<author>/ with complete metadata
2. Design inputs with filtered selectors and sensible defaults
3. Run script/blueprint-check until it passes
4. Write a runtime test covering both the leave case and the return-during-grace case
5. Run script/test until green
6. Add the import badge to README.md using script/import-links
```

Let the agent read the existing blueprints and tests first — they encode the patterns it needs.

## Human Review and Transparency

The Coding Agent prepares a draft; it does not establish that the blueprint is understood, tested, or ready to
publish. Before merging, review the diff and accurately record which checks and automated tests were performed, and
whether the blueprint was tried in a real Home Assistant instance. If review is partial or some behavior could not be
tested, document that limitation instead of implying full verification.

Extensive AI assistance is acceptable for a community blueprint collection. See [`AI_POLICY.md`](../../AI_POLICY.md) for
the project's approach to AI use, transparency, and informed user choice. Do not use this workflow for autonomous
contributions to an Open Home Foundation repository, where the official OHF AI Policy applies.

## Testing Copilot's Changes

After Copilot creates a draft pull request:

1. **Open the PR branch in Codespaces**
   - Navigate to the pull request on GitHub
   - Click "Code" → "Create codespace on `branch-name`"
   - Codespace starts with all dependencies pre-installed (see [CODESPACES.md](CODESPACES.md))

2. **Start Home Assistant**
   - Run `./script/develop` in the terminal
   - Port 8123 forwards automatically (forwarded URL appears in notification)
   - Click the forwarded port URL to open HA in browser

3. **Test the blueprint**
   - Run `script/blueprint-check` and `script/test`
   - Import it in the UI: **Settings > Automations & scenes > Blueprints**
   - Create an automation from it and verify the input form makes sense
   - Trigger it and inspect the run under **Traces**
   - Check logs: `config/home-assistant.log` or live in terminal

4. **Iterate if needed**
   - Comment on the PR with `@copilot` to request changes
   - Or make manual adjustments and commit to the PR branch
   - Stop Codespace when done to save free hours

> [!NOTE]
> Copilot Agent runs in GitHub Actions (ephemeral environment), so it cannot provide live web access to Home Assistant during development. Manual testing in Codespaces is required.

For detailed Codespaces usage, troubleshooting, and resource management, see [CODESPACES.md](CODESPACES.md).

## Tips

- Start simple - get a working prototype first
- Use `@copilot` in PR comments to iterate
- Review every iteration before merging and keep the PR's verification context accurate
- Break large changes into multiple PRs

## Agent Configuration Matrix (Vendor-Supported)

Use this matrix to keep security/approval behavior in real, vendor-supported
configuration files rather than in instruction prose.

| Agent                     | Supported config surface                                | Repo source of truth                                                                                                                                                                                                                                                                                                                               | Runtime target                                              | Notes                                                                                                                                       |
| ------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Copilot (VS Code agent)   | VS Code settings (`chat.*`, `github.copilot.*`)         | [.vscode/settings.default.jsonc](../../.vscode/settings.default.jsonc), [.devcontainer/devcontainer.json](../../.devcontainer/devcontainer.json)                                                                                                                                                                                                   | VS Code workspace + devcontainer customization settings     | Use `chat.tools.edits.autoApprove` for sensitive-path protection.                                                                           |
| Copilot CLI (terminal)    | Copilot CLI flags + CLI config home (`~/.copilot`)      | [.devcontainer/copilot/default-flags.txt](../../.devcontainer/copilot/default-flags.txt), [.devcontainer/copilot/copilot-safe](../../.devcontainer/copilot/copilot-safe), [.devcontainer/on-create.sh](../../.devcontainer/on-create.sh), [.devcontainer/.bashrc](../../.devcontainer/.bashrc), [.devcontainer/.zshrc](../../.devcontainer/.zshrc) | `~/.copilot/default-flags.txt`, `~/.local/bin/copilot-safe` | Uses the standard `copilot` command via shell alias to the wrapper. Opt out per call with `COPILOT_CLI_NO_DEFAULT_FLAGS=1`.                 |
| Claude Code (VS Code/CLI) | Claude managed settings JSON (`permissions`, `sandbox`) | [.devcontainer/claude-code/managed-settings.json](../../.devcontainer/claude-code/managed-settings.json)                                                                                                                                                                                                                                           | `/etc/claude-code/managed-settings.json`                    | Copied during container setup by [.devcontainer/on-create.sh](../../.devcontainer/on-create.sh); authors can adjust the repo file directly. |
| Codex CLI                 | Codex TOML config (`sandbox_mode`)                      | [.devcontainer/codex/config.toml](../../.devcontainer/codex/config.toml)                                                                                                                                                                                                                                                                           | `~/.codex/config.toml`                                      | Copied during container setup by [.devcontainer/on-create.sh](../../.devcontainer/on-create.sh); authors can adjust the repo file directly. |
| Gemini                    | Not recommended for this project setup                  | No default VS Code integration configured for this repository                                                                                                                                                                                                                                                                                      | N/A                                                         | Not part of the default devcontainer experience.                                                                                            |

### Practical rule

- Put policy and defaults in vendor config files first.
- Keep markdown instruction files for workflow guidance only.

## Resources

- [GitHub Copilot Best Practices](https://docs.github.com/en/copilot/tutorials/coding-agent/get-the-best-results)
- `AGENTS.md` and `.github/copilot-instructions.md` - Instructions Copilot reads automatically
