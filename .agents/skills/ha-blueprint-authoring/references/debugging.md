# Debugging a Blueprint Against a Live Instance

Read this when a blueprint validates and passes tests but misbehaves in Home Assistant, or
when you need to see what it actually does.

Runtime tests are usually faster and always repeatable — reach for the **ha-blueprint-testing**
skill first. Use the live instance for what tests cannot show: the import dialog, the
configuration UI, and integration behaviour.

## Starting the instance

```bash
./script/develop
```

This syncs `blueprints/` into `config/blueprints/` as **per-file symlinks** and starts Home
Assistant with debug logging. Then: **Settings → Automations & scenes → Blueprints** to
create an automation, script, or template entity from it.

Always use the project scripts. Hand-rolled `hass`, `pip`, or `pytest` invocations miss the
venv setup, blueprint sync, port management, and cleanup, and break in ways that are
tedious to diagnose.

**Port conflict or unresponsive instance:**

```bash
pkill -f "hass --config" || true && pkill -f "debugpy.*5678" || true && ./script/develop
```

## Picking up a change

Because the blueprints are symlinked, **file edits are live immediately** — but that is only
half the story:

| What changed                   | What to do                                                               |
| ------------------------------ | ------------------------------------------------------------------------ |
| Body of an existing blueprint  | **Developer Tools → YAML → Automations / Scripts / Template entities**   |
| A new blueprint file           | `./script/setup/sync-blueprints`, or restart `./script/develop`          |
| Inputs added, removed, renamed | Reload, then **re-create** the automation — instances cache their config |

That third row is the one that wastes time. An automation created from a blueprint stores
its resolved configuration. Reloading re-reads the blueprint, but existing instances keep
the inputs they were created with — which is exactly the behaviour real users experience on
re-import, and worth seeing at least once.

## Traces — the primary tool

**Settings → Automations → (the automation) → Traces.**

A trace shows, per step: whether it ran, which `choose:` branch was taken, every rendered
template, and `changed_variables` — the resolved value of every variable at that point.
This is the only place where you can see what an `!input` actually became.

What to look at, in order:

1. **Did the trigger fire at all?** No trace means the trigger never matched — check
   `from:`/`to:`, `for:`, and whether the entity really changed.
2. **Which branch ran?** `result: {choice: N}` on a `choose:` step.
3. **`changed_variables`** — compare the resolved values against what you expected. Wrong
   `!input` bindings and stale `now()` show up here immediately.
4. **`last_step`** — where a run stopped. A run that ends on a condition means the condition
   was false, not that something crashed.

Traces are kept per automation with a configurable count. **Give every non-obvious step an
`alias:`** — an unnamed step in a trace is a number, and that is all the information a user
sending you a trace can give you.

## Logs

- **Live:** the terminal running `./script/develop`
- **File:** `config/home-assistant.log`, previous run in `config/home-assistant.log.1`
- Template errors, schema violations, and "entity not found" all land here with the
  automation's entity id

Search for the blueprint's name or the automation's entity id. A template that fails renders
as an error line with the offending expression.

## Templates

**Developer Tools → Template** evaluates against the live state machine.

It cannot resolve `!input` — paste the template with the input's real value substituted.
This is exactly why every input used in a template gets a `variables:` binding: the binding
tells you what to substitute.

For anything that depends on `trigger.*`, the template editor cannot help. Use a trace.

## Testing the user's view

Things only the live instance shows:

- **The import dialog** — how the description renders as Markdown, and whether it answers
  what a stranger needs to know
- **The configuration form** — selector filters actually applied, section grouping and
  collapse behaviour, which fields are required
- **Import by URL** — paste the `source_url` into
  **Settings → Automations & scenes → Blueprints → Import blueprint** to confirm the round
  trip works

Walking through the configuration form once catches more usability problems than any amount
of schema validation. If you cannot configure it without reading the YAML, neither can a user.

## When it still makes no sense

1. Re-read the matching entry in [pitfalls.md](pitfalls.md) — most surprises are documented.
2. Reduce to the smallest blueprint that still shows the behaviour.
3. Write a runtime test that reproduces it. If you cannot, the mental model is wrong, not
   Home Assistant.
4. After three failed attempts at the same error, stop and explain what you tried instead
   of looping.

## Reference

- Repository scripts and instance mechanics: [`AGENTS.md`](../../../../AGENTS.md)
- [Automation troubleshooting](https://www.home-assistant.io/docs/automation/troubleshooting/)
- [Debugging templates](https://www.home-assistant.io/docs/templating/debugging/)
