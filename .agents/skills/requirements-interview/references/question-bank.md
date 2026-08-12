# Question bank

Working list for [`requirements-interview`](../SKILL.md). Read the section that matches the change, plus "Never
ask these".

Each entry is a **decision**, not a script — ask it one at a time, with your recommendation attached, and in the
developer's vocabulary rather than this table's ("Ask in the developer's language" in
[`../SKILL.md`](../SKILL.md)). The right-hand column is why it earns a turn: what breaks, or what you would
otherwise guess.

## 0. Before the first question

Answer these from the repository, then confirm the result in one line instead of asking:

| Look at                           | Tells you                                                        |
| --------------------------------- | ---------------------------------------------------------------- |
| `blueprints/*/<author>/*.yaml`    | Which blueprints exist, and the input conventions already in use |
| Their `homeassistant.min_version` | The floor this collection has already committed to               |
| `tests/`                          | What behaviour is already pinned, and the harness available      |
| `docs/development/DECISIONS.md`   | Choices already made, and what they oblige                       |
| `git log --oneline -20`           | What the developer has been working on, and in which style       |

If `initialize.sh` still exists, the collection has not been initialised — settle that before anything else
([`AGENTS.md`](../../../../AGENTS.md)).

## 1. A new blueprint

Order matters here: each block constrains the next. **Settle "What kind of thing this is" before assuming any of
the rest applies** — a template blueprint has no mode, no actions and no `max_exceeded`, and half of what follows
would be a wasted turn.

**What kind of thing this is** — the branch everything else hangs off

| The answer                                                      | What it means for the rest                                                 |
| --------------------------------------------------------------- | -------------------------------------------------------------------------- |
| It reacts to something happening, on its own                    | `automation` — the trigger and mode blocks below apply in full             |
| The user (or another automation) starts it deliberately         | `script` — no triggers; `fields:` and the return path matter instead       |
| It defines an entity whose value is derived from other entities | `template` — no mode, no actions; state and availability are the whole job |

More than one is a legitimate answer — "an automation that also exposes a helper sensor" is two blueprints, and
saying so early saves a redesign. Ask which, rather than forcing the request into one.

**Scope** — one blueprint or several

| Decision                                                                       | Why it earns a turn                                                        |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| Is this one blueprint with a switch, or two blueprints                         | A mode input that changes half the behaviour is usually two blueprints     |
| Which parts must the user be able to turn off entirely                         | An input that disables a whole branch versus a branch that is always there |
| Is there an existing blueprint — here or on the forum — that already does this | Extending one beats shipping a near-duplicate                              |
| Who is this for: the developer's own house, or strangers                       | Decides how much can be assumed and how forgiving the defaults must be     |

**What sets it off** — for the `automation` domain

| Decision                                                             | Why it earns a turn                                                         |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| What exactly happens in the house at the moment it should run        | Decides state trigger versus a purpose-specific trigger versus an event     |
| Does it also need to do something when the condition **ends**        | One trigger or two, and whether the off-path is a trigger or a `wait_for`   |
| Should several sensors count as one, or each on its own              | The `behavior:` option — `each`, `all`, or `first`                          |
| Are there times, days, or a sun position when it must not run        | Conditions versus a separate enable toggle input                            |
| Is there a manual-override case — someone touched the switch by hand | The single most common complaint about lighting blueprints                  |
| Must it survive a Home Assistant restart mid-run                     | A pending `delay:` or `wait_for_trigger` is lost; say so in the description |

**What the user picks** — the inputs, and the part that is expensive to get wrong

| Decision                                                               | Why it earns a turn                                                       |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| For each thing acted on: specific entities, or a whole area or label   | `target:` versus `entity:` — decides whether one automation covers a room |
| Which inputs are genuinely required, and which have a sensible default | Every required input is a user who might give up in the import dialog     |
| For each number: unit, range, and step                                 | A `number` selector without them is a free-text trap                      |
| For each choice: the complete set of options, and what happens on none | `select` options are user-visible and breaking to rename                  |
| Should related inputs be grouped, and should a group start collapsed   | A collapsed group hides everything in it, including anything required     |
| Is there anything the user should be able to run at the end            | An `action` selector input is the standard escape hatch                   |
| Does anything need free text at all                                    | Almost never. Ask what type it really is                                  |

**Behaviour under stress** — for the `automation` and `script` domains

| Decision                                                              | Why it earns a turn                                              |
| --------------------------------------------------------------------- | ---------------------------------------------------------------- |
| If it triggers again while still running: restart, queue, or ignore   | `mode:`, and the wrong one is a bug report about "missed" events |
| Is re-triggering normal, or a symptom                                 | `max_exceeded: silent` versus letting the warning through        |
| What should happen when a chosen entity is `unavailable` or `unknown` | The largest source of blueprint bug reports                      |
| What if the user picks nothing for an optional target                 | An empty target is not an error — decide whether it is skipped   |

**Version floor**

| Decision                                                        | Why it earns a turn                                                  |
| --------------------------------------------------------------- | -------------------------------------------------------------------- |
| Is a recent-only feature worth the version floor it costs       | Purpose-specific triggers read far better but raise `min_version`    |
| Which Home Assistant version do the intended users actually run | A floor above them means the blueprint refuses to load, with no hint |

## 2. A new input on an existing blueprint

| Decision                                                          | Why it earns a turn                                                 |
| ----------------------------------------------------------------- | ------------------------------------------------------------------- |
| Does it have a default that preserves today's behaviour exactly   | Without one, this is a breaking change for everyone who re-imports  |
| Which selector, and does an existing input already imply the type | Two inputs for one concept is how a blueprint becomes unusable      |
| Does it belong in an existing section, or does it need a new one  | Ungrouped inputs accumulate into a wall in the import dialog        |
| Does anything in the body have to handle it being unset           | `default` on the input is not the same as a value inside a template |
| Is this really an input, or a decision the blueprint should make  | Every option is a question asked of every user, forever             |

## 3. Anything that reaches users who already imported it

Ask before implementing, not in the pull request
([`ha-blueprint-release`](../../ha-blueprint-release/SKILL.md)):

| Decision                                                           | Why it earns a turn                                               |
| ------------------------------------------------------------------ | ----------------------------------------------------------------- |
| Is any input renamed or removed                                    | The user's configured value is dropped silently on re-import      |
| Does any selector change type                                      | The stored value is reinterpreted, not just re-picked             |
| Does the file name or path change                                  | It is the import URL — every published link and badge breaks      |
| Does `homeassistant.min_version` rise                              | Instances below it stop loading the blueprint entirely            |
| Does the trigger or action behaviour change in a way users rely on | Even an obvious fix is a surprise to someone who worked around it |
| Is the old behaviour worth keeping behind a new input              | The developer chooses; the default is to preserve, not to break   |

## Never ask these

The answer is already fixed. Asking invites a reply you would have to overrule, and spends a turn doing it. State
the rule instead if it comes up.

- Whether to use `device_id` — no. Entities and targets, always.
- Whether a free-text field is acceptable where a typed selector exists — it is not.
- Whether the file goes in the domain folder matching `blueprint.domain` — it must; Home Assistant loads by folder.
- Whether the extension may be `.yml` — no, Home Assistant's folder scan only matches `.yaml`.
- Whether `homeassistant.min_version` may be omitted — it may not.
- Whether `source_url` must match the real path — it must, or re-import breaks for every user.
- Whether the blueprint needs a runtime test — yes, at least the happy path.
- Whether to use the legacy `platform:`/`service:` keys — no, `trigger:`/`action:`.

## Three answers you must not take at face value

- **"Just like the example one."** The collection's example blueprints demonstrate the file layout and the test
  harness, not anyone's actual home. Ask what the real setup is.
- **"Whatever you think is best."** Fine for a genuinely reversible choice; not for input names, selector types,
  the file name, or `min_version`. For those, make a recommendation and get an explicit yes.
- **"It has an attribute for that."** An assumed attribute. It goes under **Open** in the brief until someone has
  looked at the real entity in Developer Tools.
