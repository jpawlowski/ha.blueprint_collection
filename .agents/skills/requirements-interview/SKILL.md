---
name: requirements-interview
description: >-
  Interview the developer until the requirements of a blueprint are actually settled, before any YAML is written.
  Use when asked to "grill me", "roast me", "interview me", "ask me what you need to know", "I want a blueprint
  that <does something>", "let's add <feature>", "challenge my idea", or whenever a request names a goal but none
  of the decisions underneath it. Covers when to run the interview, the one-question-at-a-time loop, the
  decisions that must be closed before YAML, the tone switch between direct and roast, when to stop, and the
  brief that hands off to the other skills. SYMPTOMS — load this if you are about to: start writing a blueprint
  from a one-line request; send a wall of numbered questions; ask something the repository already answers; ask
  in Home Assistant vocabulary the developer has no reason to know; accept "like the example one" as a
  requirement; agree with a design you can already see a problem with; or keep the brief in your head until the
  end.
license: MIT
---

# Interview the developer before writing YAML

An agent that builds exactly what was asked builds the wrong thing surprisingly often. The request is the tip of
a decision tree, and every branch left unasked gets guessed.

Here the guesses are expensive in a specific way. A blueprint's inputs are a **public interface**: users
configure automations through them, and they receive a change only when they re-import — with the values they
already chose still in place. An input renamed after publication silently drops that value; a selector whose type
changed reinterprets it. A question costs a minute now; the same question answered after publication costs a
breaking release ([`ha-blueprint-release`](../ha-blueprint-release/SKILL.md)). **Interrogate first — that is the
whole point of this skill.**

## When to run it

| Situation                                                            | Interview?                                                                     |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| A new blueprint, nothing written yet                                 | **Yes** — it produces the facts the authoring skill demands                    |
| An existing blueprint that already has users, about to be reworked   | **Yes** — the install base decides how much change is affordable               |
| A new input, a new mode, an extra branch                             | Yes, once more than two or three decisions are open                            |
| A one-line request whose scope you cannot state back in one sentence | Yes                                                                            |
| A bug with a known cause                                             | No — debug it ([`ha-blueprint-authoring`](../ha-blueprint-authoring/SKILL.md)) |
| A complete spec is already on the table                              | No. Say so, name the two or three real gaps, ask only those.                   |

Do not run it as a ritual. If nothing you could ask would change a file, you are stalling, not scoping.

## The loop

1. **Read before you ask.** Every question the repository already answers spends the developer's patience on
   nothing. Check the existing blueprints under `blueprints/`, their tests,
   [`docs/development/DECISIONS.md`](../../../docs/development/DECISIONS.md) and recent commits first. Then
   _state_ what you found and ask for confirmation instead — "the existing motion blueprint takes a target, not
   an entity list; same here?" is one word to answer.
2. **One question at a time.** A numbered list of twelve gets one reply covering three of them, and the other
   nine turn into assumptions. Ask, wait, use the answer to pick the next question.
3. **Every question carries your recommendation.** "A, B or C? I would take B, because a target selector lets one
   automation cover a whole area." The developer confirms in a word or corrects you in a sentence — either way
   you learn more than an open question would have got you.
4. **Follow the dependencies, do not tour the topics.** Resolve what other decisions hang off first: the domain
   before anything about triggers, one blueprint or two before the input list, target-or-entity before the
   action bodies. A decided branch usually kills three questions further down.
5. **Say it when you disagree.** If an answer creates a problem later — an input that will have to be renamed, a
   free-text field where a selector exists, a `mode:` that will drop runs the user expects to queue — name it in
   the same turn, with the consequence. Silent compliance here is the failure this skill exists to prevent.
6. **Show the running state every few questions**, read back from the brief file you are already appending to. A
   short "settled so far" list lets the developer catch a misunderstanding at question 8 instead of in the diff.

**Stop when no remaining question would change a file** — not at a question count, and not when the developer
sounds tired. A new blueprint usually takes fifteen to thirty questions; a second input takes three. If they
break off early, that is their call: record what is unresolved under **Open** and say what it blocks.

## Ask in the developer's language

The bank below is written in this project's vocabulary because it is a working list for you. **The question you
actually put to the developer is not.** Someone can know exactly what they want their lights to do and never have
met a selector.

| Do not ask                                | Ask                                                                                          |
| ----------------------------------------- | -------------------------------------------------------------------------------------------- |
| Target selector or entity selector?       | Should one automation cover a whole room, or does each light get its own?                    |
| Which `mode:` should this use?            | If it triggers again while it is still running, should it start over, queue, or be ignored?  |
| Should this input have a `default:`?      | Is there a sensible value most people would keep, or must everyone decide?                   |
| Do we need `max_exceeded: silent`?        | Is it normal for this to fire faster than it finishes, or is that a sign something is wrong? |
| What is the `homeassistant.min_version`?  | Is it fine if this only works on a recent Home Assistant, or must it run on older ones?      |
| Should this be a script or an automation? | Does this run on its own when something happens, or does the user start it?                  |

When the decision has to be recorded in this project's terms, give both: "that means `mode: restart` — a new
motion event cancels the pending off-timer." The developer picks up the word from a decision they just made,
which is the only way it sticks.

## What has to be closed before YAML

The question bank is the working list — do not improvise it from memory:

| File                                                         | When to read                                                                     |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| [`references/question-bank.md`](references/question-bank.md) | Every interview. Pick the section matching the change, and the "never ask" list. |

The bank is organised by change type: a new blueprint, a new input on an existing one, and anything that reaches
users who have already imported it. It also lists what **not** to ask — questions this project's rules have
already decided, where asking invites an answer you would have to overrule anyway.

## Tone

**Default: direct.** No opening praise, no "great question", no agreeing with something you can see a problem
with. "Sounds good" is not information — if part of the idea is genuinely right, say which part and move on.
Equally: do not manufacture objections to look rigorous. Direct means the assessment is honest in both
directions.

**`--roast`** — the developer asked for it, in the invocation or in plain words ("roast me", "be brutal", "don't
be nice"). It changes the wording, never the substance:

- Every jab still lands on something concrete — a file, a line, a decision, a consequence. A roast without a
  reference is just noise, and the developer cannot act on it.
- The design, the YAML and the plan get roasted. The developer never does.
- The questions do not get fewer or softer. Harder tone, same rigour, same recommendations.

Both modes obey [`AI_POLICY.md`](../../../AI_POLICY.md): do not claim to have verified something you did not run.

## The brief — written as you go, not at the end

An interview that produces no artefact was a chat. **Open `.agents/scratch/brief-<topic>.md` at the first settled
decision and append to it as each one lands** — the same gitignored directory plans live in
([`change-planning`](../change-planning/SKILL.md)).

Writing it up at the end is the failure mode this section exists to prevent. Thirty questions outlast a context
window: what is on disk survives a summarisation, a crash, and tomorrow, and what is only in the conversation
does not. Appending also forces the decision to be stated in one line at the moment it is made, which is when it
is still possible to notice that it was never actually settled.

The file, not your memory, is the "settled so far" list that loop rule 6 shows the developer.

```markdown
# Brief: <what is being built>

## Decided

- <decision> — <the reason, one line>

## Rejected

- <option> — <why it lost>

## Open

- <what the developer deferred> — blocks <what>

## Input list

- `<input_name>` — <selector>, <required or default> — <what it means to the user>

## Next

<skill to load, and the first file to touch>
```

The **Input list** is the part to read back before implementing. It is the blueprint's public interface, and
being wrong about it is the cheapest bug this project has — but only while it is still a list.

## Hand off

| The brief describes                          | Continue with                                                         |
| -------------------------------------------- | --------------------------------------------------------------------- |
| A blueprint that can now be written          | [`ha-blueprint-authoring`](../ha-blueprint-authoring/SKILL.md)        |
| More than ~10 files, or a restructure        | [`change-planning`](../change-planning/SKILL.md) — plan, then confirm |
| A choice that is expensive to reverse        | `change-planning` → an entry in `docs/development/DECISIONS.md`       |
| Behaviour worth checking against real HA     | [`ha-blueprint-testing`](../ha-blueprint-testing/SKILL.md)            |
| Anything reaching users who already imported | [`ha-blueprint-release`](../ha-blueprint-release/SKILL.md) **first**  |

Small and fully settled goes straight to implementation — the brief has already done the planning a plan would
repeat.

## Do not

- Do not ask what the repository or a decision record already states. Confirm it in one line instead.
- Do not send a wall of questions, and do not ask one without a recommendation attached.
- Do not ask in vocabulary the developer never signed up for, and do not read a vague answer as agreement — it
  more often means the question was in the wrong language.
- Do not accept "like the example one" as an answer. The collection's example blueprints demonstrate the file
  layout and the test harness, not anyone's actual home.
- Do not accept an invented entity or attribute. If nobody has confirmed that a device exposes it, that goes
  under **Open**, not into a guess.
- Do not hold the brief in your head until the end. Append as each decision lands, or a long interview loses the
  early half of itself to a context window.
- Do not close an interview without a brief and a named next step.
- Do not interview a bug report, and do not interview again over a spec that is already complete.
- Do not soften a finding because the developer sounds attached to the idea, and do not turn `--roast` into an
  insult with no file attached to it.
