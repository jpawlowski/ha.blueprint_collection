# Blueprint Pitfalls

The regression catalogue. Read the matching entry **before** writing the fix — most "new"
bugs are a documented pattern reaching a new blueprint.

Each entry is: **Symptom** (what you observe) → **Cause** → **Fix** → **Rule** (the
generalisation that prevents the next one).

Grouped by where the bug lives: structure and syntax, runtime behaviour, interface and
distribution. Letters are stable identifiers — append new ones, never renumber.

---

## Structure and syntax

### A: The blueprint never appears in Home Assistant

**Symptom** — File is in `blueprints/`, `script/blueprint-check` is green, but the import
dialog or the blueprint list does not show it.

**Cause** — Wrong extension (`.yml`), wrong folder domain, or a new file that the running
instance has not linked yet. Home Assistant's folder scan is `glob("**/*.yaml")` and loads
strictly by `blueprints/<domain>/`.

**Fix** — `.yaml`, folder domain matching `blueprint.domain`, inside the author subfolder.
For a running instance, `script/setup/sync-blueprints` (or restart `./script/develop`).

**Rule** — Path is not cosmetic. `script/blueprint-check` enforces all three; if it passed
and HA still does not see the file, the instance has stale links.

### B: `!input` inside a Jinja expression does nothing

**Symptom** — A template renders an empty string, or errors with a YAML parse failure.

**Cause** — `!input` is resolved by the YAML loader before Jinja ever runs. It cannot
appear inside `{{ … }}`.

**Fix** — Bind it to `variables:` first, use the variable in the template.

**Rule** — Every input used in a template gets a `variables:` binding, conventionally under
the same name. See [templating.md](templating.md).

### C: `states()` in `trigger_variables:` fails

**Symptom** — Automation fails to load, or the trigger never fires, with a template error
about an undefined function.

**Cause** — `trigger_variables:` is a _limited_ template context evaluated before the state
machine is reachable. `states()`, `is_state()`, `state_attr()`, `expand()` do not exist there.

**Fix** — Bind only `!input` values in `trigger_variables:`; move state reads into an
action-scope `variables:` block or a condition.

**Rule** — `trigger_variables:` exists to pass inputs into trigger options. Nothing else.

### D: A boolean variable is always true

**Symptom** — A guard that should block never blocks.

**Cause** — A `{% if %}` block that renders the bare word `false` produces the **string**
`"false"`, which is truthy.

**Fix** — Render booleans as a single `{{ … }}` expression.

**Rule** — Multi-branch `{% if %}` is only for variables consumed as strings or numbers.

### E: Template blows up when an optional entity is not configured

**Symptom** — Works for you, fails for users who left an optional input empty.

**Cause** — The idiomatic default for an optional entity input is `[]`, and `states([])`
raises rather than returning `unknown`.

**Fix** — Guard every use: `{{ my_input == [] or states(my_input) … }}`.

**Rule** — Every `default: []` input is guarded at **every** use site, including trigger
templates and `availability:`.

### F: `script/blueprint-check` reports an unused input

**Symptom** — Validation fails on an input you are sure you use.

**Cause** — Usually a rename that updated the `!input` reference but not the declaration,
or the reverse. The check runs both directions.

**Fix** — Make declarations and references agree. Delete inputs that no longer have a use.

**Rule** — A dead input is a form field the user must reason about for no reason. Removing
one is a breaking change — do it deliberately, not as cleanup.

### G: A required input hides inside a collapsed section

**Symptom** — Users report the blueprint "does nothing" and their configuration looks empty.

**Cause** — An input without a `default:` inside a `collapsed: true` section. The schema
permits it (verified against the pinned HA), so nothing warns you — but the user never
opens the section and never fills the field in.

**Fix** — Give every input in a collapsed section a `default:`; keep required inputs in an
expanded section.

**Rule** — Collapsed means optional. If it is required, it is not advanced.

### H: Legacy syntax silently keeps working — until it does not

**Symptom** — A blueprint copied from an old forum post validates but behaves oddly, or
breaks after an HA upgrade.

**Cause** — `platform:`/`service:` and singular `trigger:`/`action:` block keys are legacy
spellings. They still load, which is exactly why they spread.

**Fix** — Plural `triggers:`/`conditions:`/`actions:` with in-item `trigger:`/`condition:`/
`action:` keys. Requires `min_version: 2024.10.0`.

**Rule** — Copied examples get converted before they get committed. Check the date on any
example you copy; purpose-specific triggers changed the idiom again in 2026.7.

---

## Runtime behaviour

### I: The wait timer does not restart on renewed motion

**Symptom** — Light goes off while the room is still occupied.

**Cause** — `mode: single` (the default) ignores the new trigger, so the original run's
delay keeps counting from the first detection.

**Fix** — `mode: restart` plus `max_exceeded: silent`.

**Rule** — Any automation with a delay driven by a repeating trigger wants `restart`.
`max_exceeded: silent` because "re-triggered" is the normal case, not a warning.

### J: Automation does not resume after a Home Assistant restart

**Symptom** — Light stays on forever; the run was parked in `wait_for_trigger` or `delay:`
when HA restarted.

**Cause** — Automations do not resume. The run is simply gone.

**Fix** — Decide whether a half-finished state is acceptable. If not, add a
`homeassistant: start` trigger that re-evaluates and repairs the state, and document the
behaviour in the blueprint description.

**Rule** — Every blueprint with a suspension point must answer "what if HA restarts here?"
in its description, even if the answer is "nothing happens, turn it off manually".

### K: Trigger fires on `unavailable` → `on`

**Symptom** — The automation runs at Home Assistant startup, or after an integration reload,
with nobody present.

**Cause** — A state trigger with only `to: "on"` also matches a transition out of
`unavailable`/`unknown`.

**Fix** — Pin the origin: `from: "off"` `to: "on"`. Or use a purpose-specific trigger:
those filter `unavailable`/`unknown` out of the target state, and by default out of the
origin state too (individual trigger types may relax the origin check — confirm in a trace
if it matters).

**Rule** — State triggers name both ends. This is the most common source of "ghost"
automation runs.

### L: `for:` never elapses on a flapping sensor

**Symptom** — A trigger with `for: "00:05:00"` never fires even though the sensor looks
stable.

**Cause** — Any intermediate state change resets the timer, including a brief
`unavailable`.

**Fix** — Accept it, or filter with a `numeric_state`/template condition instead, or debounce
upstream with a helper.

**Rule** — `for:` means _uninterrupted_. Verify against a real trace, not intuition.

### M: A `target` with several entities produces surprising logic

**Symptom** — Behaviour is right for one light and wrong for three.

**Cause** — `target` selectors accept multiple entities, devices, and whole areas. Logic
written for a single entity (`states(target)`, position comparisons) does not generalise.

**Fix** — Either iterate with `expand()`, or use a purpose-specific trigger/condition with
an explicit `behavior:` (`each`/`all`/`first`, `any`/`all`).

**Rule** — Ask "what if the user picks an entire area?" before shipping any `target` input.

### N: Condition passes for one entity out of five

**Symptom** — An automation acts when it should not.

**Cause** — Purpose-specific conditions default to `behavior: any`.

**Fix** — Set `behavior: all` where you mean "all of them".

**Rule** — Never rely on the default `behavior:` when the target can hold more than one
entity. Write it explicitly.

### O: `device_id` breaks after the user replaces hardware

**Symptom** — A previously working automation silently stops.

**Cause** — Device references are registry ids tied to one physical device.

**Fix** — `entity_id`, always.

**Rule** — The one legitimate exception is a Zigbee2MQTT/ZHA button device trigger, where
no entity carries the event. Everything else uses entities.

### P: Service call reports "entity not found" for a valid entity

**Symptom** — Runs fine in your instance, fails in a user's.

**Cause** — Hardcoded entity id, or an unfiltered selector that let the user pick something
the action cannot act on (e.g. a `sensor` where a `light` was needed).

**Fix** — Filter the selector by `domain` and `device_class`; never hardcode.

**Rule** — The selector filter is the validation. If the picker can offer it, the logic must
handle it.

---

## Interface and distribution

### Q: Users' automations lose their configuration after an update

**Symptom** — After re-importing, fields are empty or reset to defaults.

**Cause** — An input key was renamed or removed. Stored configurations reference keys by
name.

**Fix** — Keep the old key working, or make it a documented breaking change: warn the
developer, use a `BREAKING CHANGE:` commit footer, and say in the release notes what users
must reconfigure.

**Rule** — Input keys are a public API. Adding a key _with a default_ is safe; changing one
is not.

### R: The fix never reaches users

**Symptom** — A bug is fixed on `main`, users still report it.

**Cause** — Home Assistant does not auto-update imported blueprints. Users receive changes
only when they re-import.

**Fix** — Say so in the release notes, explicitly, for anything users should pick up.

**Rule** — A release here is a **communication** event, not a distribution event. See the
**ha-blueprint-release** skill.

### S: Re-import is greyed out or points at the wrong file

**Symptom** — Users cannot update the blueprint.

**Cause** — `source_url` missing, or no longer matching the file's actual path after a
rename or move.

**Fix** — `source_url` is the GitHub blob URL of this file on `main`.
`script/blueprint-check` verifies it against the real path.

**Rule** — Renaming or moving a blueprint file breaks `source_url`, every README badge, and
every forum link. Choose the filename carefully the first time.

### T: Blueprint refuses to import on a user's instance

**Symptom** — "This blueprint requires Home Assistant X or later."

**Cause** — `homeassistant.min_version` above the user's version — often raised silently by
adopting new syntax.

**Fix** — Intended behaviour. The mistake is raising `min_version` _without deciding to_.
Purpose-specific triggers require 2026.7.0; input sections require 2024.6.0; plural
trigger/action keys require 2024.10.0.

**Rule** — `min_version` is a distribution decision, not a technical detail. Record it in the
commit message. See [ha-version-matrix.md](ha-version-matrix.md).

### U: CI cannot validate the blueprint

**Symptom** — `script/blueprint-check` fails with a `min_version` error.

**Cause** — `min_version` newer than the pinned development Home Assistant (`HA_VERSION` in
`.devcontainer/.env`).

**Fix** — Lower `min_version`, or bump `HA_VERSION` **and** `pytest-homeassistant-custom-component`
in `requirements_test.txt` together. That file is agent-protected: propose the change, do
not apply it.

**Rule** — An unvalidatable claim is worse than no claim.

### V: The description says nothing users need

**Symptom** — Support questions that the description should have answered.

**Cause** — Description written for developers: which helpers, which mode, which
`wait_for_trigger`.

**Fix** — Three things, in order: what it does (one plain sentence), what it needs (entity
types, integrations, helpers), what is surprising (restart behaviour, re-triggering,
unavailable entities).

**Rule** — The description is the only documentation most users read, and it is the last
thing they see before deciding whether to trust the blueprint.

### W: A script blueprint field's `default:` is ignored

**Symptom** — Calling the script without the optional field raises
`UndefinedError: 'x' is undefined`, even though the field declares `default:`.

**Cause** — A `field:`'s `default:` fills the UI form. It is **not** injected as a variable.
When the caller omits the field, the variable does not exist — and `| int(3)` / `| float(0)`
only supply a fallback for a value that _does_ exist.

**Fix** — `{{ x | default(3) | int }}`, or set the fallback in a `variables:` step before use.

**Rule** — `input` defaults are real values; `field` defaults are documentation. Every
optional field is read through `| default(…)`. Verified against the pinned Home Assistant.

---

## Adding an entry

Add one when a bug cost more than ten minutes and the cause was not obvious from the error.
Do **not** add one for a typo or a one-off.

Keep the four-part shape. The **Rule** line is the point of the entry — it is what a future
agent applies to code that does not resemble the original bug. An entry without a
generalisable rule is a changelog line, and belongs in the commit message instead.

If the pitfall is specific to one blueprint rather than to blueprints in general, it belongs
in that blueprint's notes file — see
[\_blueprint-notes.template.md](_blueprint-notes.template.md).
